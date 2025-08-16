# Basic Git Commands Explained

Git is a distributed version control system widely used for tracking changes in source code during software development. Below are some essential Git commands, their uses, and examples:

---

## 1. `git status`
Shows the current state of the working directory and staging area, including which files are changed, staged, or untracked.

**Usage:**
```sh
git status
```

**Example Output:**
```
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
        modified:   README.md
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        newfile.txt
```

---

## 2. `git init`
Initializes a new Git repository in the current directory.

**Usage:**
```sh
git init
```

**Example Output:**
```
Initialized empty Git repository in /path/to/project/.git/
```

---

## 3. `git clone`
Creates a local copy of a remote repository.

**Usage:**
```sh
git clone <repository-url>
```

**Example:**
```sh
git clone https://github.com/user/repo.git
```

---

## 4. `git add`
Stages changes (new or modified files) for the next commit.

**Usage:**
```sh
git add <file>
git add .       # Adds all changes in the directory
```

**Example:**
```sh
git add index.html
git add .       # Stages all changes
```

---

## 5. `git commit`
Records the staged changes to the repository with a message.

**Usage:**
```sh
git commit -m "Your commit message here"
```

**Example:**
```sh
git commit -m "Add new feature to homepage"
```

---

## 6. `git push`
Uploads local commits to a remote repository.

**Usage:**
```sh
git push <remote> <branch>
```
Most commonly:
```sh
git push origin main
```

**Example:**
```sh
git push origin main
```

---

## 7. `git pull`
Fetches and integrates changes from the remote repository into the current branch.

**Usage:**
```sh
git pull <remote> <branch>
```
Most commonly:
```sh
git pull origin main
```

**Example:**
```sh
git pull origin main
```

---

## Summary Table

| Command              | Purpose                            | Example                           |
|----------------------|------------------------------------|-----------------------------------|
| `git status`         | Check repo status                  | `git status`                      |
| `git init`           | Initialize new repo                | `git init`                        |
| `git clone`          | Clone remote repo                  | `git clone https://...`           |
| `git add`            | Stage changes                      | `git add .`                       |
| `git commit`         | Commit staged changes              | `git commit -m "message"`         |
| `git push`           | Push commits to remote             | `git push origin main`            |
| `git pull`           | Pull changes from remote           | `git pull origin main`            |

---

These commands form the foundation for using Git effectively in most workflows.