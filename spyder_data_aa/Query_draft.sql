SELECT * FROM aa_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'android' limit 300

SELECT * FROM 
(SELECT product_id AS id_product, rank FROM st_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'ios' limit 300) AS a
JOIN 
(SELECT * FROM st_app_info WHERE platform = 'ios') AS b 
ON (a.id_product = b.product_id)
ORDER BY RANK;

 SELECT * FROM st_app_info WHERE platform = 'ios'
 
 SELECT * FROM aa_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'ios' limit 300
 
 SELECT * FROM  aa_app_info
 
 
 
SELECT product_id FROM st_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'ios' limit 300


SELECT * FROM st_app_rank_weekly WHERE DATE = '2021-03-01' and product_id = 1440502568

SELECT * FROM st_app_info WHERE product_id = 1449121741

SELECT * FROM st_app_rank_weekly WHERE DATE='2021-03-01' and platform = 'ios' 
ORDER BY rank
LIMIT 300

SELECT * FROM st_publisher_rank_weekly WHERE DATE = '2021-03-01' AND platform = 'android';








(SELECT play_name AS play_name_aa, product_id AS product_id_aa, bundle_id AS bundle_id_aa FROM aa_app_info WHERE platform = 'android') AS a 
JOIN 
(SELECT * FROM st_app_info WHERE platform = 'android') AS b 

ON(a.bundle_id_aa = b.bundle_id) 





