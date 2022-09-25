/*
2021 Census and Homicide Data Exploration

Skills used:CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types, Windows Functions
*/


Select *
From Borough_Population_Size
Order By 3 desc

Select *
From Homicide_Greater_London
Order By 2, 7, 3


--Some Boroughs have different names between the 2 tables

Update Homicide_Greater_London
Set	   Borough = REPLACE(Borough, '&', 'and')
Where  Borough Like '%&%'


----Alter Table [Borough_Population_Size]
----Add			[Total Murderers] int;

--Update the table with the ammount of cases that happenned

Update Borough_Population_Size
Set		[Total Murderers] = (Select	Count(Borough)
								  From		Homicide_Greater_London
								  Where		Homicide_Greater_London.Borough = Borough_Population_Size.[Area name]);


--Shows the chance of you meeting a murderer if you walk around the borough in 2021

Select [Area name], [All persons], [Total Murderers], ([Total Murderers]/[All persons])*100 As [Killed Chance]
, Sum([Total Murderers]) Over (Order by [Area name]) As [London Murder Count]
From   Borough_Population_Size
Where [Area name] is not null And [Area name] Not In ('London', 'Inner London', 'Outer London')

--Using CTE
--Shows the chance of meeting a murderer in Greater London in 2021

With MurderPercentLondon ([Area Name], [Total Population], [Total Murderers])
As
(
	Select [Area name], [All persons], Sum([Total Murderers]) Over () As [Total Murderers]
	From   Borough_Population_Size
)
Select *, ([Total Murderers]/[Total Population]) * 100 As [Chance of Murder]
From MurderPercentLondon
Where [Area Name] = 'London'


--Shows at the age group of Murderers

Select Killing.[Age Group], Count(*) as [No. Murderers]
From Borough_Population_Size PopSize
Join Homicide_Greater_London Killing
	On PopSize.[Area name] = Killing.Borough
Group by Killing.[Age Group]


--Using CTE to perform Calculation on Partition By in previous query
--Shows the age percentage compared to all homicides


With YoungKillerPercent ([Murderer Age Group], [No. Murderers])
As
(
	Select Killing.[Age Group], Count(*) as [No. Murderers]
	From Borough_Population_Size PopSize
	Join Homicide_Greater_London Killing
		On PopSize.[Area name] = Killing.Borough
	Group by Killing.[Age Group]
)
Select *, (Cast([No. Murderers] As float)/(Select Sum([No. Murderers]) From YoungKillerPercent)) * 100 As [Murderer Percentage]
From YoungKillerPercent


--Shows the relation between date and age of the homicides

With KillingDates ([Month of Murder], [Murderer Age Group], [No. Murderers])
As
(
	Select Killing.[Proceedings Date], Killing.[Age Group], Count(*) as [No. Murderers]
	From Borough_Population_Size PopSize
	Join Homicide_Greater_London Killing
		On PopSize.[Area name] = Killing.Borough
	Group by Killing.[Age Group], Killing.[Proceedings Date]
)
Select *
From KillingDates

--Using Temp Table to perform Calculation on Partition By in previous query
--Shows the geological and age distribuition of homicides

Drop Table if exists #MurdererAgeDistribuition
Create Table #MurdererAgeDistribuition
(
	[Area name] nvarchar(255),
	[Age Group] nvarchar(255),
	[No. Murderers] int
)
Insert into #MurdererAgeDistribuition
Select PopSize.[Area name], Killing.[Age Group], Count(*) as [No. Murderers]
From Borough_Population_Size PopSize
Join Homicide_Greater_London Killing
	On PopSize.[Area name] = Killing.Borough
Group by Killing.[Age Group], PopSize.[Area name]
Select *
From #MurdererAgeDistribuition


--Creating View to store data for visualization
--Creates View for the murder rate in each borough

Create View BoroughMurder As 
Select [Area name], [All persons], [Total Murderers], ([Total Murderers]/[All persons])*100 As [Killed Chance]
, Sum([Total Murderers]) Over (Order by [Total Murderers] Desc) As [London Murder Count]
From   Borough_Population_Size
Where [Area name] is not null And [Area name] Not In ('London', 'Inner London', 'Outer London')


--Creates View for Age distribuition in percentage for all the murderers in 2021

Create View MurdererAgeDistribPercent As
With YoungKillerPercent ([Murderer Age Group], [No. Murderers])
As
(
Select Killing.[Age Group], Count(*) as [No. Murderers]
From Borough_Population_Size PopSize
Join Homicide_Greater_London Killing
	On PopSize.[Area name] = Killing.Borough
Group by Killing.[Age Group]
)
Select *, (Cast([No. Murderers] As float)/(Select Sum([No. Murderers]) From YoungKillerPercent)) * 100 As [Murderer Percentage]
From YoungKillerPercent


--Creates View for Age distribuition for all the murderers in 2021

Create View MurderersAgeDestrib As
Select Killing.[Age Group], Count(*) as [No. Murderers]
From Borough_Population_Size PopSize
Join Homicide_Greater_London Killing
	On PopSize.[Area name] = Killing.Borough
Group by Killing.[Age Group]


--Creates View for Age and Borough distribuition for all the murderers in 2021
--Instead of temp table, created a permanent table

Create View MurderersAgeGeoDistrib As
Select *
From MurdererAgeDistribuition

--Creates View for the Age and Date relationship of the homicides

Create View MurdererAgeDateDistrib As
With KillingDates ([Month of Murder], [Murderer Age Group], [No. Murderers])
As
(
	Select Killing.[Proceedings Date], Killing.[Age Group], Count(*) as [No. Murderers]
	From Borough_Population_Size PopSize
	Join Homicide_Greater_London Killing
		On PopSize.[Area name] = Killing.Borough
	Group by Killing.[Age Group], Killing.[Proceedings Date]
)
Select *
From KillingDates


--Creates View for the chance of meeting a murderer in Greater London

Create View MurderPercentLondon As
With MurderPercentLondon ([Area name], [Total Population], [Total Murderers])
As
(
	Select [Area name], [All persons], Sum([Total Murderers]) Over () As [Total Murderers]
	From   Borough_Population_Size
)
Select *, ([Total Murderers]/[Total Population]) * 100 As [Chance of Murder]
From MurderPercentLondon
Where [Area name] = 'London'
