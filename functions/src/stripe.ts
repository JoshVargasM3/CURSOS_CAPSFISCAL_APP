import Stripe from 'stripe';

let stripe: Stripe | null = null;

export function getStripe() {
  if (stripe) {
    return stripe;
  }
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) {
    throw new Error('STRIPE_SECRET_KEY is not configured');
  }
  stripe = new Stripe(key, {
    apiVersion: '2024-04-10',
    typescript: true,
  });
  return stripe;
}
