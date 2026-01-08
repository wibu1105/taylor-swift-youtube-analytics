{{ config(materialized='view' ,
    tags=['silver']) }}

-- Một video có thể nằm trong nhiều playlist → ta vẫn giữ granular theo (playlist_id, video_id)
select
  pi."PLAYLIST_ITEM_ID"
  , pi.playlist_id
  , pi.channel_id
  , pi.video_id
  , s.video_title
  , s."VIDEO_DESCRIPTION"
  , s."VIDEO_PUBLISHED_AT"
  , s."VIEW_COUNT"
  , s."LIKE_COUNT"
  , s."COMMENT_COUNT"
  , s."DURATION_SECONDS"
  , DATEDIFF('day', s."VIDEO_PUBLISHED_AT", current_timestamp()) as "VIDEO_AGE_DAYS" 
  , CASE 
        WHEN s."LIVE_SCHEDULED_START" is not null THEN 'Live'
        WHEN s."DURATION_SECONDS" < 60 THEN 'Shorts'
        WHEN s."DURATION_SECONDS" is null THEN 'Private videos'
        ELSE 'Normal videos'
    END AS "VIDEO_TYPE"
  , CASE
      WHEN "DURATION_SECONDS" <   60 THEN '0-1m'
      WHEN "DURATION_SECONDS" <  300 THEN '1-5m'
      WHEN "DURATION_SECONDS" <  900 THEN '5-15m'
      WHEN "DURATION_SECONDS" < 1800 THEN '15-30m'
      WHEN "DURATION_SECONDS" < 3600 THEN '30-60m'
      ELSE '60m+'
    END AS "DURATION_BUCKET"
  , pi."ADDED_TO_PLAYLIST_AT" AS "VIDEO_ADDED_TO_PLAYLIST_AT"
  , pi."POSITION_IN_PLAYLIST" AS "VIDEO_POSITION_IN_PLAYLIST"
  , pi."VIDEO_THUMBNAIL_URL_IN_PLAYLIST" AS "VIDEO_THUMBNAIL_URL"
from {{ ref('br_playlist_items') }} pi
left join {{ ref('br_video_stats') }} s
  on pi.video_id = s.video_id