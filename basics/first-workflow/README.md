# First workflow

## What it is

GitHub Actions lets GitHub run commands for you every time you push. You write the instructions in a file in the repository, and GitHub reads the file itself. The file is called a workflow. You write a first workflow, push it and read the log in the Actions tab.

## Why and when to use it

- **A repository with scripts often just stores them.** Nobody checks them when they are pushed, and an error is only noticed when someone runs the script.
- **With GitHub Actions you tell GitHub: every time someone pushes, run these commands.** That is how scripts, web pages and templates are often handled at real workplaces: what is pushed is checked and published automatically, instead of by hand.
- **The commands run on a new virtual machine that GitHub starts and removes afterwards.** It is called a runner. It is not your own computer and not a server in AWS.
- **This first workflow does almost nothing useful, but it is the foundation** for checking scripts, signing in to AWS and publishing, in the later guides.
- **Actions is free for public repositories** when you use GitHub's standard runners. See [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

## How it works

A workflow is a YAML file. The indentation with spaces means something, so be careful with it.

- **The file must be in a certain folder at the root of the repository,** otherwise GitHub does not find it: `.github/workflows/`, with a dot first. A YAML file anywhere else in the repository, for example in `scripts`, never runs.
- **`name`** is the name shown in the list in the Actions tab.
- **`on`** says when the workflow starts. With `on: push`, it starts every time someone pushes, to any branch. Other guides use other ways to start, such as a button and a schedule.
- **Under `jobs`** there is one job, here called `hello`. **`runs-on`** says which kind of runner the job runs on. `ubuntu-24.04` is used instead of `ubuntu-latest`, so that the tools do not change when GitHub moves `ubuntu-latest` to a newer version.
- **Under `steps`** come the steps in order. A step with **`uses`** uses a ready-made action, for example `actions/checkout`, which fetches the repository's files to the runner. A step with **`run`** runs your own commands in a shell, as in a terminal.

See [Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

## Prerequisites

- A repository on GitHub, cloned to your computer, that you can push to.
- [Git](https://git-scm.com/) and a terminal. On Windows, Git Bash.

Nothing is created in AWS.

## Step by step

### 1. Create and push the workflow

1. Go to the root of your repository in the terminal, and check with `ls` that you see the files you expect. If you are in the wrong folder, the workflow ends up in the wrong place and never runs, without any error message.
2. Create the folder. `-p` creates both folders at once and does not complain if they already exist:

   ```
   mkdir -p .github/workflows
   ```

3. Save [first-workflow.yml](first-workflow.yml) in the new folder as `.github/workflows/first-workflow.yml`. It prints a greeting, lists the repository's files and shows the versions of three tools.
4. Run `git status` and check that only `first-workflow.yml` comes along. Then add, commit and push. It is the push itself that starts the workflow, since the file says `on: push`:

   ```
   git add .github && git commit -m "Add first workflow"
   ```

   ```
   git push
   ```

   `&&` means that the commit only runs if `git add` succeeded. The commit message becomes the name of the run in the Actions tab.

### 2. Read the log in the Actions tab

1. Open the repository on GitHub and choose the tab **Actions**, in the same row of tabs as **Code**. All runs of all workflows are collected here.
2. In the list on the left are your workflows, with the name from the line `name`. Click **First workflow**. If it is not in the list, the file is probably in the wrong folder.
3. Click on the run, which has the same name as the commit message. There you see the job `hello`. Click on it to see the steps.
4. Expand the steps. The `echo` step says who pushed and to which branch. The `ls` step shows the repository's files, so the checkout has worked. The last step shows the versions of ShellCheck, Python and the AWS CLI, tools that are already on the runner.

## Check the result

- A green check mark means that all steps succeeded, and a red cross that a step failed.
- The same symbol shows next to the commit under the tab **Code**.

## Clean up

The workflow runs on every push. If you do not want to keep it, remove the file and push:

```
git rm .github/workflows/first-workflow.yml && git commit -m "Remove first workflow"
```

```
git push
```

## Use it in your own repository

- **Replace `ls` and `echo` with something that suits your repository,** for example listing a certain folder or counting files. Everything that works in a terminal works in principle in a `run` step, since the runner is an ordinary Linux machine.

## Common errors

| Symptom | Cause |
|---|---|
| Nothing happens after the push | The file is in the wrong folder, for example `github` without the dot, or `workflow` without the s. |
| An error in the Actions tab directly | An error in the indentation, for example a tab character instead of spaces. |

## Files

| File | What it is |
|---|---|
| `first-workflow.yml` | The workflow: prints a greeting, lists the files and shows tool versions, on every push. |
