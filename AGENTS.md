# Repository Guidelines

## Build Policy
- **No Automatic Builds**: Do NOT build the app (`flutter build apk`, split APK, or any other compilation binary) automatically after making code changes.
- Only run tests (`flutter test`) and static analysis (`flutter analyze`) to verify your code changes.
- Only build the application/APK when the user explicitly asks you to build it.

## Git Workflow
- **No Intermediate Git Commands**: Do NOT run exploratory or repetitive git commands (e.g., `git diff`, `git status`, `git log`, etc.) during work or in the middle of a task.
- **Commit Only Upon Completion**: Only run git commands when you have completely finished working on the task or project.
- **Strictly Two Git Commands**: When finished, execute exactly two git commands:
  1. `git add <changed-files>` to stage the modified project files.
  2. `git commit -m "<message>"` with a clear Conventional Commit message.
- **Never Push**: Do NOT run `git push`. The user will push commits manually when they choose.

## Execution Speed & Minimal Overhead Rules

### Fast Turnaround on Small Edits
- For simple, isolated, or small logic changes (e.g., 1–2 line fixes, UI tweaks, property updates), make the change directly and finish.
- Do NOT run full test suites or full project analyzers for minor changes unless explicitly asked or completing a major feature milestone.

### Prevent Tooling Deadlocks on Windows
- Always run Flutter CLI commands with `--no-pub` (e.g., `flutter test --no-pub`, `flutter analyze --no-pub`) to avoid hanging on network dependency checks.
- If a startup lock is detected (`Waiting for another flutter command to release the startup lock...`), immediately terminate orphaned `dart.exe` processes with `taskkill /F /IM dart.exe` instead of waiting out long background timeouts.

### Windows Line-Ending (LF/CRLF) Awareness
- Account for LF vs CRLF line endings on Windows immediately. If an exact text match fails, resolve it in a single step without cycling through multiple failed edits or scratch scripts.

### Eliminate Redundant Self-Verification
- Prioritize prompt delivery and responsiveness. Do not loop through repetitive test/analyze passes when the code edit is self-contained and verified.
