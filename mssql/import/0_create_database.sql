USE master;
GO
IF DB_ID (N'eTest') IS NOT NULL
DROP DATABASE eTest;
GO
CREATE DATABASE eTest;
GO