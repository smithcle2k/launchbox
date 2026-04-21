---
name: update-readme
description: >-
  Creates or updates README.md for LaunchBox with project overview and required social header block.
  Use when shipping docs, onboarding, or the user says "update readme".
disable-model-invocation: true
---

# Update README

## Required: social links block

Per project owner rules, the README must include **social media links at the top**, immediately after the main `# Title` heading. Use this placeholder block until real URLs are provided:

```markdown
# LaunchBox

<!-- Social: add your links below (required placement: right after the title) -->
- [Twitter / X](https://example.com/your-handle)
- [GitHub](https://github.com/yourusername)
- [LinkedIn](https://www.linkedin.com/in/yourprofile)

Brief one-line description of the app.

## Requirements

- Xcode 16+ (or match project settings), iOS deployment target as set in Xcode.

## Setup

1. Clone the repo.
2. Open `LaunchBox.xcodeproj` in Xcode (**File → Open…** or **Cmd+O**).
3. Copy `LaunchBox/Resources/Secrets.sample.plist` to `Secrets.plist` and configure — see `LaunchBox/Resources/SECRETS_SETUP.md`.

## Development

- Scheme: **LaunchBox**
- Build: **Cmd+B** in Xcode, or `xcodebuild` (see `xcode-build` skill).

## License

(Add your license.)
```

Replace placeholder URLs with the owner’s real profiles when known.

## Steps

1. If `README.md` exists, preserve unique content; merge in the social block if missing.
2. Ensure the social block is **directly under** the H1 title.
3. Keep instructions macOS-friendly (Cmd shortcuts where relevant).
4. Do not put real secrets in the README.
