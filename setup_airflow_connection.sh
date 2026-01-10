#!/bin/bash
# Script to create Snowflake connection in Airflow running in Docker

echo "Setting up Snowflake connection in Airflow..."

# Method 1: Using environment variable
export AIRFLOW_CONN_SNOWFLAKE_CONN='snowflake://TROLL1105:SimplePass123!@RBHTSPE-VX50080.snowflakecomputing.com/YOUTUBE_ANALYTICS_DB/ANALYTICS_DEV?warehouse=YOUTUBE_ANALYTICS_WH&role=ACCOUNTADMIN'

# Method 2: Using Airflow CLI (run this inside the Airflow container)
# docker exec -it <airflow-container-name> airflow connections add 'snowflake_conn' \
#   --conn-type 'snowflake' \
#   --conn-host 'RBHTSPE-VX50080.snowflakecomputing.com' \
#   --conn-login 'TROLL1105' \
#   --conn-password 'SimplePass123!' \
#   --conn-schema 'ANALYTICS_DEV' \
#   --conn-extra '{"account": "RBHTSPE-VX50080", "warehouse": "YOUTUBE_ANALYTICS_WH", "database": "YOUTUBE_ANALYTICS_DB", "role": "ACCOUNTADMIN"}'

echo "Connection setup complete!"
echo "Connection ID: snowflake_conn"
echo "You can verify in Airflow UI: Admin → Connections"