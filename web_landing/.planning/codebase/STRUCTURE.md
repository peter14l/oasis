# Codebase Structure

**Analysis Date:** 2026-04-09

## Directory Layout

```
web_landing/
├── public/
│   ├── apk/                    # Android APK downloads
│   ├── windows/                # Windows MSIX installer
│   ├── favicon.png
│   └── vite.svg
├── src/
│   ├── components/             # Reusable UI components
│   ├── pages/                  # Route page components
│   ├── assets/                 # Static assets (React SVG)
│   ├── supabaseClient.js       # Supabase client singleton
│   ├── App.jsx                 # Main app with routing
│   ├── App.css                 # Global app styles
│   ├── main.jsx                # React entry point
│   └── index.css              # Global styles + CSS variables
├── .planning/                  # GSD planning artifacts
├── package.json               # Dependencies
├── vite.config.js             # Vite configuration
└── vercel.json                # Deployment config
```

## Directory Purposes

**`src/pages/`:**
- Purpose: Full-page route components
- Contains: 11 page files (Home, Features, Pricing, Privacy, Login, SignUp, Checkout, Success, Profile, SharedMoment)
- Key files: `Home.jsx` (248 lines - hero, bento grid, carousel), `Checkout.jsx` (247 lines - payment flow), `Profile.jsx` (171 lines - user info)

**`src/components/`:**
- Purpose: Reusable UI components
- Contains: Navbar (navigation + auth state), Footer (static), Payment components (Razorpay, PayPal, PayU)
- Key files: `Navbar.jsx` (291 lines - responsive nav, dropdowns, auth), `Footer.jsx` (75 lines), `RazorpayPayment.jsx`, `PayPalPayment.jsx`, `PayUPayment.jsx`

**`public/`:**
- Purpose: Static assets served directly
- Contains: APK files, MSIX installer, favicon
- Generated: APK/MSIX built externally, committed to repo

**`src/assets/`:**
- Purpose: Bundled static assets
- Contains: react.svg (Vite template)
- Note: Minimal use - most images referenced externally or in public/

## Key File Locations

**Entry Points:**
- `src/main.jsx`: React DOM render - creates root and renders App in StrictMode
- `src/App.jsx`: Router setup with all 11 routes + ScrollToTop + ResetPasswordHandler

**Configuration:**
- `package.json`: Dependencies (React 19, Vite, Supabase, GSAP, Framer Motion, Lucide, Axios)
- `vite.config.js`: Vite build configuration
- `vercel.json`: Deployment configuration for Vercel
- `src/supabaseClient.js`: Supabase client with env vars (VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY)

**Core Logic:**
- `src/pages/Home.jsx`: Landing page with GSAP animations, carousel, download CTAs
- `src/pages/Checkout.jsx`: Payment flow with country detection, coupon validation, multi-provider support
- `src/components/Navbar.jsx`: Auth state management via Supabase subscriptions

**Testing:**
- No test files detected (no .test.*, .spec.* files in src/)

## Naming Conventions

**Files:**
- PascalCase: All React components (`Home.jsx`, `Navbar.jsx`, `RazorpayPayment.jsx`)
- camelCase: Utility/config files (`supabaseClient.js`)
- kebab-case: Not used

**Directories:**
- camelCase: `src/components`, `src/pages`, `src/assets`
- kebab-case: Not used

**Components:**
- Function component with default export: `export default function Home() {}`
- Named exports used for pages imported in App.jsx

## Where to Add New Code

**New Feature Page:**
- Implementation: `src/pages/NewFeature.jsx`
- Route: Add `<Route path="/new-feature" element={<NewFeature />} />` in `src/App.jsx`

**New Shared Component:**
- Implementation: `src/components/NewComponent.jsx`
- Import in pages: `import NewComponent from '../components/NewComponent'`

**New Utility/Service:**
- Implementation: `src/utils/newUtil.js` or `src/services/newService.js`
- Import where needed

**New Payment Provider:**
- Implementation: `src/components/NewProviderPayment.jsx`
- Integrate in `src/pages/Checkout.jsx` based on country logic

## Special Directories

**`public/apk/`:**
- Purpose: Android APK downloads
- Generated: Yes (built externally from mobile app repo)
- Committed: Yes (binary files in git)

**`public/windows/`:**
- Purpose: Windows MSIX installer
- Generated: Yes (built externally)
- Committed: Yes

**`.planning/codebase/`:**
- Purpose: GSD code mapping documents
- Generated: Yes (by gsd-codebase-mapper agent)
- Committed: Yes

---

*Structure analysis: 2026-04-09*