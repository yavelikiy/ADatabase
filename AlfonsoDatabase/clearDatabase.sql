ALTER DATABASE AlfonsoDatabase
	SET RECOVERY SIMPLE DBCC SHRINKFILE('AlfonsoDatabase_log',0,TRUNCATEONLY)
GO