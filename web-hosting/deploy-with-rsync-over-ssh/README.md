# Deploy with rsync over SSH

## What it is

Many web hosts give you an account on a server that you can reach with SSH, and a folder whose content becomes your website. GitHub Actions can copy your web pages there every time you push to `main`, with rsync over SSH. You give GitHub a key that is only used for this, tell it how to reach the server, and push a page that ends up on the website.

## Why and when to use it

- **Copying files by hand,** with FTP or the web host's file manager, is easy to forget, and it is hard to know afterwards which version is on the server.
- **When GitHub copies on every push to `main`,** the website is always the same as the repository. If something goes wrong, you push the previous version back.
- **[rsync](https://rsync.samba.org/) only sends what has changed,** so a push with one changed page sends one file, not the whole site.
- **With `--delete`, rsync also removes files on the server that are no longer in the repository.** The server then has exactly what is in the folder, and nothing that has been left behind.
- **The key is only used for deploys.** If it leaks, you remove it at the web host without affecting your own keys.

## How it works

- **The web pages are in the folder `public/` in the repository.** Only that folder is copied, not the workflow file, the README or anything else in the repository.
- **The workflow [deploy.yml](deploy.yml) runs on every push to `main`,** and with **Run workflow**.
- **The runner signs in to the server with a private SSH key** that is stored as a secret. The server has the matching public key in your account, just like when you sign in with a key yourself.
- **SSH must also know the server's host key,** so that it can check that it is talking to the right server. The workflow fetches it with `ssh-keyscan` at the start of each run. That is simple, but it means that SSH trusts whichever server answers. See [A safer way: save the host key](#a-safer-way-save-the-host-key) below.
- **Four secrets are needed,** see [Secrets and variables](../../basics/secrets-and-variables/) for how secrets work:

  | Secret | What it is |
  |---|---|
  | `SSH_PRIVATE_KEY` | The private key, the whole content of the file. |
  | `SSH_HOST` | The server's name. |
  | `SSH_USER` | Your user name on the server. |
  | `DEPLOY_PATH` | The folder on the server that is the website. |

- **The steps read the secrets as environment variables,** under `env` in the job, and not directly in the commands.
- **Two folders on the server are left alone by `--delete`:** `.well-known` and `cgi-bin`. Web hosts often create them themselves, and `.well-known` is for example used when the host renews the site's certificate. Without `--exclude`, rsync would remove them, since they are not in `public/`.

## Prerequisites

- An account at a web host where you can sign in with SSH and add your own SSH keys. Not all web hosting plans include SSH, so check that first.
- A repository on GitHub, cloned to your computer, that you can push to. See [First workflow](../../basics/first-workflow/) for how workflows work.
- An SSH key pair used only for deploys, without a password, with the public key added to your account on the web host. How to add it differs between web hosts, so see your host's help pages. Test that it works before you go on: `ssh -i <key-file> <user>@<host>`.
- A terminal with `ssh` and `ssh-keygen`. On Windows, [Git Bash](https://git-scm.com/) has them.

Test against an empty folder, or a web host without a website you want to keep: the deploy replaces what is in `<path>`.

## Placeholders

| Placeholder | What it is | Example |
|---|---|---|
| `<host>` | The server's name, from the web host | `ssh.example.com` |
| `<user>` | Your user name on the server | `webuser` |
| `<key-file>` | The private key's file on your computer | `~/deploy_key` |
| `<path>` | The website's folder on the server. See your web host's help pages. | `public_html/` |

## Step by step

### 1. Create the secrets

1. Open the repository on GitHub and choose **Settings**, under **Security and quality** **Secrets and variables**, and **Actions**, then the tab **Secrets**.
2. Click **New repository secret** for each of the four secrets:

   | Name | Secret |
   |---|---|
   | `SSH_PRIVATE_KEY` | The whole content of `<key-file>`, including the lines `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`. |
   | `SSH_HOST` | `<host>` |
   | `SSH_USER` | `<user>` |
   | `DEPLOY_PATH` | `<path>`, with `/` last |

   Show the private key with `cat <key-file>` if you want to copy it. With [GitHub CLI](https://cli.github.com/), you can read it directly from the file instead:

   ```
   gh secret set SSH_PRIVATE_KEY < <key-file>
   ```

### 2. Deploy

1. In your repository, create the folder `public` and save [index.html](public/index.html) in it. Save [deploy.yml](deploy.yml) as `.github/workflows/deploy.yml`.
2. Push to `main`. The push starts the workflow:

   ```
   git add public .github && git commit -m "Add deploy with rsync" && git push
   ```

3. Open the tab **Actions**, choose **Deploy with rsync** and open the run. Expand **Deploy public/ with rsync**: rsync lists the files it sends, here `index.html`.
4. Open your website in the browser. It shows the heading **Deployed with rsync**.
5. Change the text in `public/index.html`, commit and push again. The new run only sends `index.html`, and the website shows the new text after a reload.

## Check the result

- The run is green, and the rsync step lists the files that were sent.
- The website shows the page from `public/`.
- A file you remove from `public/` and push is also removed from the server.

## Clean up

1. Stop the deploys: remove the workflow file and push.

   ```
   git rm .github/workflows/deploy.yml && git commit -m "Remove deploy with rsync" && git push
   ```

2. Remove the secrets under **Settings**, **Secrets and variables** (under **Security and quality**), **Actions**.
3. Remove the public key from your account on the web host. After that, the key cannot be used even if it has leaked.
4. Remove the key files on your computer, the private key and the public key.

The files on the server are not removed by any of this. Remove them in the web host's file manager if you do not want to keep the website.

## A safer way: save the host key

The workflow trusts the host key that `ssh-keyscan` gets at the start of each run. If someone else answered on the server's name, for example through a hijacked DNS record, the workflow would accept that server too, and the deploy would end up there. The private key is not exposed, since it is never sent during sign-in, but the files, the user name and the path are, and your website is not updated.

The safer way is to approve the host key once yourself, and save it as a secret. If another server answers, the run stops with `Host key verification failed`.

1. Print the server's line from your own `known_hosts`. It is the host key you accepted the first time you signed in with `ssh`:

   ```
   ssh-keygen -F <host>
   ```

   The output starts with a line beginning with `#`, followed by one or more lines with the key. Copy everything.
2. Create the repository secret `SSH_KNOWN_HOSTS` with what you copied.
3. In `deploy.yml`, add the secret under `env`:

   ```
   SSH_KNOWN_HOSTS: ${{ secrets.SSH_KNOWN_HOSTS }}
   ```

4. In the step **Set up SSH**, replace the line with `ssh-keyscan` with:

   ```
   printf '%s\n' "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
   ```

If the web host changes its host key, which is rare, the deploy stops until you fetch the new key and update the secret.

## Use it in your own repository

- **Another folder than `public/`?** Change `public/` in the rsync command. Keep the `/` last: `public/` copies the content of the folder, `public` without `/` copies the folder itself, so the files end up in `<path>/public/`.
- **Another branch?** Change `branches: [main]`.
- **Does the web host use another SSH port than 22?** Add `-p <port>` to the ssh command after `-e`, for example `"ssh -p 2222 -i ~/.ssh/deploy_key -o StrictHostKeyChecking=yes"`, and to `ssh-keyscan` in the workflow: `ssh-keyscan -p <port> -H "$SSH_HOST"`. With a saved host key, fetch it with `ssh-keygen -F "[<host>]:<port>"`.
- **More folders on the server that must be left alone?** Add an `--exclude` for each.

## Common errors

| Symptom | Cause |
|---|---|
| `Permission denied (publickey)` | The public key is not added to your account on the web host, `SSH_USER` is wrong, or `SSH_PRIVATE_KEY` is missing a line. |
| `Host key verification failed` | `ssh-keyscan` could not reach `SSH_HOST`: check the name, and the port if the web host does not use 22. With a saved host key: `SSH_KNOWN_HOSTS` is empty or does not match `SSH_HOST`, or the server has a new host key. Fetch it again with `ssh-keygen -F`. |
| `rsync: command not found` | rsync is missing on the server. Ask the web host. |
| The files end up in a folder `public` on the server | The `/` after `public` is missing in the rsync command. |
| Files on the server disappeared | `--delete` removes everything that is not in `public/`. Add an `--exclude` for folders that must be kept. |

## Files

| File | What it is |
|---|---|
| `deploy.yml` | The workflow: copies `public/` to the server with rsync over SSH, on every push to `main`. |
| `public/index.html` | A minimal web page to test with. |
