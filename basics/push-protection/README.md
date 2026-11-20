# Push protection

## What it is

Push protection is a protection in GitHub against pushing secrets, such as passwords and access keys, by mistake. With it turned on, GitHub stops a push that contains a known kind of secret. You check that push protection is on in your repository, and add lines to `.gitignore` so that it is harder to even add files with secrets. You also see why a key in a public repository can never be removed from its history.

## Why and when to use it

- **A public repository can be read by anyone on the internet,** and not only the latest version but the whole history. There are automatic searches for keys in public repositories, so a key can be found very quickly.
- **If you remove the file with the key and push again, the key is still in the earlier commit.** Whoever browses the history finds it. Cleaning the history is complicated and still not enough, since someone may already have copied it.
- **A key or a password is valid until someone replaces it.** Removing the file does not make it stop working, and a key with wide permissions can give access to a whole account.
- **Push protection catches many known kinds of secrets before they reach GitHub,** but not everything, and it is possible to choose to push anyway. See it as a safety net, not a lock.
- **The important thing is that keys are never in the repository folder in the first place.** [.gitignore](../gitignore/) helps with that.

## How it works

- **Push protection is part of secret scanning,** GitHub's search for secrets such as passwords and keys in the code.
- **For new public repositories owned by personal accounts, push protection is on by default,** according to GitHub. It can be turned off by the repository's administrator, so check it.
- **When push protection stops a push,** the output shows the type of secret, the commit, the file and the line.
- **`.gitignore` lists files and folders that `git add` should not include,** even if they end up in the repository folder. See [.gitignore](../gitignore/) for how the patterns work.

See [Push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection).

## Prerequisites

- A repository on GitHub that you own, cloned to your computer.
- [Git](https://git-scm.com/) and a terminal. On Windows, Git Bash.

## Step by step

### 1. Check push protection

1. Open the tab **Settings** in the repository. It only shows for whoever owns the repository.
2. Choose **Advanced Security** in the menu on the left, under **Security and quality**. There GitHub collects the settings for secret scanning.
3. Under the heading **Secret Protection**, find **Push protection**. The switch should show **On**. If it is off, turn it on.

### 2. Add to .gitignore

1. Open `.gitignore` at the root of the repository, or create it if it does not exist.
2. Add the groups from [gitignore-additions.txt](gitignore-additions.txt) that fit the tools you use:

   ```
   # Files with passwords and keys
   .env
   *.pem
   *.key

   # AWS CLI settings and keys
   .aws/
   credentials

   # Azure CLI settings and sign-in data
   .azure/
   ```

   The first group is for files with secrets that often end up in a project folder: `.env` for passwords and settings, `*.pem` and `*.key` for key files. The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) and the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration) save their settings in the folders `.aws` and `.azure` in your home folder, not in the repository. The lines are a safety net, in case such a folder is copied into the repository.

3. Add, commit and push `.gitignore` as usual:

   ```
   git add .gitignore && git commit -m "Ignore files with secrets"
   ```

   ```
   git push
   ```

Do not test push protection with a real key. If you want to see what happens, never use a key that works.

## Check the result

- **Push protection** shows as on under **Settings** and **Advanced Security**.
- Files that match the lines, for example `.env`, no longer show in `git status`, even if they are in the repository folder.

## Clean up

Nothing to clean up. Push protection and the lines in `.gitignore` are the result.

## Good to know

- **Push protection is a setting per repository.** Check it in every public repository you have.
- **If a secret still ends up in a repository:** replace it where it was created, for example by deactivating the key or changing the password. Removing the file is not enough.

## Common errors

| Symptom | Cause |
|---|---|
| **Settings** is not shown | You are not the owner of the repository. |
| A file with a key still shows in `git status` | It was added before the line in `.gitignore`, or the name does not match. Files that git already tracks are not affected by `.gitignore`, see [.gitignore](../gitignore/). |

## Files

| File | What it is |
|---|---|
| `gitignore-additions.txt` | Lines to add to `.gitignore`, in groups: files with passwords and keys, the AWS CLI and the Azure CLI. |
