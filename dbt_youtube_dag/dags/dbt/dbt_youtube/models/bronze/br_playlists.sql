{{ config(materialized='view' ,
    tags=['bronze']) }}


select
    playlist_id 
    , title 
    , description 
    , published_at::timestamp AS "PUBLISHED_AT"
    , channel_id 
    , thumbnail_high AS "PLAYLIST_THUMBNAIL_URL"
    , item_count::bigint AS "ITEM_COUNT"
from {{ ref('playlists') }}