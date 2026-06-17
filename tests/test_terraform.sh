#!/bin/bash

echo "Initializing Terraform..."

terraform init -backend=false

if [ $? -ne 0 ]; then
  echo "Terraform init failed"
  exit 1
fi

echo "Running Terraform validation..."

terraform validate
if [ $? -ne 0 ]; then
  echo "Terraform validation failed"
  exit 1
fi

echo "Running Checkov..."

checkov -d . --framework terraform --quiet
if [ $? -ne 0 ]; then
  echo "Checkov security checks failed"
  exit 1
fi

echo "All tests passed"
