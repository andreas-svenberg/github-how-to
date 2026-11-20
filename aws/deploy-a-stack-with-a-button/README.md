# Deploy a stack with a button

## What it is

GitHub Actions can create a CloudFormation stack in AWS, and delete it, with a button in the Actions tab. You write a workflow with a choice, create or delete, and give the GitHub role the right to handle stacks whose names start with `<prefix>-gh-`, plus what the template needs for a VPC. Then you create the stack from GitHub, look at it in the console and delete it again.

## Why and when to use it

- **When you run `aws cloudformation deploy` yourself,** it is easy to use a file that is not pushed, an old copy in CloudShell, or other parameters than last time. Afterwards, nobody knows exactly what was created.
- **When GitHub runs deploy, it always uses the template on `main`,** with the parameters in the workflow. What shows in the repository is what exists in AWS.
- **The Run workflow button can have a choice:** create or delete. A workflow can have input fields of its own, shown when you click the button.
- **Each run shows in the Actions tab** with who clicked, when, which choice was made and the whole output from CloudFormation. A log you get for free.
- **The role may not handle any stacks, only those whose names start with `<prefix>-gh-`.** GitHub can neither change nor delete other stacks in the account.

## How it works

- **Under `on: workflow_dispatch` there are `inputs`.** The workflow [stack.yml](stack.yml) has one field, `action`, with the type `choice` and two options, `create` and `delete`. When you click **Run workflow**, a list with the two choices is shown.
- **The steps read the choice as `${{ inputs.action }}`,** on the line `if` in each step. The step with `if: inputs.action == 'create'` only runs when you chose create, and the other step only when you chose delete. The step that does not apply shows as skipped in the log.
- **The create step runs `aws cloudformation deploy`** with the template, the stack name and the parameter `Prefix`. Afterwards it prints the stack's outputs, the VPC's id.
- **`--no-fail-on-empty-changeset`** makes a run without changes green. By default, deploy ends with an error when there is nothing to change, and the run would turn red. See [aws cloudformation deploy](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy.html).
- **The delete step runs `aws cloudformation delete-stack` and then `wait stack-delete-complete`,** so that the run turns green only when the stack is really gone.
- **The role needs new permissions, as a third inline policy, `<prefix>-github-stack`,** in two parts:
  - CloudFormation: create, run and delete change sets, which deploy uses, read the stack's status and events, and delete the stack. Only for stacks in your region and account whose names start with `<prefix>-gh-`.
  - What the template creates, a VPC with tags. When CloudFormation creates the VPC, it does it with the permissions of whoever started the stack, that is the role. Creating a VPC cannot be limited to a certain stack, so `Resource` is `*`. The actions are only the seven that a VPC with tags needs.

## Prerequisites

- The role `<prefix>-github` and the variable `AWS_ROLE_ARN` from [Sign in to AWS without keys](../sign-in-without-keys/).
- A template that cfn-lint accepts, in `templates/demo-vpc.yaml`, see [cfn-lint in Actions](../cfn-lint-in-actions/). If you have none, use [demo-vpc.yaml](demo-vpc.yaml).
- `PREFIX` set in CloudShell, see step 0 below and [Before you start](../README.md#before-you-start) in the AWS README.

The stack only contains an empty VPC, which costs nothing, and you delete it at the end.

## Step by step

### 0. Set your prefix

Set the same prefix as in your resource names, in the CloudShell session you use for the steps below. `export` makes the prefix visible also to scripts you run with `bash`, not only to commands you type. Do it again if CloudShell has closed the session. See also [Before you start](../README.md#before-you-start) in the AWS README.

```
export PREFIX=demo
```

### 1. Give the role the right to handle the stacks

1. Open CloudShell, choose **Actions** and **Upload file**, and upload [allow-role-to-manage-stacks.sh](allow-role-to-manage-stacks.sh). If you have not uploaded files to CloudShell before, see [Before you start](../README.md#before-you-start) in the AWS README. Read it with `cat`: the policy is longer than the earlier ones. The account number is fetched by the script, and the stack names come from `PREFIX`.
2. Run the script. It puts the policy `<prefix>-github-stack` on the role with `put-role-policy`, and lists the role's inline policies:

   ```
   bash allow-role-to-manage-stacks.sh
   ```

### 2. Create the stack from GitHub

1. Create the repository variable `PREFIX`: choose **Settings**, under **Security and quality** **Secrets and variables**, and **Actions**, then the tab **Variables** and **New repository variable**. The name is `PREFIX` and the value is the same prefix as in CloudShell, for example `demo`. The workflow builds the stack name from it, `<prefix>-gh-demo`, which matches the role's policy. See [Secrets and variables](../../basics/secrets-and-variables/) for how variables work.
2. Save [stack.yml](stack.yml) as `.github/workflows/stack.yml`. Its first step stops the run with a clear error if the variable `PREFIX` is missing. Then push to `main`:

   ```
   git add .github templates && git commit -m "Add stack workflow" && git push
   ```

   Nothing starts at the push, since the workflow only has `workflow_dispatch`.
3. Open the tab **Actions** and choose **Demo stack**. Click **Run workflow**.
4. In the box that opens, under the choice of branch, there is a list with the text **What should be done with the stack?**. It is set to `create`, the default. Click the green **Run workflow**.
5. Open the run and the job `stack`, and expand the step **Create or update the stack**. Deploy says that it waits for the change set to be created and then for the stack. After a minute or two it says `Successfully created/updated stack - <prefix>-gh-demo`, and last a table with the output `VpcId`.

### 3. Check and delete

1. Open CloudFormation in the console, **Stacks** in the menu on the left. There is `<prefix>-gh-demo`, for example `demo-gh-demo`, with the status `CREATE_COMPLETE`.
2. Click on the stack and choose the tab **Resources**. There is `DemoVpc`. Click its id to come to the VPC console, where the VPC is called `<prefix>-gh-vpc` and has the tag `Project` `github-how-to`. The tab **Events** shows each step CloudFormation took when the stack was created.
3. Back in GitHub: **Actions**, **Demo stack** and **Run workflow**. This time, choose `delete` in the list and click **Run workflow**.
4. When the run is green, the wait command has finished. Reload CloudFormation in the console: the stack is gone from the list, and the VPC is gone from the VPC console.

## Check the result

- After `create`, the stack is `CREATE_COMPLETE` and the run shows `VpcId`.
- After `delete`, the stack and the VPC are gone.
- If you run `create` twice in a row without changing the template, deploy says `No changes to deploy` and the run is still green, thanks to `--no-fail-on-empty-changeset`. If you change the template on `main` and run `create` again, the stack is updated instead. The same button does the right thing whatever the state.

## Clean up

Delete the stack with `delete` as in step 3, if you have not already. If you only tried it, remove the role's policy for stacks:

```
aws iam delete-role-policy --role-name ${PREFIX}-github --policy-name ${PREFIX}-github-stack
```

In GitHub, remove the variable `PREFIX` and the workflow file `stack.yml`.

## Use it in your own repository

- **Your own template?** Change the path after `--template-file` in the workflow.
- **Start with something small,** a VPC or a bucket. A large template with servers, a database and a load balancer needs many more permissions and takes a long time to create and delete.
- **The policy only covers VPC and tags.** If your template creates something else, add those actions. The CloudFormation events under **Events** show exactly which action was denied.
- **Keep the prefix `<prefix>-gh-` in the stack name,** for example `<prefix>-gh-test`, and the policy applies without changes. Then GitHub also cannot touch the stacks you create by hand.
- **If your template has parameters,** give them after `--parameter-overrides`, as `Prefix` here. Values that differ between accounts can be repository variables, just like `AWS_ROLE_ARN`.

## Common errors

| Symptom | Cause |
|---|---|
| `AccessDenied` on a `cloudformation` action | Most often the stack name: the role may only touch stacks starting with `<prefix>-gh-`. If you change the name in the workflow, the policy must follow. |
| The stack rolls back, and **Events** says an `ec2` action was denied | The template needs something the policy does not allow. If you add a subnet, the role needs `ec2:CreateSubnet`, for example. The policy and the template belong together. |
| `ROLLBACK_COMPLETE` | A stack in that state cannot be updated. Run `delete` first, and then `create` again when the error is fixed. |
| The sign-in is denied | Another branch than `main` was chosen in the box. The trust policy only allows `main`. |
| `Create the repository variable PREFIX first` | The variable `PREFIX` is missing or misspelled. Create it as in step 2. |

## Files

| File | What it is |
|---|---|
| `allow-role-to-manage-stacks.sh` | Gives the role the right to handle stacks named `<prefix>-gh-*`, and to create a VPC with tags. |
| `stack.yml` | The workflow with the choice create or delete. |
| `demo-vpc.yaml` | The same minimal template as in [cfn-lint in Actions](../cfn-lint-in-actions/). |
