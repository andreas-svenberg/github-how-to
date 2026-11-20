# Scheduled check of AWS resources

## What it is

A workflow does not have to start on a push or a button: GitHub can start it at a set time, without anyone doing anything. You build a Friday check: every Friday at 15.00 Swedish time, GitHub lists what is running in your AWS account (servers, databases, load balancers and stacks) and shows it as a table on the run's page. The role only gets read access.

## Why and when to use it

- **The most expensive thing in an AWS account is often what has been forgotten.** An EC2 instance, an RDS database or a load balancer costs money for every hour it exists, whether anyone uses it or not. A stack created for a test can contain several of them.
- **What is left after a test on a Friday afternoon runs all weekend.** That kind of cost is easy to avoid, if you only know about it.
- **With a scheduled workflow, GitHub checks for you,** every week at the same time, even if you are nowhere near the repository.
- **The role only gets the right to list and read.** The check cannot stop, change or delete anything. If it finds something, you decide what should happen.
- **The result ends up as a table at the top of the run's page,** with one row per thing that runs. It is called a job summary: ordinary markdown that the workflow writes to a special file.

## How it works

- **Under `on: schedule`, you write a cron expression,** the same format as scheduled jobs on Linux. It has five fields: minute, hour, day of the month, month and weekday. A star means any. `0 15 * * 5` means minute 0, hour 15, all days of the month, all months, weekday 5. Weekday 5 is Friday, Sunday is 0.
- **Without the line `timezone`, GitHub reads the time as UTC.** With `timezone: 'Europe/Stockholm'`, it is always 15.00 Swedish time, also when the clocks change. The `timezone` field has existed since March 2026.
- **`workflow_dispatch`** adds the **Run workflow** button, so that you can try the check directly instead of waiting until Friday.
- **Scheduled workflows always run from the default branch, `main`,** which fits the trust policy from [Sign in to AWS without keys](../sign-in-without-keys/).
- **They can be delayed when many runs start at the same time,** and the shortest interval is every five minutes. In public repositories, they are turned off after 60 days without activity in the repository.
- **The table is written to the file that the environment variable `GITHUB_STEP_SUMMARY` points to.** Everything that ends up there is shown as formatted markdown on the run's page.

See [Events that trigger workflows](https://docs.github.com/actions/using-workflows/events-that-trigger-workflows).

## Prerequisites

- The role `<prefix>-github` and the variable `AWS_ROLE_ARN` from [Sign in to AWS without keys](../sign-in-without-keys/).
- `PREFIX` set in CloudShell, see step 0 below and [Before you start](../README.md#before-you-start) in the AWS README.

The check only reads: it creates and changes nothing, and so costs nothing in AWS.

## Step by step

### 0. Set your prefix

Set the same prefix as in your resource names, in the CloudShell session you use for the steps below. `export` makes the prefix visible also to scripts you run with `bash`, not only to commands you type. Do it again if CloudShell has closed the session. See also [Before you start](../README.md#before-you-start) in the AWS README.

```
export PREFIX=demo
```

### 1. Give the role read access

1. Open CloudShell, choose **Actions** and **Upload file**, and upload [allow-role-to-read.sh](allow-role-to-read.sh). If you have not uploaded files to CloudShell before, see [Before you start](../README.md#before-you-start) in the AWS README. Read it with `cat`. The policy `<prefix>-github-read` contains four actions, all starting with `Describe` or `List`, and none of them can change anything:
   - `ec2:DescribeInstances` lists servers.
   - `rds:DescribeDBInstances` lists databases.
   - `elasticloadbalancing:DescribeLoadBalancers` lists load balancers.
   - `cloudformation:ListStacks` lists stacks.

   Read actions like these cannot be limited to single resources, so `Resource` is `*`.
2. Run the script. It lists the role's inline policies, where `<prefix>-github-read` should now be:

   ```
   bash allow-role-to-read.sh
   ```

### 2. The workflow and a first test

1. Save [friday-check.yml](friday-check.yml) as `.github/workflows/friday-check.yml`. Look at `on: schedule` with `cron` and `timezone`, and `workflow_dispatch`. The job only has two steps, sign-in and listing, and needs no checkout since it uses no files from the repository. Push it to `main`:

   ```
   git add .github && git commit -m "Add Friday check" && git push
   ```

   Nothing starts at the push.
2. Open the tab **Actions** and choose **Friday check**. Click **Run workflow** and then the green button.
3. Open the run when it is green. At the top of the page, under the heading **Running in** and your region, is the table with the columns **Type**, **Name or id** and **Status**. If the table only has the heading row, nothing of what the check looks for is running. That is the best result a Friday check can give.

### 3. The check finds something

To see that the check works, there must be something to find. The button from [Deploy a stack with a button](../deploy-a-stack-with-a-button/) is one way:

1. Run **Demo stack** with `create`, and wait until the run is green.
2. Run **Friday check** again with **Run workflow**. You do not need to wait until Friday: the button starts exactly the same job as the schedule.
3. Now the table has a row: **Stack**, the stack's name and `CREATE_COMPLETE`. A running server or database would also be there, with its id and status.
4. Run **Demo stack** with `delete`, and then **Friday check** once more. The row is gone.

From now on, GitHub starts the check by itself every Friday at 15.00, and the runs are collected under **Friday check**. All you need to do is look there before the weekend.

## Check the result

- **Friday check** shows that it has a schedule, at the top of its page in the Actions tab.
- The run's page has the table, with a row for each thing that runs.

## Clean up

To stop the check, choose **Friday check** in the tab **Actions**, the three dots and **Disable workflow**. If you only tried it, also remove the role's read policy:

```
aws iam delete-role-policy --role-name ${PREFIX}-github --policy-name ${PREFIX}-github-read
```

To remove the role and the identity provider entirely, see Clean up in [Sign in to AWS without keys](../sign-in-without-keys/).

## Use it in your own repository

- **`friday-check.yml` works without changes.** It contains nothing account-specific, apart from the region: it uses the variable `AWS_ROLE_ARN`.
- **Another time?** Change the `cron` line, for example `0 8 * * 1` for Mondays at 08.00. Keep the line `timezone`, otherwise the time counts in UTC.
- **More rows in the table,** for example EBS volumes that are not attached to any server, or Elastic IP addresses that are not used. Both cost money without showing on any server. For each new kind of row, the role needs a new read action in the policy, for example `ec2:DescribeVolumes` for volumes. Add it to the script and run it again: `put-role-policy` replaces the old version.

## Common errors

| Symptom | Cause |
|---|---|
| The check does not run on Friday | The workflow file is not on `main`, the workflow is disabled, or the repository has had no activity for 60 days. |
| The check runs one or two hours late | The line `timezone` is missing, so the time counts in UTC. 15.00 UTC is 16.00 Swedish winter time and 17.00 summer time. |
| `AccessDenied` on a `Describe` or `List` action | The role lacks the policy from step 1, or a row was added without its read action. |

## Files

| File | What it is |
|---|---|
| `allow-role-to-read.sh` | Gives the role `<prefix>-github` read access to servers, databases, load balancers and stacks. |
| `friday-check.yml` | The workflow: every Friday at 15.00, or with **Run workflow**, writes a table of what is running. |
