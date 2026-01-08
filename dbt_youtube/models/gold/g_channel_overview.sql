{{ config(materialized='table' ,
    tags=['gold']) }}

with ch as (
  select
    channel_id
    , title as "CHANNEL_TITLE"
    , custom_url as "CHANNEL_CUSTOM_URL"
    , "PUBLISHED_AT" as "CHANNEL_PUBLISHED_AT"
    , country
    , "SUBSCRIBER_COUNT"
    , "VIEW_COUNT" AS "CHANNEL_VIEW_COUNT"
    , "VIDEO_COUNT" AS "CHANNEL_VIDEO_COUNT"
    , "CHANNEL_THUMBNAIL_URL" 
  from {{ ref('stg_channels') }}
),
v as (
  -- 1 dòng/video để tính Avg Length, Avg Rate
  select
    video_id
    ,any_value("DURATION_SECONDS") as "DURATION_SECONDS"
    ,any_value("VIEW_COUNT")       as "VIEW_COUNT"
    ,any_value("LIKE_COUNT")       as "LIKE_COUNT"
    ,any_value("COMMENT_COUNT")    as "COMMENT_COUNT"
  from {{ ref('stg_videos') }}
  group by video_id
)
select
  ch.*,
  avg(v."DURATION_SECONDS")                             as avg_video_length_sec,
  avg(v."LIKE_COUNT" / nullif(v."VIEW_COUNT", 0))         as avg_like_per_view,
  avg(v."COMMENT_COUNT" / nullif(v."VIEW_COUNT", 0))      as avg_comment_per_view
from ch
left join v on 1=1 -- cross join để lấy avg trên toàn bộ video
group by
  ch.channel_id, ch."CHANNEL_TITLE", ch."CHANNEL_CUSTOM_URL", ch."CHANNEL_PUBLISHED_AT", ch.country,
  ch."SUBSCRIBER_COUNT", ch."CHANNEL_VIEW_COUNT", ch."CHANNEL_VIDEO_COUNT", ch."CHANNEL_THUMBNAIL_URL"