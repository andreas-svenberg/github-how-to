#!/usr/bin/env bash
# allow-role-to-manage-stacks.sh
# Let the GitHub role create and delete stacks named <prefix>-gh-*,
# and the VPC resources the demo template needs.
# Run in CloudShell: bash allow-role-to-manage-stacks.sh
set -euo pipefail

if [ -z "${PREFIX:-}" ]; then
  echo "Set PREFIX first, for example export PREFIX=demo"
  exit 1
fi

# --- Settings (change them if yours are different) -----------------------
ROLE="${PREFIX}-github"          # the role from aws/sign-in-without-keys
POLICY="${PREFIX}-github-stack"  # the name of the inline policy
REGION="eu-north-1"              # the region of the stacks
STACKS="${PREFIX}-gh-*"          # the role may only touch stacks with these names

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

cat > github-stack-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyOurStacks",
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ExecuteChangeSet",
        "cloudformation:DeleteChangeSet",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:GetTemplateSummary",
        "cloudformation:DeleteStack"
      ],
      "Resource": "arn:aws:cloudformation:${REGION}:${ACCOUNT}:stack/${STACKS}/*"
    },
    {
      "Sid": "VpcForTheDemoTemplate",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:DescribeVpcAttribute",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    }
  ]
}
JSON

aws iam put-role-policy --role-name "$ROLE" \
  --policy-name "$POLICY" \
  --policy-document file://github-stack-policy.json

aws iam list-role-policies --role-name "$ROLE"
