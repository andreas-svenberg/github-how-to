#!/usr/bin/env bash
# allow-role-to-validate.sh
# Let the GitHub role validate CloudFormation templates. Validation creates nothing.
# Run in CloudShell: bash allow-role-to-validate.sh
set -euo pipefail

if [ -z "${PREFIX:-}" ]; then
  echo "Set PREFIX first, for example export PREFIX=demo"
  exit 1
fi

# --- Settings (change them if yours are different) -----------------------
ROLE="${PREFIX}-github"             # the role from aws/sign-in-without-keys
POLICY="${PREFIX}-github-validate"  # the name of the inline policy

cat > github-validate-policy.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "cloudformation:ValidateTemplate",
      "Resource": "*"
    }
  ]
}
JSON

aws iam put-role-policy --role-name "$ROLE" \
  --policy-name "$POLICY" \
  --policy-document file://github-validate-policy.json

aws iam list-role-policies --role-name "$ROLE"
