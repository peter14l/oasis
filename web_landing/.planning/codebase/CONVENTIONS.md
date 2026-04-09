# Coding Conventions

**Analysis Date:** 2026-04-09

## Naming Patterns

**Files:**
- Components: PascalCase (`Navbar.jsx`, `Footer.jsx`, `RazorpayPayment.jsx`)
- Pages: PascalCase (`Home.jsx`, `Login.jsx`, `SignUp.jsx`, `Checkout.jsx`)
- Utilities: PascalCase (`supabaseClient.js`)
- Example: `src/components/Navbar.jsx`, `src/pages/Home.jsx`

**Functions:**
- PascalCase for component functions: `function Navbar()`, `function ScrollToTop()`
- Arrow functions for hooks/handlers: `handleLogin`, `handleLogout`, `handleScroll`
- Verb prefixes for event handlers: `handle*` (e.g., `handleClickOutside`)

**Variables:**
- camelCase: `isOpen`, `scrolled`, `downloadDropdownOpen`, `currentIndex`
- Descriptive names: `dropdownRef`, `searchParams`, `accessToken`

**Types/Constants:**
- Uppercase with underscores for constants: `PULSE_ITEMS` (array of objects)
- CSS custom properties: kebab-case (`--md-sys-color-primary`, `--glass-bg`)

## Code Style

**Formatting:**
- Tool: ESLint with `@eslint/js`, `eslint-plugin-react-hooks`, `eslint-plugin-react-refresh`
- No Prettier configuration detected
- Indentation: 2 spaces (implied by ESLint default)
- Max line length: Not enforced (no rule configured)

**Linting Rules** (from `eslint.config.js`):
```javascript
{
  rules: {
    'no-unused-vars': ['error', { varsIgnorePattern: '^[A-Z_]|motion' }]
  }
}
```
- Allows unused variables starting with uppercase (components) or `motion` (framer-motion)
- React refresh enabled for hot module replacement

**Key Rules Applied:**
- React Hooks rules (recommended set)
- React Refresh for Vite compatibility

## Import Organization

**Order (observed):**
1. React core: `import { useState, useEffect } from 'react'`
2. Animation libraries: `import { motion, AnimatePresence } from 'framer-motion'`
3. React Router: `import { Link, useLocation, useNavigate } from 'react-router-dom'`
4. Icon library: `import { Menu, X, Download } from 'lucide-react'`
5. External services: `import { supabase } from '../supabaseClient'`
6. Local components: `import Navbar from './components/Navbar'`
7. GSAP: `import gsap from 'gsap'`

**Path Aliases:**
- None configured (relative paths used throughout)

## Error Handling

**Patterns:**
- Try/catch blocks for async operations:
  ```javascript
  try {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    navigate(redirect);
  } catch (err) {
    setError(err.message);
  } finally {
    setLoading(false);
  }
  ```
- Error state display in UI components
- Error boundaries not implemented

## Logging

**Framework:** No structured logging - uses `console.log` implicitly (not observed in code)

**Patterns:**
- No explicit logging in source files
- Error messages displayed to users via state

## Comments

**When to Comment:**
- Minimal comments in code
- Example from `App.jsx`:
  ```javascript
  // A simple ScrollToTop utility
  // Component to handle password reset redirect to app
  ```

**JSDoc/TSDoc:**
- Not used

## Function Design

**Size:**
- Components range from 75 lines (`Footer.jsx`) to 291 lines (`Navbar.jsx`)
- Large inline styles contribute to file length

**Parameters:**
- Props destructured inline: `function ScrollToTop() { ... }`
- No PropTypes validation

**Return Values:**
- JSX elements
- `null` for conditional rendering

## Module Design

**Exports:**
- Default exports for all components:
  ```javascript
  export default Navbar;
  export default function Home() { ... }
  ```

**Barrel Files:**
- Not used (no `index.js` barrel files)
- Direct imports from files: `import Navbar from './components/Navbar'`

## CSS Approach

**Styling Strategy:**
- Global CSS with CSS variables (`src/index.css`)
- Inline styles for component-specific positioning
- Utility classes (`.glass-panel`, `.btn`, `.container`)
- Material 3 Design tokens as CSS variables

**CSS Variables Pattern:**
```css
:root {
  --md-sys-color-primary: #D0BCFF;
  --md-sys-color-on-primary: #381E72;
  --glass-bg: rgba(28, 27, 31, 0.7);
}
```

**Component Styling:**
- Inline styles for dynamic values: `style={{ padding: scrolled ? '0.75rem' : '1.25rem' }}`
- Class names for static styles: `className="btn btn-primary"`

---

*Convention analysis: 2026-04-09*