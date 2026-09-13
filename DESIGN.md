# DESIGN.md

## Design soul
Health data made human. Calm, premium, effortless. The reference in `/references/` sets the tone: soft gradients, big cards, generous whitespace, one clear thing per card. Steal the *visual language* of that reference (gradient-as-meaning, large calm cards, human copy). Ignore its business model entirely (no supplements, no lab uploads, no biological-age claims — see SPEC.md).

The feeling to hit: opening the app should feel like a calm exhale, not a status report. A person should want to screenshot their Today screen.

## The one signature move: gradient-as-status
Color is not decoration — it encodes how a metric is doing, at a glance, before the user reads a single word. This is the whole identity of the app.

- Each metric card is filled with a **soft, blurred, multi-stop gradient**.
- The gradient's *hue* and *vibrancy* shift based on where the user's current value sits relative to their own recent baseline (NOT relative to a medical "normal" — we compare a user to themselves, which also keeps us clear of medical claims).
- General mapping (tune later):
  - Doing well / better than their baseline → cooler, vibrant greens and teals.
  - Neutral / typical for them → soft neutral warm tones (sand, pale amber).
  - Below their recent baseline → warmer oranges (encouraging, never red/alarming — this is "worth noticing," not "danger").
- **Never use red, never use alarm colors.** The worst state is a warm orange, framed gently.
- Gradients are always soft-edged and blurred, never hard geometric bands. Think diffused light, not a pie chart.

## Cards
- Large, rounded rectangles (corner radius ~28–32pt), lots of internal padding.
- One metric per card. Contents, top to bottom:
  - Small metric label (e.g. "Resting Heart Rate") — quiet, secondary.
  - The human sentence — the hero text (see copy below).
  - The value, small and secondary (e.g. "58 bpm").
- Plenty of vertical space between cards. The Today screen scrolls; don't cram.
- Subtle depth: soft shadow, no harsh borders.

## Metric → human copy (reframe, don't diagnose)
Each card leads with a human sentence derived from the value vs. the user's own baseline. Truthful, non-medical, warm. Examples (generate variants, keep them honest):
- Resting HR (low for them): "Your heart's taking it easy today."
- Resting HR (typical): "Steady as usual."
- HRV (high for them): "You're recovering well."
- HRV (low for them): "Your body might still be catching up."
- Sleep (good duration + consistent): "Well rested."
- Sleep (short): "A lighter night than usual."
- Activity (high): "You've been on the move."
- Activity (low): "A quieter day so far."
- Workouts (recent): "Nice work this week."

Never: "optimal", "abnormal", "unhealthy", "at risk", "good/bad". Describe, don't grade.

## Typography
- SwiftUI system font (SF Pro), leaning on weight contrast: light/regular for labels and values, medium/semibold for the human hero sentence.
- Large hero sentence, small quiet supporting text. Strong hierarchy = calm.
- Rounded design variant (`.rounded`) is worth trying for warmth; test against default.

## Layout & color base
- Off-white / very light neutral background (not pure white) in light mode; near-black soft neutral in dark mode. Cards' gradients pop against a quiet ground.
- Support dark mode from the start — gradients should be tuned for both.
- Respect safe areas and Dynamic Type.

## Motion
- Gradients may drift/breathe *very* slowly (subtle, ambient), if it doesn't hurt battery. Optional for v1 — get it static and beautiful first.
- Card taps: gentle spring transition into detail.
- No flashy animations. Restraint is the aesthetic.

## Detail screen
- Same calm language. A soft trend visualization (a smooth line or gradient area, not a clinical bar chart) over weeks.
- One relationship insight in plain language, given real weight on the screen (it's the payoff): e.g. "Your resting heart rate runs lower on weeks you sleep before 11pm."

## Widget
- Small widget = today's overall gradient + one word/short phrase + optionally one key value.
- It should look beautiful on the home screen next to app icons — that's the daily hook and the shareable surface.

## What to avoid (anti-patterns)
- Charts as the primary visual. (We're the anti-chart app.)
- Numbers without human framing.
- Red / alarm states.
- Dense dashboards. One idea per card.
- Anything that reads as a lab report or medical assessment.
