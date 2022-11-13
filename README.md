# NashvileDataCleaningWithSql
Nashville Housing Data:
About Dataset
Context
This is home value data for the hot Nashville market.
Content
There are 56,000+ rows altogether. However, I'm missing home detail data for about half. So if anyone wants to track that down then go for it! I'll be looking in the meantime. Enjoy.

Purpose:
The purpose of these project is to clean the dataset using SQL.
Steps of cleaning process:
1.	Standardize Date format.
Problem: 
In the process, we try to clean the date column from date time format.
Solution:
there is 4 ways to convert date format:
1. Convert, CONVERT (Date, SaleDate)
2. Cast, CAST(Sale Date AS date)
3. Substring, SUBSTRING (SaleDate,0,10)
4. Try Convert,
--a.
 Select SaleDate
		from NashvillaDataset..Nashvile
--b.
	Alter Table Nashvile
		Add SaleDateConverted Date;

--c.
	Update NashvillaDataset..Nashvile
		Set SaleDateConverted = CAST(SaleDate AS date)
--d.
	Select SaleDateConverted
		from NashvillaDataset..Nashvile


2.	Populate Property Address Data:
Problem:
There is some null value for Property Address.
Solution:
-- 1. check if there is some null values
-- 2. Find out that, there is some ParcelID and Property Address where can't exist ParcelId without PropertyAddress
--3.  Also whenever having same ParcelID, you will find same Propertyaddress.
Select PropertyAddress
from NashvillaDataset..Nashvile
 --Where PropertyAddress is null
 --Order By ParcelID
--4.  Here we will do Self join to fill the null values of Property Address 

Select a.PropertyAddress, a.ParcelID, b.PropertyAddress, b.ParcelID
from NashvillaDataset..Nashvile a
	Join NashvillaDataset..Nashvile b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ] 
	
	--a.PropertyAddress = b.PropertyAddress
	Where a.PropertyAddress is null


	--5.  Now, we will populate  to add property address who had same parcel ID with ISNULL function

Select a.PropertyAddress, a.ParcelID, b.PropertyAddress, b.ParcelID, ISNULL(a.PropertyAddress,b.PropertyAddress)
from NashvillaDataset..Nashvile a
	Join NashvillaDataset..Nashvile b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
Where a.PropertyAddress is null

	--6.  In previous code we created new column with all property address exist.
	-- in next code we update  empty cell
Update a
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from NashvillaDataset..Nashvile a
	Join NashvillaDataset..Nashvile b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
	Where a.PropertyAddress is null 
3.	Breaking out Address into individual columns (Address, city, state).

Problem:
	The Full address in one column, and we need to separate all.
Solution:
a)	We will check for special charater inside the code like ‘,’.
b)	We will use substring Clause and Charindex function to separate the address line.
c)	We can’t separate two value from one column without creating two other column.
d)	We have created two columns PropertySplitAddress, and PropertySplitCity as follow.

ALTER TABLE NashvillaDataset..Nashvile
		Add PropertySplitAddress NVARCHAR(255);

		Update NashvillaDataset..Nashvile
		SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

			ALTER TABLE NashvillaDataset..Nashvile
		Add PropertySplitCity NVARCHAR(255);

		Update NashvillaDataset..Nashvile
		SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

After all when we check our original table, we will see two new columns at the end.
SELECT *
	From NashvillaDataset..Nashvile

•	ALTERNATIVE way to split the column:
	By Using ParseName Clause, and Replace Function
As follow for Owner Property column:
	ALTER TABLE NashvillaDataset..Nashvile
	ADD OwnerSplitCity NVARCHAR(255);

	Update NashvillaDataset..Nashvile
	SET OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',' , '.'),2)


	ALTER TABLE NashvillaDataset..Nashvile
	ADD OwnerSplitAddress NVARCHAR(255);

	Update NashvillaDataset..Nashvile
	SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',' , '.'),3)


	ALTER TABLE NashvillaDataset..Nashvile
	ADD OwnerSplitState NVARCHAR(255);

	Update NashvillaDataset..Nashvile
	SET OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',' , '.'),1)
 
 

4.	Change Y and N to Yes and NO in “SoldAsVacant” field.
Problem :
We have 4 answers in SoldAsVacant for Y,Yes,N, and No.
Solution:
We will have only 2 instead of 4 by using Cas When Clause, and then Update

Update NashvillaDataset..Nashvile
	SET SoldAsVacant = case When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'NO'
		Else SoldAsVacant
		END
5.	Remove Duplicates
Usually, remove duplicate is not the best practice for SQl, you will have to create temp table and then 
start to pull the data you want.
Here we are going to use Partition method and CTE
There is some functions under Partition by (rank, order rank, row number, and more)

	Select *,
		ROW_NUMBER()OVER (
			Partition By
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			Order By 
				uniqueID
					) row_num
	From NashvillaDataset..Nashvile
	Order by ParcelID  

Let's create CTE to check for duplicate

	WITH RowNumberCte AS 
	(	Select *,
		ROW_NUMBER()OVER (
			Partition By
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			Order By 
				uniqueID
					) row_num
	From NashvillaDataset..Nashvile
	--Order by ParcelID 
	)
	Select *
	From RowNumberCte
	Where row_num>1
	Order by PropertyAddress

Now we will do deleting, by simply replace select from previous code to Delete

	WITH RowNumberCte AS 
	(	Select *,
		ROW_NUMBER()OVER (
			Partition By
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			Order By 
				uniqueID
					) row_num
	From NashvillaDataset..Nashvile
	--Order by ParcelID 
	)
	Delete
	From RowNumberCte
	Where row_num>1
	--Order by PropertyAddress

Now let's check for duplication

		WITH RowNumberCte AS 
	(	Select *,
		ROW_NUMBER()OVER (
			Partition By
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			Order By 
				uniqueID
					) row_num
	From NashvillaDataset..Nashvile
	--Order by ParcelID 
	)
	Select *
	From RowNumberCte
	Where row_num>1
	Order by PropertyAddress

Now there are no duplicates.
 
6.	Deleted unused Columns

Highly Precautions Note: Before you delete any column, ask to your supervisor.
We will just delete unused column by using Alter Table clause with Drop Column Function.

Select *
From NashvillaDataset..Nashvile


ALTER TABLE NashvillaDataset..Nashvile
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
