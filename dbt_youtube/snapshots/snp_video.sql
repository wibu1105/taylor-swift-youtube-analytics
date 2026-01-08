{% snapshot snp_video %}
{{
  config(
    target_schema='YOUTUBE_SNAP',
    unique_key='VIDEO_ID',
    strategy='check',
    check_cols=[
      'VIDEO_TITLE',
      'VIDEO_DESC',
      'VIDEO_PUBLISHED_AT',
      'VIEW_COUNT',
      'LIKE_COUNT',
      'COMMENT_COUNT',
      'DURATION_SECONDS'
    ]
  )
}}
select
  video_id,
  video_title,
  "VIDEO_DESCRIPTION",
  "VIDEO_PUBLISHED_AT",
  "VIEW_COUNT",
  "LIKE_COUNT",
  "COMMENT_COUNT",
  "DURATION_SECONDS"
from {{ ref('stg_videos') }}
{% endsnapshot %}
