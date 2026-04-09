# CONCERNS.md - Issues, Technical Debt, and Areas of Concern

## Overview

This document identifies potential issues, security concerns, performance problems, and technical debt in the Oasis web landing codebase.

---

## Security Concerns

### CRITICAL: Hardcoded Secrets in .env

The `.env` file contains **multiple sensitive credentials** that should never be committed to version control:

| Variable | Value | Risk |
|----------|-------|------|
| `VITE_SUPABASE_ANON_KEY` | Full Supabase JWT | Medium - exposes database access |
| `SENTRY_DSN` | Full Sentry DSN | Low - monitoring endpoint |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth ID | Low - publicly visible anyway |
| `GEMINI_API_KEY` | **AIzaSyA1ZOzJLeA7fUCAADvrWBVc330ya-AD-fQ** | CRITICAL - full Google AI access |
| `VITE_PAYPAL_CLIENT_ID` | PayPal API credentials | Medium - payment processing |
| `VITE_RAZORPAY_KEY_ID` | Razorpay test key | Low - test environment |

**Action Required:**
- Add `.env` to `.gitignore` immediately
- Rotate all exposed API keys
- Use environment-specific secrets for production

### No Authentication Security

- No CSRF protection detected
- No rate limiting on auth endpoints
- Session tokens stored in localStorage (vulnerable to XSS)
- No secure cookie flag for auth tokens

---

## Error Handling Issues

### Inadequate Error Messages

Auth flows use bare `alert()` for error display:

```jsx
// Login.jsx - Line 25, 41
} catch (err) {
  alert('Login failed');
}
```

**Problems:**
- No user-friendly error messages
- No logging to monitoring service (Sentry is configured but not used)
- No fallback UI states

### No Global Error Boundary

- React components can crash entire app
- No ErrorBoundary component implemented
- No graceful degradation for failed components

---

## Technical Debt

### No Testing Infrastructure

- **No test framework** (jest, vitest, etc.)
- **No test files** in codebase
- **No CI/CD test automation**
- Critical flows untested: auth, payments, routing

**High-Risk Areas Lacking Tests:**
1. Login/SignUp authentication flows
2. Payment integrations (Razorpay, PayPal, PayU)
3. Protected route behavior
4. Supabase client initialization

### No TypeScript

- Entire codebase in plain JavaScript
- No type safety for API responses
- No compile-time error detection
- Higher chance of runtime errors

### No Code Splitting

- All routes loaded at once (no lazy loading)
- Large bundle size potential
- No dynamic imports for payment libraries

---

## Payment Integration Concerns

### Multiple Payment Gateways Without Unified Interface

Three separate payment components:
- `RazorpayPayment.jsx`
- `PayPalPayment.jsx`
- `PayUPayment.jsx`

**Issues:**
- Inconsistent error handling across gateways
- No unified error reporting
- Each loads external scripts independently
- No payment failure logging

### Script Loading Vulnerabilities

Payment scripts loaded via dynamic script injection:

```jsx
// RazorpayPayment.jsx
const script = document.createElement('script');
script.src = 'https://checkout.razorpay.com/v1/checkout.js';
```

**Risks:**
- No integrity checking (subresource integrity)
- No script version pinning
- Vulnerable to CDN compromise

---

## Performance Concerns

### No Lazy Loading

All pages imported statically in App.jsx:

```jsx
import Home from './pages/Home';
import Login from './pages/Login';
// ... all pages loaded at once
```

### Large Bundle Potential

- GSAP (animation library) loaded for all users
- Framer Motion loaded for all users
- Three payment SDKs potentially loaded

### No Image Optimization

- No lazy loading for images
- No image compression
- No WebP format support

---

## Code Quality Issues

### Inline Styles Everywhere

Heavy use of inline styles makes:
- Theme changes difficult
- CSS maintenance harder
- No SSR/SSG compatibility

### No JSDoc or Documentation

- No component documentation
- No API documentation
- No inline comments for complex logic

### Inconsistent Error Handling

- Some places use `alert()`, some use console.log
- No centralized error handling
- No error tracking to Sentry

---

## Missing Production Features

1. **No HTTPS enforcement** - should redirect HTTP to HTTPS
2. **No CSP (Content Security Policy)** - vulnerable to XSS
3. **No rate limiting** - auth endpoints vulnerable to brute force
4. **No audit logging** - no track of sensitive operations
5. **No backup/restore** - no data recovery capability

---

## Recommendations Priority

### P0 - Critical (Fix Immediately)
1. Add `.env` to `.gitignore`
2. Rotate exposed API keys (especially Gemini)
3. Implement proper error handling (replace alerts)

### P1 - High (Within 1 Sprint)
4. Add error boundary to prevent app crashes
5. Implement testing infrastructure (Vitest)
6. Add lazy loading for routes

### P2 - Medium (Within 1 Month)
7. Add TypeScript for type safety
8. Implement Sentry error tracking
9. Add lazy loading for payment libraries
10. Add proper CSP headers

### P3 - Low (Backlog)
11. Add JSDoc documentation
12. Migrate inline styles to CSS modules
13. Add image optimization

---

## Summary

| Category | Count | Severity |
|----------|-------|----------|
| Security Issues | 5 | 2 Critical, 2 Medium, 1 Low |
| Error Handling | 2 | Medium |
| Technical Debt | 3 | High |
| Payment Concerns | 2 | Medium |
| Performance | 3 | Medium |
| Code Quality | 3 | Low |

**Overall Assessment: High-risk project** - Multiple security vulnerabilities and significant technical debt. Recommend addressing P0 items immediately before any production deployment.
