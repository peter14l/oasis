# External Integrations

**Analysis Date:** 2026-04-09

## APIs & External Services

**Backend/Auth:**
- Supabase - Backend-as-a-service for authentication and database
  - SDK: `@supabase/supabase-js` 2.99.3
  - Auth: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
  - Location: `src/supabaseClient.js`
  - Features used: Auth, Database, Edge Functions
  - Edge Functions invoked:
    - `razorpay-create-order` - Create Razorpay payment order
    - `razorpay-verify` - Verify Razorpay payment
    - `paypal-verify` - Verify PayPal payment
    - `payu-init` - Initialize PayU payment

**Payment Gateways:**

- **Razorpay** - Indian payment gateway
  - SDK: Script loaded from `https://checkout.razorpay.com/v1/checkout.js`
  - Key: `VITE_RAZORPAY_KEY_ID`
  - Location: `src/components/RazorpayPayment.jsx`
  - Flow: Client-side checkout with server verification via edge function

- **PayPal** - Global payment gateway
  - SDK: Script loaded from `https://www.paypal.com/sdk/js`
  - Client ID: `VITE_PAYPAL_CLIENT_ID`
  - Location: `src/components/PayPalPayment.jsx`
  - Flow: PayPal SDK buttons with order capture and verification

- **PayU** - Indian payment gateway (alternative)
  - Location: `src/components/PayUPayment.jsx`
  - Flow: Form POST to PayU with hash verification

**Animations:**
- GSAP (GreenSock Animation Platform)
  - Package: `gsap` 3.14.2
  - React integration: `@gsap/react` 2.1.2
  - Usage: Page animations and transitions

- Framer Motion
  - Package: `framer-motion` 12.29.2
  - Usage: Motion animations for UI elements

**Icons:**
- Lucide React
  - Package: `lucide-react` 0.563.0
  - Usage: Icon components throughout UI

**HTTP Client:**
- Axios
  - Package: `axios` 1.13.6
  - Usage: API requests (likely for payment callbacks or external APIs)

## Data Storage

**Database:**
- Supabase (PostgreSQL)
  - Managed by Supabase
  - Accessed via `@supabase/supabase-js` client

**File Storage:**
- Supabase Storage (implied)
  - For user-uploaded content (shared moments)

**Caching:**
- None detected

## Authentication & Identity

**Auth Provider:**
- Supabase Auth
  - Implementation: Using Supabase's built-in auth with email/password
  - Location: `src/supabaseClient.js`
  - Routes: Login (`/login`), SignUp (`/signup`), Profile (`/profile`)
  - Password reset: Handled via `oasis://` deep link protocol

## Monitoring & Observability

**Error Tracking:**
- None detected - No error tracking service configured

**Logs:**
- Browser console - Standard `console.log/error` for debugging

## CI/CD & Deployment

**Hosting:**
- Vercel - Primary deployment platform
  - Config: `vercel.json` with SPA rewrite rules
  - Builds: Automatic on git push

**CI Pipeline:**
- Vercel - Automatic builds and deployments

## Environment Configuration

**Required env vars:**
- `VITE_SUPABASE_URL` - Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Supabase anonymous key
- `VITE_RAZORPAY_KEY_ID` - Razorpay test/live key
- `VITE_PAYPAL_CLIENT_ID` - PayPal sandbox/live client ID
- `VITE_PAYU_MERCHANT_KEY` - PayU merchant key (implied for PayU)

**Secrets location:**
- Environment variables (Vite convention with `VITE_` prefix)
- Edge function secrets (managed in Supabase dashboard)

## Webhooks & Callbacks

**Incoming:**
- Payment webhooks - Handled via Supabase Edge Functions
  - Razorpay webhook → `razorpay-verify` edge function
  - PayPal webhook → `paypal-verify` edge function
  - PayU callback → Success/failure URLs (`surl`, `furl`)

**Outgoing:**
- Payment redirects:
  - Razorpay: Returns to checkout with handler callback
  - PayPal: Returns with order data
  - PayU: POST to `surl` (success) or `furl` (failure)

## Deep Links

**Mobile App Integration:**
- Custom protocol: `oasis://`
  - Used for password reset redirect to native app
  - Routes: `oasis://reset-password`

---

*Integration audit: 2026-04-09*