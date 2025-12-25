-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: Social Media (Questions 141-160)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP,
    last_active TIMESTAMP,
    is_verified BOOLEAN,
    follower_count INT,
    following_count INT
);

CREATE TABLE posts (
    post_id INT PRIMARY KEY,
    user_id INT,
    content TEXT,
    created_at TIMESTAMP,
    likes_count INT,
    comments_count INT,
    shares_count INT,
    is_public BOOLEAN
);

CREATE TABLE follows (
    follower_id INT,
    following_id INT,
    created_at TIMESTAMP,
    PRIMARY KEY (follower_id, following_id)
);

CREATE TABLE likes (
    like_id INT PRIMARY KEY,
    user_id INT,
    post_id INT,
    created_at TIMESTAMP
);

CREATE TABLE comments (
    comment_id INT PRIMARY KEY,
    post_id INT,
    user_id INT,
    content TEXT,
    created_at TIMESTAMP,
    parent_comment_id INT
);

CREATE TABLE hashtags (
    hashtag_id INT PRIMARY KEY,
    tag_name VARCHAR(100),
    post_count INT
);

CREATE TABLE post_hashtags (
    post_id INT,
    hashtag_id INT,
    PRIMARY KEY (post_id, hashtag_id)
);
*/

-- ============================================
-- QUESTION 141: Find trending hashtags
-- ============================================
-- Scenario: Discover what's popular right now

WITH recent_hashtags AS (
    SELECT 
        h.hashtag_id,
        h.tag_name,
        COUNT(*) AS recent_posts,
        COUNT(DISTINCT p.user_id) AS unique_users
    FROM hashtags h
    JOIN post_hashtags ph ON h.hashtag_id = ph.hashtag_id
    JOIN posts p ON ph.post_id = p.post_id
    WHERE p.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    GROUP BY h.hashtag_id, h.tag_name
),
previous_hashtags AS (
    SELECT 
        h.hashtag_id,
        COUNT(*) AS previous_posts
    FROM hashtags h
    JOIN post_hashtags ph ON h.hashtag_id = ph.hashtag_id
    JOIN posts p ON ph.post_id = p.post_id
    WHERE p.created_at BETWEEN CURRENT_TIMESTAMP - INTERVAL '48 hours' AND CURRENT_TIMESTAMP - INTERVAL '24 hours'
    GROUP BY h.hashtag_id
)
SELECT 
    rh.tag_name,
    rh.recent_posts,
    rh.unique_users,
    COALESCE(ph.previous_posts, 0) AS previous_posts,
    ROUND(100.0 * (rh.recent_posts - COALESCE(ph.previous_posts, 0)) / NULLIF(COALESCE(ph.previous_posts, 1), 0), 2) AS growth_pct
FROM recent_hashtags rh
LEFT JOIN previous_hashtags ph ON rh.hashtag_id = ph.hashtag_id
ORDER BY rh.recent_posts DESC
LIMIT 10;

-- ============================================
-- QUESTION 142: Calculate user engagement rate
-- ============================================
-- Scenario: Influencer analytics

SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    COUNT(DISTINCT p.post_id) AS total_posts,
    SUM(p.likes_count) AS total_likes,
    SUM(p.comments_count) AS total_comments,
    SUM(p.shares_count) AS total_shares,
    ROUND(100.0 * (SUM(p.likes_count) + SUM(p.comments_count) + SUM(p.shares_count)) / 
          (NULLIF(u.follower_count, 0) * COUNT(DISTINCT p.post_id)), 4) AS engagement_rate
FROM users u
JOIN posts p ON u.user_id = p.user_id
WHERE p.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY u.user_id, u.username, u.follower_count
HAVING COUNT(DISTINCT p.post_id) >= 5
ORDER BY engagement_rate DESC;

-- ============================================
-- QUESTION 143: Find mutual followers
-- ============================================
-- Scenario: Friend suggestions

SELECT 
    f1.follower_id AS user_id,
    u1.username AS user_name,
    f2.following_id AS suggested_user_id,
    u2.username AS suggested_user_name,
    COUNT(*) AS mutual_connections
FROM follows f1
JOIN follows f2 ON f1.following_id = f2.follower_id
JOIN users u1 ON f1.follower_id = u1.user_id
JOIN users u2 ON f2.following_id = u2.user_id
WHERE f1.follower_id != f2.following_id
AND NOT EXISTS (
    SELECT 1 FROM follows f3 
    WHERE f3.follower_id = f1.follower_id 
    AND f3.following_id = f2.following_id
)
GROUP BY f1.follower_id, u1.username, f2.following_id, u2.username
HAVING COUNT(*) >= 3
ORDER BY mutual_connections DESC;

-- ============================================
-- QUESTION 144: Analyze posting patterns
-- ============================================
-- Scenario: Best time to post analysis

SELECT 
    EXTRACT(DOW FROM created_at) AS day_of_week,
    EXTRACT(HOUR FROM created_at) AS hour_of_day,
    COUNT(*) AS post_count,
    ROUND(AVG(likes_count), 2) AS avg_likes,
    ROUND(AVG(comments_count), 2) AS avg_comments,
    ROUND(AVG(shares_count), 2) AS avg_shares,
    ROUND(AVG(likes_count + comments_count + shares_count), 2) AS avg_engagement
FROM posts
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
AND is_public = TRUE
GROUP BY EXTRACT(DOW FROM created_at), EXTRACT(HOUR FROM created_at)
ORDER BY avg_engagement DESC
LIMIT 20;

-- ============================================
-- QUESTION 145: Detect fake/bot accounts
-- ============================================
-- Scenario: Platform integrity

SELECT 
    u.user_id,
    u.username,
    u.created_at,
    u.follower_count,
    u.following_count,
    COUNT(DISTINCT p.post_id) AS post_count,
    COUNT(DISTINCT l.like_id) AS likes_given,
    ROUND(u.following_count::DECIMAL / NULLIF(u.follower_count, 0), 2) AS following_ratio,
    CASE 
        WHEN u.following_count > 1000 AND u.follower_count < 100 THEN 'HIGH'
        WHEN COUNT(DISTINCT p.post_id) = 0 AND COUNT(DISTINCT l.like_id) > 100 THEN 'HIGH'
        WHEN u.created_at > CURRENT_DATE - INTERVAL '7 days' AND COUNT(DISTINCT l.like_id) > 500 THEN 'HIGH'
        ELSE 'LOW'
    END AS bot_risk
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
LEFT JOIN likes l ON u.user_id = l.user_id
GROUP BY u.user_id, u.username, u.created_at, u.follower_count, u.following_count
HAVING (u.following_count > 1000 AND u.follower_count < 100)
    OR (COUNT(DISTINCT p.post_id) = 0 AND COUNT(DISTINCT l.like_id) > 100)
ORDER BY following_ratio DESC;

-- ============================================
-- QUESTION 146: Calculate viral coefficient
-- ============================================
-- Scenario: Content virality analysis

WITH post_spread AS (
    SELECT 
        p.post_id,
        p.user_id AS original_poster,
        p.created_at,
        p.shares_count,
        COUNT(DISTINCT s.user_id) AS unique_sharers,
        COUNT(DISTINCT f.follower_id) AS sharer_followers
    FROM posts p
    LEFT JOIN shares s ON p.post_id = s.post_id
    LEFT JOIN follows f ON s.user_id = f.following_id
    WHERE p.created_at >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY p.post_id, p.user_id, p.created_at, p.shares_count
)
SELECT 
    post_id,
    original_poster,
    shares_count,
    unique_sharers,
    sharer_followers,
    ROUND(sharer_followers::DECIMAL / NULLIF(unique_sharers, 0), 2) AS avg_reach_per_share,
    ROUND(shares_count::DECIMAL / NULLIF((SELECT follower_count FROM users WHERE user_id = original_poster), 0), 4) AS viral_coefficient
FROM post_spread
WHERE shares_count > 0
ORDER BY viral_coefficient DESC
LIMIT 50;

-- ============================================
-- QUESTION 147: Find influencer networks
-- ============================================
-- Scenario: Identify connected influencer groups

WITH influencers AS (
    SELECT user_id, username, follower_count
    FROM users
    WHERE follower_count >= 10000
),
influencer_connections AS (
    SELECT 
        i1.user_id AS influencer_1,
        i1.username AS name_1,
        i2.user_id AS influencer_2,
        i2.username AS name_2,
        CASE 
            WHEN EXISTS (SELECT 1 FROM follows WHERE follower_id = i1.user_id AND following_id = i2.user_id)
             AND EXISTS (SELECT 1 FROM follows WHERE follower_id = i2.user_id AND following_id = i1.user_id)
            THEN 'MUTUAL'
            WHEN EXISTS (SELECT 1 FROM follows WHERE follower_id = i1.user_id AND following_id = i2.user_id)
            THEN 'FOLLOWS'
            ELSE 'NONE'
        END AS connection_type
    FROM influencers i1
    CROSS JOIN influencers i2
    WHERE i1.user_id < i2.user_id
)
SELECT *
FROM influencer_connections
WHERE connection_type != 'NONE'
ORDER BY connection_type, influencer_1;

-- ============================================
-- QUESTION 148: Analyze comment sentiment threads
-- ============================================
-- Scenario: Content moderation prioritization

WITH comment_threads AS (
    SELECT 
        c.post_id,
        c.comment_id,
        c.parent_comment_id,
        c.user_id,
        c.content,
        c.created_at,
        LEVEL AS depth
    FROM comments c
    START WITH c.parent_comment_id IS NULL
    CONNECT BY PRIOR c.comment_id = c.parent_comment_id
)
SELECT 
    post_id,
    COUNT(*) AS total_comments,
    MAX(depth) AS max_thread_depth,
    COUNT(DISTINCT user_id) AS unique_commenters,
    COUNT(CASE WHEN depth > 3 THEN 1 END) AS deep_discussions
FROM comment_threads
GROUP BY post_id
ORDER BY total_comments DESC;

-- ============================================
-- QUESTION 149: Calculate follower growth rate
-- ============================================
-- Scenario: Account growth analytics

WITH daily_followers AS (
    SELECT 
        following_id AS user_id,
        DATE(created_at) AS follow_date,
        COUNT(*) AS new_followers
    FROM follows
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY following_id, DATE(created_at)
)
SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    SUM(df.new_followers) AS followers_gained_30d,
    ROUND(AVG(df.new_followers), 2) AS avg_daily_growth,
    ROUND(100.0 * SUM(df.new_followers) / NULLIF(u.follower_count - SUM(df.new_followers), 0), 2) AS growth_rate_pct
FROM users u
LEFT JOIN daily_followers df ON u.user_id = df.user_id
GROUP BY u.user_id, u.username, u.follower_count
HAVING SUM(df.new_followers) > 0
ORDER BY growth_rate_pct DESC;

-- ============================================
-- QUESTION 150: Find content gaps
-- ============================================
-- Scenario: Content strategy recommendations

WITH user_hashtags AS (
    SELECT 
        p.user_id,
        h.tag_name,
        COUNT(*) AS usage_count
    FROM posts p
    JOIN post_hashtags ph ON p.post_id = ph.post_id
    JOIN hashtags h ON ph.hashtag_id = h.hashtag_id
    GROUP BY p.user_id, h.tag_name
),
popular_hashtags AS (
    SELECT tag_name, post_count
    FROM hashtags
    WHERE post_count >= 1000
    ORDER BY post_count DESC
    LIMIT 50
)
SELECT 
    u.user_id,
    u.username,
    ph.tag_name AS trending_hashtag,
    ph.post_count AS hashtag_popularity,
    COALESCE(uh.usage_count, 0) AS user_usage
FROM users u
CROSS JOIN popular_hashtags ph
LEFT JOIN user_hashtags uh ON u.user_id = uh.user_id AND ph.tag_name = uh.tag_name
WHERE u.follower_count >= 1000
AND COALESCE(uh.usage_count, 0) = 0
ORDER BY u.user_id, ph.post_count DESC;

-- ============================================
-- QUESTION 151: Analyze user retention cohorts
-- ============================================
-- Scenario: Platform health metrics

WITH user_cohorts AS (
    SELECT 
        user_id,
        DATE_TRUNC('week', created_at) AS cohort_week
    FROM users
),
weekly_activity AS (
    SELECT 
        uc.cohort_week,
        DATE_TRUNC('week', p.created_at) AS activity_week,
        COUNT(DISTINCT uc.user_id) AS active_users
    FROM user_cohorts uc
    LEFT JOIN posts p ON uc.user_id = p.user_id
    GROUP BY uc.cohort_week, DATE_TRUNC('week', p.created_at)
)
SELECT 
    cohort_week,
    activity_week,
    EXTRACT(WEEK FROM activity_week - cohort_week) AS weeks_since_signup,
    active_users,
    FIRST_VALUE(active_users) OVER (PARTITION BY cohort_week ORDER BY activity_week) AS cohort_size,
    ROUND(100.0 * active_users / FIRST_VALUE(active_users) OVER (PARTITION BY cohort_week ORDER BY activity_week), 2) AS retention_rate
FROM weekly_activity
WHERE activity_week >= cohort_week
ORDER BY cohort_week, activity_week;

-- ============================================
-- QUESTION 152: Identify power users
-- ============================================
-- Scenario: Community ambassador program

SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    COUNT(DISTINCT p.post_id) AS posts_30d,
    COUNT(DISTINCT c.comment_id) AS comments_30d,
    COUNT(DISTINCT l.like_id) AS likes_30d,
    SUM(p.likes_count) AS likes_received,
    SUM(p.comments_count) AS comments_received,
    (COUNT(DISTINCT p.post_id) * 3 + COUNT(DISTINCT c.comment_id) * 2 + COUNT(DISTINCT l.like_id)) AS activity_score
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id AND p.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN comments c ON u.user_id = c.user_id AND c.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN likes l ON u.user_id = l.user_id AND l.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY u.user_id, u.username, u.follower_count
HAVING COUNT(DISTINCT p.post_id) >= 10 OR COUNT(DISTINCT c.comment_id) >= 50
ORDER BY activity_score DESC
LIMIT 100;

-- ============================================
-- QUESTION 153: Calculate content reach
-- ============================================
-- Scenario: Post performance analytics

WITH post_reach AS (
    SELECT 
        p.post_id,
        p.user_id,
        p.created_at,
        u.follower_count AS direct_reach,
        p.shares_count,
        (SELECT SUM(follower_count) FROM users WHERE user_id IN (
            SELECT user_id FROM shares WHERE post_id = p.post_id
        )) AS share_reach
    FROM posts p
    JOIN users u ON p.user_id = u.user_id
    WHERE p.created_at >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT 
    post_id,
    user_id,
    direct_reach,
    shares_count,
    COALESCE(share_reach, 0) AS share_reach,
    direct_reach + COALESCE(share_reach, 0) AS total_potential_reach,
    ROUND(100.0 * COALESCE(share_reach, 0) / NULLIF(direct_reach, 0), 2) AS amplification_rate
FROM post_reach
ORDER BY total_potential_reach DESC;

-- ============================================
-- QUESTION 154: Find inactive followers
-- ============================================
-- Scenario: Follower quality analysis

SELECT 
    u.user_id,
    u.username,
    u.follower_count,
    COUNT(CASE WHEN f_user.last_active < CURRENT_DATE - INTERVAL '90 days' THEN 1 END) AS inactive_followers,
    COUNT(CASE WHEN f_user.last_active >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) AS active_followers,
    ROUND(100.0 * COUNT(CASE WHEN f_user.last_active >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) / 
          NULLIF(COUNT(*), 0), 2) AS active_follower_pct
FROM users u
JOIN follows f ON u.user_id = f.following_id
JOIN users f_user ON f.follower_id = f_user.user_id
GROUP BY u.user_id, u.username, u.follower_count
ORDER BY active_follower_pct;

-- ============================================
-- QUESTION 155: Analyze hashtag co-occurrence
-- ============================================
-- Scenario: Content categorization insights

SELECT 
    h1.tag_name AS hashtag_1,
    h2.tag_name AS hashtag_2,
    COUNT(*) AS co_occurrence_count,
    ROUND(100.0 * COUNT(*) / LEAST(h1.post_count, h2.post_count), 2) AS co_occurrence_rate
FROM post_hashtags ph1
JOIN post_hashtags ph2 ON ph1.post_id = ph2.post_id AND ph1.hashtag_id < ph2.hashtag_id
JOIN hashtags h1 ON ph1.hashtag_id = h1.hashtag_id
JOIN hashtags h2 ON ph2.hashtag_id = h2.hashtag_id
WHERE h1.post_count >= 100 AND h2.post_count >= 100
GROUP BY h1.tag_name, h2.tag_name, h1.post_count, h2.post_count
HAVING COUNT(*) >= 50
ORDER BY co_occurrence_count DESC
LIMIT 50;

-- ============================================
-- QUESTION 156: Calculate average response time
-- ============================================
-- Scenario: Community engagement metrics

SELECT 
    p.user_id,
    u.username,
    COUNT(DISTINCT p.post_id) AS total_posts,
    COUNT(c.comment_id) AS total_comments_received,
    ROUND(AVG(EXTRACT(EPOCH FROM (c.created_at - p.created_at)) / 60), 2) AS avg_first_comment_minutes,
    ROUND(AVG(EXTRACT(EPOCH FROM (first_reply.created_at - c.created_at)) / 60), 2) AS avg_reply_time_minutes
FROM posts p
JOIN users u ON p.user_id = u.user_id
LEFT JOIN comments c ON p.post_id = c.post_id AND c.parent_comment_id IS NULL
LEFT JOIN LATERAL (
    SELECT MIN(created_at) AS created_at
    FROM comments
    WHERE parent_comment_id = c.comment_id AND user_id = p.user_id
) first_reply ON TRUE
WHERE p.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.user_id, u.username
HAVING COUNT(c.comment_id) >= 10
ORDER BY avg_reply_time_minutes;

-- ============================================
-- QUESTION 157: Identify content clusters
-- ============================================
-- Scenario: Topic modeling for recommendations

WITH user_interests AS (
    SELECT 
        l.user_id,
        h.tag_name,
        COUNT(*) AS interaction_count
    FROM likes l
    JOIN posts p ON l.post_id = p.post_id
    JOIN post_hashtags ph ON p.post_id = ph.post_id
    JOIN hashtags h ON ph.hashtag_id = h.hashtag_id
    GROUP BY l.user_id, h.tag_name
),
top_interests AS (
    SELECT 
        user_id,
        tag_name,
        interaction_count,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY interaction_count DESC) AS rank
    FROM user_interests
)
SELECT 
    user_id,
    STRING_AGG(tag_name, ', ' ORDER BY rank) AS top_interests,
    SUM(interaction_count) AS total_interactions
FROM top_interests
WHERE rank <= 5
GROUP BY user_id
ORDER BY total_interactions DESC;

-- ============================================
-- QUESTION 158: Calculate unfollower rate
-- ============================================
-- Scenario: Account health monitoring

WITH follow_events AS (
    SELECT 
        following_id AS user_id,
        DATE(created_at) AS event_date,
        'follow' AS event_type,
        COUNT(*) AS count
    FROM follows
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY following_id, DATE(created_at)
    
    UNION ALL
    
    SELECT 
        following_id AS user_id,
        DATE(unfollowed_at) AS event_date,
        'unfollow' AS event_type,
        COUNT(*) AS count
    FROM unfollow_log
    WHERE unfollowed_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY following_id, DATE(unfollowed_at)
)
SELECT 
    u.user_id,
    u.username,
    SUM(CASE WHEN fe.event_type = 'follow' THEN fe.count ELSE 0 END) AS new_followers,
    SUM(CASE WHEN fe.event_type = 'unfollow' THEN fe.count ELSE 0 END) AS unfollowers,
    SUM(CASE WHEN fe.event_type = 'follow' THEN fe.count ELSE -fe.count END) AS net_change,
    ROUND(100.0 * SUM(CASE WHEN fe.event_type = 'unfollow' THEN fe.count ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN fe.event_type = 'follow' THEN fe.count ELSE 0 END), 0), 2) AS churn_rate
FROM users u
LEFT JOIN follow_events fe ON u.user_id = fe.user_id
GROUP BY u.user_id, u.username
ORDER BY churn_rate DESC;

-- ============================================
-- QUESTION 159: Find conversation starters
-- ============================================
-- Scenario: Identify engaging content creators

SELECT 
    p.user_id,
    u.username,
    COUNT(DISTINCT p.post_id) AS total_posts,
    SUM(p.comments_count) AS total_comments,
    ROUND(AVG(p.comments_count), 2) AS avg_comments_per_post,
    COUNT(CASE WHEN p.comments_count >= 10 THEN 1 END) AS viral_discussions,
    ROUND(100.0 * COUNT(CASE WHEN p.comments_count >= 10 THEN 1 END) / COUNT(*), 2) AS viral_rate
FROM posts p
JOIN users u ON p.user_id = u.user_id
WHERE p.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.user_id, u.username
HAVING COUNT(DISTINCT p.post_id) >= 5
ORDER BY avg_comments_per_post DESC;

-- ============================================
-- QUESTION 160: Generate personalized feed
-- ============================================
-- Scenario: Content recommendation algorithm

WITH user_preferences AS (
    SELECT 
        l.user_id,
        ph.hashtag_id,
        COUNT(*) AS preference_score
    FROM likes l
    JOIN posts p ON l.post_id = p.post_id
    JOIN post_hashtags ph ON p.post_id = ph.post_id
    WHERE l.created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY l.user_id, ph.hashtag_id
),
following_posts AS (
    SELECT 
        f.follower_id AS user_id,
        p.post_id,
        p.created_at,
        p.likes_count,
        p.comments_count
    FROM follows f
    JOIN posts p ON f.following_id = p.user_id
    WHERE p.created_at >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT 
    fp.user_id,
    fp.post_id,
    fp.created_at,
    fp.likes_count + fp.comments_count AS engagement,
    COALESCE(SUM(up.preference_score), 0) AS relevance_score,
    (fp.likes_count + fp.comments_count) * (1 + COALESCE(SUM(up.preference_score), 0) * 0.1) AS feed_score
FROM following_posts fp
LEFT JOIN post_hashtags ph ON fp.post_id = ph.post_id
LEFT JOIN user_preferences up ON fp.user_id = up.user_id AND ph.hashtag_id = up.hashtag_id
WHERE fp.user_id = 12345  -- Target user
GROUP BY fp.user_id, fp.post_id, fp.created_at, fp.likes_count, fp.comments_count
ORDER BY feed_score DESC
LIMIT 50;
