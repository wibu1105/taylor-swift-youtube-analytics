#!/bin/bash
# Script to fix duplicate seed data by running full refresh

echo "Running dbt seed with full refresh to clear duplicate data..."

# Run seed with full refresh
docker exec -it dbt-youtube-dag_7c31f9-api-server-1 /usr/local/airflow/venv/bin/dbt seed --full-refresh --project-dir /usr/local/airflow/dags/dbt/dbt_youtube --profiles-dir /tmp/cosmos/profile/539f31e9eddf1677d0496e6d35e537f2bd9bf5c6b1459de46db20ee575daadfb --profile default --target dev

echo "Seed refresh completed!"