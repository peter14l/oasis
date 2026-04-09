# Architecture

**Analysis Date:** 2026-04-09

## Pattern Overview

**Overall:** Single Page Application (SPA) with client-side routing

**Key Characteristics:**
- React 19 with Vite as the build tool
- React Router v7 for client-side routing with nested layouts
- Supabase for authentication and backend services
- Component-based architecture with reusable layout wrappers

## Layers

**Presentation Layer (Pages):**
- Purpose: Route handlers that render full-page content
- Location: `src/pages/`
- Contains: 11 page components (Home, Features, Pricing, Login, SignUp, Checkout, Success, Profile, Privacy, SharedMoment)
- Depends on: Components, routing, animation libraries
- Used by: React Router in App.jsx

**Layout Layer:**
- Purpose: Wraps all pages with consistent navigation and footer
- Location: `src/App.jsx`
- Contains: Router setup, ScrollToTop utility, Navbar/Footer wrapper
- Depends on: react-router-dom, Navbar component, Footer component
- Used by: Entry point main.jsx

**Shared Component Layer:**
- Purpose: Reusable UI components used across pages
- Location: `src/components/`
- Contains: Navbar, Footer, Payment components (Razorpay, PayPal, PayU)
- Depends on: Lucide icons, animation libraries (framer-motion), supabase client
- Used by: Pages and App.jsx

**Integration Layer:**
- Purpose: Supabase client configuration and external service integrations
- Location: `src/supabaseClient.js`
- Contains: Supabase client initialization with environment variables
- Depends on: @supabase/supabase-js
- Used by: Navbar, Login, Profile, Checkout, SignUp

## Data Flow

**Authentication Flow:**
1. User navigates to /login or /signup
2. Page calls supabase.auth.signInWithPassword() or signInWithOAuth()
3. Supabase returns session with user data
4. Navbar subscribes to auth state changes via onAuthStateChange
5. Profile page checks session on mount and redirects if not authenticated

**Payment Flow:**
1. User navigates to /checkout with plan/currency params
2. Checkout page fetches country via ipapi.co
3. Based on country, renders appropriate payment component (Razorpay for India, PayPal for others)
4. Payment success redirects to /success

**Routing Flow:**
1. BrowserRouter wraps entire app in App.jsx
2. Routes defined with path and element
3. ScrollToTop component resets scroll position on route change
4. Navbar closes mobile menu on any route change

## Key Abstractions

**Client Abstraction:**
- Purpose: Centralized Supabase client instance
- Examples: `src/supabaseClient.js`
- Pattern: Singleton export - createClient() returns single instance used across app

**Payment Abstraction:**
- Purpose: Multi-provider payment handling
- Examples: `src/components/RazorpayPayment.jsx`, `src/components/PayPalPayment.jsx`, `src/components/PayUPayment.jsx`
- Pattern: Component-based with props for plan, amount, currency, onSuccess callback

**Route Guard Abstraction:**
- Purpose: Protect authenticated routes
- Examples: `src/pages/Profile.jsx` (checks session, redirects to /login)
- Pattern: useEffect + getSession() + navigate()

## Entry Points

**Application Entry:**
- Location: `src/main.jsx`
- Triggers: HTML loads, React mounts to #root
- Responsibilities: Initialize React StrictMode, render App component

**Routing Entry:**
- Location: `src/App.jsx`
- Triggers: BrowserRouter initialized
- Responsibilities: Define all routes, wrap with layout (Navbar/Footer), handle special routes (ResetPasswordHandler)

**Deep Link Entry:**
- Location: `src/App.jsx` (ResetPasswordHandler component)
- Triggers: User clicks password reset link from email
- Responsibilities: Parse URL params (code, access_token, refresh_token), redirect to native app via oasis:// protocol

## Error Handling

**Strategy:** Component-level error states with user feedback

**Patterns:**
- Login/SignUp: Display error messages from Supabase in UI
- Checkout: Try-catch blocks with user-visible error messages
- Profile: Loading states while checking authentication

## Cross-Cutting Concerns

**Logging:** No structured logging - uses console.log for debugging (ipapi fetch, payment errors)

**Validation:**
- Form validation: HTML5 required attributes + React state
- Payment: Amount validation in payment components

**Authentication:**
- Provider: Supabase Auth (email/password + Google OAuth)
- Session management: getSession() + onAuthStateChange subscription
- Protected routes: Manual checks in Profile, Checkout (redirect to /login)

**Animations:**
- Primary: Framer Motion (page transitions, dropdowns, modals)
- Secondary: GSAP + ScrollTrigger (scroll-triggered reveals, parallax)

---

*Architecture analysis: 2026-04-09*