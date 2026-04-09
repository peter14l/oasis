# PROJECT.md - Oasis Private Social Platform

## Project Overview

**Name:** Oasis  
**Type:** React 19 + Vite SPA (Private Social Platform)  
**Workspace:** F:/oasis/web_landing

## Vision

Oasis is the ultimate private sanctuary for your digital life. Share disappearing moments (Ripples), collaborate on infinite boards (Canvas), and keep your circles close. With Signal Protocol encryption, privacy is absolute.

## Product Summary

- **Core Value:** Private, encrypted social platform for sharing moments
- **Target Users:** Privacy-conscious individuals seeking secure social sharing
- **Current State:** React SPA with Supabase auth, payment integrations working

## Key Features (Current)

1. **Authentication** - Supabase-based email auth
2. **Ripples** - Disappearing moments that matter
3. **Circles** - Organized intimate spaces
4. **Canvas** - Collaborative infinite boards
5. **Payment** - Razorpay, PayPal, PayU integrations
6. **Downloads** - Android APK, Windows MSIX

## Project Goals

1. **MVP with Security Focus**
   - Test coverage for critical flows
   - Working auth flow
   - Secure payments
   - Production-ready deployment

2. **Timeline:** Under 1 month

## Technical Context

- React 19.2.0
- Vite (rolldown-vite)
- Supabase (@supabase/supabase-js)
- GSAP + Framer Motion for animations
- Razorpay, PayPal, PayU payment gateways

## Constraints

- Timeline: Under 1 month
- Focus: Security + test coverage

## Codebase State

Codebase has been mapped. Key concerns identified:
- `.env` NOT in `.gitignore` (CRITICAL)
- No testing infrastructure
- Hardcoded API keys exposed
- No TypeScript

---

*Created: 2026-04-09*
*Status: GSD Project Initialized*
