/* This file is developed in MySQL workbench.The below SQL- queries are written for Olympic
 dataset. This file consists of 20 SQL queries   */

/* Creating database to store tables */
create database olympic;
use olympic;

/* Creating table structure to store data */
create table if not exists olympics_histry
(
	id          INT,
    name        VARCHAR(200),
    sex         VARCHAR(3),
    age         VARCHAR(6),
    height     VARCHAR(6),
    weight     VARCHAR(6),
    team        VARCHAR(70),
    noc         VARCHAR(5),
    games       VARCHAR(20),
    year        INT,
    season      VARCHAR(10),
    city        VARCHAR(30),
    sport       VARCHAR(50),
    event       VARCHAR(100),
    medal       VARCHAR(7));
    
     CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_REGIONS
(
    noc         VARCHAR(5),
    region      VARCHAR(40),
    notes       VARCHAR(30)
);
    
/* load data into the tables created */    
    load data infile "D:\athlete_events.csv"
    into table olympics_histry
    character set latin1
    fields terminated by ','
    enclosed by '"'
    lines terminated by'\n'
    ignore 1 rows ;
    
  
load data infile "D:\olympic-regions.csv"
into table OLYMPICS_HISTORY_NOC_REGIONS
character set latin1
fields terminated by ','
enclosed by '"'
lines terminated by'\n'
ignore 1 rows ; 

set sql_safe_updates = 0;
set session sql_mode = '';

/* Checking first 5 records to understand the data */
select * from OLYMPICS_HISTORY_NOC_REGIONS limit 5;
select * from olympics_histry limit 5;

/*SQl queries for the problem statements*/

/*1.	How many olympics games have been held?*/
select count(distinct games) from olympics_histry;

/*2.	List down all Olympics games held so far.*/
select  distinct games,city from olympics_histry order by city;
/* or--*/
select year,season,city from olympics_histry
group by year,season,city  order by year;

/*3.	Mention the total no of nations who participated in each olympics game?*/
select games, count(distinct noc) as Total_nations from olympics_histry
 group by games order by Total_nations desc;
 
 /*4.	Which year saw the highest and lowest no of countries participating in olympics?*/
(select year,Total_nations,"lowest" as Participation from ( select year, count(distinct noc) as Total_nations from olympics_histry
 group by year order by Total_nations limit 1) as t)
 union all
 (select year, Total_nations, "Highest" from ( select year, count(distinct noc) as Total_nations from olympics_histry
 group by year order by Total_nations desc limit 1) as t);
 
 /*5.	Which nation has participated in all of the olympic games?*/
 select team as country, count(distinct games) from olympics_histry group by team
 having count(distinct games)= 51;
 
 /*6.	Identify the sport which was played in all summer olympics.*/
 with cte1 as 
 (select count(distinct games) as Total_games_summer from olympics_histry 
 where season = "Summer") ,
cte2 as(select sport, count(distinct games) as Tot_games_played from olympics_histry 
where season = "Summer" group by sport) 
select s.sport, s.Tot_games_played, f.Total_games_summer from cte2 s
inner join cte1 f
on s.Tot_games_played = f.Total_games_summer;
 
 /*--------or-----*/
 
 select sport,count(distinct games) as Total_games from olympics_histry 
 group by sport having Total_games = 29 ;
 
 /*  7.	Which Sports were just played only once in the olympics?  */
 
 with cte1 as(
 select distinct games as games, sport from olympics_histry ),
 cte2 as( select sport, count(1)as no_times_played from cte1
 group by 1)
 select a.games,a.sport, b.no_times_played from cte1 a
 inner join cte2 b
 on a.sport = b.sport
 where b.no_times_played=1
 order by a.sport;
 
 /*  8.	Fetch the total no of sports played in each olympic games.  */
with t1 as (select distinct games as games, sport from olympics_histry group by 1,2 order by 1),
t2 as(select games, count(1) as total_sports from t1 group by 1)
select * from t2 
order by  2 desc;
 
/*  9.	Fetch details of the oldest athletes to win a gold medal.  */

update  olympics_histry
set age = null where age = "NA";

set sql_safe_updates = 0; 

alter table olympics_histry
modify column age int;


with cte as(select name,age,sex,team,games,city,sport,event,medal, 
dense_rank() over(partition by medal order by age desc) as rnk from olympics_histry)
select * from cte
where rnk=1 and medal like "G%";

/*  10.	Find the Ratio of male and female athletes participated in all olympic games.  */

with t1 as (select count(id) as Female from olympics_histry where sex = "F"),
	t2 as (select count(id) as Male from olympics_histry where sex = "M")
select concat(round(t2.Male/t1.Female), ":1")as ratio  from t2,t1;

/*  11. Fetch the top 5 athletes who have won the most gold medals.  */
/* here when we write medal = "Gold" or any type of medal it is giving nothing so I used like clause */
select name, sum(gold_medals)  from
(select name, team,
case 
	when medal like "G%" then 1 else 0  
end as gold_medals 
from olympics_histry) as test
group by 1
order by 2 desc limit 5;

/*  12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).  */
select name, team, count(medal) from olympics_histry where medal regexp '^[GSB]'
group by 1,2
order by 3 desc limit 5;

/*  Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.  */
 with cte as(
 select b.region, sum(a.flag) as Total_medals from
 ( select noc, case 
 when medal like "N%" then 0 else 1
 end as flag
 from olympics_histry)  a
 left join  olympics_history_noc_regions b
 on b.noc = a.noc 
 group by 1
 order by 2 desc limit 5) 

select *, dense_rank() over(order by Total_medals desc) as Rank_num
from cte;

/*  . List down total gold, silver and bronze medals won by each country.  */

select a. region, 
count(case when b.medal like "G%" then 1 end) as  Gold_medals,
count( case when b.medal like "S%" then 2 end) as  silver_medals,
count(case when b.medal like "B%" then 3 end)  Bronze_medals
from olympics_histry b 
left join olympics_history_noc_regions a
on a.noc = b.noc
group by 1
order by 2 desc  ;

/*  15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.  */
 with cte as (select  games, noc, 
count(case when medal like "G%" then 1 end) as  Gold_medals,
count( case when medal like "S%" then 2 end) as  silver_medals,
count(case when medal like "B%" then 3 end) as  Bronze_medals
from olympics_histry 
group by 1,2
order by 1,2) 
select a.games, b.region as Country, a.Gold_medals, a.silver_medals, a.Bronze_medals
from cte a  
left join  olympics_history_noc_regions b
on a.noc = b.noc;

/* 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games. */
select  distinct games, concat(first_value(Country) over(partition by games order by 
Gold_medals desc ), '-', first_value(Gold_medals) over(partition by games order by Gold_medals desc)) as max_gold, 
concat(first_value(Country) over(partition by games order by 
silver_medals desc ), '-', first_value(silver_medals) over(partition by games order by silver_medals desc)) as max_silver, 
concat(first_value(Country) over(partition by games order by 
Bronze_medals desc ), '-', first_value(Bronze_medals) over(partition by games order by Bronze_medals desc)) as max_Bronze
from (with cte as (select  games, noc, 
count(case when medal like "G%" then 1 end) as  Gold_medals,
count( case when medal like "S%" then 2 end) as  silver_medals,
count(case when medal like "B%" then 3 end) as  Bronze_medals
from olympics_histry 
group by 1,2
order by 1,2) 
select a.games, b.region as Country, a.Gold_medals, a.silver_medals, a.Bronze_medals
from cte a  
left join  olympics_history_noc_regions b
on a.noc = b.noc) as test;

/* 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games. */
select  distinct games, concat(first_value(Country) over(partition by games order by 
Gold_medals desc ), '-', first_value(Gold_medals) over(partition by games order by Gold_medals desc)) as max_gold, 
concat(first_value(Country) over(partition by games order by 
silver_medals desc ), '-', first_value(silver_medals) over(partition by games order by silver_medals desc)) as max_silver, 
concat(first_value(Country) over(partition by games order by Bronze_medals desc ), '-', 
first_value(Bronze_medals) over(partition by games order by Bronze_medals desc)) as max_Bronze,
concat(first_value(Country) over(partition by games order by Total_medals desc), '-',
 first_value(Total_medals) over (partition by games order by Total_medals desc)) as Max_medals
from (with cte as (select  games, noc, 
count(case when medal like "G%" then 1 end) as  Gold_medals,
count( case when medal like "S%" then 2 end) as  silver_medals,
count(case when medal like "B%" then 3 end) as  Bronze_medals,
count(case when medal regexp '^[GSB]' then 1 end) as Total_medals
from olympics_histry 
group by 1,2
order by 1,2) 
select a.games, b.region as Country, a.Gold_medals, a.silver_medals, a.Bronze_medals,a.Total_medals
from cte a  
left join  olympics_history_noc_regions b
on a.noc = b.noc) as test;

/* 18. Which countries have never won gold medal but have won silver/bronze medals? */

with cte as (select noc, count(case when medal like 'G%' then "1" end) as Gold_medal,
count( case when medal like "S%" then "2" end) as  silver_medals,
count(case when medal like "B%" then "3" end) as  Bronze_medals
from olympics_histry
group by 1)
select a.region, b.Gold_medal, b.silver_medals, b.Bronze_medals
from cte b
left join olympics_history_noc_regions a 
on a.noc = b.noc
where b.Gold_medal = 0
group by 1,2,3,4
order by 2 desc, 3 desc,4 desc;

/* 19. In which Sport/event, India has won highest medals. */

with cte as(select noc, sport, count(case when medal regexp '^[GSB]' then 1 end) as Total_medals
from olympics_histry where noc = 'IND'
group by 1,2
order by 3 desc limit 1)
select a.region, b.Total_medals from olympics_history_noc_regions a 
inner join cte b
on a.noc = b.noc;

/* 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games */
 with cte as (select noc, games,sport,
 count(case when medal <> "NA" then 1 end) As Total_medals
 from olympics_histry 
 group by 1,2,3 )
 select a.region,b.games,b.sport, b.Total_medals from olympics_history_noc_regions a 
inner join cte b
on a.noc = b.noc
where b.sport = "Hockey" and a.region = "India"
order by 4 desc ;