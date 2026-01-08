{{ config(materialized='view' ,
    tags=['bronze']) }}

select
  channel_id,
  title,
  custom_url,
  published_at::timestamp as "PUBLISHED_AT",
  country,
  subscriber_count::bigint as "SUBSCRIBER_COUNT",
  view_count::bigint as "VIEW_COUNT",
  video_count::bigint as "VIDEO_COUNT" , 
  thumbnail_high AS "CHANNEL_THUMBNAIL_URL"
from {{ ref('channels') }}
