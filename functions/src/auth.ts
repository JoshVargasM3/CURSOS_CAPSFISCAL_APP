import * as functions from 'firebase-functions';
import { Role } from './types';

export function requireAuth(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }
  return context.auth.uid;
}

export function requireRole(context: functions.https.CallableContext, role: Role) {
  if (!context.auth || context.auth.token.role !== role) {
    throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions.');
  }
}

export function requireAdmin(context: functions.https.CallableContext) {
  requireRole(context, 'admin');
}

export function requireChecker(context: functions.https.CallableContext) {
  requireRole(context, 'checker');
}
