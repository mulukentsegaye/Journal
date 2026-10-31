# Repository Guidelines

## Build Policy
- **No Automatic Builds**: Do NOT build the app (`flutter build apk`, split APK, or any other compilation binary) automatically after making code changes.
- Only run tests (`flutter test`) and static analysis (`flutter analyze`) to verify your code changes.
- Only build the application/APK when the user explicitly asks you to build it.

## Commit Cadence
- **Frequent Commits**: Every time you work and complete a committable step (e.g., implementing a feature, fixing a bug, refactoring, or updating UI), commit it immediately after verifying that it works.
- **Commit Messages**: Use clear, concise commit messages following Conventional Commits (e.g., `feat:`, `fix:`, `refactor:`, `chore:`, `test:`).
- **Scope Verification**: Always verify staged changes (`git status` / diff) before committing to ensure only intentional, project-relevant changes are included.
- **Push**: Push committed changes to `origin main`.
