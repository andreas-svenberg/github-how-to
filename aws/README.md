# AWS

Guides for GitHub Actions that work with Amazon Web Services. Start with
Sign in to AWS without keys: the other guides here use the role and the
repository variable that it creates.

New to GitHub Actions? Do [First workflow](../basics/first-workflow/) first.

## Reading order

| Guide | What you do |
|---|---|
| [Sign in to AWS without keys](sign-in-without-keys/) | Let GitHub Actions sign in to AWS with OpenID Connect, without stored keys. |
| [Publish a web page to Amazon S3](publish-a-web-page-to-amazon-s3/) | Push to `main`, and the page is published to an S3 bucket. |
| [cfn-lint in Actions](cfn-lint-in-actions/) | Check CloudFormation templates on every push. Builds on [ShellCheck in Actions](../basics/shellcheck-in-actions/). |
| [Deploy a stack with a button](deploy-a-stack-with-a-button/) | Create and delete a CloudFormation stack with **Run workflow**. |
| [Scheduled check of AWS resources](scheduled-check-of-resources/) | Every Friday, list what is running in the account. |

## Before you start

- Resource names are written with a prefix of your own choice, for example
  `<prefix>-github`. Set it once in the terminal: `export PREFIX=demo`.
  `export` is needed so that scripts you run with `bash` also see the prefix.
- The region is set in two places: among the settings at the top of the
  scripts that need it, and on the line `aws-region` in the workflow files.
  The guides use `eu-north-1`. Use the same region in the console.
- The scripts are uploaded to CloudShell with **Actions** and **Upload file**.
  See [Files in CloudShell](https://github.com/andreas-svenberg/aws-how-to/tree/main/05-files-in-cloudshell)
  in aws-how-to for how to upload and download files.
