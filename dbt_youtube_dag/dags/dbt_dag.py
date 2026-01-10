import os
from datetime import datetime
from airflow import DAG

# Constants - keep these lightweight
DBT_PROJECT_PATH = "/usr/local/airflow/dags/dbt/dbt_youtube"
SNOWFLAKE_CONN_ID = "snowflake_conn"
SNOWFLAKE_DATABASE = "YOUTUBE_ANALYTICS_DB"
SNOWFLAKE_SCHEMA = "ANALYTICS_DEV"

# DAG default arguments
DEFAULT_ARGS = {
    "owner": "airflow",
    "retries": 1,
}

# Define the DAG
with DAG(
    dag_id="dbt_youtube_pipeline",
    default_args=DEFAULT_ARGS,
    description="DBT pipeline for YouTube data processing with medallion architecture",
    start_date=datetime(2025, 9, 20),
    schedule="@daily",
    catchup=False,
    tags=["dbt", "youtube", "medallion"],
) as dag:
    
    def create_dbt_tasks():
        """Create DBT tasks - imported here to avoid timeout during DAG parsing."""
        from cosmos import DbtTaskGroup, ProjectConfig, ExecutionConfig, ProfileConfig, RenderConfig
        from cosmos.profiles import SnowflakeUserPasswordProfileMapping
        
        # Get DBT executable path at runtime
        dbt_executable_path = f"{os.environ.get('AIRFLOW_HOME', '/usr/local/airflow')}/venv/bin/dbt"
        
        # Shared configurations
        def get_project_config():
            return ProjectConfig(DBT_PROJECT_PATH)

        def get_execution_config():
            return ExecutionConfig(dbt_executable_path=dbt_executable_path)

        def get_profile_config():
            return ProfileConfig(
                profile_name="default",
                target_name="dev",
                profile_mapping=SnowflakeUserPasswordProfileMapping(
                    conn_id=SNOWFLAKE_CONN_ID,
                    profile_args={
                        "database": SNOWFLAKE_DATABASE,
                        "schema": SNOWFLAKE_SCHEMA
                    }
                )
            )

        def create_dbt_task_group(group_id, select_criteria):
            return DbtTaskGroup(
                group_id=group_id,
                project_config=get_project_config(),
                profile_config=get_profile_config(),
                execution_config=get_execution_config(),
                render_config=RenderConfig(select=[select_criteria]),
            )
        
        # Create task groups
        seeds_layer = create_dbt_task_group("seeds", "path:seeds")
        bronze_layer = create_dbt_task_group("bronze", "tag:bronze")
        silver_layer = create_dbt_task_group("silver", "tag:silver")
        gold_layer = create_dbt_task_group("gold", "tag:gold")
        
        # Define pipeline flow
        seeds_layer >> bronze_layer >> silver_layer >> gold_layer
        
        return seeds_layer, bronze_layer, silver_layer, gold_layer
    
    # Create tasks
    create_dbt_tasks()