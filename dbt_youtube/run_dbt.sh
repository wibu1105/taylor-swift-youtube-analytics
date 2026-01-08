#!/bin/bash

# Load environment variables from .env file
set -a
source ../.env
set +a

# Run dbt commands
echo "Running dbt deps..."
dbt deps --profiles-dir .

echo "Running dbt seed..."
dbt seed --profiles-dir .

echo "Running dbt run..."
dbt run --profiles-dir .

echo "Running dbt test..."
dbt test --profiles-dir .

echo "Running dbt snapshot..."
dbt snapshot --profiles-dir .

echo "All dbt commands completed!"