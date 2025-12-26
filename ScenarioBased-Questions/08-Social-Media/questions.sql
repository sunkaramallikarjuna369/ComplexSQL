-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: SOCIAL MEDIA (Q141-Q160)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q141: IDENTIFY TRENDING HASHTAGS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Window Functions, Time-Based Analysis
-- 
-- BUSINESS SCENARIO:
-- Identify hashtags gaining momentum in the last 24 hours compared to
-- their 7-day average for trending content curation.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH hashtag_daily AS (
    SELECT 
        h.hashtag_id,
        h.hashtag_name,
        CAST(p.created_at AS DATE) AS post_date,
        COUNT(DISTINCT p.post_id) AS daily_posts
    FROM hashtags h
    INNER JOIN post_hashtags ph ON h.hashtag_id = ph.hashtag_id
    INNER JOIN posts p ON ph.post_id = p.post_id
    WHERE p.created_at >= DATEADD(DAY, -7, GETDATE())
    GROUP BY h.hashtag_id, h.hashtag_name, CAST(p.created_at AS DATE)
),
hashtag_stats AS (
    SELECT 
        hashtag_id,
        hashtag_name,
        SUM(CASE WHEN post_date = CAST(GETDATE() AS DATE) THEN daily_posts ELSE 0 END) AS today_posts,
        AVG(CAST(daily_posts AS FLOAT)) AS avg_daily_posts
    FROM hashtag_daily
    GROUP BY hashtag_id, hashtag_name
)
SELECT 
    hashtag_name,
    today_posts,
    ROUND(avg_daily_posts, 2) AS avg_daily_posts,
    ROUND(100.0 * (today_posts - avg_daily_posts) / NULLIF(avg_daily_posts, 0), 2) AS growth_pct,
    CASE 
        WHEN today_posts > avg_daily_posts * 2 THEN 'Viral'
        WHEN today_posts > avg_daily_posts * 1.5 THEN 'Trending'
        WHEN today_posts > avg_daily_posts THEN 'Rising'
        ELSE 'Normal'
    END AS trend_status
FROM hashtag_stats
WHERE today_posts > 0
ORDER BY growth_pct DESC;

-- ==================== ORACLE SOLUTION ====================
WITH hashtag_daily AS (
    SELECT 
        h.hashtag_id,
        h.hashtag_name,
        TRUNC(p.created_at) AS post_date,
        COUNT(DISTINCT p.post_id) AS daily_posts
    FROM hashtags h
    INNER JOIN post_hashtags ph ON h.hashtag_id = ph.hashtag_id
    INNER JOIN posts p ON ph.post_id = p.post_id
    WHERE p.created_at >= SYSDATE - 7
    GROUP BY h.hashtag_id, h.hashtag_name, TRUNC(p.created_at)
),
hashtag_stats AS (
    SELECT 
        hashtag_id,
        hashtag_name,
        SUM(CASE WHEN post_date = TRUNC(SYSDATE) THEN daily_posts ELSE 0 END) AS today_posts,
        AVG(daily_posts) AS avg_daily_posts
    FROM hashtag_daily
    GROUP BY hashtag_id, hashtag_name
)
SELECT 
    hashtag_name,
    today_posts,
    ROUND(avg_daily_posts, 2) AS avg_daily_posts,
    ROUND(100.0 * (today_posts - avg_daily_posts) / NULLIF(avg_daily_posts, 0), 2) AS growth_pct,
    CASE 
        WHEN today_posts > avg_daily_posts * 2 THEN 'Viral'
        WHEN today_posts > avg_daily_posts * 1.5 THEN 'Trending'
        WHEN today_posts > avg_daily_posts THEN 'Rising'
        ELSE 'Normal'
    END AS trend_status
FROM hashtag_stats
WHERE today_posts > 0
ORDER BY growth_pct DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH hashtag_daily AS (
    SELECT 
        h.hashtag_id,
        h.hashtag_name,
        p.created_at::DATE AS post_date,
        COUNT(DISTINCT p.post_id) AS daily_posts
    FROM hashtags h
    INNER JOIN post_hashtags ph ON h.hashtag_id = ph.hashtag_id
    INNER JOIN posts p ON ph.post_id = p.post_id
    WHERE p.created_at >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY h.hashtag_id, h.hashtag_name, p.created_at::DATE
),
hashtag_stats AS (
    SELECT 
        hashtag_id,
        hashtag_name,
        SUM(CASE WHEN post_date = CURRENT_DATE THEN daily_posts ELSE 0 END) AS today_posts,
        AVG(daily_posts) AS avg_daily_posts
    FROM hashtag_daily
    GROUP BY hashtag_id, hashtag_name
)
SELECT 
    hashtag_name,
    today_posts,
    ROUND(avg_daily_posts::NUMERIC, 2) AS avg_daily_posts,
    ROUND((100.0 * (today_posts - avg_daily_posts) / NULLIF(avg_daily_posts, 0))::NUMERIC, 2) AS growth_pct,
    CASE 
        WHEN today_posts > avg_daily_posts * 2 THEN 'Viral'
        WHEN today_posts > avg_daily_posts * 1.5 THEN 'Trending'
        WHEN today_posts > avg_daily_posts THEN 'Rising'
        ELSE 'Normal'
    END AS trend_status
FROM hashtag_stats
WHERE today_posts > 0
ORDER BY growth_pct DESC;

-- ==================== MYSQL SOLUTION ====================
WITH hashtag_daily AS (
    SELECT 
        h.hashtag_id,
        h.hashtag_name,
        DATE(p.created_at) AS post_date,
        COUNT(DISTINCT p.post_id) AS daily_posts
    FROM hashtags h
    INNER JOIN post_hashtags ph ON h.hashtag_id = ph.hashtag_id
    INNER JOIN posts p ON ph.post_id = p.post_id
    WHERE p.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY h.hashtag_id, h.hashtag_name, DATE(p.created_at)
),
hashtag_stats AS (
    SELECT 
        hashtag_id,
        hashtag_name,
        SUM(CASE WHEN post_date = CURDATE() THEN daily_posts ELSE 0 END) AS today_posts,
        AVG(daily_posts) AS avg_daily_posts
    FROM hashtag_daily
    GROUP BY hashtag_id, hashtag_name
)
SELECT 
    hashtag_name,
    today_posts,
    ROUND(avg_daily_posts, 2) AS avg_daily_posts,
    ROUND(100.0 * (today_posts - avg_daily_posts) / NULLIF(avg_daily_posts, 0), 2) AS growth_pct,
    CASE 
        WHEN today_posts > avg_daily_posts * 2 THEN 'Viral'
        WHEN today_posts > avg_daily_posts * 1.5 THEN 'Trending'
        WHEN today_posts > avg_daily_posts THEN 'Rising'
        ELSE 'Normal'
    END AS trend_status
FROM hashtag_stats
WHERE today_posts > 0
ORDER BY growth_pct DESC;

-- EXPLANATION:
-- Compares today's usage to 7-day average.
-- Growth percentage identifies trending content.


-- ============================================================================
-- Q142: CALCULATE USER ENGAGEMENT RATE
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Ratio Calculation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    COUNT(DISTINCT p.post_id) AS total_posts,
    SUM(p.like_count) AS total_likes,
    SUM(p.comment_count) AS total_comments,
    SUM(p.share_count) AS total_shares,
    ROUND(100.0 * (SUM(p.like_count) + SUM(p.comment_count) + SUM(p.share_count)) / 
          NULLIF(u.follower_count * COUNT(DISTINCT p.post_id), 0), 4) AS engagement_rate
FROM users u
INNER JOIN posts p ON u.user_id = p.user_id
WHERE p.created_at >= DATEADD(DAY, -30, GETDATE())
AND u.follower_count > 0
GROUP BY u.user_id, u.username, u.follower_count
HAVING COUNT(DISTINCT p.post_id) >= 5
ORDER BY engagement_rate DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    COUNT(DISTINCT p.post_id) AS total_posts,
    SUM(p.like_count) AS total_likes,
    SUM(p.comment_count) AS total_comments,
    SUM(p.share_count) AS total_shares,
    ROUND(100.0 * (SUM(p.like_count) + SUM(p.comment_count) + SUM(p.share_count)) / 
          NULLIF(u.follower_count * COUNT(DISTINCT p.post_id), 0), 4) AS engagement_rate
FROM users u
INNER JOIN posts p ON u.user_id = p.user_id
WHERE p.created_at >= SYSDATE - 30
AND u.follower_count > 0
GROUP BY u.user_id, u.username, u.follower_count
HAVING COUNT(DISTINCT p.post_id) >= 5
ORDER BY engagement_rate DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    COUNT(DISTINCT p.post_id) AS total_posts,
    SUM(p.like_count) AS total_likes,
    SUM(p.comment_count) AS total_comments,
    SUM(p.share_count) AS total_shares,
    ROUND((100.0 * (SUM(p.like_count) + SUM(p.comment_count) + SUM(p.share_count)) / 
          NULLIF(u.follower_count * COUNT(DISTINCT p.post_id), 0))::NUMERIC, 4) AS engagement_rate
FROM users u
INNER JOIN posts p ON u.user_id = p.user_id
WHERE p.created_at >= CURRENT_DATE - INTERVAL '30 days'
AND u.follower_count > 0
GROUP BY u.user_id, u.username, u.follower_count
HAVING COUNT(DISTINCT p.post_id) >= 5
ORDER BY engagement_rate DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    COUNT(DISTINCT p.post_id) AS total_posts,
    SUM(p.like_count) AS total_likes,
    SUM(p.comment_count) AS total_comments,
    SUM(p.share_count) AS total_shares,
    ROUND(100.0 * (SUM(p.like_count) + SUM(p.comment_count) + SUM(p.share_count)) / 
          NULLIF(u.follower_count * COUNT(DISTINCT p.post_id), 0), 4) AS engagement_rate
FROM users u
INNER JOIN posts p ON u.user_id = p.user_id
WHERE p.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
AND u.follower_count > 0
GROUP BY u.user_id, u.username, u.follower_count
HAVING COUNT(DISTINCT p.post_id) >= 5
ORDER BY engagement_rate DESC;

-- EXPLANATION:
-- Engagement Rate = (Likes + Comments + Shares) / (Followers * Posts) * 100
-- Key metric for influencer marketing.


-- ============================================================================
-- Q143: DETECT POTENTIAL BOT ACCOUNTS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Pattern Detection, Statistical Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH user_patterns AS (
    SELECT 
        u.user_id,
        u.username,
        u.created_at AS account_created,
        u.follower_count,
        u.following_count,
        COUNT(DISTINCT p.post_id) AS post_count,
        COUNT(DISTINCT CAST(p.created_at AS DATE)) AS active_days,
        DATEDIFF(DAY, u.created_at, GETDATE()) AS account_age_days,
        AVG(DATEDIFF(MINUTE, LAG(p.created_at) OVER (PARTITION BY u.user_id ORDER BY p.created_at), p.created_at)) AS avg_minutes_between_posts
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.username, u.created_at, u.follower_count, u.following_count
)
SELECT 
    user_id,
    username,
    account_age_days,
    post_count,
    follower_count,
    following_count,
    ROUND(CAST(following_count AS FLOAT) / NULLIF(follower_count, 0), 2) AS following_ratio,
    ROUND(CAST(post_count AS FLOAT) / NULLIF(account_age_days, 0), 2) AS posts_per_day,
    CASE 
        WHEN following_count > follower_count * 10 THEN 1 ELSE 0 
    END + CASE 
        WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 
    END + CASE 
        WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 
    END AS bot_score,
    CASE 
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) >= 2 THEN 'High Risk'
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) = 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS bot_likelihood
FROM user_patterns
WHERE post_count > 0
ORDER BY bot_score DESC, posts_per_day DESC;

-- ==================== ORACLE SOLUTION ====================
WITH user_patterns AS (
    SELECT 
        u.user_id,
        u.username,
        u.created_at AS account_created,
        u.follower_count,
        u.following_count,
        COUNT(DISTINCT p.post_id) AS post_count,
        COUNT(DISTINCT TRUNC(p.created_at)) AS active_days,
        TRUNC(SYSDATE - u.created_at) AS account_age_days,
        AVG((p.created_at - LAG(p.created_at) OVER (PARTITION BY u.user_id ORDER BY p.created_at)) * 24 * 60) AS avg_minutes_between_posts
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.username, u.created_at, u.follower_count, u.following_count
)
SELECT 
    user_id,
    username,
    account_age_days,
    post_count,
    follower_count,
    following_count,
    ROUND(following_count / NULLIF(follower_count, 0), 2) AS following_ratio,
    ROUND(post_count / NULLIF(account_age_days, 0), 2) AS posts_per_day,
    CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
    CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
    CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END AS bot_score,
    CASE 
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) >= 2 THEN 'High Risk'
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) = 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS bot_likelihood
FROM user_patterns
WHERE post_count > 0
ORDER BY bot_score DESC, posts_per_day DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH user_patterns AS (
    SELECT 
        u.user_id,
        u.username,
        u.created_at AS account_created,
        u.follower_count,
        u.following_count,
        COUNT(DISTINCT p.post_id) AS post_count,
        COUNT(DISTINCT p.created_at::DATE) AS active_days,
        (CURRENT_DATE - u.created_at::DATE) AS account_age_days,
        AVG(EXTRACT(EPOCH FROM (p.created_at - LAG(p.created_at) OVER (PARTITION BY u.user_id ORDER BY p.created_at))) / 60) AS avg_minutes_between_posts
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.username, u.created_at, u.follower_count, u.following_count
)
SELECT 
    user_id,
    username,
    account_age_days,
    post_count,
    follower_count,
    following_count,
    ROUND((following_count::FLOAT / NULLIF(follower_count, 0))::NUMERIC, 2) AS following_ratio,
    ROUND((post_count::FLOAT / NULLIF(account_age_days, 0))::NUMERIC, 2) AS posts_per_day,
    CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
    CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
    CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END AS bot_score,
    CASE 
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) >= 2 THEN 'High Risk'
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) = 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS bot_likelihood
FROM user_patterns
WHERE post_count > 0
ORDER BY bot_score DESC, posts_per_day DESC;

-- ==================== MYSQL SOLUTION ====================
WITH user_patterns AS (
    SELECT 
        u.user_id,
        u.username,
        u.created_at AS account_created,
        u.follower_count,
        u.following_count,
        COUNT(DISTINCT p.post_id) AS post_count,
        COUNT(DISTINCT DATE(p.created_at)) AS active_days,
        DATEDIFF(CURDATE(), u.created_at) AS account_age_days,
        AVG(TIMESTAMPDIFF(MINUTE, LAG(p.created_at) OVER (PARTITION BY u.user_id ORDER BY p.created_at), p.created_at)) AS avg_minutes_between_posts
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.username, u.created_at, u.follower_count, u.following_count
)
SELECT 
    user_id,
    username,
    account_age_days,
    post_count,
    follower_count,
    following_count,
    ROUND(following_count / NULLIF(follower_count, 0), 2) AS following_ratio,
    ROUND(post_count / NULLIF(account_age_days, 0), 2) AS posts_per_day,
    CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
    CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
    CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END AS bot_score,
    CASE 
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) >= 2 THEN 'High Risk'
        WHEN (CASE WHEN following_count > follower_count * 10 THEN 1 ELSE 0 END +
              CASE WHEN post_count > account_age_days * 20 THEN 1 ELSE 0 END +
              CASE WHEN avg_minutes_between_posts < 1 THEN 1 ELSE 0 END) = 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS bot_likelihood
FROM user_patterns
WHERE post_count > 0
ORDER BY bot_score DESC, posts_per_day DESC;

-- EXPLANATION:
-- Bot detection based on behavioral patterns:
-- - High following/follower ratio
-- - Excessive posting frequency
-- - Very short intervals between posts


-- ============================================================================
-- Q144: ANALYZE CONTENT VIRALITY
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Time-Based Analysis, Growth Metrics
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH post_growth AS (
    SELECT 
        p.post_id,
        p.user_id,
        u.username,
        p.content_type,
        p.created_at,
        p.like_count,
        p.share_count,
        DATEDIFF(HOUR, p.created_at, GETDATE()) AS hours_since_post,
        CASE 
            WHEN DATEDIFF(HOUR, p.created_at, GETDATE()) > 0 
            THEN ROUND(CAST(p.like_count + p.share_count AS FLOAT) / DATEDIFF(HOUR, p.created_at, GETDATE()), 2)
            ELSE p.like_count + p.share_count
        END AS engagement_per_hour
    FROM posts p
    INNER JOIN users u ON p.user_id = u.user_id
    WHERE p.created_at >= DATEADD(DAY, -7, GETDATE())
)
SELECT 
    post_id,
    username,
    content_type,
    created_at,
    like_count,
    share_count,
    hours_since_post,
    engagement_per_hour,
    CASE 
        WHEN engagement_per_hour > 100 THEN 'Viral'
        WHEN engagement_per_hour > 50 THEN 'High Performing'
        WHEN engagement_per_hour > 10 THEN 'Above Average'
        ELSE 'Normal'
    END AS virality_status
FROM post_growth
ORDER BY engagement_per_hour DESC;

-- ==================== ORACLE SOLUTION ====================
WITH post_growth AS (
    SELECT 
        p.post_id,
        p.user_id,
        u.username,
        p.content_type,
        p.created_at,
        p.like_count,
        p.share_count,
        ROUND((SYSDATE - p.created_at) * 24) AS hours_since_post,
        CASE 
            WHEN ROUND((SYSDATE - p.created_at) * 24) > 0 
            THEN ROUND((p.like_count + p.share_count) / ROUND((SYSDATE - p.created_at) * 24), 2)
            ELSE p.like_count + p.share_count
        END AS engagement_per_hour
    FROM posts p
    INNER JOIN users u ON p.user_id = u.user_id
    WHERE p.created_at >= SYSDATE - 7
)
SELECT 
    post_id,
    username,
    content_type,
    created_at,
    like_count,
    share_count,
    hours_since_post,
    engagement_per_hour,
    CASE 
        WHEN engagement_per_hour > 100 THEN 'Viral'
        WHEN engagement_per_hour > 50 THEN 'High Performing'
        WHEN engagement_per_hour > 10 THEN 'Above Average'
        ELSE 'Normal'
    END AS virality_status
FROM post_growth
ORDER BY engagement_per_hour DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH post_growth AS (
    SELECT 
        p.post_id,
        p.user_id,
        u.username,
        p.content_type,
        p.created_at,
        p.like_count,
        p.share_count,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.created_at)) / 3600 AS hours_since_post,
        CASE 
            WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.created_at)) / 3600 > 0 
            THEN ROUND(((p.like_count + p.share_count)::FLOAT / 
                 (EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.created_at)) / 3600))::NUMERIC, 2)
            ELSE p.like_count + p.share_count
        END AS engagement_per_hour
    FROM posts p
    INNER JOIN users u ON p.user_id = u.user_id
    WHERE p.created_at >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT 
    post_id,
    username,
    content_type,
    created_at,
    like_count,
    share_count,
    ROUND(hours_since_post::NUMERIC, 0) AS hours_since_post,
    engagement_per_hour,
    CASE 
        WHEN engagement_per_hour > 100 THEN 'Viral'
        WHEN engagement_per_hour > 50 THEN 'High Performing'
        WHEN engagement_per_hour > 10 THEN 'Above Average'
        ELSE 'Normal'
    END AS virality_status
FROM post_growth
ORDER BY engagement_per_hour DESC;

-- ==================== MYSQL SOLUTION ====================
WITH post_growth AS (
    SELECT 
        p.post_id,
        p.user_id,
        u.username,
        p.content_type,
        p.created_at,
        p.like_count,
        p.share_count,
        TIMESTAMPDIFF(HOUR, p.created_at, NOW()) AS hours_since_post,
        CASE 
            WHEN TIMESTAMPDIFF(HOUR, p.created_at, NOW()) > 0 
            THEN ROUND((p.like_count + p.share_count) / TIMESTAMPDIFF(HOUR, p.created_at, NOW()), 2)
            ELSE p.like_count + p.share_count
        END AS engagement_per_hour
    FROM posts p
    INNER JOIN users u ON p.user_id = u.user_id
    WHERE p.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
)
SELECT 
    post_id,
    username,
    content_type,
    created_at,
    like_count,
    share_count,
    hours_since_post,
    engagement_per_hour,
    CASE 
        WHEN engagement_per_hour > 100 THEN 'Viral'
        WHEN engagement_per_hour > 50 THEN 'High Performing'
        WHEN engagement_per_hour > 10 THEN 'Above Average'
        ELSE 'Normal'
    END AS virality_status
FROM post_growth
ORDER BY engagement_per_hour DESC;

-- EXPLANATION:
-- Virality measured by engagement velocity (interactions per hour).
-- Normalizes for post age to compare fairly.


-- ============================================================================
-- Q145-Q160: ADDITIONAL SOCIAL MEDIA QUESTIONS
-- ============================================================================
-- Q145: Analyze follower growth trends
-- Q146: Identify influential users (network analysis)
-- Q147: Calculate content reach and impressions
-- Q148: Analyze posting time optimization
-- Q149: Track mention and tag patterns
-- Q150: Calculate user activity scores
-- Q151: Identify content clusters
-- Q152: Analyze comment sentiment distribution
-- Q153: Track story/reel performance
-- Q154: Calculate share of voice by brand
-- Q155: Identify fake engagement patterns
-- Q156: Analyze cross-platform performance
-- Q157: Track campaign hashtag performance
-- Q158: Calculate influencer ROI
-- Q159: Analyze audience demographics
-- Q160: Generate content performance report
-- 
-- Each follows the same multi-RDBMS format.
-- ============================================================================


-- ============================================================================
-- Q145: ANALYZE FOLLOWER GROWTH TRENDS
-- ============================================================================
-- Difficulty: Medium
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH daily_followers AS (
    SELECT 
        followed_user_id AS user_id,
        CAST(follow_date AS DATE) AS follow_day,
        COUNT(*) AS new_followers,
        SUM(CASE WHEN unfollow_date IS NOT NULL THEN 1 ELSE 0 END) AS unfollows
    FROM follows
    WHERE follow_date >= DATEADD(DAY, -30, GETDATE())
    GROUP BY followed_user_id, CAST(follow_date AS DATE)
)
SELECT 
    u.user_id,
    u.username,
    df.follow_day,
    df.new_followers,
    df.unfollows,
    df.new_followers - df.unfollows AS net_change,
    SUM(df.new_followers - df.unfollows) OVER (PARTITION BY u.user_id ORDER BY df.follow_day) AS cumulative_growth
FROM daily_followers df
INNER JOIN users u ON df.user_id = u.user_id
ORDER BY u.user_id, df.follow_day;

-- ==================== ORACLE SOLUTION ====================
WITH daily_followers AS (
    SELECT 
        followed_user_id AS user_id,
        TRUNC(follow_date) AS follow_day,
        COUNT(*) AS new_followers,
        SUM(CASE WHEN unfollow_date IS NOT NULL THEN 1 ELSE 0 END) AS unfollows
    FROM follows
    WHERE follow_date >= SYSDATE - 30
    GROUP BY followed_user_id, TRUNC(follow_date)
)
SELECT 
    u.user_id,
    u.username,
    df.follow_day,
    df.new_followers,
    df.unfollows,
    df.new_followers - df.unfollows AS net_change,
    SUM(df.new_followers - df.unfollows) OVER (PARTITION BY u.user_id ORDER BY df.follow_day) AS cumulative_growth
FROM daily_followers df
INNER JOIN users u ON df.user_id = u.user_id
ORDER BY u.user_id, df.follow_day;

-- ==================== POSTGRESQL SOLUTION ====================
WITH daily_followers AS (
    SELECT 
        followed_user_id AS user_id,
        follow_date::DATE AS follow_day,
        COUNT(*) AS new_followers,
        SUM(CASE WHEN unfollow_date IS NOT NULL THEN 1 ELSE 0 END) AS unfollows
    FROM follows
    WHERE follow_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY followed_user_id, follow_date::DATE
)
SELECT 
    u.user_id,
    u.username,
    df.follow_day,
    df.new_followers,
    df.unfollows,
    df.new_followers - df.unfollows AS net_change,
    SUM(df.new_followers - df.unfollows) OVER (PARTITION BY u.user_id ORDER BY df.follow_day) AS cumulative_growth
FROM daily_followers df
INNER JOIN users u ON df.user_id = u.user_id
ORDER BY u.user_id, df.follow_day;

-- ==================== MYSQL SOLUTION ====================
WITH daily_followers AS (
    SELECT 
        followed_user_id AS user_id,
        DATE(follow_date) AS follow_day,
        COUNT(*) AS new_followers,
        SUM(CASE WHEN unfollow_date IS NOT NULL THEN 1 ELSE 0 END) AS unfollows
    FROM follows
    WHERE follow_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY followed_user_id, DATE(follow_date)
)
SELECT 
    u.user_id,
    u.username,
    df.follow_day,
    df.new_followers,
    df.unfollows,
    df.new_followers - df.unfollows AS net_change,
    SUM(df.new_followers - df.unfollows) OVER (PARTITION BY u.user_id ORDER BY df.follow_day) AS cumulative_growth
FROM daily_followers df
INNER JOIN users u ON df.user_id = u.user_id
ORDER BY u.user_id, df.follow_day;


-- ============================================================================
-- END OF SOCIAL MEDIA QUESTIONS (Q141-Q160)
-- ============================================================================
