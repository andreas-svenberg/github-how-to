#!/usr/bin/env bash
# remove-github-role.sh
# Remove the role for GitHub Actions, with all its inline policies,
# and the identity provider for GitHub.
# Run in CloudShell when you no longer need it: bash remove-github-role.sh
set -euo pipefail

if [ -z "${PREFIX:-}" ]; then
  echo "Set PREFIX first, for example export PREFIX=demo"
  exit 1
fi

# --- Settings ------------------------------------------------------------
ROLE="${PREFIX}-github"   # the role to remove

# All inline policies on the role, then the role itself
for p in $(aws iam list-role-policies --role-name "$ROLE" --query PolicyNames --output text); do
  aws iam delete-role-policy --role-name "$ROLE" --policy-name "$p"
  echo "Removed the policy $p"
done
aws iam delete-role --role-name "$ROLE"
echo "Removed the role $ROLE"

# The identity provider for GitHub. Comment out these lines if
# another role in the account still uses it.
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws iam delete-open-id-connect-provider \
  --open-id-connect-provider-arn "arn:aws:iam::${ACCOUNT}:oidc-provider/token.actions.githubusercontent.com"
echo "Removed the identity provider for GitHub"
