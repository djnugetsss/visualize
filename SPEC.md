# SPEC.md

## What this app is
An iOS app that reads the user's existing Apple Health data and reflects it back as a calm, beautiful daily glance. The user logs nothing. They grant HealthKit read access once, and the app immediately shows them how they're doing today using soft color gradients + plain human language instead of charts and clinical numbers.

The whole point: **make health data feel human, not clinical.** The beauty is the product. If a screen looks like a lab report or a spreadsheet, it's wrong.

## Who it's for
Anyone with an iPhone (and ideally an Apple Watch) who has health data sitting unused in Apple Health because it's ugly and hard to read.

## The core experience (v1 — build ONLY this)
1. **Permission screen** — explains what we read and why, requests HealthKit read authorization.
2. **Hero screen ("Today")** — a vertical stack of large gradient cards, one per metric. Each card shows the metric as color + one human sentence + the value, small. No charts on this screen.
3. **Card detail screen** — tap a card → see the trend over time AND one relationship insight (e.g. "your resting heart rate runs lower on weeks you sleep before 11pm").
4. **Home-screen widget** — shows today's overall gradient / one key metric at a glance. This is the daily hook.

That is the entire v1. Do not build: accounts, login, onboarding quizzes, social features, notifications, settings beyond a basic screen, data export, or anything not listed above.

## HealthKit metrics for v1
Read-only. These are chosen because they're commonly available and require NO medical claims:
- Resting heart rate
- Heart rate variability (HRV / SDNN)
- Sleep (duration + consistency of bedtime)
- Steps / active energy (daily activity)
- Workouts (count + recency)

If a metric has no data for a user, the card shows a gentle empty state ("No sleep data yet") — never an error, never a zero that looks like a bad score.

## HARD RULES (do not violate)
- **No medical claims of any kind.** No "biological age", no "you are X years younger", no diagnosis, no "healthy/unhealthy" verdicts, no risk scores, no lab-value interpretation. We describe and reflect; we never assess or advise.
- **No lab uploads, no health records, no supplements, no storefront, no affiliate links.** (These are in the reference image — deliberately excluded.)
- **No data leaves the device.** Everything is read from HealthKit and computed locally. No backend, no analytics that send health data, no cloud.
- **Human language only.** Card copy reframes metrics into how-you-feel language, but stays truthful and non-medical. "Well rested" not "optimal sleep architecture." Neutral-to-encouraging tone, never alarming.
- **Monetization is deferred.** Do NOT add any paywall, StoreKit, or RevenueCat code now. BUT architect "insights" (the detail-screen relationship insights + any future recap/story features) as a clean, separable module so a paywall can wrap it later without a rewrite. The Today glance stays free forever; insights are the future paid tier.

## Tech
- SwiftUI, iOS 17+ target.
- HealthKit for all data (read-only authorization).
- WidgetKit for the widget.
- No third-party dependencies unless truly necessary; if one is proposed, explain why before adding.
- Local-only. No networking layer in v1.

## Build order (follow strictly)
1. Scaffold app + HealthKit entitlement + permission request screen. Plumbing only.
2. **Verify real HealthKit reads work on device/simulator before ANY UI polish.** Print real values to console first.
3. Build ONE gradient card (resting heart rate) driven by the real value, end to end and beautiful.
4. Only then add the remaining cards.
5. Then the card detail screen (trend + one relationship insight).
6. Then the widget.

Do not move to the next step until the current one works with real data. One live, beautiful card before five.

## Definition of done for v1
- App requests and receives HealthKit permission.
- Today screen shows real gradient cards for all available metrics, updating from actual data.
- Tapping a card shows a real trend + one real relationship insight.
- Widget shows today's glance.
- Nothing on any screen reads as clinical or makes a medical claim.
