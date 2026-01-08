"""
YouTube Analytics DAG

This DAG orchestrates the YouTube data extraction and dbt transformation pipeline.
It extracts data from Taylor Swift's YouTube channel and processes it through dbt models.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeSqlApiOperator
from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping
import os

# Default arguments for the DAG
default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# DAG definition
dag = DAG(
    'youtube_analytics_pipeline',
    default_args=default_args,
    description='YouTube Analytics Data Pipeline with dbt',
    schedule_interval='@daily',
    catchup=False,
    tags=['youtube', 'analytics', 'dbt', 'snowflake'],
)

def extract_youtube_data():
    """
    Extract YouTube data using the notebook logic
    """
    import sys
    import subprocess
    
    # Run the data extraction notebook
    result = subprocess.run([
        'jupyter', 'nbconvert', 
        '--to', 'notebook', 
        '--execute', 
        '--output', '/tmp/executed_notebook.ipynb',
        '/usr/local/airflow/youtube-data-extraction/extract-data.ipynb'
    ], capture_output=True, text=True)
    
    if result.returncode != 0:
        raise Exception(f"Notebook execution failed: {result.stderr}")
    
    print("YouTube data extraction completed successfully")

# Task 1: Extract YouTube data
extract_data_task = PythonOperator(
    task_id='extract_youtube_data',
    python_callable=extract_youtube_data,
    dag=dag,
)

# Task 2: Test Snowflake connection
test_connection = SnowflakeSqlApiOperator(
    task_id='test_snowflake_connection',
    sql="SELECT CURRENT_TIMESTAMP() as test_time;",
    snowflake_conn_id='snowflake_default',
    dag=dag,
)

# dbt configuration
profile_config = ProfileConfig(
    profile_name="dbt_youtube",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id="snowflake_default",
        profile_args={
            "database": "YOUTUBE_ANALYTICS_DB",
            "schema": "ANALYTICS_DEV",
        },
    ),
)

# dbt DAG configuration
dbt_youtube_dag = DbtDag(
    project_config=ProjectConfig(
        dbt_project_path="/usr/local/airflow/dbt_youtube/",
    ),
    profile_config=profile_config,
    execution_config=ExecutionConfig(
        dbt_executable_path="dbt",
    ),
    schedule_interval=None,  # Triggered by main DAG
    start_date=datetime(2024, 1, 1),
    catchup=False,
    dag_id="dbt_youtube_models",
    tags=["dbt", "youtube", "transformation"],
)

# Task dependencies
extract_data_task >> test_connection