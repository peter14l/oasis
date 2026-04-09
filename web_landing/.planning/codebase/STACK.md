# Technology Stack

**Analysis Date:** 2026-04-09

## Languages

**Primary:**
- JavaScript (ES6+) - Used throughout the codebase via JSX
- JSX - React component syntax

**Secondary:**
- CSS - Used for component styling (inline and CSS files)

## Runtime

**Environment:**
- Node.js 18+ (implied by Vite requirements)

**Package Manager:**
- npm (implied by package.json)
- Lockfile: `package-lock.json` present

## Frameworks

**Core:**
- React 19.2.0 - UI framework
- React Router DOM 7.13.0 - Client-side routing

**Build/Dev:**
- Vite 7.2.5 (via rolldown-vite npm package) - Build tool and dev server
- @vitejs/plugin-react 5.1.1 - React Fast Refresh support

**Testing:**
- None detected - No test framework configured

**Linting:**
- ESLint 9.39.1 - Code linting
- eslint-plugin-react-hooks 7.0.1 - React hooks linting
- eslint-plugin-react-refresh 0.4.24 - React refresh compatibility

## Key Dependencies

**Core UI:**
- `react` 19.2.0 - Core React library
- `react-dom` 19.2.0 - React DOM renderer
- `react-router-dom` 7.13.0 - Routing

**Animations:**
- `gsap` 3.14.2 - GSAP animation library
- `@gsap/react` 2.1.2 - React integration for GSAP
- `framer-motion` 12.29.2 - Animation library

**Backend/Data:**
- `@supabase/supabase-js` 2.99.3 - Supabase client for auth and database
- `axios` 1.13.6 - HTTP client (likely for API calls)

**UI Utilities:**
- `lucide-react` 0.563.0 - Icon library

## Configuration

**Build:**
- `vite.config.js` - Vite configuration with React plugin

**Environment Variables (expected):**
- `VITE_SUPABASE_URL` - Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Supabase anon key
- `VITE_RAZORPAY_KEY_ID` - Razorpay key for payment
- `VITE_PAYPAL_CLIENT_ID` - PayPal client ID

**Deployment:**
- Vercel - Configured via `vercel.json` with SPA rewrite rules

## Platform Requirements

**Development:**
- Node.js 18+
- npm for package management

**Production:**
- Vercel or any static hosting
- Edge functions support (for Supabase edge functions)

---

*Stack analysis: 2026-04-09*