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
