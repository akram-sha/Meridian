#!/usr/bin/env bash
# Creates the forecast-cache DynamoDB table against a running LocalStack container
# and enables native TTL on the `ttl` attribute. Run after:
#   docker compose -f docker/docker-compose.localstack.yml up -d
set -euo pipefail

ENDPOINT="http://localhost:4566"
TABLE_NAME="meridian-forecast-cache"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

echo "Waiting for LocalStack DynamoDB..."
until aws --endpoint-url="$ENDPOINT" dynamodb list-tables >/dev/null 2>&1; do
  sleep 1
done

if aws --endpoint-url="$ENDPOINT" dynamodb describe-table --table-name "$TABLE_NAME" >/dev/null 2>&1; then
  echo "Table $TABLE_NAME already exists."
else
  aws --endpoint-url="$ENDPOINT" dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=pk,AttributeType=S \
    --key-schema AttributeName=pk,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

  aws --endpoint-url="$ENDPOINT" dynamodb update-time-to-live \
    --table-name "$TABLE_NAME" \
    --time-to-live-specification "Enabled=true,AttributeName=ttl"

  echo "Created $TABLE_NAME with TTL enabled on 'ttl'."
fi
