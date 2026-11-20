# Sign in to AWS without keys

## What it is

To publish to AWS, validate a template or create a stack from GitHub Actions, GitHub must be able to sign in to AWS. With OpenID Connect (OIDC), it can do that without any AWS keys stored in GitHub. GitHub gets a short-lived identity token for each run, and AWS exchanges it for temporary keys to a role that you decide over. You set it up in three parts: AWS trusts GitHub, a role that only your repository may use, and a workflow that signs in and asks who it is.

## Why and when to use it

- **The simple way, seen in many guides, is an IAM user with an access key,** stored as a secret, a GitHub Secret, in the repository. GitHub hides it in the logs, so it looks safe.
- **The problem is that it is still a real key that is valid until someone deactivates it.** It can leak through a workflow that prints it, through someone with access to the repository, or through a mistake. And it must be rotated regularly, which rarely happens.
- **With OIDC, a workflow can ask GitHub for an identity token** for each run. The token says exactly which repository and which branch the run comes from, and is only valid for a few minutes.
- **AWS checks the token and gives temporary keys to a role in exchange.** The keys expire by themselves, here after one hour. It is the same idea as when an EC2 instance gets permissions through a role instead of keys on disk.
- **The result: there are no long-lived keys anywhere in GitHub.** Nothing to leak, nothing to rotate and nothing to forget.

## How it works

Three parts must match for the sign-in to work. If any part is wrong, the sign-in is denied, and that is exactly how it should be.

- **An identity provider in IAM.** It tells your AWS account that identity tokens from GitHub Actions may be used. It is created once per account and then used by all roles that GitHub should reach. The address is GitHub's token issuer, `https://token.actions.githubusercontent.com`, and the audience is `sts.amazonaws.com`, AWS's service for temporary keys.
- **An IAM role with a trust policy.** The trust policy says who may assume the role: only tokens from GitHub, with the right audience, and from exactly your repository and the branch `main`. Another repository, even one of your own, is denied.
- **The workflow.** It must explicitly be allowed to ask for a token, with `id-token: write`, and it must know which role to assume. The role's ARN is stored as a variable in the repository.

When the workflow runs, a ready-made action from AWS, `aws-actions/configure-aws-credentials`, fetches a token from GitHub, sends it to AWS STS and gets temporary keys back. The rest of the job runs the AWS CLI as usual.

**The subject (`sub`) is the most important line in the trust policy.** It identifies the repository and the branch. GitHub has two formats:

- With names only: `repo:<owner>/<repository>:ref:refs/heads/main`
- With names and ids: `repo:<owner>@<owner-id>/<repository>@<repository-id>:ref:refs/heads/main`. Repositories created after 15 July 2026 use this format automatically, so that the identity cannot be taken over if someone later creates a repository with the same name.

Do not guess which one your repository uses. The workflow [show-subject.yml](show-subject.yml) prints it.

See [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) and [OpenID Connect reference](https://docs.github.com/en/actions/reference/security/oidc).

## Prerequisites

- A repository on GitHub that you own, cloned to your computer, that you can push to `main`. See [First workflow](../../basics/first-workflow/) for how workflows work.
- An AWS account where you can create IAM roles from [AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html), for example as an administrator.
- `PREFIX` set in CloudShell, see step 0 below and [Before you start](../README.md#before-you-start) in the AWS README.

The role gets no permissions at all in this guide, so nothing costs money.

| Placeholder | What it is | Example |
|---|---|---|
| `<owner>` | Your GitHub account or organisation | `my-account` |
| `<repository>` | The name of your repository | `my-repo` |
| `<owner-id>`, `<repository-id>` | The numeric ids that `show-subject.yml` prints | `12345678`, `987654321` |

## Step by step

### 0. Set your prefix

Set the same prefix as in your resource names, in the CloudShell session you use for the steps below. `export` makes the prefix visible also to scripts you run with `bash`, not only to commands you type. Do it again if CloudShell has closed the session. See also [Before you start](../README.md#before-you-start) in the AWS README.

```
export PREFIX=demo
```

### 1. Find your repository's subject

1. Save [show-subject.yml](show-subject.yml) as `.github/workflows/show-subject.yml` in your repository and push to `main`:

   ```
   git add .github && git commit -m "Show OIDC subject" && git push
   ```

2. Open the run in the tab **Actions** and expand the step **Show OIDC claims**. It asks GitHub for a token and prints only the claims in it, never the token itself.
3. Copy the value on the line `sub`. It is exactly the value that should be in the trust policy, and it ends with `ref:refs/heads/main` when you push to `main`.
4. Remove the workflow again, since it runs on every push:

   ```
   git rm .github/workflows/show-subject.yml && git commit -m "Remove show-subject" && git push
   ```

### 2. Let AWS trust GitHub

1. Open the AWS console, check the region at the top right, and open CloudShell with the icon in the top bar.
2. Create the identity provider:

   ```
   aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com
   ```

   - `--url` is the address of GitHub's token issuer. Spell it exactly like that, without a slash at the end.
   - `--client-id-list` is the audience that GitHub's token should be issued to.
   - No certificate thumbprint is given. It is optional: AWS checks the provider's certificate against its own trusted certificate authorities, and only uses a thumbprint if the certificate is not signed by one of them. See [CreateOpenIDConnectProvider](https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateOpenIDConnectProvider.html).

   The answer is the provider's ARN. If you get the error `EntityAlreadyExists`, the provider already exists in the account, and you can go on. There can only be one provider per address in an account.

3. Check it. The line ending in `token.actions.githubusercontent.com` should be there:

   ```
   aws iam list-open-id-connect-providers
   ```

### 3. Create the role

1. Upload [create-github-role.sh](create-github-role.sh) to CloudShell with **Actions** and **Upload file**. If you have not uploaded files to CloudShell before, see [Before you start](../README.md#before-you-start) in the AWS README.
2. Open the script with `nano` and change `SUB` at the top to the value from step 1. Save with **Ctrl+O**, confirm with Enter and exit with **Ctrl+X**:

   ```
   nano create-github-role.sh
   ```

3. Run the script:

   ```
   bash create-github-role.sh
   ```

   It fetches the account number with `aws sts get-caller-identity`, writes the trust policy to the file `trust-policy.json` and creates the role `<prefix>-github`. The answer is one line, the role's ARN, starting with `arn:aws:iam` and ending with `role/<prefix>-github`. Copy it.

The role has no permissions at all. That is enough here, since `aws sts get-caller-identity` needs no permissions. The guides that follow add exactly the permissions each one needs.

### 4. The role's ARN as a variable in the repository

The workflow needs to know which role to assume. You could write the ARN directly in the file, but then the account number ends up in the repository, and you want to be able to change role without changing the file.

1. Open the repository on GitHub and choose the tab **Settings**.
2. In the menu on the left, under **Security and quality**, choose **Secrets and variables** and then **Actions**.
3. Choose the tab **Variables**, not **Secrets**, since the ARN is not a secret: it gives no access by itself. Click **New repository variable**.
4. Name it `AWS_ROLE_ARN`, paste the role's ARN as value and click **Add variable**.

In the workflow, the variable is read as `${{ vars.AWS_ROLE_ARN }}`. A variable shows in plain text in logs and settings, which is right here. A secret is for things that give access, and you deliberately have none of that. See [Secrets and variables](../../basics/secrets-and-variables/) for how variables and secrets work.

### 5. The workflow and the Run workflow button

1. Save [who-am-i.yml](who-am-i.yml) as `.github/workflows/who-am-i.yml`. Look at it:
   - `permissions` with `id-token: write`. Without that line, the job gets no token, and the sign-in fails directly.
   - A step with `aws-actions/configure-aws-credentials`, which does the exchange, with the role from the variable and the region `eu-north-1`. Change the region if yours is another.
   - A step that runs `aws sts get-caller-identity`.
   - `on: workflow_dispatch`, which gives a **Run workflow** button instead of starting on push. That is practical for anything that touches AWS: you decide when something runs.
2. Push it to `main`. Nothing happens in the tab **Actions** at the push, since the workflow only starts manually. The file must be on `main` for the button to show.

   ```
   git add .github && git commit -m "Add who-am-i workflow" && git push
   ```

3. Open the tab **Actions** and click **Who am I in AWS** in the list on the left. Click **Run workflow**, check that the branch is `main`, and click the green **Run workflow** in the box that opens. Reload the page if the run does not show directly.

## Check the result

1. Open the run and the job `who-am-i`. If it is green, the sign-in has succeeded.
2. Expand the step with `configure-aws-credentials`. It says that the role was assumed and which region is used.
3. Expand the step **Who am I**. The output is the same as when you run `aws sts get-caller-identity` in CloudShell: `UserId`, `Account` and `Arn`. The `Arn` says `assumed-role/<prefix>-github/` and a session name. GitHub is signed in as the role, with temporary keys that expire within an hour.
4. Look through the repository, **Settings** and the log. There is no access key anywhere. The only thing stored in GitHub is the role's name, and it gives no access without a valid token from exactly this repository.

## Clean up

Keep the role and the identity provider if you go on with the other guides in [AWS](../): they build on them and cost nothing.

When you no longer need them, [remove-github-role.sh](remove-github-role.sh) removes all inline policies on the role, the role itself and the identity provider. A role cannot be removed while it has policies. Do not remove the identity provider if another role in the account uses it: comment out the last lines first.

```
bash remove-github-role.sh
```

In GitHub, remove the variable `AWS_ROLE_ARN` under **Settings**, **Secrets and variables** (under **Security and quality**), **Actions** and the tab **Variables**, and the workflow file `who-am-i.yml`.

## What is denied, and why

Each no here is a protection built in on purpose.

- **Another repository with the same workflow and your role's ARN is denied,** since it sends another subject. That is why the trust policy checks the exact subject, and not only that the token comes from GitHub. Checking only the audience would let any repository on GitHub assume the role.
- **Another branch than `main` is denied,** since the subject ends with the branch name. A branch with a half-finished workflow cannot reach AWS.
- **Without `id-token: write`, the job never asks for a token,** and there is nothing to exchange for keys. The error shows in the step with `configure-aws-credentials`.
- **A single wrong character in the subject gives the same no.** AWS does not say what was wrong, for security reasons. Compare character by character with what `show-subject.yml` printed.
- **Even when the sign-in succeeds, the role can only do what you explicitly give it.** Here, nothing.

## Good to know

- **If an AWS access key still ends up in a repository:** go to IAM directly, deactivate and delete the key, and create a new one if needed. Removing the file is not enough. See [Push protection](../../basics/push-protection/) for how to keep keys out of a repository.

## Common errors

| Symptom | Cause |
|---|---|
| Not authorized to perform `sts:AssumeRoleWithWebIdentity` | One of the three parts does not match. Most often the subject: check it character by character, and that the run is on `main`. |
| `EntityAlreadyExists` when creating the provider | The provider already exists in the account. Go on. |
| The **Run workflow** button does not show | The workflow file is not on `main`, or does not have `on: workflow_dispatch`. |
| The script says to change `SUB` | `SUB` still has the placeholder. Change it to the value from `show-subject.yml`. |

## Files

| File | What it is |
|---|---|
| `show-subject.yml` | Prints the subject that GitHub sends for your repository. Remove it after use. |
| `create-github-role.sh` | Creates the role `<prefix>-github` with a trust policy for your repository's subject. |
| `who-am-i.yml` | Signs in to AWS with the role and runs `aws sts get-caller-identity`. |
| `remove-github-role.sh` | Removes the role, its inline policies and the identity provider. |
