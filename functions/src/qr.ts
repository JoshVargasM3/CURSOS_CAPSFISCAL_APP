import jwt from 'jsonwebtoken';

export interface QrTokenPayload {
  uid: string;
  courseId: string;
  issuedAt: number;
}

export function signQrToken(payload: QrTokenPayload, expiresInSeconds: number) {
  const secret = process.env.QR_SECRET;
  if (!secret) {
    throw new Error('QR_SECRET is not configured');
  }
  return jwt.sign(payload, secret, { expiresIn: expiresInSeconds });
}

export function verifyQrToken(token: string) {
  const secret = process.env.QR_SECRET;
  if (!secret) {
    throw new Error('QR_SECRET is not configured');
  }
  return jwt.verify(token, secret) as QrTokenPayload & jwt.JwtPayload;
}
