
# aa info没有 但 st info 有

SELECT bundle_id FROM
(SELECT * FROM st_app_info WHERE platform = 'android') AS a
LEFT JOIN 
(SELECT bundle_id AS aa_bundle_id from aa_app_info WHERE platform = 'android')AS b
ON(a.bundle_id = b.aa_bundle_id)
WHERE aa_bundle_id IS NULL
 

# aa rank没有但是 st rank有 

SELECT * from aa_app_info WHERE bundle_id IN  
(SELECT product_id FROM 
(SELECT * FROM st_app_rank_weekly WHERE DATE = '2021-03-01' AND platform = 'android' ORDER BY RANK LIMIT 300) AS d
LEFT JOIN 
(SELECT * FROM 
(SELECT product_id AS id_product,  bundle_id FROM aa_app_info WHERE platform = 'android') AS a  
JOIN
(SELECT product_id AS aa_product_id FROM aa_app_rank_weekly WHERE DATE='2021-03-01' AND platform = 'android') AS b
ON(a.id_product = b.aa_product_id)) AS c
ON(d.product_id = c.bundle_id) 
WHERE id_product IS NULL
);

SELECT * FROM aa_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'android' limit 300
SELECT * FROM aa_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'ios' limit 300


SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'ios' limit 300
SELECT * FROM st_app_info

SELECT * FROM
(SELECT product_id AS st_product_id, app_name FROM st_app_info WHERE subclass = '解谜/脑筋急转弯' AND platform = 'ios') AS a
JOIN 
(SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'ios') AS b
ON (a.st_product_id = b.product_id) 
ORDER BY downloads desc 


SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-08' and platform = 'ios' AND product_id = ''


# 找到指定类别指定日期指定平台游戏下载量排行
SELECT * FROM
(SELECT product_id AS st_product_id FROM st_app_info WHERE class = '超休闲' AND platform = 'ios') AS a
JOIN 
(SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-01' ) AS b
ON (a.st_product_id = b.product_id) 
ORDER BY RANK

SELECT * FROM st_app_info

# 找到指定类别指定日期指定平台游戏下载量排行
SELECT * FROM
(SELECT product_id AS st_product_id FROM st_app_info WHERE sub_subject = '车') AS a
JOIN 
(SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-08') AS b
ON (a.st_product_id = b.product_id) 

SELECT * FROM
(SELECT product_id AS st_product_id FROM st_app_info WHERE subclass = '跑酷') AS a
JOIN 
(SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-08') AS b
ON (a.st_product_id = b.product_id) 

SELECT * FROM
(SELECT product_id AS st_product_id FROM st_app_info WHERE subclass = '解压游戏') AS a
JOIN 
(SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-08') AS b
ON (a.st_product_id = b.product_id) 


SELECT * FROM
(SELECT product_id AS st_product_id FROM st_app_info WHERE subclass LIKE '%解谜%') AS a
JOIN 
(SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-08') AS b
ON (a.st_product_id = b.product_id) 



# 删除表
TRUNCATE TABLE st_premium_apps # 
DELETE st_premium_apps



SELECT * FROM premium_apps WHERE unified_id = '5ff90781682b7c2f2ae5508d'


SELECT * FROM st_app_info WHERE play_name LIKE '%跑酷%'  # 需要使用模糊查询

on duplicate KEY

SELECT * FROM st_app_info WHERE publisher_id IS NULL ;
SELECT * FROM st_premium_apps

INSERT INTO st_premium_apps (publisher_id)
SELECT publisher_id AS st_publisher_id, product_id AS st_product_id FROM st_app_info 


SELECT * FROM st_app_info  WHERE unified_name LIKE '%sling%'


SELECT * FROM top_app_weekly  WHERE 

# update 
UPDATE st_app_info SET sub_subject = 'IP' WHERE ID = 566


# 每周标签 
SELECT * FROM( 
(SELECT * FROM st_app_info) AS a  
JOIN 
(SELECT product_id AS product_id_rank, rank FROM st_app_rank_weekly WHERE DATE = '2021-03-15' AND platform = 'ios' AND RANK between 501  AND 600 ) AS b  
ON (a.product_id = b.product_id_rank) 
) ORDER BY RANK;




SELECT * FROM aa_app_info WHERE subject = 'ip';






SELECT * FROM st_app_rank_weekly WHERE DATE = '2021-03-08' 
ORDER BY RANK


SELECT * FROM top_app_weekly WHERE DATE = '2021-03-08' and source_platform = 'Sensor Tower'
ORDER BY RANK DESC


# product_id 是唯一的，group by product_id之后 count distinct publihser_id 后如是唯一即可判断每个国家publisher_id是否一样

SELECT publisher_id, downloads FROM premium_apps WHERE country = 'AU'
GROUP BY publisher_id
ORDER BY downloads DESC 

SELECT * FROM premium_apps;
SELECT * FROM premium_publishers;

SELECT * FROM
(SELECT * FROM st_app_info WHERE subclass LIKE '%跑酷%') AS a
JOIN 
(SELECT product_id AS pre_product_id FROM premium_apps WHERE platform='ios') AS b
ON (a.product_id = b.pre_product_id) 
GROUP BY product_id


SELECT
	decade,
	MAX(CASE
		 WHEN gender = 'F' THEN name
		 ELSE '' END) AS name_f,
	MAX(CASE
		 WHEN gender = 'M' THEN NAME
       ELSE '' END) AS name_m
FROM (
	SELECT
	  decade,
	  gender,
	  name,
	  RANK() OVER (PARTITION BY decade, gender ORDER BY frequency DESC) as x
	FROM
	data )
WHERE x = 1
GROUP BY 1
ORDER BY 1




