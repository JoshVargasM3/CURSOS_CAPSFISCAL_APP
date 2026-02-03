import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import Stripe from 'stripe';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

admin.initializeApp();
const db = admin.firestore();

const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripeWebhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
const qrSecret = process.env.QR_SECRET;
const defaultCurrency = process.env.DEFAULT_CURRENCY || 'usd';

if (!stripeSecretKey) {
  throw new Error('Missing STRIPE_SECRET_KEY');
}
if (!qrSecret) {
  throw new Error('Missing QR_SECRET');
}

const stripe = new Stripe(stripeSecretKey, { apiVersion: '2023-10-16' });

function assertRole(context: functions.https.CallableContext, role: string) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }
  const tokenRole = context.auth.token.role;
  if (tokenRole !== role && tokenRole !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Insufficient role');
  }
}

async function getCourse(courseId: string) {
  const courseSnap = await db.doc(`courses/${courseId}`).get();
  if (!courseSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Course not found');
  }
  return courseSnap;
}

async function getOrCreateEnrollment(uid: string, courseId: string, courseData: FirebaseFirestore.DocumentData) {
  const enrollments = await db
    .collection('enrollments')
    .where('uid', '==', uid)
    .where('courseId', '==', courseId)
    .limit(1)
    .get();

  if (!enrollments.empty) {
    return enrollments.docs[0];
  }

  const enrollmentRef = db.collection('enrollments').doc();
  await enrollmentRef.set({
    uid,
    courseId,
    stateId: courseData.stateId,
    sedeId: courseData.sedeId,
    status: 'pending',
    paidFull: false,
    sessionsPaid: [],
    lastQrIssuedAt: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  return enrollmentRef.get();
}

export const setRole = functions.https.onCall(async (data, context) => {
  assertRole(context, 'admin');
  const { uid, role } = data as { uid?: string; role?: string };
  if (!uid || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'uid and role required');
  }
  if (!['admin', 'checker', 'customer'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid role');
  }
  await admin.auth().setCustomUserClaims(uid, { role });
  return { ok: true };
});

export const createPaymentIntentFull = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }
  const { courseId } = data as { courseId?: string };
  if (!courseId) {
    throw new functions.https.HttpsError('invalid-argument', 'courseId required');
  }
  const courseSnap = await getCourse(courseId);
  const courseData = courseSnap.data()!;
  if (!courseData.isActive) {
    throw new functions.https.HttpsError('failed-precondition', 'Course inactive');
  }
  if (!['full_only', 'both'].includes(courseData.paymentModeAllowed)) {
    throw new functions.https.HttpsError('failed-precondition', 'Full payment not allowed');
  }

  const enrollmentSnap = await getOrCreateEnrollment(context.auth.uid, courseId, courseData);
  const paymentRef = db.collection('payments').doc();
  const amount = Math.round(Number(courseData.priceFull) * 100);

  const intent = await stripe.paymentIntents.create({
    amount,
    currency: defaultCurrency,
    metadata: {
      paymentId: paymentRef.id,
      uid: context.auth.uid,
      courseId,
      type: 'full'
    }
  });

  await paymentRef.set({
    uid: context.auth.uid,
    courseId,
    enrollmentId: enrollmentSnap.id,
    type: 'full',
    sessionIds: [],
    amount,
    currency: defaultCurrency,
    provider: 'stripe',
    stripePaymentIntentId: intent.id,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    confirmedAt: null
  });

  return { clientSecret: intent.client_secret, paymentId: paymentRef.id };
});

export const createPaymentIntentSessions = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }
  const { courseId, sessionIds } = data as { courseId?: string; sessionIds?: string[] };
  if (!courseId || !sessionIds || !Array.isArray(sessionIds) || sessionIds.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'courseId and sessionIds required');
  }
  const courseSnap = await getCourse(courseId);
  const courseData = courseSnap.data()!;
  if (!courseData.isActive) {
    throw new functions.https.HttpsError('failed-precondition', 'Course inactive');
  }
  if (!['per_session_only', 'both'].includes(courseData.paymentModeAllowed)) {
    throw new functions.https.HttpsError('failed-precondition', 'Session payment not allowed');
  }

  const sessionsSnap = await db
    .collection(`courses/${courseId}/sessions`)
    .where(admin.firestore.FieldPath.documentId(), 'in', sessionIds)
    .get();
  if (sessionsSnap.empty) {
    throw new functions.https.HttpsError('not-found', 'Sessions not found');
  }
  let amount = 0;
  sessionsSnap.docs.forEach((doc) => {
    const price = Number(doc.data().price || 0);
    amount += Math.round(price * 100);
  });

  const enrollmentSnap = await getOrCreateEnrollment(context.auth.uid, courseId, courseData);
  const paymentRef = db.collection('payments').doc();

  const intent = await stripe.paymentIntents.create({
    amount,
    currency: defaultCurrency,
    metadata: {
      paymentId: paymentRef.id,
      uid: context.auth.uid,
      courseId,
      type: 'sessions'
    }
  });

  await paymentRef.set({
    uid: context.auth.uid,
    courseId,
    enrollmentId: enrollmentSnap.id,
    type: 'sessions',
    sessionIds,
    amount,
    currency: defaultCurrency,
    provider: 'stripe',
    stripePaymentIntentId: intent.id,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    confirmedAt: null
  });

  return { clientSecret: intent.client_secret, paymentId: paymentRef.id };
});

export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  if (!stripeWebhookSecret) {
    res.status(500).send('Missing STRIPE_WEBHOOK_SECRET');
    return;
  }
  const sig = req.headers['stripe-signature'];
  if (!sig || typeof sig !== 'string') {
    res.status(400).send('Missing signature');
    return;
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeWebhookSecret);
  } catch (err) {
    res.status(400).send(`Webhook Error: ${(err as Error).message}`);
    return;
  }

  const intent = event.data.object as Stripe.PaymentIntent;
  const paymentId = intent.metadata?.paymentId;
  if (!paymentId) {
    res.status(200).send('No payment metadata');
    return;
  }

  const paymentRef = db.doc(`payments/${paymentId}`);
  const paymentSnap = await paymentRef.get();
  if (!paymentSnap.exists) {
    res.status(200).send('Payment not found');
    return;
  }
  const paymentData = paymentSnap.data()!;
  const enrollmentRef = db.doc(`enrollments/${paymentData.enrollmentId}`);

  if (event.type === 'payment_intent.succeeded') {
    await paymentRef.update({
      status: 'succeeded',
      confirmedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    if (paymentData.type === 'full') {
      await enrollmentRef.set(
        {
          paidFull: true,
          status: 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        { merge: true }
      );
    } else {
      await enrollmentRef.set(
        {
          sessionsPaid: admin.firestore.FieldValue.arrayUnion(...paymentData.sessionIds),
          status: 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        { merge: true }
      );
    }
  }

  if (event.type === 'payment_intent.payment_failed') {
    await paymentRef.update({ status: 'failed' });
  }

  if (event.type === 'charge.refunded') {
    await paymentRef.update({ status: 'refunded' });
  }

  res.status(200).send('ok');
});

export const issueCourseQrToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }
  const { courseId } = data as { courseId?: string };
  if (!courseId) {
    throw new functions.https.HttpsError('invalid-argument', 'courseId required');
  }
  const courseSnap = await getCourse(courseId);
  const courseData = courseSnap.data()!;
  const enrollmentSnap = await getOrCreateEnrollment(context.auth.uid, courseId, courseData);
  const enrollmentData = enrollmentSnap.data()!;
  const endDate = courseData.endDate?.toDate?.();
  if (!endDate) {
    throw new functions.https.HttpsError('failed-precondition', 'Course endDate missing');
  }
  const expDate = new Date(endDate.getTime() + 7 * 24 * 60 * 60 * 1000);
  const token = jwt.sign(
    {
      uid: context.auth.uid,
      courseId,
      exp: Math.floor(expDate.getTime() / 1000),
      jti: uuidv4()
    },
    qrSecret
  );
  await enrollmentSnap.ref.set(
    {
      lastQrIssuedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    { merge: true }
  );
  return { token, expiresAt: expDate.toISOString(), paidFull: enrollmentData.paidFull };
});

export const validateCourseQrToken = functions.https.onCall(async (data, context) => {
  assertRole(context, 'checker');
  const { token, sessionId } = data as { token?: string; sessionId?: string };
  if (!token) {
    throw new functions.https.HttpsError('invalid-argument', 'token required');
  }

  let payload: { uid: string; courseId: string };
  try {
    payload = jwt.verify(token, qrSecret) as { uid: string; courseId: string };
  } catch (err) {
    if ((err as Error).name === 'TokenExpiredError') {
      return { allowed: false, reason: 'TOKEN_EXPIRED' };
    }
    return { allowed: false, reason: 'INVALID_TOKEN' };
  }

  const enrollmentQuery = await db
    .collection('enrollments')
    .where('uid', '==', payload.uid)
    .where('courseId', '==', payload.courseId)
    .limit(1)
    .get();

  if (enrollmentQuery.empty) {
    return { allowed: false, reason: 'NOT_ENROLLED' };
  }

  const enrollmentSnap = enrollmentQuery.docs[0];
  const enrollmentData = enrollmentSnap.data();
  const courseSnap = await getCourse(payload.courseId);
  const courseData = courseSnap.data()!;

  if (!courseData.isActive) {
    return { allowed: false, reason: 'COURSE_INACTIVE' };
  }

  const paidFull = Boolean(enrollmentData.paidFull);
  const sessionsPaid: string[] = enrollmentData.sessionsPaid || [];
  const sessionAllowed = sessionId ? sessionsPaid.includes(sessionId) : false;

  if (!paidFull && sessionId && !sessionAllowed) {
    return { allowed: false, reason: 'SESSION_NOT_PAID' };
  }

  if (!paidFull && !sessionAllowed) {
    return { allowed: false, reason: 'PAYMENT_REQUIRED' };
  }

  let alreadyCheckedIn = false;
  if (sessionId) {
    const attendanceRef = db.doc(`attendance/${payload.courseId}/sessions/${sessionId}/records/${payload.uid}`);
    const attendanceSnap = await attendanceRef.get();
    if (attendanceSnap.exists) {
      alreadyCheckedIn = true;
    } else {
      await attendanceRef.set({
        uid: payload.uid,
        enrollmentId: enrollmentSnap.id,
        checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
        checkedInBy: context.auth?.uid || null,
        validationSnapshot: {
          paidFull,
          sessionsPaidCount: sessionsPaid.length,
          allowedReason: paidFull ? 'PAID_FULL' : 'SESSION_PAID'
        }
      });
    }
  }

  const userSnap = await db.doc(`users/${payload.uid}`).get();
  const userData = userSnap.data() || {};

  return {
    allowed: true,
    reason: alreadyCheckedIn ? 'ALREADY_CHECKED_IN' : 'ALLOWED',
    userDisplay: {
      fullName: userData.fullName || '',
      email: userData.email || '',
      phone: userData.phone || ''
    },
    courseDisplay: {
      title: courseData.title || '',
      sedeId: courseData.sedeId || '',
      stateId: courseData.stateId || ''
    },
    paymentSnapshot: {
      paidFull,
      sessionsPaidCount: sessionsPaid.length,
      sessionsPaidContainsThisSession: sessionId ? sessionsPaid.includes(sessionId) : false
    }
  };
});
