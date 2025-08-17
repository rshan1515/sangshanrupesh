# Advanced Git Commands: Complete Usage, Debugging, and Best Practices

## Table of Contents
1. [Overview](#overview)
2. [`git stash`](#git-stash)
3. [`git cherry-pick`](#git-cherry-pick)
4. [`git revert`](#git-revert)
5. [`git reset`](#git-reset)
6. [Quick Reference Table](#quick-reference-table)
7. [Best Practices](#best-practices)
8. [Troubleshooting & Recovery](#troubleshooting--recovery)
9. [Sample Debugging Workflow](#sample-debugging-workflow)
10. [Further Learning](#further-learning)

---

## Overview

Advanced Git commands help you manage complex workflows, debug issues, and recover from mistakes efficiently. Below is a concise guide to their usage, with practical scenarios and troubleshooting advice.

---

## `git stash`

**Purpose:**  
Temporarily saves (stashes) your local modifications so you can work elsewhere, then restores them when needed.

**Common Usage:**
```sh
# Stash tracked changes
git stash

# Stash tracked and untracked changes
git stash -u

# List all stashes
git stash list

# Apply and remove the most recent stash
git stash pop

# Apply a specific stash (keep it in the list)
git stash apply stash@{1}

# Remove a specific stash
git stash drop stash@{1}
```

**Practical Scenarios:**  
- Switch branches to fix a critical bug, then return to your work.
- Clean your working directory before running tests.

**Tip:**  
Stashes are stack-based (LIFO)—be sure to pop/apply the correct one!

---

## `git cherry-pick`

**Purpose:**  
Apply the changes from a specific commit (or range) onto your current branch.

**Common Usage:**
```sh
# Apply a single commit
git cherry-pick <commit-hash>

# Apply multiple commits
git cherry-pick <commit1> <commit2>

# Apply a range of commits
git cherry-pick <start-commit-hash>^..<end-commit-hash>
```

**Practical Scenarios:**  
- Bring a hotfix from one branch to another without merging unrelated changes.
- Apply only relevant commits from a feature branch.

**Tip:**  
Resolve conflicts that may arise during cherry-pick carefully. Use `git cherry-pick --abort` to cancel if needed.

---

## `git revert`

**Purpose:**  
Create a new commit that undoes the changes of a previous commit, keeping history intact.

**Common Usage:**
```sh
# Revert a single commit
git revert <commit-hash>

# Revert multiple commits
git revert <commit1> <commit2>

# Revert a range of commits
git revert <start-commit-hash>^..<end-commit-hash>
```

**Practical Scenarios:**  
- Undo a buggy commit after pushing to a shared branch.
- Roll back only specific changes without affecting others.

**Tip:**  
Use revert for collaborative environments to avoid rewriting history.

---

## `git reset`

**Purpose:**  
Move the current branch pointer to a different commit, with optional changes to your working directory and staging area.

**Modes:**
- `--soft`: Keep changes staged (in index).
- `--mixed` (default): Keep changes in working directory, unstaged.
- `--hard`: Discard all changes in working directory and index.

**Common Usage:**
```sh
# Soft reset (undo commit, keep changes staged)
git reset --soft HEAD~1

# Mixed reset (undo commit, keep changes unstaged)
git reset --mixed HEAD~1

# Hard reset (undo commit, discard changes)
git reset --hard HEAD~1

# Reset to a specific commit
git reset --hard <commit-hash>
```

**Practical Scenarios:**  
- Clean up local history before pushing.
- Remove unwanted commits and changes before sharing code.

**Warning:**  
`git reset --hard` deletes changes permanently!

---

## Quick Reference Table

| Command            | What It Does                               | Best For                                | Safety     |
|--------------------|--------------------------------------------|-----------------------------------------|------------|
| `git stash`        | Temporarily saves/restores changes         | Context switches, cleaning workspace    | Safe       |
| `git cherry-pick`  | Applies specific commit(s) to branch       | Hotfixes, selective code transfer       | Safe       |
| `git revert`       | Undoes commit(s) with new commit           | Undo after push, preserving history     | Very Safe  |
| `git reset`        | Resets branch pointer, alters work area    | Local history rewrite, cleanups         | Hard = Risky|

---

## Best Practices

- **Stash before switching branches to avoid losing work.**
- **Cherry-pick only what's necessary to minimize merge conflicts.**
- **Revert for collaborative undo—reset for local corrections.**
- **Never use `reset --hard` unless you're absolutely sure.**
- **Push regularly to remote for backup and traceability.**

---

## Troubleshooting & Recovery

- **Lost commit after reset?** Use `git reflog` to find and restore.
- **Stuck stash?** Use `git stash list` and `git stash apply/drop` as needed.
- **Merge/cherry-pick conflicts?** Resolve manually, then `git add` and `git cherry-pick --continue`.
- **Accidental revert?** Revert the revert with another `git revert`.

---

## Sample Debugging Workflow

```sh
# Stash unfinished work
git stash

# Switch to branch needing debug
git checkout bugfix-branch

# Apply a fix from another branch
git cherry-pick <fix-commit-hash>

# If cherry-pick fails, abort
git cherry-pick --abort

# If fix causes issues, revert it
git revert HEAD

# Restore original work
git checkout my-feature-branch
git stash pop

# If local history is messy, reset
git reset --hard <good-commit-hash>
```

---

## Further Learning

- [Pro Git Book](https://git-scm.com/book/en/v2)
- [GitHub Docs](https://docs.github.com/en)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

---