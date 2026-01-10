#!/bin/bash

# Load environment variables from .env file
export $(cat .env | grep -v '^#' | xargs)

# Change to dbt project directory
cd dbt_youtube

# Run the dbt command passed as argument
dbt "$@"