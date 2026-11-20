# cfn-lint in Actions

## What it is

The same idea as checking bash scripts with ShellCheck, but for CloudFormation templates. You extend the workflow **Check** with two new jobs: `cfn-lint`, which checks the templates on every push, and `validate`, which signs in with the GitHub role and runs `aws cloudformation validate-template`, but only on `main`. Then you put a typo in the template, see it turn red and fix it. Nothing is created in AWS: validation creates nothing.

## Why and when to use it

- **A typo in a property, for example `CidrBlok` instead of `CidrBlock`, looks reasonable in an editor.** Without a check, it is only noticed at `aws cloudformation deploy`.
- **By then CloudFormation has already started,** finds the error, rolls back and leaves a stack in `ROLLBACK_COMPLETE` that must be deleted before you can try again. That takes minutes, and the error message is under **Events**.
- **cfn-lint is a tool from AWS that reads the template without sending it anywhere.** It knows all resource types and their properties, and says if a property does not exist, is missing or has the wrong type.
- **`aws cloudformation validate-template` sends the template to AWS,** which checks that it is valid YAML or JSON with the right basic structure and lists the parameters. It catches fewer errors than cfn-lint, but shows that AWS itself accepts the file and that the sign-in works.
- **Both run on push, long before anyone runs deploy.** An error becomes a red cross in Actions, not a failed stack in the account.

## How it works

The guide extends the workflow from [ShellCheck in Actions](../../basics/shellcheck-in-actions/) instead of making a new one. Then all checks of the repository are in one place, and the status badge from that guide also covers templates.

- **The job `shellcheck` is exactly as in [ShellCheck in Actions](../../basics/shellcheck-in-actions/).** Jobs in the same workflow run in parallel, so the new ones do not affect it.
- **The job `cfn-lint` installs Python 3.12 with `actions/setup-python`,** installs cfn-lint with `pip` and runs it on all YAML files in the folder `templates`. `setup-python` is used so as not to install into the runner's own Python, which Ubuntu protects against such changes.
- **The job `validate` signs in with the role and runs `validate-template` on each template.** It only runs on `main`, since the trust policy from [Sign in to AWS without keys](../sign-in-without-keys/) only allows sign-in from `main`. Without the condition, every push to another branch would give a red cross.
- **`needs: cfn-lint` makes `validate` wait for `cfn-lint`,** and skip if cfn-lint finds errors. There is no reason to ask AWS about a template that you already know is wrong.
- **`if: github.ref == 'refs/heads/main'`** is the condition for `main`.
- **The role needs a new permission,** as an inline policy of its own, `<prefix>-github-validate`. It only contains `cloudformation:ValidateTemplate`. That action creates nothing and cannot be limited to a certain resource, so `Resource` is `*`.

## Prerequisites

- The workflow `check.yml` from [ShellCheck in Actions](../../basics/shellcheck-in-actions/).
- The role `<prefix>-github` and the variable `AWS_ROLE_ARN` from [Sign in to AWS without keys](../sign-in-without-keys/). Without them, see "Use it in your own repository" below.
- A CloudFormation template in the folder `templates` at the root of the repository. If you have none, use [demo-vpc.yaml](demo-vpc.yaml), a template with an empty VPC.
- `PREFIX` set in CloudShell, see step 0 below and [Before you start](../README.md#before-you-start) in the AWS README.

## Step by step

### 0. Set your prefix

Set the same prefix as in your resource names, in the CloudShell session you use for the steps below. `export` makes the prefix visible also to scripts you run with `bash`, not only to commands you type. Do it again if CloudShell has closed the session. See also [Before you start](../README.md#before-you-start) in the AWS README.

```
export PREFIX=demo
```

### 1. Give the role the right to validate

1. Open CloudShell, choose **Actions** and **Upload file**, and upload [allow-role-to-validate.sh](allow-role-to-validate.sh). If you have not uploaded files to CloudShell before, see [Before you start](../README.md#before-you-start) in the AWS README. There is nothing to change in it: it contains no bucket name or account number, only the action `ValidateTemplate`.
2. Run the script. It writes the policy to a file and puts it on the role with `aws iam put-role-policy`. Last, it lists the role's inline policies, where `<prefix>-github-validate` should now be:

   ```
   bash allow-role-to-validate.sh
   ```

### 2. Replace check.yml and push

1. If the repository has no template yet, create the folder `templates` and save [demo-vpc.yaml](demo-vpc.yaml) there.
2. Open `.github/workflows/check.yml`, select everything and replace it with the content of [check.yml](check.yml). The job `shellcheck` is unchanged. New are the line `permissions` at the top and the two jobs `cfn-lint` and `validate` at the bottom.
3. Commit and push to `main`:

   ```
   git add .github templates && git commit -m "Check templates" && git push
   ```

4. Open the tab **Actions** and the run under **Check**. The three jobs show as boxes, and an arrow from `cfn-lint` to `validate` shows that `validate` waits. After half a minute or so, all three are green. Open `validate` and the step **Validate templates in AWS**: there is the template's name and its two parameters, `Prefix` and `VpcCidr`.

### 3. A typo in the template

1. Open `templates/demo-vpc.yaml` and change `CidrBlock` to `CidrBlok` on line 18, that is remove the letter c. It still looks reasonable, and the YAML file is still valid.
2. Commit and push:

   ```
   git commit -am "Test typo" && git push
   ```

3. In **Actions**, **Check** turns red. The job `cfn-lint` has failed, `validate` is grey and skipped, and `shellcheck` is green. Open `cfn-lint` and the step **Run cfn-lint**:

   ```
   E3014 Only one of ['CidrBlock', 'Ipv4IpamPoolId'] is a required property
   templates/demo-vpc.yaml:17:5

   E3002 Additional properties are not allowed ('CidrBlok' was unexpected. Did you mean 'CidrBlock'?)
   templates/demo-vpc.yaml:18:7
   ```

   E3002 says that `CidrBlok` is not allowed and asks if you meant `CidrBlock`. E3014 says that the VPC now lacks an address range. Both point at file and line. The output comes from cfn-lint 1.61.0, run in November 2026, and can be worded differently in other versions.

4. Change it back to `CidrBlock`, commit and push. Now all three jobs are green again:

   ```
   git commit -am "Fix typo" && git push
   ```

## Check the result

- **Check** has three green jobs on `main`.
- With a typo, `cfn-lint` is red and `validate` is skipped.

## Clean up

The extended workflow is the result. If you only tried it, remove the role's policy for validation:

```
aws iam delete-role-policy --role-name ${PREFIX}-github --policy-name ${PREFIX}-github-validate
```

## cfn-lint compared with validate-template

| cfn-lint | validate-template |
|---|---|
| Runs entirely on the runner. Needs no sign-in to AWS, and therefore works on all branches, even branches the role does not trust. | Runs in AWS and needs sign-in, so here it only runs on `main`. |
| Finds wrong properties, such as `CidrBlok`, wrong data types, references to resources or parameters that do not exist, and much more. The most important of the two. | Checks that the template is valid YAML or JSON with the right basic structure, and shows the parameters. Fast and safe, since it creates nothing. |

Neither check can know everything. A bucket name that is already taken, a limit in the account or a missing permission only shows when the stack is created. The checks remove the simple errors, so that the hard ones are the only ones left.

## Use it in your own repository

- **Are your templates in another folder?** Change the path both in the cfn-lint step and in the `for` loop in `validate`. cfn-lint can also take several paths after each other.
- **Without [Sign in to AWS without keys](../sign-in-without-keys/),** remove the whole job `validate` and the line `permissions`. You still have cfn-lint, which does not need AWS at all.
- **Codes starting with E are errors and codes starting with W are warnings,** and by default both give a red cross. To let only errors stop the run, add `--non-zero-exit-code error` after `cfn-lint`. The warnings still show in the log, but the run is green. The advantage is a softer start, the drawback that warnings easily stay.

## Common errors

| Symptom | Cause |
|---|---|
| `cfn-lint` is red | The template has errors. Read the codes in the log and search for them. |
| `validate` is skipped | `cfn-lint` failed, or the push was not to `main`. |
| `validate` fails with `AccessDenied` on `ValidateTemplate` | The role lacks the policy from step 1. |
| `validate` fails at the sign-in | See Common errors in [Sign in to AWS without keys](../sign-in-without-keys/). |

## Files

| File | What it is |
|---|---|
| `check.yml` | The workflow from [ShellCheck in Actions](../../basics/shellcheck-in-actions/), with the jobs `cfn-lint` and `validate`. |
| `allow-role-to-validate.sh` | Gives the role `<prefix>-github` the right to validate templates, nothing else. |
| `demo-vpc.yaml` | A minimal template with an empty VPC. |
