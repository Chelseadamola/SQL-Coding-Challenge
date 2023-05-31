/*** Create a database ***/
 create database CodeChallenge;
 go
 
 --setting the database as specified current database for current session until another database is specified
 use CodeChallenge;
 go 

 -- Create the tables in the database and pull data from the csv file to populate the table
-- First table

 Create table continent_map (
 country_code varchar (10),
 continent_code varchar (10)
 )

 bulk insert continent_map
 from 'C:\Users\HITACHI\AppData\Local\Temp\Temp1_BrainTree_SQL_Coding_Challenge_Data_Analyst-main.zip\BrainTree_SQL_Coding_Challenge_Data_Analyst-main\data_csv\continent_map.csv'
 with ( 
 firstrow = 2,
 fieldterminator = ',',
 rowterminator = '\n',
 datafiletype = 'char',
 tablock
 )

 -- Second table

 Create table continents (
 continent_code varchar (10),
 continent_name varchar (50)
 )

 bulk insert continents
 from 'C:\Users\HITACHI\AppData\Local\Temp\Temp1_BrainTree_SQL_Coding_Challenge_Data_Analyst-main.zip\BrainTree_SQL_Coding_Challenge_Data_Analyst-main\data_csv\continents.csv'
 with ( 
 firstrow = 2,
 fieldterminator = ',',
 rowterminator = '\n',
 datafiletype = 'char',
 tablock
 )

 -- Third table

 Create table countries (
 country_code varchar (10),
 country_name varchar (100)
 )

 bulk insert countries
 from 'C:\Users\HITACHI\AppData\Local\Temp\Temp1_BrainTree_SQL_Coding_Challenge_Data_Analyst-main.zip\BrainTree_SQL_Coding_Challenge_Data_Analyst-main\data_csv\countries.csv'
 with ( 
 firstrow = 2,
 fieldterminator = ',',
 rowterminator = '\n',
 datafiletype = 'char',
 tablock
 )

 --Fourth table

 Create table per_capita (
 country_code varchar (10),
 year int,
 gdp_per_capita decimal (38,2)
 )

 bulk insert per_capita
 from 'C:\Users\HITACHI\AppData\Local\Temp\Temp1_BrainTree_SQL_Coding_Challenge_Data_Analyst-main.zip\BrainTree_SQL_Coding_Challenge_Data_Analyst-main\data_csv\per_capita.csv'
 with ( 
 firstrow = 2,
 fieldterminator = ',',
 rowterminator = '\n',
 datafiletype = 'char',
 tablock
 )

--Number 1
 -- Displaying values where country_code is null as country_code = "FOO" and make appear first on the list
select coalesce (country_code, 'FOO') as country_code
from continent_map
group by country_code
having count(*) > 1 

order by case when country_code is null then 0 else 1 end, country_code asc 


-- Deleting multiple records of country codes in the continent_map table to prevent multiple country names after joining
with cte as (
   select *, row_number () over ( partition by country_code order by continent_code) as countrycode
    from continent_map )
delete 
  from cte
  where countrycode > 1

-- To confirm successful deletion of dulicate coubtry_code rows
select country_code
  from continent_map
    group by country_code
      having count (*) > 1

-- Confirming 1 record per country
select cou.country_name
from continent_map as co join countries as cou
on co.country_code = cou.country_code
group by cou.country_name
having count(cou.country_name) > 1


--Number 2
-- Created a cte joining all the tables to themselves to pick out specific colums while joining the per-capita table to itself so as to calculate the year over year growth for each country.
 with growth_rates as (

         select cnt.continent_name, pc1.country_code, c.country_name, ((pc2.gdp_per_capita - pc1.gdp_per_capita) / pc1.gdp_per_capita) * 100 as growthpercent,  row_number () over (partition by cnt.continent_name order by (pc2.gdp_per_capita - pc1.gdp_per_capita) / pc1.gdp_per_capita  * 100 desc ) as Rank
            from per_capita as pc1 join per_capita as pc2
			   on pc1.country_code = pc2. country_code join  countries  as c
               on pc1.country_code = c.country_code join continent_map as cm 
               on c.country_code = cm.country_code join continents as cnt
               on cm.continent_code = cnt.continent_code
		    where pc1.year = 2011 and pc2.year = 2012 
	)

--selected required columns from the cte while formatting the columns with values to decimal and percent standard
select Rank, continent_name, country_code, country_name, format(growthpercent,'p2') as growthpercent
  from growth_rates
  where rank between 10 and 12
 
 --Number 3
 WITH cte as (
   select cnt.continent_name as names, sum(gdp_per_capita) as TotalGDP 
     from per_capita as pc
       join countries as c on pc.country_code = c.country_code 
       join continent_map as cm on c.country_code = cm.country_code
	   join continents as cnt on cm.continent_code = cnt.continent_code
     where pc.year = 2012 
       group by cnt.continent_name 
	          )
select 
	     concat(cast(sum (case when names = 'Asia' then TotalGDP end)/ sum(TotalGDP) * 100 as decimal(38,2)), '%') as Asia,
	     concat(cast(sum(case when names = 'Europe' then TotalGDP end)/sum(TotalGDP) * 100 as decimal(38,2)), '%') as Europe, 
	     concat(cast(sum(case when names not in ('Asia','Europe') then TotalGDP end)/ sum(TotalGDP) * 100 as decimal(38,2)), '%') as 'Rest of the world'
from cte;
 
 



 --Number 4a
select count(*) as country_count, concat('$',format(sum(gdp_per_capita), 'n2')) as gdp_sum 
  from per_capita as pc
      join countries as c on pc.country_code = c.country_code 
      join continent_map as cm on c.country_code = cm.country_code
	  join continents as cnt on cm.continent_code = cnt.continent_code
  where pc.year = 2007 and c.country_name like '%an%'

 -- Number 4b
select count(*) as country_count, concat('$',format(sum(gdp_per_capita),'n2')) as gdp_sum 
   from per_capita as pc
      join countries as c on pc.country_code = c.country_code 
      join continent_map as cm on c.country_code = cm.country_code
	  join continents as cnt on cm.continent_code = cnt.continent_code
 where pc.year = 2007 and c.country_name collate Latin1_General_CS_AI like '%an%'

 --Number 5
 select pc.year, count(*) as country_count, concat('$',format(sum(pc.gdp_per_capita), 'n2')) as total 
  from per_capita as pc
     join countries as c on pc.country_code = c.country_code 
	 join continent_map as cm on c.country_code = cm.country_code
	 join continents as cnt on cm.continent_code = cnt.continent_code
   where pc.year < 2012 and pc.gdp_per_capita is not null 
  group by pc.year;

--Number 6
with cte as (
    select cnt.continent_name, c.country_code, c.country_name, concat('$', pc.gdp_per_capita) as gdp_per_capita, concat('$', sum(pc.gdp_per_capita) over (partition by cnt.continent_name order by cnt.continent_name, substring(c.country_name, 2, 3) desc)) as running_total, row_number() over (partition by cnt.continent_name order by cnt.continent_name, substring(c.country_name, 2, 3) desc) as rn
           from per_capita as pc
              join countries as c on pc.country_code = c.country_code 
	          join continent_map as cm on c.country_code = cm.country_code
	          join continents as cnt on cm.continent_code = cnt.continent_code
            where pc.year = 2009   
     )
  select top 1 continent_name, country_code, country_name, gdp_per_capita, running_total
    from cte
    where running_total >= $70000.00;

--Number 7
 with cte as (
   select cnt.continent_name, c.country_code, c.country_name, avg(gdp_per_capita) as avg_gdp_per_capita, row_number () over (partition by cnt.continent_name order by avg(gdp_per_capita)) as rank 
     from per_capita as pc
       join countries as c on pc.country_code = c.country_code 
       join continent_map as cm on c.country_code = cm.country_code
	   join continents as cnt on cm.continent_code = cnt.continent_code
   group by cnt.continent_name, c.country_code, c.country_name
             )
 select rank, continent_name, country_code, country_name, concat('$',format(avg_gdp_per_capita, 'n2')) as avg_gdp_per_capita
 from cte
 where avg_gdp_per_capita in (select max(avg_gdp_per_capita) from cte group by continent_name)
 order by continent_name, country_code, country_name
