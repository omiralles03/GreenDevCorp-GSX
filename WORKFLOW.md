# GreenDevCorp-GSX Workflow

This document defines how we collaborate on the repository and how we set it up.

## 1. Branching Strategy

We opted for a **Feature Branch Workflow** since we will be working on multiple parts of the project at once, using the following structure:

* **`main`**: Production code. Represents the state of the server once each weeks task is complete and tested.
* **`dev`**: Development branch. Where we combine features and test them before pushing them to main.
* **`feat/topic-name`**: Temporary branches for specific tasks.

![Image of the Workflow](https://playbook.hackney.gov.uk/assets/images/gitflow-eb3f4dcf2519612fde7260fde99ace54.png)
## 2. Naming Conventions

- **Branches**: `feat/feature-topic`, `fix/issue-topic`, `docs/documentation-topic`.
- **Commits**: Commits with a descriptive messages (e.g., `Initial commit: ...`, `Fix: ...`, `Feature: ...`).

## 3. Regular Operations

### Start a task
```
git checkout dev
git pull origin dev
git checkout -b feat/task-name
```

### Finish a task
1. **Sync with dev** to handle conflicts.
```
git checkout dev
git pull origin dev
git checkout feat/task-name
git merge --no-ff dev
```
2. Push and PR
```
git push -u origin feat/task-name
```
[Compare & Pull Request.](https://github.com/omiralles03/GreenDevCorp-GSX/pulls)

### Check recently pushed features
```
fit fetch origin
git checkout --track origin/branch-name
```
_Note: Use `--track` to avoid **Detached HEAD**_
