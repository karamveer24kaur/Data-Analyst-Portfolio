/*
Cleaning Data in SQL Queries
*/

select * 
from NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------------------------

-- I.) Standardize Date Format

-- check what really we want to change and how we want it
-- a.)
select SaleDateConverted, CONVERT(Date, SaleDate)
from NashvilleHousing

-- update the table and set the column to the new value in the table
UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- the above query did not change the values of the existing table by the name SaleDate
-- lets try to make a new column and set converted values in it

-- 1.) new column made
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

-- 2.) update the values in here
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- 3.) check in a to see the changes
--------------------------------------------------------------------------------------------------------------------------------------------

-- II.) Populate Property Address data
select *
from NashvilleHousing
--where PropertyAddress is null
order by ParcelID

-- we encounter duplicate parcel ids in the parcelID column
-- we can use self join to check wherever the parcel ids match and the address is null, to add the data from the complete table
-- to populate the row with null values ISNULL is used 
-- syntax = ISNULL(column_to_be_checked_for_null_values, value_to_populate_null_values)
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- Let's update the values now, don't use table name, use any one of the alias, or it will give an error
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------------------------------

-- III.) Breaking out Address into individual columns (Address, City, State)

select PropertyAddress
from NashvilleHousing
-- we will be using substring and charecter index 

select 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
from NashvilleHousing

-- we cannot separate two values from one column without creating two new columns, using ALTER
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

select *
from NashvilleHousing

-- now for the owner address, delimiter = anything separating two values, here it is ','
-- here we use parsname instead of substrings
select OwnerAddress
from NashvilleHousing

-- this does nothing because parsname only detects period '.' and not ','
-- we can replace all the ',' with period
-- parsname works backwards, hence instead of using 1, 2, 3 use 3, 2 ,1 == separated values successfully
select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
from NashvilleHousing

-- now we just need to add columns to add these values in them
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

select *
from NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------

-- IV.) Changing Y and N to Yes and No in "Sold as Vacant" Field

select DISTINCT(SoldAsVacant), count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant
order by 2

-- to make the chnages we are going to use the case statements here
select SoldAsVacant
, CASE when SoldAsVacant = 'Y' THEN 'Yes'
       when SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
  END
from NashvilleHousing

-- lets make the update
update NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' THEN 'Yes'
       when SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
  END

--------------------------------------------------------------------------------------------------------------------------------------------

-- V.) Remove the Duplicates
-- we will use CTE and use windows function to find out duplicate values like ROW_NUMBER

with rownumCTE AS(
select *, 
   ROW_NUMBER() OVER(
   PARTITION BY ParcelID,
                PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
				UniqueID
				) row_num
from NashvilleHousing
--order by ParcelID
)
select *
from rownumCTE
where row_num > 1
--order by PropertyAddress

--------------------------------------------------------------------------------------------------------------------------------------------

-- VI.) Deleting all the unused columns

select *
from NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate