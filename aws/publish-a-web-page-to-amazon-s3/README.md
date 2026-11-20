# Publish a web page to Amazon S3

## What it is

GitHub Actions can publish a web page for you: push to `main`, and the page is out. You create an S3 bucket that shows `index.html` as a website, give the GitHub role the right to put files in just that bucket, and write a workflow that uploads the page every time `index.html` changes on `main`. Then you change the page and see it update without touching AWS.

## Why and when to use it

- **Without automation:** you change `index.html`, push, open the console or CloudShell, upload the file and hope it was the right version. That is three places where something can go wrong, and nobody sees afterwards what was published.
- **With a workflow, pushing to `main` is enough.** GitHub uploads exactly the version that is in the repository, and the tab **Actions** shows who pushed, when and what was published.
- **The workflow only starts when `index.html` changes.** A change in a script or a template should not publish the page again unnecessarily.
- **The role gets one single permission: to put files in this bucket.** It cannot read other buckets, delete anything or start servers. That is least privilege, and the reason for giving permissions step by step.
- **The pattern, push to `main` and then automatic publishing, is the same as for real websites.** The difference is only the size of what is published.

## How it works

Three things are needed: a bucket that shows the page, a permission on the role, and a workflow.

- **The bucket gets two settings that an ordinary bucket does not have.** Static website hosting makes S3 answer with `index.html` on a web address. A bucket policy lets anyone read the files, but nobody write. See [Static website on S3](https://github.com/andreas-svenberg/aws-how-to/tree/main/20-static-website-on-s3) in aws-how-to for more about that.
- **The permission is an inline policy directly on the role,** named `<prefix>-github-site`. An inline policy only belongs to that role and goes with it if the role is deleted. It contains one action, `s3:PutObject`, and only on the files in your bucket. That is enough to upload `index.html` with `aws s3 cp`.
- **The bucket's name is a variable in the repository, `SITE_BUCKET`,** just like the role's ARN. Then nothing account-specific is in the workflow file itself.
- **The workflow [publish.yml](publish.yml) starts on push to `main`, but only if `index.html` is among the changed files.** That is controlled with `branches` and `paths` under `on: push`. It also has `workflow_dispatch`, the **Run workflow** button, which is needed the first time, since `index.html` does not change when you push the workflow file itself.

## Prerequisites

- The identity provider, the role `<prefix>-github` and the variable `AWS_ROLE_ARN` in the repository, from [Sign in to AWS without keys](../sign-in-without-keys/).
- An `index.html` at the root of the repository. If you have none, use [index.html](index.html).
- `PREFIX` set in CloudShell, see step 0 below and [Before you start](../README.md#before-you-start) in the AWS README.

A bucket with one small page costs very little. See [Amazon S3 pricing](https://aws.amazon.com/s3/pricing/).

| Placeholder | What it is | Example |
|---|---|---|
| `<bucket-name>` | A new bucket name. Bucket names are unique across all of AWS, so include something of your own | `my-gh-site-01` |

## Step by step

### 0. Set your prefix

Set the same prefix as in your resource names, in the CloudShell session you use for the steps below. `export` makes the prefix visible also to scripts you run with `bash`, not only to commands you type. Do it again if CloudShell has closed the session. See also [Before you start](../README.md#before-you-start) in the AWS README.

```
export PREFIX=demo
```

### 1. Create the bucket

1. Open CloudShell, choose **Actions** and **Upload file**, and upload [create-site-bucket.sh](create-site-bucket.sh). If you have not uploaded files to CloudShell before, see [Before you start](../README.md#before-you-start) in the AWS README. It creates the bucket, allows a public bucket policy, adds a policy that gives everyone read access to the files and turns on static website hosting with `index.html` as start page. Last, it prints the web address.
2. Change `BUCKET` at the top to `<bucket-name>`, with `nano`. Save with **Ctrl+O**, confirm with Enter and exit with **Ctrl+X**:

   ```
   nano create-site-bucket.sh
   ```

3. Run the script:

   ```
   bash create-site-bucket.sh
   ```

   The last line is the web address, `http://<bucket-name>.s3-website.<region>.amazonaws.com`. Open it: you get an error that `index.html` is missing, and that is right, since the bucket is empty. The address also shows in the console under the bucket's **Properties**, at the bottom under **Static website hosting**.

### 2. Give the role the right to publish

1. Upload [allow-role-to-publish.sh](allow-role-to-publish.sh) to CloudShell in the same way.
2. Change `BUCKET` at the top to exactly the same name as in the previous script. If the names differ, the role gets the right to the wrong bucket, and the publishing is denied.

   ```
   nano allow-role-to-publish.sh
   ```

3. Run the script. It writes the policy to a file and puts it on the role with `aws iam put-role-policy`. Last, it lists the role's inline policies, where `<prefix>-github-site` should be:

   ```
   bash allow-role-to-publish.sh
   ```

   Check in the console too: IAM, **Roles**, `<prefix>-github` and the tab **Permissions**. The policy only contains `s3:PutObject` on your bucket.

### 3. Variable and workflow

1. In the repository on GitHub, choose **Settings**, under **Security and quality** **Secrets and variables**, and **Actions**, then the tab **Variables** and **New repository variable**. The name is `SITE_BUCKET` and the value is the bucket's name, only the name, without `s3://` and without slashes. See [Secrets and variables](../../basics/secrets-and-variables/) for how variables work.
2. Save [publish.yml](publish.yml) as `.github/workflows/publish.yml`. The steps are checkout, sign-in with the role, `aws s3 cp` of `index.html`, and a line that writes the web address on the run's page. If `index.html` is not in the repository yet, add it too. Then push:

   ```
   git add .github index.html && git commit -m "Add publish workflow" && git push
   ```

   The workflow may not start from this push, if `index.html` did not change. That is right.
3. Open the tab **Actions**, choose **Publish** and click **Run workflow** on `main`. When the run is green, the web address is at the top of the run's page. Click it: now it shows your page with **Version 1**.

### 4. Change the page and see it update

1. Open `index.html` and change **Version 1** to **Version 2**.
2. Commit and push. It is an ordinary commit: nothing in the commands has to do with AWS.

   ```
   git commit -am "Update site to version 2" && git push
   ```

3. Go to the tab **Actions**. **Publish** has started by itself, since `index.html` changed on `main`.
4. When **Publish** is green, reload the web page. Now it says **Version 2**. If the old version still shows, the browser may have saved the page: reload with **Ctrl+F5**.

## Check the result

- The web address shows the latest version of `index.html`.
- **Publish** starts by itself when `index.html` changes on `main`, but not for other files.

## Clean up

Remove the bucket with its files, the role's policy for the site, and the variable:

```
aws s3 rb s3://<bucket-name> --force
```

```
aws iam delete-role-policy --role-name ${PREFIX}-github --policy-name ${PREFIX}-github-site
```

In GitHub, remove the variable `SITE_BUCKET` and the workflow file `publish.yml`.

## Use it in your own repository

- **Is the page in a folder, for example `site`?** Change `paths` to `site/**` and the command to copy from that folder. The permission only covers the bucket, not which files you send.
- **Several files, for example images and a style sheet?** `aws s3 sync` is more convenient than `cp`. Then the role also needs `s3:ListBucket` on the bucket itself, without `/*`, since `sync` first compares what is already there.

## Common errors

| Symptom | Cause |
|---|---|
| `AccessDenied` in the step **Upload index.html** | Almost always the name: the bucket name in the policy, in the variable `SITE_BUCKET` and of the bucket must be exactly the same. Compare character by character. |
| `AccessDenied` on `put-bucket-policy` | Block Public Access is on for the whole account. It is changed in S3, **Block Public Access settings for this account**, in the menu on the left. |
| `BucketAlreadyExists` | The name is taken, in some account. Choose another. |
| **Publish** does not start after a push | The change was not in `index.html` at the root of the repository. The **Run workflow** button always works. |
| Nothing is published from another branch | The workflow only starts for `main`, and the role only accepts sign-ins from `main`. That is two protections on purpose. |
| The browser downloads the page instead of showing it | The file got the wrong type. That is why the workflow gives `--content-type "text/html; charset=utf-8"`. |
| `NoSuchEntity` when running `allow-role-to-publish.sh` | The role does not exist. Do [Sign in to AWS without keys](../sign-in-without-keys/) first. |

## Files

| File | What it is |
|---|---|
| `create-site-bucket.sh` | Creates a public bucket with static website hosting and prints the web address. |
| `allow-role-to-publish.sh` | Gives the role `<prefix>-github` the right to upload files to the bucket, nothing else. |
| `publish.yml` | Uploads `index.html` to the bucket when it changes on `main`, or with **Run workflow**. |
| `index.html` | A simple example page with a version line. |
