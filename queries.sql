--create the tables

CREATE TABLE if not exists production_data(
year int,
region varchar(30),
province varchar(30),
source varchar(30),
production_gwh float
)


CREATE TABLE if not exists consumption_data(
year int,
region varchar(30),
province varchar(30),
sector varchar(30),
consumption_gwh float
)

--qui ottengo la produzione totale per anno per singola fonte (query1)

select
year,
source,
round(sum(production_gwh)::numeric, 1) as production_gwh 
from production_data
group by year, source order by year


--produzione per fonte per anno per regione

select
year,
region,
source,
sum(production_gwh) as production_gwh
from production_data
group by source, year, region
order by region, year asc

--queries per vedere la variazione % dal 2000 al 2024 in termini di crescita delle varie fonti

--option1
with 
	tab1 as (
select
source,
year,
sum(production_gwh) as prod_gwh_2000
from production_data
where year = 2000
group by source, year
),
	tab2 as (
select
source,
year,
sum(production_gwh) as prod_gwh_2024
from production_data
where year = 2024
group by source, year
)

select
t1.source,
t1.prod_gwh_2000,
t2.prod_gwh_2024,
round(((t2.prod_gwh_2024 - t1.prod_gwh_2000) * 100 / nullif(t1.prod_gwh_2000,0))::numeric, 1) as var_pct
from tab1 t1
join tab2 t2
on t1.source = t2.source
order by var_pct desc 

--option2
select
    source,
    sum(case when year = 2000 then production_gwh end) as prod_2000,
    sum(case when year = 2024 then production_gwh end) as prod_2024,
    (
        sum(case when year = 2024 then production_gwh end) -
        sum(case when year = 2000 then production_gwh end)
    ) * 100.0 /
    nullif(sum(case when year = 2000 then production_gwh end), 0) as var_pct
from production_data
group by source
having sum(case when year = 2000 then production_gwh end) is not null 
and sum(case when year = 2024 then production_gwh end) is not null;


--top 3 fonti produttive di energia dal 2020 al 2024

select
source,
sum(production_gwh) as production_gwh
from production_data
where year >= 2020
group by source
order by production_gwh desc limit 3

--consumo per settore dal più energivoro al meno energivoro

select 
sector,
sum(consumption_gwh) as consumption_gwh
from consumption_data
group by sector
order by consumption_gwh desc

--consumo per regione in ordine decrescente

select 
lower(region) as region,
sum(consumption_gwh) as consumption_gwh
from consumption_data
where year >= 2020
group by lower(region)
order by consumption_gwh desc

--percentuale del consumo regionale coperta da fonti rinnovabili dal 2020 al 2024 (query3)

with
	production as (
	select
	region,
	sum(production_gwh) as production_gwh
	from production_data
	where year >= 2020 and 
	source != 'Termoelettrico' and 
	source != 'Accumulo Stand Alone'
	group by region
		),

	consumption as (
	select
	region,
	sum(consumption_gwh) as consumption_gwh
	from consumption_data
	where year >= 2020
	group by region
	)

select
p.region,
round(((p.production_gwh/c.consumption_gwh)*100)::numeric, 1) as renewable_coverage_pct
from production p
join consumption c
on p.region = c.region
order by renewable_coverage_pct

--consumo per settore per ogni regione

select
region,
sector,
round(sum(consumption_gwh)::numeric, 1) as consumption_gwh
from consumption_data
group by region, sector
order by region

--consumo per settore dal 2000 (query2)

select
year,
sector,
round(sum(consumption_gwh)::numeric, 1) as consumption_gwh
from consumption_data
group by sector, year
order by year 