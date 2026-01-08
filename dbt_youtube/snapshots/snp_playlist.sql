{% snapshot snp_playlist %}
{{
  config(
    target_schema='YOUTUBE_SNAP',
    unique_key='PLAYLIST_ID',
    strategy='check',
    check_cols=[
      'PLAYLIST_TITLE',
      'PLAYLIST_DESC',
      'PUBLISHED_AT',
      'CHANNEL_ID',
      'ITEM_COUNT',
      'PLAYLIST_THUMBNAIL_URL'
    ]
  )
}}
select
  playlist_id,
  playlist_title,
  playlist_desc,
  "PUBLISHED_AT",
  channel_id,
  "ITEM_COUNT",
  "PLAYLIST_THUMBNAIL_URL"
from {{ ref('stg_playlists') }}
{% endsnapshot %}
