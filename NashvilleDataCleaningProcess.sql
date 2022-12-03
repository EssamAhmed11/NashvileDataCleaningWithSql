

/* Here is the cleaning data processing for DataSet called Nashville, and in this dataset we are going to use
sql queries to optimize the data */

-- 1. select all table

Select *
from NashvillaDataset..Nashvile

-------------------------------------------------------------------------
-- I. Standardize Date Format---------------------------------------
-------------------------------------------------------------------------
-- there is 4 ways to convert date format :
-- 1. Convert, CONVERT(Date, SaleDate)
-- 2. Cast , CAST(SaleDate AS date)
-- 3. Subtring, SUBSTRING(SaleDate,0,10)
-- 4. Try Convert, 


-- to use update method won't be effected as this method.

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



-------------------------------------------------------------------------
--II. Populate Property Address Data-----
-------------------------------------------------------------------------

-- 1. check if there is some null values
-- Find out that, there is some ParcelID and Property Address where can't exist ParcelId without PropertyAddress
-- Also whenever having same ParcelID, you will find same Propertyaddress.

Select PropertyAddress
from NashvillaDataset..Nashvile
 --Where PropertyAddress is null
 --Order By ParcelID


 -- Here we will do Self join to fill the null values of Property Address 

Select a.PropertyAddress, a.ParcelID, b.PropertyAddress, b.ParcelID
from NashvillaDataset..Nashvile a
	Join NashvillaDataset..Nashvile b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ] 
	
	--a.PropertyAddress = b.PropertyAddress
	Where a.PropertyAddress is null


	-- Now, we will populate  to add property address who had same parcel ID with ISNULL function

Select a.PropertyAddress, a.ParcelID, b.PropertyAddress, b.ParcelID, ISNULL(a.PropertyAddress,b.PropertyAddress)
from NashvillaDataset..Nashvile a
	Join NashvillaDataset..Nashvile b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
Where a.PropertyAddress is null

	-- In previous code we created new column with all property address exist.
	-- in next code we update  empty cell
Update a
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from NashvillaDataset..Nashvile a
	Join NashvillaDataset..Nashvile b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
	Where a.PropertyAddress is null

	----------------------------------------------------------------------------
	--III. Breaking out Address into individual columns (Address, city, state)--------
	-------------------------------------------------------------------------------
	---------------------------------------
	--------Property Address --------------
	---------------------------------------
	-- in this piece of code we are going to use Substring Clause, But in addition that CHARINDEX And LEN

	Select  SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address, 
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as city
	From NashvillaDataset..Nashvile

	-- As long as I can't separate the column from the table, 
	-- I usually use "Alter Table Clause" then "Update Clause".
	-- we can't separate two values from one column without creating two other columns.

	Select  SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address, 
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as city
	From NashvillaDataset..Nashvile

	ALTER TABLE NashvillaDataset..Nashvile
		Add PropertySplitAddress NVARCHAR(255);

		Update NashvillaDataset..Nashvile
		SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

			ALTER TABLE NashvillaDataset..Nashvile
		Add PropertySplitCity NVARCHAR(255);

		Update NashvillaDataset..Nashvile
		SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))


		SELECT *
			From NashvillaDataset..Nashvile


	---------------------------------------
	--------Owner Address --------------
	---------------------------------------
	----using parse name----------
	------------------------------

	Select PARSENAME(Replace(OwnerAddress, ',' , '.'),3),
	PARSENAME(Replace(OwnerAddress, ',' , '.'),2),
	PARSENAME(Replace(OwnerAddress, ',' , '.'),1)
	From NashvillaDataset..Nashvile

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

	----------------------------------------------------------------------------
	--VI. Change Y and N to Yes and NO in “sold as vacant” field--------
	-------------------------------------------------------------------------------

	Select Distinct SoldAsVacant, count (SoldAsVacant)
	From NashvillaDataset..Nashvile
	Group by SoldAsVacant
	order by 2


	Select SoldAsVacant,
	case When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'NO'
		Else SoldAsVacant
		END
	From NashvillaDataset..Nashvile

	Update NashvillaDataset..Nashvile
	SET SoldAsVacant = case When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'NO'
		Else SoldAsVacant
		END

-------------------------------------------------------------------------------
	--V. Remove Duplicates--------------------------------------------
	-------------------------------------------------------------------------------

	Select *
	From NashvillaDataset..Nashvile

	-- Usually, remove duplicate is not the best practice for SQl, you will have to create temp table and then 
	-- start to pull the data you want.
	-- Here we are going to use Partition method and CTE
	-- There is some functions under Partition by (rank, order rank, row number, and more)

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

	--Let's create CTE to check for dulplicate

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

	-- Now we will do deleting, by simply replace select from previous code to Delete

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

	--Now let's check for duplication

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

	--Now there are no duplicates.


-------------------------------------------------------------------------------
--VI. Deleted unused columns--------------------------------------------
-------------------------------------------------------------------------------

-- Highly Precautions Note: Before you delete any column, ask to your supervisor

Select *
From NashvillaDataset..Nashvile


ALTER TABLE NashvillaDataset..Nashvile
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate