import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import dotenv from 'dotenv';
import { getCourse, getSession, getUserProfile, db } from './firestore';
import { requireAdmin, requireAuth, requireChecker } from './auth';
import Stripe from 'stripe';
import { getStripe } from './stripe';
import { signQrToken, verifyQrToken } from './qr';
import { PaymentType } from './types';

dotenv.config();

const REGION = 'us-central1';
const CURRENCY = 'mxn';

export const setRole = functions.region(REGION).https.onCall(async (data, context) => {
  requireAdmin(context);
  const uid = data?.uid as string | undefined;
  const role = data?.role as string | undefined;
  if (!uid || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'uid and role are required');
  }
  if (!['admin', 'checker', 'customer'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'invalid role');
  }
  await admin.auth().setCustomUserClaims(uid, { role });
  return { ok: true };
});

export const createPaymentIntentFull = functions.region(REGION).https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const courseId = data?.courseId as string | undefined;
  if (!courseId) {
    throw new functions.https.HttpsError('invalid-argument', 'courseId is required');
  }
  const course = await getCourse(courseId);
  if (!course || !course.data.isActive) {
    throw new functions.https.HttpsError('not-found', 'Course not found');
  }
  if (course.data.paymentModeAllowed === 'per_session_only') {
    throw new functions.https.HttpsError('failed-precondition', 'Course does not allow full payment');
  }

  const paymentRef = db.collection('payments').doc();
  const amount = Math.round(course.data.priceFull * 100);
  const stripe = getStripe();

  await paymentRef.set({
    uid,
    courseId,
    enrollmentId: null,
    type: 'full' as PaymentType,
    sessionIds: [],
    amount,
    currency: CURRENCY,
    provider: 'stripe',
    stripePaymentIntentId: null,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    confirmedAt: null,
  });

  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency: CURRENCY,
    metadata: {
      paymentId: paymentRef.id,
      uid,
      courseId,
      type: 'full',
    },
  });

  await paymentRef.update({
    stripePaymentIntentId: paymentIntent.id,
    status: paymentIntent.status,
  });

  return { clientSecret: paymentIntent.client_secret, paymentId: paymentRef.id };
});

export const createPaymentIntentSessions = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const courseId = data?.courseId as string | undefined;
    const sessionIds = (data?.sessionIds as string[]) ?? [];
    if (!courseId || sessionIds.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'courseId and sessionIds are required');
    }
    const course = await getCourse(courseId);
    if (!course || !course.data.isActive) {
      throw new functions.https.HttpsError('not-found', 'Course not found');
    }
    if (course.data.paymentModeAllowed === 'full_only') {
      throw new functions.https.HttpsError('failed-precondition', 'Course does not allow per-session payment');
    }

    const sessions = await Promise.all(
      sessionIds.map((sessionId) => getSession(courseId, sessionId))
    );
    const invalid = sessions.find((session) => !session || !session.data.isActive);
    if (invalid) {
      throw new functions.https.HttpsError('failed-precondition', 'One or more sessions are invalid');
    }

    const amount = Math.round(
      sessions.reduce((sum, session) => sum + (session?.data.price ?? 0), 0) * 100
    );

    const paymentRef = db.collection('payments').doc();
    const stripe = getStripe();

    await paymentRef.set({
      uid,
      courseId,
      enrollmentId: null,
      type: 'sessions' as PaymentType,
      sessionIds,
      amount,
      currency: CURRENCY,
      provider: 'stripe',
      stripePaymentIntentId: null,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      confirmedAt: null,
    });

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: CURRENCY,
      metadata: {
        paymentId: paymentRef.id,
        uid,
        courseId,
        type: 'sessions',
        sessionIds: sessionIds.join(','),
      },
    });

    await paymentRef.update({
      stripePaymentIntentId: paymentIntent.id,
      status: paymentIntent.status,
    });

    return { clientSecret: paymentIntent.client_secret, paymentId: paymentRef.id };
  });

export const issueCourseQrToken = functions.region(REGION).https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const courseId = data?.courseId as string | undefined;
  if (!courseId) {
    throw new functions.https.HttpsError('invalid-argument', 'courseId is required');
  }
  const enrollmentSnap = await db
    .collection('enrollments')
    .where('uid', '==', uid)
    .where('courseId', '==', courseId)
    .where('status', '==', 'active')
    .limit(1)
    .get();

  if (enrollmentSnap.empty) {
    throw new functions.https.HttpsError('failed-precondition', 'Enrollment not active');
  }

  const expiresIn = 60 * 15;
  const issuedAt = Math.floor(Date.now() / 1000);
  const token = signQrToken({ uid, courseId, issuedAt }, expiresIn);
  const exp = issuedAt + expiresIn;

  await enrollmentSnap.docs[0].ref.update({
    lastQrIssuedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { token, exp };
});

export const validateCourseQrToken = functions.region(REGION).https.onCall(async (data, context) => {
  requireChecker(context);
  const token = data?.token as string | undefined;
  const sessionId = data?.sessionId as string | undefined;
  if (!token || !sessionId) {
    throw new functions.https.HttpsError('invalid-argument', 'token and sessionId are required');
  }

  let decoded;
  try {
    decoded = verifyQrToken(token);
  } catch (error) {
    const reason =
      error instanceof Error && error.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'INVALID_TOKEN';
    return {
      allowed: false,
      reason,
      alreadyCheckedIn: false,
      userDisplay: null,
      courseDisplay: null,
      paymentSnapshot: null,
    };
  }

  const { uid, courseId } = decoded;
  if (!uid || !courseId) {
    throw new functions.https.HttpsError('failed-precondition', 'INVALID_TOKEN');
  }

  const course = await getCourse(courseId);
  if (!course || !course.data.isActive) {
    return {
      allowed: false,
      reason: 'COURSE_INACTIVE',
      alreadyCheckedIn: false,
      userDisplay: null,
      courseDisplay: null,
      paymentSnapshot: null,
    };
  }

  const session = await getSession(courseId, sessionId);
  if (!session || !session.data.isActive) {
    return {
      allowed: false,
      reason: 'SESSION_NOT_PAID',
      alreadyCheckedIn: false,
      userDisplay: null,
      courseDisplay: { title: course.data.title, sedeId: course.data.sedeId, stateId: course.data.stateId },
      paymentSnapshot: null,
    };
  }

  const enrollmentSnap = await db
    .collection('enrollments')
    .where('uid', '==', uid)
    .where('courseId', '==', courseId)
    .where('status', '==', 'active')
    .limit(1)
    .get();

  if (enrollmentSnap.empty) {
    return {
      allowed: false,
      reason: 'NOT_ENROLLED',
      alreadyCheckedIn: false,
      userDisplay: null,
      courseDisplay: { title: course.data.title, sedeId: course.data.sedeId, stateId: course.data.stateId },
      paymentSnapshot: null,
    };
  }

  const enrollment = enrollmentSnap.docs[0].data();
  const paidFull = Boolean(enrollment.paidFull);
  const sessionsPaid = (enrollment.sessionsPaid as string[]) ?? [];
  const sessionsPaidContainsThisSession = sessionsPaid.includes(sessionId);
  const paymentSnapshot = {
    paidFull,
    sessionsPaidCount: sessionsPaid.length,
    sessionsPaidContainsThisSession,
  };

  if (!paidFull && sessionsPaid.length === 0) {
    return {
      allowed: false,
      reason: 'PAYMENT_REQUIRED',
      alreadyCheckedIn: false,
      userDisplay: null,
      courseDisplay: { title: course.data.title, sedeId: course.data.sedeId, stateId: course.data.stateId },
      paymentSnapshot,
    };
  }

  if (!paidFull && !sessionsPaidContainsThisSession) {
    return {
      allowed: false,
      reason: 'SESSION_NOT_PAID',
      alreadyCheckedIn: false,
      userDisplay: null,
      courseDisplay: { title: course.data.title, sedeId: course.data.sedeId, stateId: course.data.stateId },
      paymentSnapshot,
    };
  }

  const recordRef = db.doc(`attendance/${courseId}/sessions/${sessionId}/records/${uid}`);
  let alreadyCheckedIn = false;

  await db.runTransaction(async (tx) => {
    const recordSnap = await tx.get(recordRef);
    if (recordSnap.exists) {
      alreadyCheckedIn = true;
      return;
    }
    tx.set(recordRef, {
      uid,
      enrollmentId: enrollmentSnap.docs[0].id,
      checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
      checkedInBy: context.auth?.uid ?? null,
      validationSnapshot: {
        paidFull,
        sessionsPaidCount: sessionsPaid.length,
        allowedReason: 'OK',
      },
    });
  });

  if (alreadyCheckedIn) {
    return {
      allowed: false,
      reason: 'ALREADY_CHECKED_IN',
      alreadyCheckedIn: true,
      userDisplay: null,
      courseDisplay: { title: course.data.title, sedeId: course.data.sedeId, stateId: course.data.stateId },
      paymentSnapshot,
    };
  }

  const userDisplay = await getUserProfile(uid);

  return {
    allowed: true,
    reason: null,
    alreadyCheckedIn: false,
    userDisplay,
    courseDisplay: { title: course.data.title, sedeId: course.data.sedeId, stateId: course.data.stateId },
    paymentSnapshot,
  };
});

export const stripeWebhook = functions.region(REGION).https.onRequest(async (req, res) => {
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret) {
    res.status(500).send('Missing STRIPE_WEBHOOK_SECRET');
    return;
  }
  const signature = req.headers['stripe-signature'];
  if (!signature || Array.isArray(signature)) {
    res.status(400).send('Missing stripe signature');
    return;
  }

  const stripe = getStripe();
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, signature, secret);
  } catch (error) {
    res.status(400).send('Invalid signature');
    return;
  }

  if (event.type.startsWith('payment_intent')) {
    const paymentIntent = event.data.object as { id: string; status: string; metadata?: Record<string, string> };

    const paymentId = paymentIntent.metadata?.paymentId;
    const uid = paymentIntent.metadata?.uid;
    const courseId = paymentIntent.metadata?.courseId;
    const type = paymentIntent.metadata?.type as PaymentType | undefined;
    const sessionIds = paymentIntent.metadata?.sessionIds
      ? paymentIntent.metadata?.sessionIds.split(',').filter(Boolean)
      : [];

    let paymentRef = paymentId ? db.collection('payments').doc(paymentId) : null;
    if (paymentRef && !(await paymentRef.get()).exists) {
      paymentRef = null;
    }
    if (!paymentRef) {
      const snap = await db
        .collection('payments')
        .where('stripePaymentIntentId', '==', paymentIntent.id)
        .limit(1)
        .get();
      if (!snap.empty) {
        paymentRef = snap.docs[0].ref;
      }
    }

    if (paymentRef) {
      await paymentRef.set(
        {
          status: paymentIntent.status,
          confirmedAt:
            paymentIntent.status === 'succeeded'
              ? admin.firestore.FieldValue.serverTimestamp()
              : null,
        },
        { merge: true }
      );
    }

    if (event.type === 'payment_intent.succeeded' && uid && courseId && type) {
      const enrollmentSnap = await db
        .collection('enrollments')
        .where('uid', '==', uid)
        .where('courseId', '==', courseId)
        .limit(1)
        .get();

      const course = await getCourse(courseId);
      if (course) {
        let enrollmentId: string | null = null;
        const payload = {
          uid,
          courseId,
          stateId: course.data.stateId,
          sedeId: course.data.sedeId,
          status: 'active',
          paidFull: type === 'full',
          sessionsPaid: type === 'sessions' ? sessionIds : [],
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (enrollmentSnap.empty) {
          const newRef = await db.collection('enrollments').add({
            ...payload,
            paidFull: type === 'full',
            sessionsPaid: type === 'sessions' ? sessionIds : [],
            status: 'active',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          enrollmentId = newRef.id;
        } else {
          const ref = enrollmentSnap.docs[0].ref;
          enrollmentId = ref.id;
          await ref.set(
            {
              paidFull: type === 'full' ? true : enrollmentSnap.docs[0].data().paidFull,
              sessionsPaid: type === 'sessions'
                ? Array.from(new Set([...(enrollmentSnap.docs[0].data().sessionsPaid ?? []), ...sessionIds]))
                : enrollmentSnap.docs[0].data().sessionsPaid ?? [],
              status: 'active',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }

        if (paymentRef && enrollmentId) {
          await paymentRef.set({ enrollmentId }, { merge: true });
        }
      }
    }
  }

  res.json({ received: true });
});
