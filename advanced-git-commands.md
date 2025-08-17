# Advanced Git Commands: Usage, Examples, and Debugging Tips

Mastering advanced Git commands streamlines your workflow and boosts your ability to debug, recover, and manage code. Below are key commands, with clear explanations, usage examples, and debugging scenarios.

---

## 1. `git stash`

**Purpose:**  
Temporarily shelves (stashes) changes you’ve made to your working directory so you can work on something else, then come back and re-apply them.

**Usage:**
```sh
# Stash all local changes (tracked files)
git stash

# Stash, including untracked files
git stash -u

# See all stashed changes
git stash list

# Apply the most recent stash and remove it from the stash list
git stash pop

# Apply a stash but keep it in the stash list
git stash apply stash@{0}

# Delete a specific stash
git stash drop stash@{0}
```

**Debugging Scenario:**  
Stash your in-progress work before switching branches to hotfix a bug, then return and restore your changes after debugging.

---

## 2. `git cherry-pick`

**Purpose:**  
Apply the changes from a specific commit onto your current branch. Useful for bringing bug fixes or features from one branch to another.

**Usage:**
```sh
# Cherry-pick a commit by its hash
git cherry-pick <commit-hash>

# Cherry-pick a range of commits
git cherry-pick <start-commit-hash>^..<end-commit-hash>
```

**Debugging Scenario:**  
A bugfix exists on another branch. Cherry-pick the fix into your branch to test or release it without merging unrelated changes.

---

## 3. `git revert`

**Purpose:**  
Undo a specific commit by creating a new commit. This is a safe way to undo changes, especially on shared branches.

**Usage:**
```sh
# Revert a single commit
git revert <commit-hash>

# Revert a range of commits
git revert <start-commit-hash>^..<end-commit-hash>
```

**Debugging Scenario:**  
A recent commit broke something. Revert it to restore a working state, keeping history intact and minimizing disruption for collaborators.

---

## 4. `git reset`

**Purpose:**  
Move the current branch pointer to a different commit and update the index and/or working directory, depending on the mode:

- **--soft**: Keep changes staged.
- **--mixed** (default): Keep changes in working directory, unstaged.
- **--hard**: Discard all changes in working directory and index.

**Usage:**
```sh
# Undo last commit, keep changes staged
git reset --soft HEAD~1

# Undo last commit, keep changes in working directory
git reset --mixed HEAD~1

# Undo last commit, discard changes completely
git reset --hard HEAD~1

# Reset to a specific commit by hash
git reset --hard <commit-hash>
```

**Debugging Scenario:**  
You made several local commits that turned out to be wrong. Use reset to return to a clean slate and try again.

**Warning:**  
`git reset --hard` will permanently discard changes—use with caution!

---

## Quick Reference Table

| Command         | What It Does                                  | Best For                              | Safety  |
|-----------------|-----------------------------------------------|---------------------------------------|---------|
| `git stash`     | Save/restore local changes temporarily        | Switching context, debug sessions     | Safe    |
| `git cherry-pick`| Apply specific commit(s) to current branch   | Isolating bug fixes, selective merging| Safe    |
| `git revert`    | Undo specific commit(s) with a new commit     | Undoing mistakes after push           | Very Safe|
| `git reset`     | Move HEAD, optionally alter working directory | Undoing local history                 | Hard = Risky|

---

## Best Practices

- **Use `git stash` for quick context switches.**
- **Use `git cherry-pick` for surgical code transfers.**
- **Use `git revert` to safely undo commits on shared branches.**
- **Use `git reset` for local history rewrites (before pushing).**
- **Never use `git reset --hard` unless you're sure you don't need your changes.**

---

## Useful Debugging Workflow Example

```sh
# Save your current messy work
git stash

# Checkout the branch where you need to debug
git checkout bugfix-branch

# Apply a specific fix from another branch via cherry-pick
git cherry-pick <fix-commit-hash>

# If something goes wrong, revert the cherry-pick
git revert HEAD

# When ready, return to your original branch and restore your work
git checkout my-feature-branch
git stash pop

# If you need a clean slate locally, perform a hard reset
git reset --hard <good-commit-hash>
```

---

For more Git tips, see [Pro Git Book](https://git-scm.com/book/en/v2) or [GitHub Docs](https://docs.github.com/en).