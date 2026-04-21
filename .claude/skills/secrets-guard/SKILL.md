---
name: secrets-guard
description: >-
  Prevents committing API keys in LaunchBox; use Secrets.plist + Core/Secrets.swift.
  Use when adding third-party SDKs, URLs, or any credential; or reviewing for secret leaks.
paths:
  - "**/*.swift"
  - "**/*.plist"
---

# Secrets guard

## Rules

1. **Never** paste production API keys, tokens, or private URLs into Swift source, committed plists, or README.
2. **Do** load configuration at runtime from `Secrets.plist` (git-ignored), with keys read through `enum Secrets` in `Core/Secrets.swift`.
3. **Template** for local setup: copy `Resources/Secrets.sample.plist` → `Resources/Secrets.plist` and fill locally — see `Resources/SECRETS_SETUP.md`.

## Adding a new secret

1. Add a key to `Secrets.sample.plist` with a placeholder value.
2. Add a static accessor on `Secrets` that reads from the loaded dictionary with a safe default.
3. Document the key in `SECRETS_SETUP.md` (not the real value).

## Review checklist

- [ ] No `sk_live`, `AIza`, 40-char hex tokens, or `Bearer ey` in repo
- [ ] New keys only in `Secrets` + plist pattern

Files: `LaunchBox/Core/Secrets.swift`, `LaunchBox/Resources/Secrets.sample.plist`, `LaunchBox/Resources/SECRETS_SETUP.md`.
