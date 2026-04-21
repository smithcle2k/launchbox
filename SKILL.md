---
name: launchbox-1
description: A methodology for finding and validating shippable, low-competition iOS app ideas. Use this skill when the user wants to identify "Blue Ocean" app opportunities, validate demand vs. saturation, or pivot hardware-blocked ideas into viable <24h builds.
---

# App Research Specialist

## When to use this skill
- When a user wants to find a high-intent, low-competition iOS app niche.
- When an initial app idea is blocked by iOS Sandbox/Private API restrictions and needs a "Hardware Pivot."
- When the goal is to build and ship an MVP in less than 24 hours.

## How to use it

### 1. Demand Discovery (The 8 Stems)
Execute search queries using these exact patterns to find high-intent "search gaps":
- "best app for..."
- "is there an app that..."
- "how to [action] on iphone"
- "app to help with..."
- "alternative to [popular app] for ios"
- "ios app for [niche/hobby]"
- "why doesn't iphone have..."
- "[industry] app ideas"

### 2. Saturation & Competition Filter
Validate candidates against the iTunes Search API:
- **Viable:** High search intent but < 10 direct competitors.
- **Saturated:** Top 5 results have > 10k reviews or are dominated by major incumbents.

### 3. The Pivot Logic (Crucial)
If an idea is technically impossible due to Apple’s restrictions (e.g., system-level battery mods or AirPods settings), you must find a "Hardware-Adjacent" alternative:
- **Blocked Idea:** System-level AirPods EQ.
- **Adjacent Pivot:** Motion-controlled game using `CMHeadphoneMotionManager`.
- **Blocked Idea:** Custom iPhone Lock Screen widgets (system-level).
- **Adjacent Pivot:** "Live Activities" status tracker for a specific niche.

### 4. Reddit Sentiment Verification
Scan subreddits (r/iOSProgramming, r/AppIdeas) for:
- "Pain points" or "Why is [Competitor] so expensive?"
- High-upvote requests for features that existing apps ignore.

### 5. Deployment Brief
For the final candidate, provide:
- **The Hook:** Why it will trend.
- **The Tech Stack:** Specifically which Public APIs/Frameworks to use.
- **The <24h MVP:** The one core feature to ship immediately.
