# github-how-to

Short, practical guides for common tasks in GitHub and GitHub Actions. Each
guide is self-contained: what it is, when to use it, what you need before you
start, step-by-step instructions, how to check the result and how to clean up
afterwards.

## Before you start

- The guides are meant to be used in a repository of your own. Copy the files
  from a guide's folder to your repository. Workflow files only run from
  `.github/workflows` at the root of a repository, so put them there, not in
  a folder of their own.
- In the guides that use AWS, resource names are written with a prefix of
  your own choice, for example `<prefix>-github`. Set it once in the
  terminal: `export PREFIX=demo`. `export` is needed so that scripts you run
  with `bash` also see the prefix.
- In the same guides, set your region once in the terminal:
  `REGION=eu-north-1`, and use the same region in the console.
- Placeholders are written in angle brackets, for example `<repository>`.
  Replace the whole placeholder, brackets included.

## Guides

| # | Guide | What it does |
|---|-------|--------------|
| 01 | First workflow | Let GitHub run commands on every push with a workflow file, and read the result in the Actions tab. |
| 02 | Push protection | Let GitHub stop a push that contains a secret, and see why a key in a public repository can never be removed from its history. |
| 03 | ShellCheck in Actions | Check bash scripts with ShellCheck on every push, and show the result with a status badge in the README. |
| 04 | Sign in to AWS without keys | Let GitHub Actions sign in to AWS with OpenID Connect and a role, without any stored access keys. |
| 05 | Publish a web page to S3 | Publish a web page to an S3 bucket automatically when the page changes. |
| 06 | cfn-lint in Actions | Check CloudFormation templates with cfn-lint and `validate-template` in a workflow, before any stack is created. |
| 07 | Deploy a stack with a button | Create and delete a CloudFormation stack from GitHub with the Run workflow button. |
| 08 | Scheduled check of AWS resources | Run a workflow on a schedule that lists what is still running in AWS, so nothing is forgotten over the weekend. |

## License

MIT, see [LICENSE](LICENSE).
