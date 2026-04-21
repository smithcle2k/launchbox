---
name: commit
description: >-
  Stages changes and creates a conventional commit message from the diff for LaunchBox.
  Invoke manually only — not for automatic runs.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git add *) Bash(git commit *)
argument-hint: "[optional topic]"
---

# Commit

**Manual invocation only.** Do not run unless the user asked to commit.

## Steps

1. `git status` — confirm intended files.
2. `git diff` — understand scope; group unrelated changes into separate commits if large.
3. Stage: `git add` with explicit paths or `-p` for partial staging.
4. Message format (Conventional Commits):

   ```text
   type(scope): short description

   Optional body explaining why.
   ```

   Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

   Scope examples: `home`, `router`, `theme`, `secrets`.

5. Commit: `git commit -m "type(scope): ..."`

If `$ARGUMENTS` is present, fold it into the subject or body as the user’s topic hint.

## Rules

- Do not commit `Secrets.plist` with real keys (must remain git-ignored).
- If pre-commit review was skipped, suggest `/review-before-commit` first.
