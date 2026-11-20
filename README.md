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
- Placeholders are written in angle brackets, for example `<repository>`.
  Replace the whole placeholder, brackets included.

## Areas

The guides are grouped by area. Each area has its own README with the
guides in reading order.

| Area | What it covers |
|---|---|
| [Basics](basics/) | GitHub and GitHub Actions on their own: a first workflow, `.gitignore`, push protection, ShellCheck, and secrets and variables. Start here. |
| [AWS](aws/) | GitHub Actions against Amazon Web Services: sign-in without keys, S3, CloudFormation and a scheduled check. |
| [Web hosting](web-hosting/) | GitHub Actions that publish to an ordinary web host with rsync over SSH. |

## License

MIT, see [LICENSE](LICENSE).
