#!/usr/bin/env bash
# create-site-bucket.sh
# Create a public S3 bucket that serves a web page.
# Run in CloudShell: bash create-site-bucket.sh
# Change BUCKET to a globally unique name before you run it.
set -euo pipefail

# --- Settings (change them before you run the script) --------------------
BUCKET="<bucket-name>"   # globally unique, the same name in allow-role-to-publish.sh
REGION="eu-north-1"      # the region of the bucket

if [[ "$BUCKET" == *"<"* ]]; then
  echo "Change BUCKET at the top of the script to a unique name."
  exit 1
fi

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Allow a public bucket policy (objects stay private until the policy below)
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Anyone may read the files, nobody may write
cat > site-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET}/*"
    }
  ]
}
JSON
aws s3api put-bucket-policy --bucket "$BUCKET" --policy file://site-policy.json

# Serve index.html as a web site
aws s3 website "s3://$BUCKET" --index-document index.html

echo "Web address: http://${BUCKET}.s3-website.${REGION}.amazonaws.com"
