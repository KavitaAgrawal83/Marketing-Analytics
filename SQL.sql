
--creating table customer 
	select distinct customer_id into Customers from film_final

--creating table not_rented_film 
	select c.customer_id , f.film_id , f.title ,cat.[name]
	into not_rented_film
	from Customers c
	cross join film f
	join film_category fc on fc.film_id = f.film_id
	join category cat on cat.category_id = fc.category_id
	left join film_final ff
	on ff.customer_id = c.customer_id and ff.film_id = f.film_id
	where ff.rental_id is null
	order by c.customer_id ,f.title ,cat.[name]

	select * from not_rented_film

--creating table rented_cnt_tbl 
	select  [name],title ,count(rental_id ) rental_cnt,
	ROW_NUMBER()over(partition by [name] order by count(rental_id)desc) rn
	into rented_cnt_tbl
	from film_final
	group by  [name],title

	select top 10 * from rented_cnt_tbl


--creating table :top_1st_cat_tbl (calculating top 1st cat ,total_film_watched , avg ,percent_rank)
	with t1 as (
		select customer_id , title ,[name] category ,count(rental_id)  as rental_cnt
		from film_final
		group by title ,[name] ,customer_id
	)
	,t2 as (
		select customer_id , title ,category ,rental_cnt ,
		row_number()over(partition by customer_id order by rental_cnt desc) rn,
		AVG( rental_cnt )  over(partition by category ) avg_ ,
		PERCENT_RANK() over(partition by category order by rental_cnt ) percent_rn
		from t1
	)
		select  
		customer_id , category ,rental_cnt ,avg_ ,percent_rn
		into top_1st_cat_tbl
		from t2 where rn = 1

select * from top_1st_cat_tbl


--top 3 films by top 1st cat per customer
	select a.customer_id ,a.category ,b.title
	INTO Top3_Films_1st_Cat
	from (
		--top 1st cat
		select customer_id ,category from (
			select customer_id , title ,[name] category ,count(rental_id)  as rental_cnt ,
			row_number()over(partition by customer_id order by count(rental_id) desc) rn
			from film_final
			group by title ,[name] ,customer_id 
			) t where rn = 1
		) a
		inner join (
		--top 3 films
		select  
			customer_id ,r.[name] , r.title 
			from rented_cnt_tbl r
			inner join not_rented_film nr on r.title = nr.title
			where rn < 4
		) b
		on a.customer_id = b.customer_id and a.category = b.[name]


--creating table :top_2nd_cat_tbl (calculating top 2nd cat ,total_film_watched , proportion of film watched )
	with t1 as (
		select customer_id , title ,[name] category ,count(rental_id)  as rental_cnt,
		count(rental_id) over(partition by customer_id) total_cat_rental
		from film_final
		group by title ,[name] ,customer_id ,rental_id
	)
	,t2 as (
		select customer_id , title ,category ,rental_cnt ,
		row_number()over(partition by customer_id order by rental_cnt desc) rn ,total_cat_rental ,
		cast(rental_cnt as float ) / total_cat_rental * 100 as proportion_of_film_watched
		from t1
	)
		select 
		customer_id , category ,rental_cnt ,proportion_of_film_watched 
		into top_2nd_cat_tbl
		from t2 where rn = 2

	select * from top_2nd_cat_tbl


--top 3 films by top 2nd cat per customer
	select a.customer_id ,a.category ,b.title
	INTO Top3_Films_2nd_Cat
	from (
		--top 2nd cat
		select customer_id ,category from (
			select customer_id , title ,[name] category ,count(rental_id)  as rental_cnt ,
			row_number()over(partition by customer_id order by count(rental_id) desc) rn
			from film_final
			group by title ,[name] ,customer_id 
			) t where rn = 2
		) a
		inner join (
		--top 3 films
		select  
			customer_id ,r.[name] , r.title 
			from rented_cnt_tbl r
			inner join not_rented_film nr on r.title = nr.title
			where rn < 4
		) b
		on a.customer_id = b.customer_id and a.category = b.[name]


--top 3 films of favourite actor 
select c.customer_id ,c.actor_name , d.title
INTO Top3_Film_Actor
from (
	select customer_id ,actor_name
	from (
		select customer_id, count(title ) film_cnt,actor_name ,
		ROW_NUMBER()over (partition by customer_id order by count(title )  desc) rn
		from film_final
		group by customer_id  ,actor_name
		) t where rn = 1
	) c
inner join (		
	select * from (
		select * ,
		row_number()over(partition by customer_id , actor_name order by rental_cnt desc) rn
		from (
			select a.customer_id ,a.title ,b.actor_name ,b.rental_cnt 
			from (	
				--film_nt_watched
					select customer_id , title from not_rented_film
					) a
			inner join (
					--actor_film_list
					select distinct title , actor_name ,count(rental_id) rental_cnt 
					from film_final
					group by title ,actor_name
					)b
			on a.title = b.title
		) m 
	) n where rn < 4
) d
on c.customer_id = d.customer_id	and c.actor_name = d.actor_name

	
	
--Creating table Category_
	select f.film_id ,f.title , c.name
	INTO Category_
	from film f
	left join film_category fc on fc.film_id = f.film_id
	left join category c on c.category_id = fc.category_id


	select * from Customers
	select * from not_rented_film

	select * from top_1st_cat_tbl
	select * from top_2nd_cat_tbl
	select * from Top3_Films_1st_Cat
	select * from Top3_Films_2nd_Cat
	select * from Top3_Film_Actor
	select * from Category_


	select avg([length]) avg_length ,
	case 
		when avg([length])  > 120 then 'long'
		else 'short'
		end as film_length_cat
	from film_final
	group by rating

--this can be used to understand rental patterns of customers, such as the frequency and timing of their rentals.
	SELECT rental_id, customer_id, rental_date, 
       RANK() OVER (PARTITION BY customer_id ORDER BY rental_date) as rental_rank
	FROM film_final;

--This query determines the shortest and longest films that start with 'A'. 
--This could be useful in understanding the range of film lengths in a certain category.
	SELECT MIN(length) as min_length, MAX(length) as max_length
	FROM film_final
	WHERE title LIKE 'A%';


--This query lists all rentals and, for each rental it sorts by the most recent rental. 
--This helps analyze rental trends and active customers.
	select customer_id ,rental_id 
	from film_final
	order by rental_date desc


select * from not_rented_film where customer_id = '1'
select * from rented_cnt_tbl
select distinct customer_id from film_final where customer_id = '191'



 
	