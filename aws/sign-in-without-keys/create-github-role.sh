#!/usr/bin/env bash
# create-github-role.sh
# Create the role that GitHub Actions may assume with OIDC.
# Run in CloudShell: bash create-github-role.sh
# Change SUB to the subject of your own repository before you run it.
set -euo pipefail

if [ -z "${PREFIX:-}" ]; then
  echo "Set PREFIX first, for example export PREFIX=demo"
  exit 1
fi

# --- Settings (change them before you run the script) --------------------
# The subject GitHub sends for your repository and branch, from show-subject.yml
SUB="repo:<owner>@<owner-id>/<repository>@<repository-id>:ref:refs/heads/main"
ROLE="${PREFIX}-github"   # the name of the role

if [[ "$SUB" == *"<"* ]]; then
  echo "Change SUB at the top of the script to the subject of your repository."
  exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# Trust policy: only GitHub's OIDC provider, only this audience, only this exact subject
cat > trust-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "${SUB}"
        }
      }
    }
  ]
}
JSON

aws iam create-role --role-name "$ROLE" \
  --assume-role-policy-document file://trust-policy.json \
  --query Role.Arn --output text
