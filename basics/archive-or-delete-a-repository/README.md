# Archive or delete a repository

## What it is

When a repository is no longer used, you can archive it or delete it. An archived repository stays on GitHub but becomes read-only. A deleted repository is gone, but can in most cases be restored within 90 days. You try both on a test repository: archive and unarchive it, delete it and restore it.

## Why and when to use it

- **Archive when the repository is finished but worth keeping:** a course project, an old version, or code that others still link to. Everything stays, nobody can change it, and you can unarchive it whenever you want.
- **Delete when the repository should not exist at all:** a test, a mistake, or a repository that has been replaced by another.
- **The choice matters most for public repositories,** since others may link to them, fork them or depend on them.
- **Before either one, check what depends on the repository:** links in documents, other repositories, and services that trust it, for example a role in AWS that GitHub Actions in the repository signs in with.

## How it works

| | Archive | Delete |
|---|---|---|
| The repository | Stays, but is read-only: code, issues, pull requests, releases, wiki and more cannot be changed. | Is removed. |
| Collaborators | Cannot be added or removed. Others can only fork or star it. | Lose their access. Team permissions are removed for good. |
| Actions and secrets | Not documented. Disable and remove them first, see step 2. | Not documented. Disable and remove them first, see step 2. |
| Forks | Are not affected. | Forks of a public repository are not deleted. Forks of a private repository are deleted. |
| Undo | **Unarchive this repository** under **Settings**, at any time. | **Restore** under **Deleted repositories**, within 90 days, unless the repository is part of a fork network that still has other repositories in it. |

GitHub recommends closing all issues and pull requests and updating the README and the description before you archive a repository, so that visitors see why it is archived.

See [Archiving repositories](https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories), [Deleting a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/deleting-a-repository) and [Restoring a deleted repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/restoring-a-deleted-repository).

## Prerequisites

- A GitHub account. To archive or delete a repository you need admin permissions for it, which you have for your own repositories.

Nothing is created outside GitHub.

## Placeholders

| Placeholder | What it is | Example |
|---|---|---|
| `<owner>` | Your GitHub account | `my-account` |

## Step by step

### 1. Create a test repository

Practise on a repository that does not matter, not on the one you want to get rid of.

1. On GitHub, click **+** at the top right and choose **New repository**.
2. Name it `archive-test`, choose **Public**, and turn on adding a README, so that the repository is not empty.
3. Click **Create repository**.

### 2. Before you archive or delete

Do this for the real repository later. For the test repository there is nothing to do.

1. **Update the README and the description** to say why the repository is archived or where it has moved, if you archive it.
2. **Close open issues and pull requests,** or move them to the repository that replaces it.
3. **Search for what links to the repository,** in your own documents, other repositories and web pages.
4. **Disable the workflows and remove the secrets.** GitHub's documentation does not say whether workflows still run in an archived repository, so do not rely on archiving to stop them. Disable each workflow under **Actions**, and remove the repository's secrets under **Settings**, **Secrets and variables** (under **Security and quality**). See [Secrets and variables](../secrets-and-variables/).
5. **Remove access that trusts the repository,** for example a role in AWS that GitHub Actions signs in with. See Clean up in [Sign in to AWS without keys](../../aws/sign-in-without-keys/).

### 3. Archive and unarchive

1. Open `archive-test` and choose **Settings**.
2. At the bottom of the page **General**, under **Danger Zone**, click **Archive this repository**.
3. Read the warnings, type the repository's name, and click **I understand the consequences, archive this repository**.
4. The repository now has a banner that says it is archived and read-only. Try to edit the README on the web page: it is not possible.
5. Unarchive it: **Settings**, **Danger Zone**, **Unarchive this repository**, and **I understand the consequences, unarchive this repository**. The banner is gone.

### 4. Delete

1. Open `archive-test` and choose **Settings**.
2. At the bottom of the page **General**, under **Danger Zone**, click **Delete this repository**.
3. Click **I want to delete this repository**, and then **I have read and understand these effects**.
4. Type the repository's full name, `<owner>/archive-test`, and click **Delete this repository**.

The repository is gone, and its address no longer shows it.

### 5. Restore

1. Click your profile picture at the top right and choose **Settings**. This is the settings for your account, not for a repository.
2. In the menu on the left, under **Code, planning, and automation**, choose **Repositories**, and then **Deleted repositories**.
3. Next to `archive-test`, click **Restore**, and then **I understand, restore this repository**.

It can take up to an hour after the deletion before the repository shows in the list.

## Check the result

- After step 3, `archive-test` is not archived.
- After step 5, `archive-test` is back, with its README.

## Clean up

Delete `archive-test` again as in step 4. Leave it in **Deleted repositories**: it is removed for good after 90 days.

## Common errors

| Symptom | Cause |
|---|---|
| **Settings** or **Danger Zone** is not shown | You do not have admin permissions for the repository, or the organization does not allow it. |
| The repository is not in **Deleted repositories** | It was deleted less than an hour ago, or more than 90 days ago, or it is part of a fork network with other repositories in it. |

## Files

This guide has no files.
