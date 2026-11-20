# Secrets and variables

## What it is

A workflow often needs values that should not be written in the workflow file: a password, a key, a server name or an account number. GitHub lets you store them in the repository's settings, as **secrets** or **variables**, and the workflow reads them by name. You create one of each, read them in a workflow and see that the secret is hidden in the log.

## Why and when to use it

- **A value written in a workflow file is visible to everyone who can read the repository,** and stays in the history even if you remove it later. For a key or a password in a public repository, that is the same as publishing it.
- **A secret is stored encrypted by GitHub** and is only handed to the workflow when it runs. If the workflow prints it, GitHub replaces it with `***` in the log.
- **A variable is for values that are not secret** but differ between repositories or change now and then, for example a region, a server name or the ARN of a role. It is shown in plain text, both in the settings and in the log.
- **The same workflow file can then be used in several repositories,** each with its own values in the settings.
- **Rule of thumb:** if it would be a problem for the value to end up in a public log, it is a secret. Otherwise it can be a variable.

## How it works

- **Both are created under Settings, Secrets and variables, Actions,** in two tabs: **Secrets** and **Variables**.
- **In the workflow, a secret is read as `${{ secrets.NAME }}`** and a variable as `${{ vars.NAME }}`.
- **Names may only contain letters, digits and `_`,** must not start with a digit or with `GITHUB_`, and are not case sensitive when you use them. GitHub stores secret names in upper case.
- **Hand the value to the commands as an environment variable,** under `env`, instead of writing `${{ secrets.NAME }}` directly in a command. GitHub recommends this: a value on a command line can be seen by other processes on the machine.
- **Secrets cannot be used directly in a condition with `if`.** Put the secret in an environment variable and test that instead, as in the example below. Variables can be used in `if`.
- **The hiding in the log is not guaranteed.** GitHub only recognises the exact value. If the workflow changes it, for example encodes it or prints part of it, the result can be shown in plain text. Avoid structured data such as JSON as the value of a secret, for the same reason.
- **Workflows started by pull requests from forks do not get the repository's secrets.** Otherwise anyone could open a pull request with a workflow that sends them somewhere.
- **Secrets and variables can also be set for an organization or an environment.** If the same name exists at several levels, the most specific one wins: environment before repository, repository before organization. This guide only uses the repository level.

See [Using secrets in GitHub Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) and [Store information in variables](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables).

## Prerequisites

- A repository on GitHub, cloned to your computer, that you can push to, and where you can open **Settings**. See [First workflow](../first-workflow/) for how workflows work.

Nothing is created outside GitHub.

## Step by step

### 1. Create a variable and a secret

1. Open the repository on GitHub and choose **Settings**. In the menu on the left, under **Security and quality**, choose **Secrets and variables** and then **Actions**.
2. Choose the tab **Variables** and click **New repository variable**. Fill in:

   | Field | Value |
   |---|---|
   | Name | `GREETING` |
   | Value | `Hello from a variable` |

   Click **Add variable**. The value is shown in the list.
3. Choose the tab **Secrets** and click **New repository secret**. Fill in:

   | Field | Value |
   |---|---|
   | Name | `DEMO_SECRET` |
   | Secret | `not-a-real-password` |

   Click **Add secret**. The list only shows the name, not the value. You can replace the value or remove the secret, but GitHub does not show the value again.

Never use a real password or key for the test: the point of the test is to print the value.

### 2. Read them in a workflow

1. Save [show-secrets-and-variables.yml](show-secrets-and-variables.yml) as `.github/workflows/show-secrets-and-variables.yml`. Look at `env` under the job: that is where the secret and the variable become environment variables. Push it:

   ```
   git add .github && git commit -m "Add secrets and variables demo" && git push
   ```

   Nothing starts at the push, since the workflow only has `workflow_dispatch`.
2. Open the tab **Actions**, choose **Show secrets and variables**, click **Run workflow** and then the green button.
3. Open the run and the job `show`, and expand the steps:
   - **Check that the secret is set** is skipped, since the secret exists.
   - **Print the variable** shows `The variable GREETING is: Hello from a variable`.
   - **Print the secret** shows `The secret DEMO_SECRET is: ***`.

### 3. See what happens without the secret

1. Under **Settings**, **Secrets and variables**, **Actions** and the tab **Secrets**, remove `DEMO_SECRET`.
2. Run **Show secrets and variables** again. The first step now stops the run with the error `The secret DEMO_SECRET is not set`. A secret that does not exist is read as an empty string, without any error of its own. That is why it is worth checking.

## Check the result

- The variable is shown in plain text in the log, the secret as `***`.
- Without the secret, the run stops with a clear error instead of continuing with an empty value.

## Clean up

Remove the variable `GREETING` under the tab **Variables**, and the secret `DEMO_SECRET` if it is still there. Remove the workflow file and push:

```
git rm .github/workflows/show-secrets-and-variables.yml && git commit -m "Remove secrets and variables demo" && git push
```

## Use it in your own repository

- **Long values, such as a private SSH key,** are easiest to paste in the web page, the whole file content including the first and last lines. With [GitHub CLI](https://cli.github.com/) you can read the value directly from a file instead, so that it is never copied by hand:

  ```
  gh secret set SSH_PRIVATE_KEY < deploy_key
  ```

- **Name the values after what they are,** for example `SSH_HOST` or `AWS_ROLE_ARN`, not after the workflow that uses them. Then several workflows can share them.

## Common errors

| Symptom | Cause |
|---|---|
| The value is empty in the workflow, without any error | The name is misspelled, or the value is a secret but is read with `vars`, or the other way around. |
| A secret is shown in plain text in the log | The workflow has changed the value before printing it, for example with `base64` or by printing part of it. |
| The workflow fails at `if` with a secret | Secrets cannot be used directly in `if`. Test an environment variable instead. |
| The secrets are empty in a pull request | The pull request comes from a fork. Its workflows do not get the repository's secrets. |

## Files

| File | What it is |
|---|---|
| `show-secrets-and-variables.yml` | Checks that the secret exists, prints the variable and prints the secret, which shows as `***`. |
