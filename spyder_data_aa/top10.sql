


SELECT final.date, final.pub_id, final.product_id_info, final.app_name, final.name_publisher, final.icon, final.play_name, final.subject_name, final.parent_company_id, final.rank_pub, MAX(final.downloads_arw)  FROM(
SELECT *FROM(    
	SELECT  ai.pub_id, ai.product_id_info,ai.app_name,ai.name_publisher,ai.icon, ai.play_name,ai.subject_name,ai.parent_company_id as parent_company_id_arw,ai.parent_company_name,ai.publisher_country, srw.downloads AS downloads_arw, srw.date from(
	SELECT * from
   (select publisher_id as pub_id, product_id AS product_id_info, app_name, publisher_name as name_publisher, icon, play_name, subject_name from st_app_info 
   where platform = 'ios'
	) as auxai
   join 
   (select * from st_publisher_info) AS infopa 
   on (auxai.pub_id = infopa.publisher_id)
   ) AS ai 
   join
   (select * from st_app_rank_weekly
   where DATE = '2021-02-22' and platform = 'ios'
   )AS srw
	ON(srw.product_id=ai.product_id_info) 	
	) AS arwp
	JOIN 	  
  (SELECT * FROM(
  select * from(
  select pr.downloads, pi.publisher_id, pi.publisher_name, pi.parent_company_id, pr.rank as rank_pub, pr.date as date_week from
          (select * from st_publisher_info) as pi 
      join
          (
          select * from st_publisher_rank_weekly
          where date = '2021-02-22' and platform = 'ios'
          ) AS pr 
      on (pi.publisher_id = pr.publisher_id)
      ) AS parent
      group by parent.parent_company_id
      order by parent.downloads DESC
      ) AS pub_aux LIMIT 10
      ) AS pub #需要括起来当成一个表
      ON( arwp.parent_company_id_arw=pub.parent_company_id)
				)AS final
    GROUP BY final.parent_company_id
    ORDER BY final.rank_pub
    ;
                 
                 
                 
                 
                 
                 
                 
