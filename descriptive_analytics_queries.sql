-- =====================================================
-- DESCRIPTIVE ANALYTICS QUERIES - SỬ DỤNG LỚP GOLD
-- =====================================================
-- Các câu SQL để phân tích mô tả dữ liệu YouTube Analytics
-- Sử dụng các bảng Gold đã được pre-aggregated

-- =====================================================
-- 1. TỔNG QUAN KÊNH (CHANNEL OVERVIEW)
-- =====================================================

-- 1.1. KPI tổng quan của kênh Taylor Swift
SELECT 
    channel_title,
    subscriber_count,
    channel_view_count,
    channel_video_count,
    ROUND(avg_video_length_sec/60, 2) as avg_video_length_minutes,
    ROUND(avg_like_per_view * 100, 2) as avg_like_rate_percent,
    ROUND(avg_comment_per_view * 100, 2) as avg_comment_rate_percent
FROM g_channel_overview;

-- 1.2. Tính toán engagement metrics tổng thể
SELECT 
    channel_title,
    subscriber_count,
    channel_view_count,
    ROUND(channel_view_count::FLOAT / subscriber_count, 2) as views_per_subscriber,
    ROUND(avg_like_per_view * 100, 2) as engagement_rate_percent,
    CASE 
        WHEN avg_like_per_view > 0.04 THEN 'Excellent'
        WHEN avg_like_per_view > 0.02 THEN 'Good' 
        WHEN avg_like_per_view > 0.01 THEN 'Average'
        ELSE 'Below Average'
    END as engagement_level
FROM g_channel_overview;

-- =====================================================
-- 2. PHÂN TÍCH HIỆU SUẤT VIDEO (VIDEO PERFORMANCE)
-- =====================================================

-- 2.1. Top 10 video có lượt xem cao nhất
SELECT 
    rn_by_views as rank_by_views,
    video_title,
    view_count,
    like_count,
    comment_count,
    ROUND(like_per_view * 100, 2) as like_rate_percent,
    ROUND(comment_per_view * 100, 2) as comment_rate_percent,
    published_date,
    ROUND(duration_seconds/60, 2) as duration_minutes
FROM g_video_rankings 
WHERE rn_by_views <= 10
ORDER BY rn_by_views;

-- 2.2. Top 10 video có tỷ lệ engagement cao nhất
SELECT 
    rn_by_like_rate as rank_by_engagement,
    video_title,
    view_count,
    like_count,
    ROUND(like_per_view * 100, 2) as like_rate_percent,
    published_date,
    CASE 
        WHEN duration_seconds < 60 THEN 'Shorts'
        WHEN duration_seconds < 300 THEN 'Short-form'
        WHEN duration_seconds < 900 THEN 'Medium-form'
        ELSE 'Long-form'
    END as content_length_category
FROM g_video_rankings 
WHERE rn_by_like_rate <= 10
ORDER BY rn_by_like_rate;

-- 2.3. Video mới nhất và hiệu suất của chúng
SELECT 
    rn_newest as recency_rank,
    video_title,
    published_date,
    view_count,
    ROUND(like_per_view * 100, 2) as like_rate_percent,
    ROUND(comment_per_view * 100, 2) as comment_rate_percent,
    DATEDIFF('day', published_date, CURRENT_DATE()) as days_since_published
FROM g_video_rankings 
WHERE rn_newest <= 15
ORDER BY rn_newest;

-- =====================================================
-- 3. PHÂN TÍCH LOẠI NỘI DUNG (CONTENT MIX ANALYSIS)
-- =====================================================

-- 3.1. Phân tích cơ cấu nội dung và hiệu suất
SELECT 
    video_type,
    videos_count,
    ROUND(videos_count * 100.0 / SUM(videos_count) OVER(), 2) as percentage_of_total,
    total_views,
    ROUND(total_views::FLOAT / videos_count, 0) as avg_views_per_video,
    ROUND(avg_like_per_view * 100, 2) as avg_like_rate_percent,
    ROUND(avg_comment_per_view * 100, 2) as avg_comment_rate_percent
FROM g_content_mix
ORDER BY videos_count DESC;

-- 3.2. So sánh hiệu suất giữa các loại nội dung
SELECT 
    video_type,
    videos_count,
    ROUND(total_views::FLOAT / videos_count, 0) as avg_views_per_video,
    ROUND(avg_like_per_view * 100, 2) as avg_like_rate_percent,
    CASE 
        WHEN avg_like_per_view = (SELECT MAX(avg_like_per_view) FROM g_content_mix) THEN 'Best Performing'
        WHEN avg_like_per_view >= (SELECT AVG(avg_like_per_view) FROM g_content_mix) THEN 'Above Average'
        ELSE 'Below Average'
    END as performance_category
FROM g_content_mix
ORDER BY avg_like_per_view DESC;

-- =====================================================
-- 4. PHÂN TÍCH THỜI GIAN ĐĂNG TẢI (UPLOAD TIMING)
-- =====================================================

-- 4.1. Heatmap thời gian đăng tải theo ngày trong tuần
SELECT 
    CASE published_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_of_week,
    SUM(videos_count) as total_videos,
    ROUND(SUM(videos_count) * 100.0 / (SELECT SUM(videos_count) FROM g_upload_heatmap), 2) as percentage
FROM g_upload_heatmap
GROUP BY published_dow
ORDER BY published_dow;

-- 4.2. Thời gian đăng tải tối ưu trong ngày
SELECT 
    published_hour,
    SUM(videos_count) as total_videos,
    ROUND(SUM(videos_count) * 100.0 / (SELECT SUM(videos_count) FROM g_upload_heatmap), 2) as percentage,
    CASE 
        WHEN published_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN published_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN published_hour BETWEEN 18 AND 22 THEN 'Evening'
        ELSE 'Night/Early Morning'
    END as time_period
FROM g_upload_heatmap
GROUP BY published_hour
ORDER BY total_videos DESC;

-- 4.3. Pattern đăng tải theo ngày và giờ (Top combinations)
SELECT 
    CASE published_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_of_week,
    published_hour,
    videos_count,
    ROUND(videos_count * 100.0 / (SELECT SUM(videos_count) FROM g_upload_heatmap), 2) as percentage_of_total
FROM g_upload_heatmap
WHERE videos_count > 0
ORDER BY videos_count DESC
LIMIT 10;

-- =====================================================
-- 5. PHÂN TÍCH ĐỘ DÀI VIDEO (DURATION ANALYSIS)
-- =====================================================

-- 5.1. Phân phối độ dài video
SELECT 
    duration_bucket,
    videos_count,
    ROUND(videos_count * 100.0 / SUM(videos_count) OVER(), 2) as percentage_of_total,
    ROUND(avg_duration_sec/60, 2) as avg_duration_minutes,
    CASE 
        WHEN duration_bucket = '0-1m' THEN 'Shorts/Clips'
        WHEN duration_bucket IN ('1-5m', '5-15m') THEN 'Standard Length'
        WHEN duration_bucket IN ('15-30m', '30-60m') THEN 'Long Form'
        ELSE 'Extended Content'
    END as content_category
FROM g_duration_distribution
ORDER BY 
    CASE duration_bucket
        WHEN '0-1m' THEN 1
        WHEN '1-5m' THEN 2
        WHEN '5-15m' THEN 3
        WHEN '15-30m' THEN 4
        WHEN '30-60m' THEN 5
        ELSE 6
    END;

-- 5.2. Chiến lược độ dài nội dung
SELECT 
    CASE 
        WHEN duration_bucket = '0-1m' THEN 'Shorts Strategy'
        WHEN duration_bucket IN ('1-5m', '5-15m') THEN 'Standard Strategy'
        WHEN duration_bucket IN ('15-30m', '30-60m') THEN 'Long-form Strategy'
        ELSE 'Extended Strategy'
    END as content_strategy,
    SUM(videos_count) as total_videos,
    ROUND(SUM(videos_count) * 100.0 / (SELECT SUM(videos_count) FROM g_duration_distribution), 2) as strategy_percentage,
    ROUND(AVG(avg_duration_sec)/60, 2) as avg_duration_minutes
FROM g_duration_distribution
GROUP BY 1
ORDER BY total_videos DESC;

-- =====================================================
-- 6. PHÂN TÍCH PLAYLIST (PLAYLIST PERFORMANCE)
-- =====================================================

-- 6.1. Top 10 playlist hiệu suất cao nhất
SELECT 
    playlist_title,
    items_detected as video_count,
    top_video_title,
    top_video_views,
    ROUND(top_video_views::FLOAT / NULLIF(items_detected, 0), 0) as avg_views_estimate
FROM g_playlist_performance
WHERE top_video_views IS NOT NULL
ORDER BY top_video_views DESC
LIMIT 10;

-- 6.2. Phân tích kích thước playlist
SELECT 
    CASE 
        WHEN items_detected <= 5 THEN 'Small (1-5 videos)'
        WHEN items_detected <= 15 THEN 'Medium (6-15 videos)'
        WHEN items_detected <= 30 THEN 'Large (16-30 videos)'
        ELSE 'Extra Large (30+ videos)'
    END as playlist_size_category,
    COUNT(*) as playlist_count,
    ROUND(AVG(items_detected), 1) as avg_videos_per_playlist,
    ROUND(AVG(top_video_views), 0) as avg_top_video_views
FROM g_playlist_performance
WHERE items_detected > 0
GROUP BY 1
ORDER BY playlist_count DESC;

-- 6.3. Playlist với performance tốt nhất theo tỷ lệ
SELECT 
    playlist_title,
    items_detected,
    top_video_views,
    CASE 
        WHEN items_detected <= 10 THEN 'Focused Collection'
        WHEN items_detected <= 20 THEN 'Standard Album'
        ELSE 'Comprehensive Collection'
    END as playlist_type,
    ROUND(top_video_views::FLOAT / GREATEST(items_detected, 1), 0) as performance_per_video
FROM g_playlist_performance
WHERE items_detected > 0 AND top_video_views IS NOT NULL
ORDER BY performance_per_video DESC
LIMIT 15;

-- =====================================================
-- 7. PHÂN TÍCH TỔNG HỢP (CROSS-DIMENSIONAL ANALYSIS)
-- =====================================================

-- 7.1. Tổng hợp insights chính
WITH channel_stats AS (
    SELECT 
        subscriber_count,
        channel_view_count,
        channel_video_count,
        ROUND(avg_like_per_view * 100, 2) as avg_engagement_rate
    FROM g_channel_overview
),
content_insights AS (
    SELECT 
        COUNT(*) as total_content_types,
        MAX(CASE WHEN video_type = 'Normal videos' THEN videos_count END) as normal_videos,
        MAX(CASE WHEN video_type = 'Shorts' THEN videos_count END) as shorts_count
    FROM g_content_mix
),
timing_insights AS (
    SELECT 
        COUNT(DISTINCT published_dow) as active_days_per_week,
        MAX(videos_count) as peak_upload_count
    FROM g_upload_heatmap
)
SELECT 
    'Channel Performance Summary' as metric_category,
    cs.subscriber_count,
    cs.channel_view_count,
    cs.avg_engagement_rate,
    ci.normal_videos,
    ci.shorts_count,
    ti.active_days_per_week,
    ti.peak_upload_count
FROM channel_stats cs
CROSS JOIN content_insights ci  
CROSS JOIN timing_insights ti;

-- 7.2. Performance benchmarking
SELECT 
    'Performance Benchmarks' as analysis_type,
    (SELECT ROUND(AVG(like_per_view) * 100, 2) FROM g_video_rankings) as avg_like_rate_all_videos,
    (SELECT ROUND(AVG(like_per_view) * 100, 2) FROM g_video_rankings WHERE rn_by_views <= 10) as avg_like_rate_top10,
    (SELECT COUNT(*) FROM g_video_rankings WHERE like_per_view > 0.05) as videos_above_5percent_engagement,
    (SELECT COUNT(*) FROM g_duration_distribution) as total_duration_categories,
    (SELECT MAX(videos_count) FROM g_duration_distribution) as most_common_duration_count;

-- =====================================================
-- 8. INSIGHTS VÀ RECOMMENDATIONS
-- =====================================================

-- 8.1. Content strategy recommendations
SELECT 
    'Content Strategy Insights' as insight_category,
    (SELECT video_type FROM g_content_mix ORDER BY avg_like_per_view DESC LIMIT 1) as best_performing_content_type,
    (SELECT duration_bucket FROM g_duration_distribution ORDER BY videos_count DESC LIMIT 1) as most_used_duration,
    (SELECT CASE published_dow WHEN 0 THEN 'Sunday' WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday' 
                WHEN 3 THEN 'Wednesday' WHEN 4 THEN 'Thursday' WHEN 5 THEN 'Friday' WHEN 6 THEN 'Saturday' END 
     FROM g_upload_heatmap GROUP BY published_dow ORDER BY SUM(videos_count) DESC LIMIT 1) as most_active_day;

-- 8.2. Performance gaps analysis  
SELECT 
    'Performance Analysis' as analysis_type,
    (SELECT COUNT(*) FROM g_video_rankings WHERE like_per_view < 0.02) as videos_below_avg_engagement,
    (SELECT COUNT(*) FROM g_video_rankings WHERE view_count < 1000000) as videos_below_1m_views,
    (SELECT COUNT(*) FROM g_playlist_performance WHERE items_detected < 5) as small_playlists_count,
    (SELECT ROUND(AVG(videos_count), 0) FROM g_upload_heatmap WHERE videos_count > 0) as avg_videos_per_active_timeslot;