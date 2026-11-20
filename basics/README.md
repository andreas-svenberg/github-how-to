# Basics

Guides for GitHub and GitHub Actions that work the same whatever you
deploy to. Nothing here needs an account outside GitHub.

## Reading order

| Guide | What you do |
|---|---|
| [First workflow](first-workflow/) | Write a workflow that runs on every push, and read its log in the Actions tab. |
| [.gitignore](gitignore/) | Keep files such as logs, build output and secrets out of git, and stop tracking a file that was added by mistake. |
| [Push protection](push-protection/) | See how GitHub stops a push that contains a secret, and keep secrets out of the repository with `.gitignore`. |
| [ShellCheck in Actions](shellcheck-in-actions/) | Check your shell scripts on every push, and show the result as a status badge. |
| [Secrets and variables](secrets-and-variables/) | Store keys and settings in the repository's settings, and read them in a workflow. |

## Next

- [AWS](../aws/): GitHub Actions against Amazon Web Services.
- [Web hosting](../web-hosting/): GitHub Actions that publish to an ordinary web host.
