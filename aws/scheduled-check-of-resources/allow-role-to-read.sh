#!/usr/bin/env bash
# allow-role-to-read.sh
# Let the GitHub role read what is running. Read only, nothing else.
# Run in CloudShell: bash allow-role-to-read.sh
set -euo pipefail

if [ -z "${PREFIX:-}" ]; then
  echo "Set PREFIX first, for example export PREFIX=demo"
  exit 1
fi

# --- Settings (change them if yours are different) -----------------------
ROLE="${PREFIX}-github"         # the role from aws/sign-in-without-keys
POLICY="${PREFIX}-github-read"  # the name of the inline policy

cat > github-read-policy.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "rds:DescribeDBInstances",
        "elasticloadbalancing:DescribeLoadBalancers",
        "cloudformation:ListStacks"
      ],
      "Resource": "*"
    }
  ]
}
JSON

aws iam put-role-policy --role-name "$ROLE" \
  --policy-name "$POLICY" \
  --policy-document file://github-read-policy.json

aws iam list-role-policies --role-name "$ROLE"
