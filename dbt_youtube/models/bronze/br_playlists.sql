{{ config(materialized='view' ,
    tags=['bronze']) }}


select
    playlist_id 
    , title as playlist_title
    , description as playlist_desc 
    , published_at::timestamp AS "PUBLISHED_AT"
    , channel_id 
    , thumbnail_high AS "PLAYLIST_THUMBNAIL_URL"
    , item_count::bigint AS "ITEM_COUNT"
from {{ ref('playlists') }}