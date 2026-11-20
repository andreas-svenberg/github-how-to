# ShellCheck in Actions

## What it is

ShellCheck reads a bash script without running it and points out common mistakes, a bit like a spell checker for bash. You add a workflow that checks all bash scripts in the repository with ShellCheck on every push, see it turn red because of a script with errors, read the error in the log, fix the script and see it turn green. Last, you add a status badge to the README, so that everyone sees whether the check passes.

## Why and when to use it

- **Errors in bash often do not show until the script runs,** and then maybe on a server, or where it already does damage.
- **A script can look right and work when you try it,** but break when a folder or a file has a space in its name. A classic example is a variable without quotes around it.
- **ShellCheck knows hundreds of common mistakes.** For each note, it shows the file, the line, a code starting with `SC` and a suggestion for how to fix it. The code can be searched for, and the [ShellCheck wiki](https://www.shellcheck.net/wiki/) explains each one.
- **In a workflow, the check runs on every push,** without anyone having to remember it. If ShellCheck finds something, the run turns red directly after the push.

## How it works

The workflow [check.yml](check.yml) is named **Check** and also starts with `on: push`. A repository can have any number of workflows, and each file becomes a workflow of its own in the Actions tab.

- **The job is called `shellcheck`** and runs on `ubuntu-24.04`. ShellCheck is already installed on that runner.
- **The steps:** `actions/checkout`, which fetches the files, then the ShellCheck version, then a list of all files ending in `.sh`, so that the log shows exactly which files are checked.
- **The last step uses `find`** to find all `.sh` files in the repository, except in the folder `.git`, and runs `shellcheck` on them. You do not need to change the workflow when you add a new script.
- **When ShellCheck finds something, it ends with an exit code that is not zero.** That is something else than the codes starting with `SC`. Then the step, the job and the whole run fail, and GitHub shows a red cross.

## Prerequisites

- A repository on GitHub, cloned to your computer, that you can push to. See [First workflow](../first-workflow/) for how workflows work.
- [Git](https://git-scm.com/), [VS Code](https://code.visualstudio.com/) or another editor, and a terminal. On Windows, Git Bash.

| Placeholder | What it is | Example |
|---|---|---|
| `<owner>` | Your GitHub account or organisation | `my-account` |
| `<repository>` | The name of your repository | `my-repo` |

## Step by step

### 1. Add a script with errors and the workflow

1. Create the folder `scripts` at the root of the repository, and save [report.sh](report.sh) there as `scripts/report.sh`. It counts the files in a folder, and has two deliberate notes for ShellCheck on line 7.
2. Create the folder for workflows if it does not exist, and save [check.yml](check.yml) there:

   ```
   mkdir -p .github/workflows
   ```

3. Run `git status` and check what comes along. Then add, commit and push:

   ```
   git add scripts .github && git commit -m "Add ShellCheck"
   ```

   ```
   git push
   ```

4. Open the tab **Actions**, choose **Check** in the list on the left and open the run. Wait a few seconds. It turns red, and that is exactly what you want.

### 2. Read the error in the log

1. Click on the job `shellcheck`. The steps that succeeded have a green check mark, and the step that failed has a red cross.
2. Expand the step **Run ShellCheck**. The output has the same form as when you run ShellCheck in a terminal: first the file and the line, then the line from the script with marks under it, and last the codes:

   ```
   In ./scripts/report.sh line 7:
   count=$(ls $folder | wc -l)
           ^--------^ SC2012 (info): Use find instead of ls to better handle non-alphanumeric filenames.
              ^-----^ SC2086 (info): Double quote to prevent globbing and word splitting.
   ```

   - **SC2086** means that the variable `folder` has no quotes. If the folder name contains a space, it is split into two words, and the script counts the wrong folder or fails. The fix is to put the variable in double quotes.
   - **SC2012** means that `ls` is not reliable for counting files, since the output of `ls` is made for humans and can look different. ShellCheck suggests `find` instead.

   The output above comes from ShellCheck 0.11.0, run in November 2026. Other versions can word it a little differently.

### 3. Fix the script and see it turn green

1. Open `scripts/report.sh` and change line 7 to:

   ```
   count=$(find "$folder" -maxdepth 1 -type f | wc -l)
   ```

   - The double quotes around `$folder` fix SC2086: the folder name is kept together as one word, even if it contains spaces. Line 6, where `folder` gets its value, does not need to change, since a value is never split in an ordinary assignment.
   - `find` instead of `ls` fixes SC2012. `-maxdepth 1` only looks in the folder itself and not in subfolders, and `-type f` only counts ordinary files.

   The whole fixed file is in [report-fixed.sh](report-fixed.sh).

2. Commit and push. `-a` takes along all changed files that git already knows about, so no separate `git add` is needed:

   ```
   git commit -am "Fix ShellCheck notes" && git push
   ```

3. Go to the tab **Actions** again. The new run of **Check** turns green. The step **Run ShellCheck** now shows nothing at all: ShellCheck is silent when everything is in order.

### 4. Status badge in the README

A status badge is a small image in the README that shows whether the check passes. It is shown on the repository's start page.

1. Open `README.md` at the root of the repository.
2. Paste this line at the top, directly under the heading, and replace `<owner>` and `<repository>` with your account and your repository:

   ```
   ![Check](https://github.com/<owner>/<repository>/actions/workflows/check.yml/badge.svg)
   ```

   The line is markdown for an image: an exclamation mark, an alternative text in square brackets and an address in parentheses. The address is the repository's address, then `actions/workflows`, the workflow's file name and last `badge.svg`. GitHub draws the image every time someone opens the page.

3. Commit and push the README, and open the repository's start page. Now it says **Check** and **passing** in green.

## Check the result

- **Check** is green in the Actions tab.
- The badge on the start page shows **passing**.
- The badge shows the result of the latest run on the default branch, `main`. If someone pushes a script with errors, it turns red and shows **failing**, and everyone who visits the repository sees it.

## Clean up

The workflow and the badge are the result. If you do not want to keep them, remove `.github/workflows/check.yml`, the badge line in the README and, if you only added it for this guide, `scripts/report.sh`, and push.

## Use it in your own repository

- **`check.yml` works in any repository without changes.** Since `find` searches the whole repository, all bash scripts are checked, whatever folder they are in. If the repository has no `.sh` files, the run is green without checking anything, and that shows in the step that lists the files.
- **It is common to get several notes the first time.** Read them one at a time, search for the code and fix what you understand. Do not change something you do not understand just to get green.
- **ShellCheck has four levels: error, warning, info and style.** As the workflow is written, all levels stop the run. To let only the more serious levels give a red cross, add `--severity=warning` after `shellcheck` in the last step. Then info and style still show in the log, but the run is green. Note that both notes in this guide are at the level info, so with `--severity=warning` the run would be green even before the fix.

## Common errors

| Symptom | Cause |
|---|---|
| **Check** does not show in the Actions tab | The file is not in `.github/workflows` at the root of the repository. |
| The run is green but nothing was checked | There are no `.sh` files, or they have another ending. See the step that lists the files. |
| The badge shows as a broken image | The address is wrong: check the account, the repository and the file name `check.yml`. |

## Files

| File | What it is |
|---|---|
| `check.yml` | The workflow: runs ShellCheck on all `.sh` files on every push. |
| `report.sh` | A small script with two deliberate notes for ShellCheck. |
| `report-fixed.sh` | The same script, fixed. |
