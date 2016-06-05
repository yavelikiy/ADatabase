DECLARE @cursor CURSOR
DECLARE @session INT
DECLARE @query VARCHAR(500)

SET @cursor = CURSOR FOR
	SELECT spid FROM master..sysprocesses
		WHERE dbid=db_id('!dbName!')	
OPEN @cursor
FETCH @cursor INTO @session
WHILE @@FETCH_STATUS=0
BEGIN
	SET @query='kill '+CONVERT(VARCHAR,@session)
	EXEC(@query)	
FETCH @cursor INTO @session
END

GO
DROP DATABASE [!dbName!]