# .gitignore

## What it is

`.gitignore` is a file in the repository that lists files and folders that git should leave alone. Files that match a line in it do not show in `git status`, and `git add` does not include them. You create a `.gitignore`, check which line ignores a file, and stop git from tracking a file that was added before it was ignored.

## Why and when to use it

- **A repository folder often has files that should not be in the repository:** log files, build output, settings for your editor, and files with passwords or keys.
- **Without `.gitignore`, it is easy to add them by mistake** with `git add .`, and once they are pushed, they are in the history.
- **Files with secrets are the most important case.** A key that has been pushed to a public repository must be treated as leaked, even if you remove it afterwards. See [Push protection](../push-protection/).
- **`.gitignore` is committed like any other file,** so everyone who clones the repository gets the same rules.

## How it works

- **Each line is a pattern.** A file that matches a pattern is ignored:

  | Pattern | Matches |
  |---|---|
  | `app.log` | Files and folders named `app.log`, in any folder. |
  | `*.log` | All names that end with `.log`. `*` matches anything except `/`. |
  | `build/` | Folders named `build`, and everything in them. The `/` last means folders only. |
  | `/notes.txt` | `notes.txt` at the root only, not in subfolders. A `/` first anchors the pattern to the folder where `.gitignore` is. |
  | `docs/**/*.pdf` | PDF files in `docs` and all its subfolders. `**` matches any number of folders. |
  | `!keep.log` | An exception: `keep.log` is not ignored, even though `*.log` matches it. |

- **Lines that start with `#` are comments,** and empty lines are ignored.
- **`.gitignore` usually lies at the root of the repository,** but there can be more in subfolders. Their patterns apply from the folder where they lie.
- **`.gitignore` only affects files that git does not already track.** A file that has been added and committed stays in git even if a line in `.gitignore` matches it. You have to stop tracking it with `git rm --cached`, see step 3.
- **`git check-ignore -v` shows which line ignores a file,** useful when a file is ignored and you do not understand why.

See [gitignore](https://git-scm.com/docs/gitignore) in the Git documentation.

## Prerequisites

- A repository cloned to your computer.
- [Git](https://git-scm.com/) and a terminal. On Windows, Git Bash.

Nothing is created outside your repository folder.

## Step by step

### 1. Create files that should be ignored

1. Go to the root of your repository in the terminal.
2. Create a log file, a file with passwords and a build folder. They are empty, since only the names matter here:

   ```
   touch app.log .env && mkdir -p build && touch build/output.txt
   ```

3. Run `git status`. Under **Untracked files**, `.env`, `app.log` and `build/` are shown. A `git add .` now would include all three.

### 2. Ignore them

1. Open `.gitignore` at the root of the repository, or create it if it does not exist. Add the lines from [gitignore-example.txt](gitignore-example.txt):

   ```
   # Log files
   *.log

   # Files with passwords
   .env

   # Build output
   build/
   ```

2. Run `git status` again. The three are gone. Only `.gitignore` is shown, if it is new or changed.
3. Ask git which line ignores each file:

   ```
   git check-ignore -v app.log .env build/output.txt
   ```

   Each line in the output shows the file, the line number and the pattern that matched, for example `.gitignore:2:*.log` followed by `app.log`. A file that is not ignored gives no output.
4. Commit `.gitignore`:

   ```
   git add .gitignore && git commit -m "Add .gitignore"
   ```

### 3. Stop tracking a file that is already in git

1. Create a file and commit it, as if it had been added before anyone thought of ignoring it:

   ```
   echo "hello" > debug.txt && git add debug.txt && git commit -m "Add debug.txt"
   ```

2. Add a line with `debug.txt` to `.gitignore`. Then change the file:

   ```
   echo "changed" >> debug.txt
   ```

3. Run `git status`. `debug.txt` is shown as modified, even though `.gitignore` has a line for it. Git already tracks the file, so the line has no effect.
4. Stop tracking the file. `--cached` removes it from git but keeps it in your folder:

   ```
   git rm --cached debug.txt
   ```

   Git answers `rm 'debug.txt'`. Check with `ls` that the file is still there.
5. Commit. The commit removes the file from the repository, and from now on `.gitignore` applies to it:

   ```
   git add .gitignore && git commit -m "Stop tracking debug.txt"
   ```

The file is still in the earlier commits. For a file with a password or a key, that is not enough: treat the secret as leaked and replace it.

## Check the result

- `git status` shows none of the ignored files.
- `git check-ignore -v` shows a line for each ignored file.
- `debug.txt` is still in your folder, but no longer in git.

## Clean up

Remove the test files:

```
rm -r app.log .env build debug.txt
```

Remove the test lines from `.gitignore`, or keep the ones you want, and commit. Push if you want the commits on GitHub.

## Use it in your own repository

- **Start from a template.** GitHub has [ready-made `.gitignore` files](https://github.com/github/gitignore) for many languages and tools, and you can choose one when you create a repository on GitHub.
- **Ignore secrets by name pattern,** for example `.env`, `*.pem` and `*.key`, before such files exist in the folder.
- **Keep secrets outside the repository folder altogether** when you can. `.gitignore` is the safety net, not the plan.

## Common errors

| Symptom | Cause |
|---|---|
| A file is still shown in `git status` despite a line in `.gitignore` | Git already tracks it. Stop tracking it with `git rm --cached`, as in step 3. |
| A file you need is ignored | A pattern matches more than you meant. `git check-ignore -v` shows which line. Make the pattern narrower, or add an exception with `!`. |
| A pattern with `/` last does not ignore a file | `/` last only matches folders. Remove the `/` to match files too. |

## Files

| File | What it is |
|---|---|
| `gitignore-example.txt` | The lines from step 2: log files, `.env` and the build folder. |
