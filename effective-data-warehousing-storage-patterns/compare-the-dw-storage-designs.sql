/******************************************************
 *
 * Name:         compare-the-dw-storage-design.sql
 *     
 * Design Phase:
 *     Author:   John Miner
 *     Date:     03-01-2013
 *     Blog:     www.craftydba.com
 *
 *     Purpose:  What is the i/o between designs using
 *               the worst case scenerio, a full
 *               table scan?
 *
 ******************************************************/


-- ~~~~~~~~~~~~~~~~~
--  FULL TABLE SCAN
-- ~~~~~~~~~~~~~~~~~


--
-- 1 - Database warehouse (one big file)
--

-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BIG_JONS_BBQ_DW]
GO

-- Query the table
SELECT *
FROM [FACT].[CUSTOMERS]
WHERE cus_qtr_key = '2011002' AND cus_state = 'DC';
GO


/*


(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 12715, physical reads 3, read-ahead reads 12692, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 874 ms,  elapsed time = 2042 ms.

*/



--
-- 2 - Database sharding - try 1
--

-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BBQ_SHARD_2011002]
GO

-- Query the table
SELECT *
FROM [FACT].[CUSTOMERS]
WHERE cus_qtr_key = '2011002' AND cus_state = 'DC';
GO

/*


(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 1601, physical reads 3, read-ahead reads 1581, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 390 ms,  elapsed time = 574 ms.

*/


--
-- 3 - Database sharding - try 2
--

-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BBQ_SHARD_2011002]
GO

-- Query the table
SELECT *
FROM [FACT].[CUSTOMERS]
WHERE cus_state = 'DC';
GO

/*

(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 1601, physical reads 3, read-ahead reads 1581, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 421 ms,  elapsed time = 846 ms.

*/


--
-- 4 - Partitioned View
--

-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Query the table
SELECT *
FROM [BBQ_PART_VIEW].[FACT].[CUSTOMERS]
WHERE cus_qtr_key = '2011002' AND cus_state = 'DC';
GO

/*

(6485 row(s) affected)
Table 'CUSTOMERS_2011002'. Scan count 1, logical reads 1666, physical reads 2, read-ahead reads 1650, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 47 ms,  elapsed time = 325 ms.

*/


--
-- 5 - Table Partitions
--

-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Query the table
SELECT *
FROM [BBQ_TABLE_PART].[FACT].[CUSTOMERS]
WHERE cus_qtr_key = '2011002' AND cus_state = 'DC';
GO

/*

(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 1225, physical reads 2, read-ahead reads 1209, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 78 ms,  elapsed time = 289 ms.

*/




-- ~~~~~~~~~~~~~~~~~
--  ADD AN INDEX
-- ~~~~~~~~~~~~~~~~~

--
-- A - Database warehouse (one big file)
--

-- Select the correct database
USE [BIG_JONS_BBQ_DW]
GO

-- Delete existing index
IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_CUSTOMER_QRY1')
    DROP INDEX [IX_CUSTOMER_QRY1] ON [FACT].[CUSTOMERS]
GO

-- Create a index on where criteria
CREATE NONCLUSTERED INDEX [IX_CUSTOMER_QRY1]
ON [FACT].[CUSTOMERS] ([cus_start_date_key], [cus_state])
GO

-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BIG_JONS_BBQ_DW]
GO

-- Query the table (skip cus_qtr_key since skews results)
SELECT 
    [cus_id]
   ,[cus_lname]
   ,[cus_fname]
   ,[cus_phone]
   ,[cus_address]
   ,[cus_city]
   ,[cus_state]
   ,[cus_zip]
   ,[cus_package_key]
   ,[cus_start_date_key]
   ,[cus_end_date_key]
   ,[cus_date_str]
FROM 
    [FACT].[CUSTOMERS] C
WHERE 
    [cus_start_date_key] >= 91 AND 
	[cus_start_date_key] <= 181 AND 
    [cus_state] = 'DC'
OPTION (TABLE HINT ( c, INDEX( IX_CUSTOMER_QRY1 ) ) )
GO

-- Without hint

/*

(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 27984, physical reads 55, read-ahead reads 12340, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 156 ms,  elapsed time = 5185 ms.

*/


-- With hint

/*

(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 27984, physical reads 55, read-ahead reads 12340, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 249 ms,  elapsed time = 4946 ms.


*/


--
-- B - Database sharding 
--

-- Select the correct database
USE [BBQ_SHARD_2011002]
GO

-- Delete existing index
IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_CUSTOMER_QRY1')
    DROP INDEX [IX_CUSTOMER_QRY1] ON [FACT].[CUSTOMERS]
GO

-- Create a index on where criteria
CREATE NONCLUSTERED INDEX [IX_CUSTOMER_QRY1]
ON [FACT].[CUSTOMERS] ([cus_start_date_key], [cus_state])
GO


-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BBQ_SHARD_2011002]
GO

-- Query the table (skip cus_qtr_key since skews results)
SELECT 
    [cus_id]
   ,[cus_lname]
   ,[cus_fname]
   ,[cus_phone]
   ,[cus_address]
   ,[cus_city]
   ,[cus_state]
   ,[cus_zip]
   ,[cus_package_key]
   ,[cus_start_date_key]
   ,[cus_end_date_key]
   ,[cus_date_str]
FROM 
    [FACT].[CUSTOMERS]
WHERE 
    [cus_start_date_key] >= 91 AND 
	[cus_start_date_key] <= 181 AND 
    [cus_state] = 'DC';
GO

/*

(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 1601, physical reads 3, read-ahead reads 1581, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 94 ms,  elapsed time = 329 ms.

*/


--
-- C - Partitioned View - try 1
--

-- Select the correct database
USE [BBQ_PART_VIEW]
GO

-- Delete existing index
IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_CUSTOMER_QRY2')
    DROP INDEX [IX_CUSTOMER_QRY2] ON [FACT].[CUSTOMERS_2011002]
GO

-- Create a index on where criteria
CREATE NONCLUSTERED INDEX [IX_CUSTOMER_QRY2]
ON [FACT].[CUSTOMERS_2011002] ([cus_start_date_key], [cus_state])
GO


-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BBQ_PART_VIEW]
GO

-- Query the table (skip cus_qtr_key since skews results)
SELECT 
    [cus_id]
   ,[cus_lname]
   ,[cus_fname]
   ,[cus_phone]
   ,[cus_address]
   ,[cus_city]
   ,[cus_state]
   ,[cus_zip]
   ,[cus_package_key]
   ,[cus_start_date_key]
   ,[cus_end_date_key]
   ,[cus_date_str]
FROM 
    [FACT].[CUSTOMERS]
WHERE 
    [cus_qtr_key] = '2011002' AND 
    [cus_start_date_key] >= 91 AND 
	[cus_start_date_key] <= 181 AND 
    [cus_state] = 'DC';
GO

-- Can not get optimizer to use extra index

/*

(6485 row(s) affected)
Table 'CUSTOMERS_2011002'. Scan count 1, logical reads 1666, physical reads 2, read-ahead reads 1650, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 15 ms,  elapsed time = 390 ms.

*/


--
-- C - Partitioned View - try 2
--

-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BBQ_PART_VIEW]
GO

-- Query the table (skip cus_qtr_key since skews results)
SELECT 
    [cus_id]
   ,[cus_lname]
   ,[cus_fname]
   ,[cus_phone]
   ,[cus_address]
   ,[cus_city]
   ,[cus_state]
   ,[cus_zip]
   ,[cus_package_key]
   ,[cus_start_date_key]
   ,[cus_end_date_key]
   ,[cus_date_str]
FROM 
    [FACT].[CUSTOMERS_2011002] c
WHERE 
    [cus_start_date_key] >= 91 AND 
	[cus_start_date_key] <= 181 AND 
    [cus_state] = 'DC'
OPTION (TABLE HINT ( c, INDEX( IX_CUSTOMER_QRY2 ) ) )
GO

-- No improvement using table directly

/* 

(6485 row(s) affected)
Table 'CUSTOMERS_2011002'. Scan count 1, logical reads 1666, physical reads 2, read-ahead reads 1650, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 46 ms,  elapsed time = 333 ms.

*/

-- Forcing index uses both clustered and non-clustered index

/*

SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 54 ms.

(6485 row(s) affected)
Table 'CUSTOMERS_2011002'. Scan count 1, logical reads 32583, physical reads 2, read-ahead reads 1677, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 78 ms,  elapsed time = 342 ms.


*/


--
-- 5 - Table Partitions
--

-- Select the correct database
USE [BBQ_TABLE_PART]
GO

-- Delete existing index
IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_CUSTOMER_PART_QRY')
    DROP INDEX [IX_CUSTOMER_PART_QRY] ON [FACT].[CUSTOMERS]
GO

-- Create a index on where criteria
CREATE NONCLUSTERED INDEX [IX_CUSTOMER_PART_QRY]
  ON [FACT].[CUSTOMERS] ([cus_state], [cus_qtr_key])
  ON PS_HASH_BY_QTR ([cus_qtr_key])
GO


-- Remove clean buffers & clear plan cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

-- Show time & i/o
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

-- Select the correct database
USE [BBQ_TABLE_PART]
GO

-- Query the table
SELECT *
FROM [FACT].[CUSTOMERS] c
WHERE 
    cus_qtr_key = '2011002' AND 
	cus_state = 'DC'
OPTION (TABLE HINT ( c, INDEX( IX_CUSTOMER_PART_QRY ) ) )
GO

/*


SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 17 ms.

(6485 row(s) affected)
Table 'CUSTOMERS'. Scan count 1, logical reads 24960, physical reads 87, read-ahead reads 557, 
lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 47 ms,  elapsed time = 265 ms.

*/