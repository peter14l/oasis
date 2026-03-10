# Morrow — Monetization Plan

## App Overview

Morrow is a **privacy-first social media platform** built with Flutter + Supabase. Its existing feature surface is rich:

- **Social Feed** — posts (text, image, video), reactions, comments, polls
- **Stories** — ephemeral content with reactions
- **Messaging** — end-to-end encrypted DMs, smart replies, voice transcripts, shared albums, audio rooms
- **Communities** — group spaces with dedicated feeds
- **Time Capsules** — schedule-lock content (solo + collaborative, location-triggered)
- **Vault** — PIN-protected private space for posts, media, chats, collections
- **Creator Analytics** — follower growth, engagement rate, best posting times, content-type breakdown
- **AI Content Companion** — caption & hashtag suggestions, posting-time recommendations, caption quality scoring
- **Digital Well-being Suite** — screen time tracking, quiet mode, focus mode, wind-down mode, break reminders, wellness streaks & achievements
- **Nearby Discovery** — find users and events by location (GPS-powered)
- **Cross-Posting** — one-click share to Twitter/X, Facebook, LinkedIn, Threads
- **Collections** — curated boards of saved content
- **Media Download** — save content locally
- **Enhanced Moderation** — reporting, content safety

---

## Recommended Tier Structure

### ✦ Free — "Morrow"
Everything a casual user needs to get started and stay engaged. No credit card, no limits on the essentials.

### ✦ Pro — "Morrow Pro" (formerly "Morrow+")
For power users, creators, and people who want the premium experience — deeper features, higher limits, and elite privacy.

---

## Free vs Pro Feature Comparison

| Category | Free | Morrow Pro |
|---|---|---|
| **Feed & Posts** | Unlimited posts | ✔ Same |
| **Stories** | Up to 3 active stories | Unlimited concurrent stories |
| **Messaging** | E2E encrypted DMs | ✔ Same |
| **Voice Transcripts in DMs** | ❌ Not available | ✔ Included |
| **Audio Rooms** | Listen-only | ✔ Host audio rooms |
| **Communities** | Join up to 5 | Join unlimited |
| **Community Creation** | Create 1 community | Create unlimited communities |
| **Time Capsules** | 3 active capsules | Unlimited capsules |
| **Collaborative Capsules** | ❌ Not available | ✔ Invite up to 10 contributors |
| **Location-Triggered Capsules** | ❌ Not available | ✔ Set GPS unlock zones |
| **Music on Capsules** | ❌ Not available | ✔ Attach a music track |
| **Vault** | 10-item limit, PIN only | Unlimited items, biometric unlock |
| **Cross-Device Vault Sync** | ❌ Not available | ✔ Encrypted cloud sync |
| **AI Caption Suggestions** | 2 suggestions per post | 10 suggestions + tone variants |
| **AI Hashtag Recommendations** | Basic set (5 tags) | Smart set (30 tags) |
| **Posting-Time Optimizer** | Generic day-of-week times | Personalized based on your audience |
| **Caption Quality Check** | ❌ Not available | ✔ Live score with fix suggestions |
| **Creator Analytics** | 7-day metrics | Full 90-day history + export |
| **Audience Demographics** | ❌ Not available | ✔ Top locations, interests |
| **Content-Type Breakdown** | ❌ Not available | ✔ Image vs video vs text ROI |
| **Best-Time Heatmap** | ❌ Not available | ✔ Personalized hourly map |
| **Nearby Discovery** | Radius: 10 km | Radius: 50 km + filter by interest |
| **Nearby Events** | ❌ Not available | ✔ See & RSVP to nearby events |
| **Cross-Posting** | Share natively (system sheet) | Direct-publish to Twitter/X, LinkedIn |
| **Stories Autopost** | ❌ Not available | ✔ Auto-share story to social platforms |
| **Collections** | 3 collections, 50 items each | Unlimited collections & items |
| **Media Download** | ✔ (own content only) | ✔ (with permission, any saved content) |
| **Verified Badge** | ❌ Not available | ✔ Pro badge on profile |
| **Profile Customization** | Default themes only | 20+ exclusive themes & link banners |
| **Digital Well-being** | Screen time tracking, basic quiet mode | + Focus mode scheduling, Wind-down mode, Wellness streaks |
| **Well-being Weekly Report** | ❌ Not available | ✔ Full PDF wellness report |
| **Ads** | Standard ads in feed | ✔ Completely ad-free |
| **Priority Support** | Community help center | ✔ 24–48 hr e-mail priority support |
| **Early Access** | Standard rollout | ✔ Beta features first |

---

## Pricing

### Global (USD)
| Plan | Monthly | Annual (save ~30%) |
|---|---|---|
| Free | $0 | $0 |
| **Morrow Pro** | **$4.99 / mo** | **$34.99 / yr** (~$2.92/mo) |

*Comparable benchmarks: BeReal Premium $2.99/mo · Reddit Premium $5.99/mo · Twitter Blue $8/mo · Snapchat+ $3.99/mo*

> **Rationale:** $4.99/mo positions Morrow Pro as genuinely affordable while beating ad-free competitors. The annual price ($34.99) incentivizes long-term commitment and improves LTV.

---

### India Pricing (INR — Purchasing Power Parity)
| Plan | Monthly | Annual (save ~30%) |
|---|---|---|
| Free | ₹0 | ₹0 |
| **Morrow Pro** | **₹199 / mo** | **₹1,199 / yr** (~₹100/mo) |

*Comparable: YouTube Premium ₹139/mo · Spotify ₹119/mo · Snapchat+ ₹49/mo · LinkedIn Premium ₹1,299/mo*

> **Rationale:** ₹199/mo sits comfortably above Snapchat+ (₹49) while being well below LinkedIn Premium (₹1,299). This tier is aspirational but accessible for India's growing creator and Gen-Z demographic. Annual at ₹1,199 is the primary push.

---

## Feature-to-Paywall Mapping (Implementation Priorities)

The features listed below are the highest-value paywalls — they are already **built in the codebase** and only need a subscription check injected at the call site.

| Priority | Feature | Code Location |
|---|---|---|
| 🔴 High | Unlimited vault items + biometric unlock | [vault_service.dart](file:///f:/morrow_v2/lib/services/vault_service.dart) |
| 🔴 High | Creator analytics (90-day + demographics + content breakdown) | [creator_analytics_service.dart](file:///f:/morrow_v2/lib/services/creator_analytics_service.dart) |
| 🔴 High | AI caption quality check + extended suggestions | [ai_content_service.dart](file:///f:/morrow_v2/lib/services/ai_content_service.dart) |
| 🔴 High | Collaborative & location-triggered time capsules | [enhanced_time_capsule_service.dart](file:///f:/morrow_v2/lib/services/enhanced_time_capsule_service.dart) |
| 🟡 Mid | Nearby events + extended radius | [nearby_discovery_service.dart](file:///f:/morrow_v2/lib/services/nearby_discovery_service.dart) |
| 🟡 Mid | Ad-free experience | Feed rendering layer |
| 🟡 Mid | Wellness weekly report + focus mode scheduling | [wellness_service.dart](file:///f:/morrow_v2/lib/services/wellness_service.dart), [screen_time_service.dart](file:///f:/morrow_v2/lib/services/screen_time_service.dart) |
| 🟢 Low | Unlimited communities + story count | [community_service.dart](file:///f:/morrow_v2/lib/services/community_service.dart), [stories_service.dart](file:///f:/morrow_v2/lib/services/stories_service.dart) |
| 🟢 Low | Pro badge + profile themes | [profile_service.dart](file:///f:/morrow_v2/lib/services/profile_service.dart), [edit_profile_screen.dart](file:///f:/morrow_v2/lib/screens/edit_profile_screen.dart) |

---

## Revenue Projections (Conservative Estimates)

Assuming 50,000 MAU at 6 months post-launch with a **3% conversion** rate:

| Market | Paid Users | Monthly Revenue | Annual Revenue |
|---|---|---|---|
| Global (avg $4.99/mo excl. India) | 1,200 | ~$6,000 | ~$72,000 |
| India (₹199/mo) | 300 | ~₹59,700 (~$720) | ~₹7,16,400 (~$8,600) |
| **Combined** | **1,500** | **~$6,720** | **~$80,600** |

> Growing past 200,000 MAU with 5% conversion produces ~$500K ARR — a realistic 18-month target for a well-marketed app.

---

## Additional Revenue Levers (Post-Launch)

1. **Creator Tipping / Gifting** — users send micro-payments directly to creators (take a 15% cut). Already has the social graph to support this.
2. **Boosted Posts** — pay-to-boost visibility in the feed for creators (CPM or flat fee). Minimal engineering; reuse existing feed ranking.
3. **Event Tickets** — integrate ticketing for nearby events (already built in [NearbyDiscoveryService](file:///f:/morrow_v2/lib/services/nearby_discovery_service.dart#6-204)). Charge 5–10% per ticket sold.
4. **Brand Verification & Partnerships** — verified brand accounts with analytics APIs (B2B SaaS model, ₹5K–₹20K/month in India).

---

## Recommended Launch Approach

1. **Month 1** — Ship `subscription_service.dart` wrapping RevenueCat or Superwall. Gate the 🔴 High-priority features.
2. **Month 2** — Run a **Pro Free Trial** (14 days) on signup. Show what you're missing on first paywall hit.
3. **Month 3** — Introduce annual plan with limited-time 40% discount to drive conversions.
4. **Month 4+** — A/B test price points at ₹149 vs ₹199 in India and $3.99 vs $4.99 globally. Double down on the winning price.

---

*Plan authored: March 2026 · Based on Morrow v2 codebase analysis*
