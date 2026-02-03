export type Role = 'admin' | 'checker' | 'customer';

export type PaymentType = 'full' | 'sessions';

export type PaymentStatus =
  | 'requires_payment_method'
  | 'requires_action'
  | 'processing'
  | 'succeeded'
  | 'canceled'
  | 'failed'
  | 'pending';

export interface CourseData {
  title: string;
  description: string;
  stateId: string;
  sedeId: string;
  startDate: string;
  endDate: string;
  priceFull: number;
  paymentModeAllowed: 'full_only' | 'per_session_only' | 'both';
  isActive: boolean;
}

export interface SessionData {
  title: string;
  dateTime: string;
  price: number;
  isActive: boolean;
}

export interface EnrollmentData {
  uid: string;
  courseId: string;
  stateId: string;
  sedeId: string;
  status: 'pending' | 'active' | 'cancelled' | 'completed';
  paidFull: boolean;
  sessionsPaid: string[];
  lastQrIssuedAt?: FirebaseFirestore.Timestamp;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}
