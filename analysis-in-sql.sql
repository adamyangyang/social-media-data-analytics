-- After importing data and creating the database in MySQL, we begin analyzing the dataset.

-- ------------------------------------------
--                Age analysis
-- ------------------------------------------

-- Find the number of users by each age
-- CREATE TEMPORARY TABLE age_individual
SELECT
	age,
    COUNT(age) AS num_of_users
FROM user_profiles
GROUP BY 1
ORDER BY 1

-- Generation Segmentation 
SELECT
	CASE 
		WHEN age BETWEEN 0 AND 25 THEN "Gen Z" 
		WHEN age BETWEEN 26 AND 41 THEN "Millennials"
        WHEN age BETWEEN 42 AND 44 THEN "Gen X"
	END AS generation,
    SUM(num_of_users) AS user_count
FROM age_individual
GROUP BY 1 */

-- Age group segementation
SELECT
	CASE 
		WHEN age <= 1 THEN "Infant" 
		WHEN age BETWEEN 2 AND 4 THEN "Toddler"
        WHEN age BETWEEN 5 AND 12 THEN "Children"
        WHEN age BETWEEN 13 AND 19 THEN "Teenager"
        WHEN age BETWEEN 20 AND 39 THEN "Young Adult"
        WHEN age >= 40  THEN "Middle Age Adult"
	END AS age_groups,
    CASE 
		WHEN age <= 1 THEN "0 - 1" 
		WHEN age BETWEEN 2 AND 4 THEN "2 - 4"
        WHEN age BETWEEN 5 AND 12 THEN "5 - 12"
        WHEN age BETWEEN 13 AND 19 THEN "13 - 19"
        WHEN age BETWEEN 20 AND 39 THEN "20 - 39"
        WHEN age >= 40  THEN "40 & over"
	END AS age_range,
    SUM(num_of_users) AS user_count
FROM age_individual
GROUP BY 1 		

-- Interests of 20 - 39 yr old 
SELECT
    interests,
    COUNT(interests) AS count_
FROM user_profiles_agg_ints 
WHERE age BETWEEN 20 AND 39
GROUP BY 1
ORDER BY age 			

-- Create a temporary table to further analyze the largest user group on the platform.

-- Temp table for 20 - 39 yr old users
-- CREATE TEMPORARY TABLE twnty_to_39s
SELECT * 
FROM user_profiles
WHERE age BETWEEN 20 AND 39 

-- Create a temporary table to get the types of content 20 - 39 yr old engages with.
-- It also includes the types of reactions used as well as the date & time.

-- Temp table for data on 20 - 39 yr old users + category + date_time + reaction_type 
-- CREATE TEMPORARY TABLE twnty_to_39s_activity_time
SELECT 
	r.row_id, r.date_time, 
    r.content_id, c.category, 
    t_t_39s.user_id, r.reaction_type
FROM reactions r
	JOIN twnty_to_39s t_t_39s
		ON t_t_39s.user_id = r.user_id
	LEFT JOIN content c
		ON r.content_id = c.content_id 		

-- 20 - 39 yr old activity by hour 
SELECT 
	HOUR(date_time) AS hr,
    COUNT(user_id) AS num_of_users
FROM twnty_to_39s_activity_time
GROUP BY 1
ORDER BY 1 		

-- 20 - 39 yr old activity by day of the week
SELECT
	CASE
		WHEN day_of_week = 0 THEN "Mon"
        WHEN day_of_week = 1 THEN "Tue"
        WHEN day_of_week = 2 THEN "Wed"
        WHEN day_of_week = 3 THEN "Thu"
        WHEN day_of_week = 4 THEN "Fri"
        WHEN day_of_week = 5 THEN "Sat"
        WHEN day_of_week = 6 THEN "Sun"
	END AS day_name,
    num_of_users
FROM (
    SELECT
        WEEKDAY(date_time) AS day_of_week,
        COUNT(user_id) AS num_of_users
    FROM twnty_to_39s_activity_time
    GROUP BY 1
    ORDER BY 1 
) subq1
GROUP BY 1 				

-- ------------------------------------------
--            Category analysis
-- ------------------------------------------

-- Post Count by category 
SELECT * FROM (
SELECT 
	category,
	COUNT(category) AS total_count
FROM content
GROUP BY 1
ORDER BY 2 DESC 		) subq 

-- Create a temporary table to join together content and reactions from social media posts

-- Temp table for Content + Reactions
-- CREATE TEMPORARY TABLE content_w_reactions
SELECT
	r.row_id, r.date_time, 
    r.content_id, c.type, c.category,
    r.reaction_type
FROM reactions r
	LEFT JOIN content c
		ON c.content_id = r.content_id	         

-- Total number of posts made by yr & mo 
SELECT
	YEAR(r.date_time) AS yr,
    MONTH(r.date_time) AS mo,
    COUNT(c.content_id) AS content_count
FROM reactions r
	LEFT JOIN content c
		ON c.content_id = r.content_id
GROUP BY 1, 2
ORDER BY 1, 2 */


-- Create a temporary table to ge the number of posts made for each year & month by content categories.

-- Temp table for num of posts made for EACH yr & mo, grouped by categories 
-- CREATE TEMPORARY TABLE content_count_by_yr_mo
SELECT
	YEAR(date_time) AS yr,
    MONTH(date_time) AS mo,
    category,
    COUNT(category) AS content_count
FROM content_w_reactions
-- WHERE YEAR(date_time) = 2020 	# 2020 is used as a test year.
GROUP BY 1, 2, 3
ORDER BY 3, 1, 2, 3 			 

-- Total popularity score for each category
SELECT
	category,
    SUM(score) AS total_score
FROM reactions r
	LEFT JOIN content c
		ON c.content_id = r.content_id
	LEFT JOIN reaction_types rt
		ON rt.type = r.reaction_type
GROUP BY 1 			

-- Create a temporary table to get the top performing social media posts by year, month & category.

-- Temp tables for top performing posts by yr, mo & category
-- STEP 1: Find the highest posts made for each year & month
-- Once done, create a temp table for joining to another table in step 2
CREATE TEMPORARY TABLE cc1
SELECT
	yr, 
    mo,
	MAX(content_count) AS content_count
FROM content_count_by_yr_mo
GROUP BY 1, 2

-- STEP 2: Join the main table with step 1
-- CREATE TEMPORARY TABLE yr_mo_top_categories
SELECT 
	cc2.yr, cc2.mo, 
    cc2.category, 
    cc2.content_count
FROM content_count_by_yr_mo cc2
	LEFT JOIN cc1
		ON cc2.content_count = cc1.content_count
        AND cc2.yr = cc1.yr 	# 2nd join condition as a failsafe
        AND cc2.mo = cc1.mo 	# 3rd join condition as a failsafe
WHERE cc2.content_count = cc1.content_count     -- condition to only return content count from prev table (cc2)
												-- that matches to current table (cc2)

-- What's the best performing category from the dataset? (Ans: animals (7))
SELECT
	category,
    COUNT(category) AS num_of_times_as_top_performer
FROM yr_mo_top_categories
GROUP BY 1 

-- Find out which months were the 'animals' most popular (Ans: January) 
-- Also, order by content_count in descending order
SELECT *
FROM yr_mo_top_categories
WHERE category = "animals"
ORDER BY 1,2
ORDER BY content_count DESC 


-- ------------------------------------------
--             Reaction analysis
-- ------------------------------------------

-- Top 5 reactions: Heart (1,622), Scared (1,572), Peeking (1,559), Hate (1,552) , Interested (1,549) 
SELECT 
	reaction_type,
    COUNT(reaction_type) AS total_reactions
FROM reactions
GROUP BY reaction_type
ORDER BY total_reactions DESC
LIMIT 5 		

-- Find the total number of reactions & its score for animal category -> Super Love (R: 123, S: 9,225)
SELECT
	reaction_type,
    COUNT(reaction_type) AS total_reactions,
    SUM(rt.score) AS total_score
FROM content_w_reactions cwr
LEFT JOIN reaction_types rt
	ON rt.type = cwr.reaction_type
WHERE category = "animals"
GROUP BY 1
ORDER BY 3 DESC 		 

-- Find the similar metrics for the other 4 categories (science, healthy eating, technology, food)
-- Science - Total reactions & score for each reaction type -> Want (R: 126, S: 8,820)
SELECT
	reaction_type,
    COUNT(reaction_type) AS total_reactions,
    SUM(rt.score) AS total_score
FROM content_w_reactions cwr
LEFT JOIN reaction_types rt
	ON rt.type = cwr.reaction_type
WHERE category = "science"
GROUP BY 1
ORDER BY 3 DESC 		 	

-- Healthy Eating - Total reactions & score for each reaction type -> Adore (R: 122, S: 8,784)
SELECT
	reaction_type,
    COUNT(reaction_type) AS total_reactions,
    SUM(rt.score) AS total_score
FROM content_w_reactions cwr
LEFT JOIN reaction_types rt
	ON rt.type = cwr.reaction_type
WHERE category = "healthy eating"
GROUP BY 1
ORDER BY 3 DESC 		 	

-- Technology - Total reactions & score for each reaction type -> Adore (R: 129, S: 9,288)
SELECT
	reaction_type,
    COUNT(reaction_type) AS total_reactions,
    SUM(rt.score) AS total_score
FROM content_w_reactions cwr
LEFT JOIN reaction_types rt
	ON rt.type = cwr.reaction_type
WHERE category = "technology"
GROUP BY 1
ORDER BY 3 DESC 		 

-- Food - Total reactions & score for each reaction type -> Cherish (R: 119, S: 8,330)
SELECT
	reaction_type,
    COUNT(reaction_type) AS total_reactions,
    SUM(rt.score) AS total_score
FROM content_w_reactions cwr
LEFT JOIN reaction_types rt
	ON rt.type = cwr.reaction_type
WHERE category = "food"
GROUP BY 1
ORDER BY 3 DESC 		 


-- ------------------------------------------
--              Time analysis
-- ------------------------------------------

-- Date time is located in reactions table

-- Create a temporary table to order the table where user engages with social media post by year, month & day.

-- Temp table, Order content by reaction_time as there isn't a date_time for content_id
-- CREATE TEMPORARY TABLE content_ordered_by_yr_mo_dt
SELECT * FROM reactions 
ORDER BY YEAR(date_time), MONTH(date_time), DAY(date_time)      

-- Join the temporary table to get the url of each piece of social media content.

-- Temp table for content_id, date_time, category, user_id & reaction type
-- CREATE TEMPORARY TABLE content_w_category_dt_user_id_reaction
SELECT 
	cymd.row_id, cymd.date_time, 
    cymd.content_id, c.type, c.category,
    cymd.user_id, cymd.reaction_type, 
    c.url
FROM content_ordered_by_yr_mo_dt cymd
	LEFT JOIN content c
		ON c.content_id = cymd.content_id 


-- Temp table to find when 20 - 39 yr old are most active at by hour of time
-- CREATE TEMPORARY TABLE users_active_time_by_hr
SELECT
	HOUR(date_time) AS hr,
    COUNT(reaction_type) AS total_reactions
FROM content_w_category_dt_user_id_reaction
GROUP BY 1
ORDER BY 1 

-- ------------------------------------------
--             Content analysis
-- ------------------------------------------

-- Find the # of content types (i.e. photo, video, GIF) --> 4 types (audio, GIF, photo & video)
SELECT DISTINCT type FROM content

-- Find the number of posts made based on each content type -> (photo: 261, video: 259, GIF: 244, audio: 236)
SELECT * FROM (
SELECT
	type,
    COUNT(type) AS total_count
FROM content
GROUP BY 1
ORDER BY 2 DESC 		) agg 

-- Find the most popular content type by engagement -> (photo: 6847, video: 6499, GIF: 6313, audio: 5894)
-- Done so by finding the total of reactions for each content type
SELECT 
	content_type,
    COUNT(reaction_type) AS engagement_count
FROM (
SELECT 
	r.content_id, c.type AS content_type,
    r.user_id, r.reaction_type
FROM content c
	LEFT JOIN reactions r
		ON r.content_id = c.content_id ) agg
GROUP BY 1 

-- Find what categories are usually posted in which type of content 
SELECT
	category, content_type, MAX(total_count) AS total_posts
FROM (

SELECT 
	category, type AS content_type,
    COUNT(category) AS total_count
FROM content
GROUP BY 1, 2
ORDER BY 3 DESC ) sub

GROUP BY 1
ORDER BY 2  			

-- Temp tables to find all engagement by content type & category 
-- STEP 1: Create temporary table for all engagement by content type & category
-- CREATE TEMPORARY TABLE eng_by_cont_type_cat
SELECT
	category,
	content_type,
    COUNT(reaction_type) AS total_count
FROM (
SELECT 
	r.content_id, c.type AS content_type, c.category,
    r.user_id, r.reaction_type
FROM content c
	LEFT JOIN reactions r
		ON r.content_id = c.content_id ) agg
GROUP BY 1, 2
ORDER BY 1, 2 		

--STEP 2: Create seperate temp table to get the max engagement count
-- CREATE TEMPORARY TABLE max_eng_count
SELECT
	category,
    MAX(total_count) AS total_count
FROM eng_by_cont_type_cat
GROUP BY 1 			

-- STEP 3: Join back STEP 2's table with STEP 1's table
-- Also create a temporary table for future reference
-- CREATE TEMPORARY TABLE best_eng_by_type_cat
SELECT
	mec.category,
    aec.content_type,
    mec.total_count
FROM max_eng_count mec
	JOIN eng_by_cont_type_cat aec
		ON aec.category = mec.category
        AND aec.total_count = mec.total_count 			

-- Temp tables to compare all engagements vs phto engagements

-- STEP 1: Create a temp table to get only photo engagements
-- CREATE TEMPORARY TABLE eng_by_cont_type_cat_photo_only
SELECT *
FROM eng_by_cont_type_cat
WHERE content_type = "photo"

-- STEP 2: Join best_eng_by_type_cat table with STEP 1's table for comparison
SELECT
	t1.category, t1.content_type,
    t1.total_count AS best_eng,
    t2.total_count AS photo_eng
FROM best_eng_by_type_cat t1
	LEFT JOIN eng_by_cont_type_cat_photo_only t2
		ON t1.category = t2.category 			


-- ------------------------------------------
--            Sentiment analysis
-- ------------------------------------------
-- Temp tables to find the most popular sentiment for each category
-- STEP 1: Create a temp table using reactions table as a base & left joining with reaction_types & content table
-- CREATE TEMPORARY TABLE content_category_reactions_w_sentiment_score
SELECT 
	r.row_id, r.date_time,
    r.content_id, c.category, 
    r.user_id, r.reaction_type, rt.sentiment, rt.score
FROM reactions r
	LEFT JOIN reaction_types rt
		ON rt.type = r.reaction_type
	LEFT JOIN content c
		ON c.content_id = r.content_id
    
    
-- STEP 2: Group data by category & sentiment (to get both positives & negatives) + the total count of each sentiment.
-- CREATE TEMPORARY TABLE category_w_sentiment_total_count
SELECT 
	category, 
    sentiment, COUNT(sentiment) AS sentiment_count
FROM content_category_reactions_w_sentiment_score
GROUP BY 1, 2   

-- STEP 3: Create a seperate table to find the max count for each category
-- CREATE TEMPORARY TABLE category_w_max_count
SELECT
	category, MAX(sentiment_count) AS total_count
FROM category_w_sentiment_total_count
GROUP BY 1 			

-- STEP 4: Join STEP 3's table with STEP 4's table & aggregate data
-- Also, create a temp table for future reference
-- CREATE TEMPORARY TABLE sentiment_by_cat
SELECT
	cws.category, cws.sentiment, mx_count.total_count
FROM category_w_sentiment_total_count cws
	LEFT JOIN category_w_max_count mx_count
		ON mx_count.category = cws.category	# Extra fail-safe conditions to ensure joins are done properly
        AND mx_count.total_count = cws.sentiment_count # Extra fail-safe conditions to ensure joins are done properly
WHERE mx_count.total_count IS NOT NULL
ORDER BY 3 DESC 				


-- Temp tables to find the most used reaction for the positive sentiment in each category 
-- STEP 1: Create temp table for sentiments & reactions
-- CREATE TEMPORARY TABLE sent_w_react
SELECT 
	category, 
    reaction_type, COUNT(reaction_type) AS reaction_count,
    sentiment, COUNT(sentiment) AS sentiment_count
FROM content_category_reactions_w_sentiment_score
GROUP BY 1, 2, 4  		


-- STEP 2: Create temp table to find the highest reactions by category & reaction type (without reaction type)
-- CREATE TEMPORARY TABLE highest_pos_reactions_by_cat_react_type
SELECT
	category,
    MAX(reaction_count) AS highest_reactions
FROM sent_w_react
WHERE sentiment = "positive"
GROUP BY 1
ORDER BY 1				

-- STEP 3: Join STEP 2's table with STEP 1's table to find the reaction type & highest reactions
-- CREATE TEMPORARY TABLE reaction_type_by_cat_pos_only
SELECT 
	t1.category, t2.reaction_type, t1.highest_reactions
FROM highest_pos_reactions_by_cat_react_type t1
	JOIN sent_w_react t2
		ON t1.category = t2.category
        AND t1.highest_reactions = t2.reaction_count
ORDER BY 1				

-- STEP 4a: Join STEP 3's table with sentiment_by_cat table
-- CREATE TEMPORARY TABLE sent_react_type_count_by_cat
SELECT
	t2.category, t2.sentiment, t2.total_count AS sentiment_count,
    t1.reaction_type AS most_used_reaction, t1.highest_reactions AS reactions_count
FROM reaction_type_by_cat_pos_only t1
	JOIN sentiment_by_cat t2
		ON t1.category = t2.category			

-- STEP 4b: Use STEP 4a's table to create groups for reaction type for future use
SELECT
	*,
    CASE
		WHEN reaction_type = "adore" THEN "G1"
        WHEN reaction_type = "cherish" THEN "G2"
        WHEN reaction_type = "heart" THEN "G3"
        WHEN reaction_type = "interested" THEN "G4"
        WHEN reaction_type = "intrigued" THEN "G5"
        WHEN reaction_type = "like" THEN "G6"
        WHEN reaction_type = "love" THEN "G7"
        WHEN reaction_type = "want" THEN "G8"
	END AS reaction_grouping
FROM sent_react_type_count_by_cat 			


-- Temp table to find most popular reactions (regardless of positive or negative) 
-- STEP 1: Create temp table to find the highest reactions by category & reaction type (without reaction type)
-- CREATE TEMPORARY TABLE highest_reactions_by_cat_react_type
SELECT 
	category,
    MAX(reaction_count) AS highest_reactions
FROM sent_w_react
GROUP BY 1					

-- STEP 2: JOIN STEP 1's table with sent_w_react table to find most used reaction
-- Also, join with reaction_type table to get the sentiment of each category
SELECT 
	t1.category, t2.reaction_type, rt.sentiment, t1.highest_reactions
FROM highest_reactions_by_cat_react_type t1
	JOIN sent_w_react t2
		ON t1.category = t2.category
        AND t1.highest_reactions = t2.reaction_count
	LEFT JOIN reaction_types rt
		ON t2.reaction_type = rt.type 
ORDER BY 1