#!/usr/bin/env python3
"""
Test script to verify .env file configuration and connections
"""

import os
from dotenv import load_dotenv
import snowflake.connector
from googleapiclient.discovery import build

def test_env_loading():
    """Test if .env file loads correctly"""
    print("🔍 Testing .env file loading...")
    
    # Load .env file
    load_dotenv()
    
    # Check YouTube API Key
    youtube_key = os.getenv("YOUTUBE_API_KEY")
    print(f"✅ YouTube API Key: {'✓ Loaded' if youtube_key else '❌ Missing'}")
    
    # Check Snowflake credentials
    sf_account = os.getenv("SNOWFLAKE_ACCOUNT")
    sf_user = os.getenv("SNOWFLAKE_USER")
    sf_password = os.getenv("SNOWFLAKE_PASSWORD")
    sf_warehouse = os.getenv("SNOWFLAKE_WAREHOUSE")
    sf_database = os.getenv("SNOWFLAKE_DATABASE")
    sf_schema = os.getenv("SNOWFLAKE_SCHEMA")
    
    print(f"✅ Snowflake Account: {'✓ Loaded' if sf_account else '❌ Missing'}")
    print(f"✅ Snowflake User: {'✓ Loaded' if sf_user else '❌ Missing'}")
    print(f"✅ Snowflake Password: {'✓ Loaded' if sf_password else '❌ Missing'}")
    print(f"✅ Snowflake Warehouse: {'✓ Loaded' if sf_warehouse else '❌ Missing'}")
    print(f"✅ Snowflake Database: {'✓ Loaded' if sf_database else '❌ Missing'}")
    print(f"✅ Snowflake Schema: {'✓ Loaded' if sf_schema else '❌ Missing'}")
    
    return all([youtube_key, sf_account, sf_user, sf_password, sf_warehouse, sf_database, sf_schema])

def test_youtube_api():
    """Test YouTube API connection"""
    print("\n🔍 Testing YouTube API connection...")
    
    try:
        youtube_key = os.getenv("YOUTUBE_API_KEY")
        if not youtube_key:
            print("❌ YouTube API Key not found")
            return False
            
        # Build YouTube service
        youtube = build('youtube', 'v3', developerKey=youtube_key)
        
        # Test with a simple request
        request = youtube.channels().list(
            part='snippet,statistics',
            forHandle='@TaylorSwift'
        )
        response = request.execute()
        
        if response.get('items'):
            channel = response['items'][0]
            print(f"✅ YouTube API connection successful!")
            print(f"   Channel: {channel['snippet']['title']}")
            print(f"   Subscribers: {channel['statistics']['subscriberCount']}")
            return True
        else:
            print("❌ No channel data returned")
            return False
            
    except Exception as e:
        print(f"❌ YouTube API connection failed: {str(e)}")
        return False

def test_snowflake_connection():
    """Test Snowflake connection"""
    print("\n🔍 Testing Snowflake connection...")
    
    try:
        # Get credentials from environment
        conn_params = {
            'account': os.getenv("SNOWFLAKE_ACCOUNT"),
            'user': os.getenv("SNOWFLAKE_USER"),
            'password': os.getenv("SNOWFLAKE_PASSWORD"),
            'warehouse': os.getenv("SNOWFLAKE_WAREHOUSE"),
            'database': os.getenv("SNOWFLAKE_DATABASE"),
            'schema': os.getenv("SNOWFLAKE_SCHEMA"),
        }
        
        # Test connection
        conn = snowflake.connector.connect(**conn_params)
        cursor = conn.cursor()
        
        # Test query
        cursor.execute("SELECT CURRENT_VERSION()")
        result = cursor.fetchone()
        
        print(f"✅ Snowflake connection successful!")
        print(f"   Version: {result[0]}")
        print(f"   Warehouse: {conn_params['warehouse']}")
        print(f"   Database: {conn_params['database']}")
        print(f"   Schema: {conn_params['schema']}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Snowflake connection failed: {str(e)}")
        return False

def main():
    """Main test function"""
    print("🚀 Testing Taylor Swift YouTube Analytics Environment Configuration\n")
    
    # Test .env loading
    env_ok = test_env_loading()
    
    if not env_ok:
        print("\n❌ Environment variables not properly loaded. Please check your .env file.")
        return
    
    # Test connections
    youtube_ok = test_youtube_api()
    snowflake_ok = test_snowflake_connection()
    
    # Summary
    print("\n" + "="*60)
    print("📊 CONNECTION TEST SUMMARY")
    print("="*60)
    print(f"Environment Variables: {'✅ PASS' if env_ok else '❌ FAIL'}")
    print(f"YouTube API:          {'✅ PASS' if youtube_ok else '❌ FAIL'}")
    print(f"Snowflake Database:   {'✅ PASS' if snowflake_ok else '❌ FAIL'}")
    
    if all([env_ok, youtube_ok, snowflake_ok]):
        print("\n🎉 All connections successful! Your environment is ready.")
    else:
        print("\n⚠️  Some connections failed. Please check your .env configuration.")

if __name__ == "__main__":
    main()