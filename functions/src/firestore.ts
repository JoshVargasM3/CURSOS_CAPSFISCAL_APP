import * as admin from 'firebase-admin';
import { CourseData, SessionData } from './types';

admin.initializeApp();

export const db = admin.firestore();

export async function getCourse(courseId: string) {
  const snap = await db.doc(`courses/${courseId}`).get();
  if (!snap.exists) {
    return null;
  }
  return { id: snap.id, data: snap.data() as CourseData };
}

export async function getSession(courseId: string, sessionId: string) {
  const snap = await db.doc(`courses/${courseId}/sessions/${sessionId}`).get();
  if (!snap.exists) {
    return null;
  }
  return { id: snap.id, data: snap.data() as SessionData };
}

export async function getUserProfile(uid: string) {
  const snap = await db.doc(`users/${uid}`).get();
  if (!snap.exists) {
    return null;
  }
  return snap.data() as { fullName?: string; email?: string; phone?: string };
}
