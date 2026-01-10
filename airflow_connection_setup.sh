#!/bin/bash
# Script to set up Snowflake connection for Airflow

# Set Airflow connection via environment variable
export AIRFLOW_CONN_SNOWFLAKE_CONN='snowflake://TROLL1105:SimplePass123!@RBHTSPE-VX50080.snowflakecomputing.com/YOUTUBE_ANALYTICS_DB/ANALYTICS_DEV?warehouse=YOUTUBE_ANALYTICS_WH&role=ACCOUNTADMIN'

echo "Snowflake connection configured for Airflow"
echo "Connection ID: snowflake_conn"
echo "Account: RBHTSPE-VX50080"
echo "Database: YOUTUBE_ANALYTICS_DB"
echo "Schema: ANALYTICS_DEV"