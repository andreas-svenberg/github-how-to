#!/usr/bin/env bash
# allow-role-to-publish.sh
# Let the GitHub role upload files to the site bucket, nothing else.
# Run in CloudShell: bash allow-role-to-publish.sh
set -euo pipefail

if [ -z "${PREFIX:-}" ]; then
  echo "Set PREFIX first, for example export PREFIX=demo"
  exit 1
fi

# --- Settings (change them before you run the script) --------------------
BUCKET="<bucket-name>"          # the same name as in create-site-bucket.sh
ROLE="${PREFIX}-github"         # the role from aws/sign-in-without-keys
POLICY="${PREFIX}-github-site"  # the name of the inline policy

if [[ "$BUCKET" == *"<"* ]]; then
  echo "Change BUCKET at the top of the script to the name of your bucket."
  exit 1
fi

cat > github-site-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${BUCKET}/*"
    }
  ]
}
JSON

aws iam put-role-policy --role-name "$ROLE" \
  --policy-name "$POLICY" \
  --policy-document file://github-site-policy.json

aws iam list-role-policies --role-name "$ROLE"
