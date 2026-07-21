create table lung_disease (
       patient_id int primary key,
	   age int,
	   gender varchar (20),
	   smoling_status varchar(20),
	   lung_capacity numeric (4,2),
	   disease_type varchar (30),
	   treatment_type varchar (30),
	   hospital_visits int,
	   recovered varchar (20)
	   
);

alter table lung_disease
rename column smoling_status to smoking_status;


select count(*)
from lung_disease;

select *
from lung_disease;
---------------------------------------------------------------------
1.what is the overall recovery rate across all the patients?
---------------------------------------------------------------------

select 
round(sum (case
       when recovered = 'Yes' then 1
	    else 0
	    end)*100.0
	 /
		count( case
		        when recovered in ('Yes' , 'No') then 1
				end),
		2) || '%' as recovery_rate
from lung_disease;


-------------------------------------------------------------
2.What is the recovery rate broken down by Disease Type?
-------------------------------------------------------------

select disease_type,
round( sum (case
           when recovered = 'Yes' then 1
		   else 0
		   end)* 100.0
		   /
	count(case 
	      when recovered in ('Yes','No') then 1
		  end),2) || '%' as recovery_rate
from lung_disease
where disease_type <> 'Unknown'
group by disease_type;

----------------------------------------------------------
3.What is the average Lung Capacity by Disease Type?
----------------------------------------------------------

select disease_type,
       round(avg(lung_capacity),2) as avg_lung_capacity
from lung_disease
where disease_type <> 'Unknown'
group by disease_type;


-------------------------------------------------------------------
4.How does smoking status relate to disease type distribution?
-------------------------------------------------------------------

select disease_type,
       smoking_status,
count(*) as total_patients
from lung_disease
where disease_type <> 'Unknown'
and smoking_status IN ('Yes','No')
group by disease_type, smoking_status
order by disease_type, smoking_status;

----------------------------------------------------------------------------------------------------------------
5.Which Disease Type has the highest average Hospital Visits, and does that correlate with lower recovery rates?
----------------------------------------------------------------------------------------------------------------
select disease_type,
       round(avg(hospital_visits),2) as avg_visits,
       round( sum (case
           when recovered = 'Yes' then 1
		   else 0
		   end)* 100.0
		   /
	count(case 
	      when recovered in ('Yes','No') then 1
		  end),2) as recovery_rate
from lung_disease
where disease_type <> 'Unknown'
group by disease_type
order by avg_visits desc;

--------------------------------------------------------------------------------------------------
6.How does recovery rate differ by Treatment Type within each Disease Type (two-level grouping)?
--------------------------------------------------------------------------------------------------

select treatment_type,
       disease_type,
	   round( sum (case
           when recovered = 'Yes' then 1
		   else 0
		   end)* 100.0
		   /
	count(case 
	      when recovered in ('Yes','No') then 1
		  end),2) as recovery_rate
from lung_disease
where treatment_type <> 'Not recorded'
and disease_type <> 'Unknown'
group by disease_type, treatment_type
order by disease_type, recovery_rate desc; 

---------------------------------------------------------------------------------------------------
7.What age group (using CASE WHEN buckets: 20-40, 41-60, 61-80, 80+) has the best recovery outcomes?
----------------------------------------------------------------------------------------------------

select case
		when age between 20 and 40 then '20-40'
		when age between 41 and 60 then '41-60'
		when age between 61 and 80 then '61-80'
		else '80+'
		end as age_bucket,
		round( sum (case
           when recovered = 'Yes' then 1
		   else 0
		   end)* 100.0
		   /
	  count(case 
	      when recovered in ('Yes','No') then 1
		  end),2) as recovery_rate  
from lung_disease
group by age_bucket
order by recovery_rate desc;


--------------------------------------------------------------------------------------------
8.Are smokers recovering at a different rate than non-smokers, controlling for Disease Type?
--------------------------------------------------------------------------------------------

select disease_type,
        smoking_status,
	    round( sum (case
           when recovered = 'Yes' then 1
		   else 0
		   end)* 100.0
		   /
	  count(case 
	      when recovered in ('Yes','No') then 1
		  end),2) as recovery_rate 
from lung_disease
where disease_type <> 'Unknown'
and smoking_status in ('Yes','No')
group by disease_type,smoking_status
order by disease_type,recovery_rate desc;


-----------------------------------------------------------------------------------------------------------------
9.Rank diseases by recovery rate — which is the "most treatable" and "least treatable" condition in this dataset?
-----------------------------------------------------------------------------------------------------------------

with recovery_rates as (select disease_type,
                       round( sum (case
                       when recovered = 'Yes' then 1
		               else 0
		              end)* 100.0
		              /
	                 count(case 
	                  when recovered in ('Yes','No') then 1
		             end),2) as recovery_rate
					 from lung_disease
					 where disease_type <> 'Unknown'
					 group by disease_type),

ranked as (select *,
           rank()over(order by recovery_rate desc) as rnk
		   from recovery_rates)
		   

select disease_type,
       recovery_rate || '%' as recovery_rate,
	   rnk,
	   case
	   when rnk = 1 then 'Most treatable'
	   when rnk = (select max(rnk) from ranked) then 'Least treatable'
	   else 'Moderately treatable'
	   end as treatment_chances
from ranked
order by rnk;


----------------------------------------------------------------------------------------------------
10. find the top 3 age groups with highest hospital visit counts within each disease type
----------------------------------------------------------------------------------------------------

with visit_count as (select
                     disease_type,
                     case
		              when age between 20 and 40 then '20-40'
		              when age between 41 and 60 then '41-60'
		              when age between 61 and 80 then '61-80'
		              else '80+'
		              end as age_group,
					  sum(hospital_visits) as hospital_visit_count
					 from lung_disease
					 where disease_type <> 'Unknown'
					 group by disease_type, age_group),

 ranked as (select *,
            rank() over(partition by disease_type order by hospital_visit_count desc) as rnk
            from visit_count)

select disease_type,
    age_group,
    hospital_visit_count,
    rnk
from ranked 
where rnk <= 3
order by disease_type,
rnk;


---------------------------------------------------------------------------------------------------------
11.Calculate a running/cumulative average of Lung Capacity ordered by Age 
---------------------------------------------------------------------------------------------------------

select age,
       lung_capacity,
	   round(avg(lung_capacity) over (order by age
	   rows between unbounded preceding and current row),2) as running_average
from lung_disease;


---------------------------------------------------------------------------------------------------------------
12.Identify rows with missing/imputed data and show how excluding them changes the recovery rate
---------------------------------------------------------------------------------------------------------------

select 'excluding unknown' as data_type,
       round(sum(case when recovered ='Yes' then 1
	   else 0
	   end)*100.0
	   /
	   count(*),2) as recovery_rate
	   from lung_disease
	   WHERE disease_type <> 'Unknown'
         AND smoking_status <> 'Unknown'
         AND recovered IN ('Yes','No')
union all

select 'including unknown' as data_type,
round(sum(case when recovered = 'Yes' then 1
else 0
end)*100.0
/
count(*),2) 
from lung_disease;


----------------------------------------End----------------------------------------------------------	   
	   
 
	   