CREATE FUNCTION UPCASE
(
  @input nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
	IF @input IS NULL 
	BEGIN
		RETURN NULL
	END
	
	DECLARE @output nvarchar(max)
	DECLARE @ctr int, @len int, @found_at int
	DECLARE @LOWER_CASE_a int, @LOWER_CASE_z int, @Delimiter char(3), @UPPER_CASE_A int, @UPPER_CASE_Z int
	DECLARE @RU_LOWER_CASE_a int, @RU_LOWER_CASE_z int, @RU_UPPER_CASE_A int, @RU_UPPER_CASE_Z int
	
	SET @ctr = 1
	SET @len = LEN(@input)
	SET @output = ''
	
	-- для английских букв
	SET @LOWER_CASE_a = 97
	SET @LOWER_CASE_z = 122
	SET @Delimiter = ' ,-'
	SET @UPPER_CASE_A = 65
	SET @UPPER_CASE_Z = 90

  -- для русских букв
	SET @RU_LOWER_CASE_a = 224
	SET @RU_LOWER_CASE_z = 255
	SET @RU_UPPER_CASE_A = 192
	SET @RU_UPPER_CASE_Z = 223

	WHILE @ctr <= @len
	BEGIN
		IF (ASCII(SUBSTRING(@input,@ctr,1)) BETWEEN @LOWER_CASE_a AND @LOWER_CASE_z) OR 
		   (ASCII(SUBSTRING(@input,@ctr,1)) BETWEEN @RU_LOWER_CASE_a AND @RU_LOWER_CASE_z) OR
		   (ASCII(SUBSTRING(@input,@ctr,1)) BETWEEN @UPPER_CASE_A AND @UPPER_CASE_Z) OR
		   (ASCII(SUBSTRING(@input,@ctr,1)) BETWEEN @RU_UPPER_CASE_A AND @RU_UPPER_CASE_Z)
		BEGIN
			SET @output = @output + SUBSTRING(@input,@ctr,1)
			SET @output = UPPER(@output)
			SET @output = @output + SUBSTRING(@input,@ctr+1,@len-@ctr+1)
			SET @ctr = @len + 1	
		END
		ELSE
		BEGIN
			SET @output = @output + SUBSTRING(@input,@ctr,1)
		END	
		SET @ctr = @ctr + 1	
	END
	RETURN @output
END
GO


CREATE FUNCTION [types items]
(@type VARCHAR(20), @portion INT)
RETURNS VARCHAR(20)
AS
BEGIN
    IF @type = 'di' RETURN 'шт'
    IF @type = 'dp' RETURN portion || 'г'
    IF @type = 'fi' RETURN 'шт'
    IF @type = 'fp' RETURN portion || 'г'
    RETURN 'г'
END
GO

CREATE PROCEDURE [Стоимость по блюдамView]
(@condition VARCHAR(500))
AS
BEGIN
	SET @condition = REPLACE(@condition, 'WHERE', 'AND')	
	DECLARE @script NVARCHAR(max);

	CREATE TABLE #res(
		[Тип] VARCHAR(20),
		[Порядок] INT,
		[Русское название] VARCHAR(80),
		[Количество] INT,
		[БЕИ] VARCHAR(20),
		[Стоимость] MONEY,
	)

	SET @script=N'
	INSERT INTO #res
	SELECT ''Блюда'' AS [Тип],[Типы блюд].[Порядок],[Блюда].[Русское название] AS [Название], 
			SUM([Заказы блюд].[Количество]) AS [Количество], 
			dbo.[БЕИ СИ блюда]([Заказы блюд].[Вес]) AS [БЕИ],
			SUM([Заказы блюд].[Стоимость])
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
				   INNER JOIN [Счета посетителей] ON [Заказы блюд].[id счёта посетителей]  = [Счета посетителей].[id]
				   INNER JOIN [Типы блюд] ON [Блюда].[id типа блюда] = [Типы блюд].[id]
		WHERE [Заказы блюд].[Время отмены] IS NULL AND [Заказы блюд].[Вес] = ''1шт'' ' + @condition + '
		GROUP BY [Типы блюд].[Порядок],[Блюда].[Русское название], [Блюда].[Стоимость],[Заказы блюд].[Вес]
	UNION ALL		
	SELECT ''Блюда'' AS [Тип],[Типы блюд].[Порядок],[Блюда].[Русское название] AS [Название], 
			SUM(CAST([Заказы блюд].[Вес] AS INT)) AS [Количество], 
			dbo.[БЕИ СИ блюда]([Заказы блюд].[Вес]),
			SUM([Заказы блюд].[Стоимость]) 
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
				   INNER JOIN [Счета посетителей] ON [Заказы блюд].[id счёта посетителей]  = [Счета посетителей].[id]
				   INNER JOIN [Типы блюд] ON [Блюда].[id типа блюда] = [Типы блюд].[id]
		WHERE [Заказы блюд].[Время отмены] IS NULL AND [Заказы блюд].[Вес] <> ''1шт'' ' + @condition + '
		GROUP BY [Типы блюд].[Порядок],[Блюда].[Русское название], [Блюда].[Стоимость], dbo.[БЕИ СИ блюда]([Заказы блюд].[Вес])'
	EXECUTE sp_executesql @script
		
		
	SET @script=N'
	INSERT INTO #res
	SELECT ''Ланч блюда'' AS [Тип],1000000 AS [Порядок],[Ланч блюда].[Русское название] AS [Название], 
			SUM([Заказы ланч блюд].[Количество]) AS [Количество], 
			dbo.[БЕИ СИ блюда]([Заказы ланч блюд].[Вес]),
			SUM([Заказы ланч блюд].[Стоимость])
		FROM [Заказы ланч блюд] INNER JOIN [Ланч блюда] ON [Заказы ланч блюд].[id ланч блюда] = [Ланч блюда].[id]
			        INNER JOIN [Счета посетителей] ON [Заказы ланч блюд].[id счёта посетителей]  = [Счета посетителей].[id]
		WHERE [Заказы ланч блюд].[Время отмены] IS NULL AND [Заказы ланч блюд].[Вес] = ''1шт'' ' + @condition + '
		GROUP BY [Ланч блюда].[Русское название],[Ланч блюда].[Стоимость],[Заказы ланч блюд].[Вес]
	UNION ALL
	SELECT ''Ланч блюда'' AS [Тип],1000000 AS [Порядок],[Ланч блюда].[Русское название] AS [Название], 
			SUM(CAST([Заказы ланч блюд].[Вес] AS INT)) AS [Количество], 
			dbo.[БЕИ СИ блюда]([Заказы ланч блюд].[Вес]),
			SUM([Заказы ланч блюд].[Стоимость])
		FROM [Заказы ланч блюд] INNER JOIN [Ланч блюда] ON [Заказы ланч блюд].[id ланч блюда] = [Ланч блюда].[id]
				        INNER JOIN [Счета посетителей] ON [Заказы ланч блюд].[id счёта посетителей]  = [Счета посетителей].[id]
		WHERE [Заказы ланч блюд].[Время отмены] IS NULL AND [Заказы ланч блюд].[Вес] <> ''1шт'' ' + @condition + '
		GROUP BY [Ланч блюда].[Русское название],[Ланч блюда].[Стоимость],dbo.[БЕИ СИ блюда]([Заказы ланч блюд].[Вес])
	UNION ALL		
	SELECT ''Спецблюда''  AS [Тип],1000001 AS [Порядок],[Заказы спецблюд].[Русское название] AS [Название], 
			SUM([Заказы спецблюд].[Количество]) AS [Количество], 
			''шт'',
			SUM([Заказы спецблюд].[Стоимость]*[Заказы спецблюд].[Количество])
		FROM [Заказы спецблюд] INNER JOIN [Счета посетителей] ON [Заказы спецблюд].[id счёта посетителей]  = [Счета посетителей].[id]
		WHERE [Заказы спецблюд].[Время отмены] IS NULL ' + @condition + '
		GROUP BY [Заказы спецблюд].[Русское название],[Заказы спецблюд].[Стоимость]'
	EXECUTE sp_executesql @script


	SET @script=N'
	INSERT INTO #res
	SELECT ''Напитки'',[Типы напитков].[Порядок],[Напитки].[Русское название] AS [Название], 
				SUM([Заказы напитков].[Количество]) AS [Количество], 
				dbo.[БЕИ СИ напитка]([Заказы напитков].[Объём]),
				SUM([Заказы напитков].[Стоимость])
		FROM [Заказы напитков] INNER JOIN [Напитки] ON [Заказы напитков].[id напитка] = [Напитки].[id]
								INNER JOIN [Счета посетителей] ON [Заказы напитков].[id счёта посетителей]  = [Счета посетителей].[id]
								INNER JOIN [Типы напитков] ON [Напитки].[id типа напитка] = [типы напитков].[id]
		WHERE [Заказы напитков].[Время отмены] IS NULL ' + @condition + ' AND ([Заказы напитков].[Объём] = ''1бут'' OR [Заказы напитков].[Объём]= ''1шт'')
		GROUP BY [Типы напитков].[Порядок],[Напитки].[Русское название], [Напитки].[Стоимость], [Заказы напитков].[Объём]
	UNION ALL
	SELECT ''Напитки'',[Типы напитков].[Порядок],[Напитки].[Русское название] AS [Название], 
				SUM( dbo.[БЕИ объём напитка]([Заказы напитков].[Объём],[Заказы напитков].[Количество порций]) * [Заказы напитков].[Количество] ) AS [Количество], 
				dbo.[БЕИ СИ напитка]([Заказы напитков].[Объём]),
				SUM([Заказы напитков].[Стоимость])
		FROM [Заказы напитков] INNER JOIN [Напитки] ON [Заказы напитков].[id напитка] = [Напитки].[id]
								INNER JOIN [Счета посетителей] ON [Заказы напитков].[id счёта посетителей]  = [Счета посетителей].[id]
								INNER JOIN [Типы напитков] ON [Напитки].[id типа напитка] = [типы напитков].[id]
		WHERE [Заказы напитков].[Время отмены] IS NULL ' + @condition + ' AND ([Заказы напитков].[Объём] = ''50'' OR [Заказы напитков].[Объём] = ''100'')
		GROUP BY [Типы напитков].[Порядок],[Напитки].[Русское название], [Напитки].[Стоимость], dbo.[БЕИ СИ напитка]([Заказы напитков].[Объём])'
	EXECUTE sp_executesql @script
	
	
	SET @script=N'
	SELECT * FROM #res ORDER BY [Тип],[Порядок]'
	EXECUTE sp_executesql @script
END
GO


CREATE PROCEDURE [Стоимость по счетамView]
(@condition VARCHAR(1000))
AS
BEGIN
	DECLARE @script NVARCHAR(max);

	SET @script=N'
	SELECT [Счета посетителей].[Номер счёта], 
		dbo.[Получить счёта стоимость без скидки]([Счета посетителей].[Номер счёта]) AS [Полная стоимость счёта],
		[Счета посетителей].[Скидка],
		dbo.[Получить счёта стоимость со скидкой]([Счета посетителей].[Номер счёта]) AS [Стоимость счёта со скидкой],
		[Счета посетителей].[Аванс]		
		FROM [Счета посетителей] ' + @condition;
	EXECUTE sp_executesql @script;
END
GO

CREATE PROCEDURE [Количество посетителейView]
(@condition VARCHAR(1000))
AS
BEGIN
	DECLARE @script NVARCHAR(max);

	SET @script=N'
	SELECT [Дата посещения],COUNT(*) AS [Количество посетителей]
		FROM [Счета посетителей]
		' + @condition + '	
		GROUP BY [Дата посещения]
		ORDER BY [Дата посещения]'
	EXECUTE sp_executesql @script;
END
GO

CREATE PROCEDURE [Популярность блюдView]
(@condition VARCHAR(1000))
AS
BEGIN
	DECLARE @script NVARCHAR(max);

	SET @script=N'
	SELECT 1 AS ''Порядок'', [Тип блюда], [Русское название] AS [Название блюда], SUM([Количество])
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
				   INNER JOIN [Типы блюд] ON [Блюда].[id типа блюда] = [Типы блюд].[id]
				   INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы блюд].[id счёта посетителей]
		' + @condition + '
		GROUP BY [Тип блюда], [Русское название]
	UNION ALL
	SELECT 2 AS ''Порядок'', [Тип ланч блюда] AS [Тип блюда], [Русское название] AS [Название блюда], SUM([Количество])
		FROM [Заказы ланч блюд] INNER JOIN [Ланч блюда] ON [Заказы ланч блюд].[id ланч блюда] = [Ланч блюда].[id]
				   INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы ланч блюд].[id счёта посетителей]
		' + @condition + '
		GROUP BY [Тип ланч блюда], [Русское название]
	ORDER BY [Порядок], [Тип блюда], [Название блюда]'
	EXECUTE sp_executesql @script;
END
GO

CREATE PROCEDURE [Популярность напитковView] 
(@condition VARCHAR(1000))
AS
BEGIN
	DECLARE @script NVARCHAR(max);

	SET @script=N'
	SELECT [Тип напитка], [Русское название] AS [Название напитка], SUM([Количество])
		FROM [Заказы напитков] INNER JOIN [Напитки] ON [Заказы напитков].[id напитка] = [Напитки].[id]
				   INNER JOIN [Типы напитков] ON [Напитки].[id типа напитка] = [Типы напитков].[id]
				   INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы напитков].[id счёта посетителей]
		'+ @condition + '
		GROUP BY [Тип напитка], [Русское название]
		ORDER BY [Тип напитка], [Русское название]'
	EXECUTE sp_executesql @script;
END
GO

CREATE PROCEDURE [Популярность ингредиентовView]
(@condition VARCHAR(1000))
AS
BEGIN
	DECLARE @script NVARCHAR(max);

	SET @script=N'
	SELECT [Добавить] AS [Добавили/Убрали],[Русское название] AS [Название блюда],[Название ингредиента],COUNT(*) AS [Количество]
		FROM [Изменение рецептов блюд] INNER JOIN [Заказы блюд] ON [Изменение рецептов блюд].[id заказа блюда] = [Заказы блюд].[id]
						  INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы блюд].[id счёта посетителей]
					      INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
					      INNER JOIN [Ингредиенты] ON [Изменение рецептов блюд].[id ингредиента] = [Ингредиенты].[id]
	' + @condition + '
	GROUP BY [Добавить],[Русское название],[Название ингредиента]
	ORDER BY [Русское название],[Название ингредиента],[Добавить],[Количество]'
	EXECUTE sp_executesql @script;
END
GO

CREATE PROCEDURE [Продуктивность официантовView]
(@condition VARCHAR(1000))
AS
BEGIN
	DECLARE @script NVARCHAR(max);

	SET @script=N'
	SELECT [ФИО] AS [Официант], COUNT(*) AS [Количество]
		FROM (
			SELECT [фио]
				FROM [Официанты]INNER JOIN [Заказы блюд] ON [Официанты].[id] = [Заказы блюд].[id официанта]
						INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы блюд].[id счёта посетителей] 
				' + @condition + '
				UNION ALL
				SELECT [фио]
					FROM [Официанты]INNER JOIN [Заказы напитков] ON [Официанты].[id] = [Заказы напитков].[id официанта]
							INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы напитков].[id счёта посетителей] 
				' + @condition + '
				UNION ALL
				SELECT [фио]
					FROM [Официанты] INNER JOIN [Заказы ланч блюд] ON [Официанты].[id] = [Заказы ланч блюд].[id официанта]
							INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы ланч блюд].[id счёта посетителей] 
				' + @condition + '
				)AS t 
		GROUP BY [фио]
		ORDER BY [ФИО]'
	EXECUTE sp_executesql @script;
END
GO

CREATE PROCEDURE [Использование скидокView]
(@condition VARCHAR(1000))
AS
BEGIN
	DECLARE @script NVARCHAR(max);
	SET @condition = REPLACE(@condition, 'WHERE', 'AND')	

	SET @script=N'
	SELECT [Скидка],SUM([Полная стоимость блюд с данной скидкой])AS [Полная стоимость блюд с данной скидкой],SUM([Оплаченная стоимость блюд с данной скидкой]) AS [Оплаченная стоимость блюд с данной скидкой],SUM(Разница) AS Разница
	FROM (
	SELECT [Скидка],
			SUM([Заказы блюд].[Стоимость]) AS [Полная стоимость блюд с данной скидкой],
			dbo.[Округление цены](SUM([Заказы блюд].[Стоимость])*((100-[скидка])/100.0))  AS [Оплаченная стоимость блюд с данной скидкой],
			SUM([Заказы блюд].[Стоимость]) - dbo.[Округление цены](SUM([Заказы блюд].[Стоимость])*((100-[скидка])/100.0)) AS Разница
	        FROM [Счета посетителей] INNER JOIN [Заказы блюд] ON [Счета посетителей].[id] = [Заказы блюд].[id счёта посетителей]
				        INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
				        INNER JOIN [Цеха] ON [Блюда].[id цеха] = [Цеха].[id]
		WHERE [скидка] IS NOT NULL AND [Заказы блюд].[Время отмены] IS NULL AND [Блюда].[id цеха] <> (SELECT [id] FROM [Цеха] WHERE [Цех] = ''Бар'') '+@condition+' 
		GROUP BY [Скидка]
	UNION ALL
	SELECT [Скидка],
			SUM([Стоимость]*[количество]) AS [Полная стоимость блюд с данной скидкой],
			dbo.[Округление цены](SUM([Стоимость]*[количество])*((100-[скидка])/100.0))  AS [Оплаченная стоимость блюд с данной скидкой],
			SUM([Стоимость]*[количество]) - dbo.[Округление цены](SUM([Стоимость]*[количество])*((100-[скидка])/100.0)) AS Разница
	        FROM [Счета посетителей] INNER JOIN [Заказы спецблюд] ON [Счета посетителей].[id] = [Заказы спецблюд].[id счёта посетителей]
		WHERE [скидка] IS NOT NULL AND [Заказы спецблюд].[Время отмены] IS NULL AND [Заказы спецблюд].Тип = ''Блюдо'' '+@condition+' 
		GROUP BY [Скидка]
	) AS tab
	GROUP BY [Скидка]'
	EXECUTE sp_executesql @script;
END
GO

/***********************************************************/
/*Системные процедуры*/
/***********************************************************/
CREATE PROCEDURE [Убить пользователей]
(@databaseName VARCHAR(50))
AS
BEGIN
	DECLARE @query varchar(max)

	/*проверка, что это не системная БД*/
	IF db_id(@databasename) < 4
	BEGIN
		RETURN
	END

	SELECT @query='kill '+CONVERT(VARCHAR, spid)+ '; '
		FROM master..sysprocesses 
		WHERE dbid=db_id(@databasename)

	IF LEN(@query) > 0
	BEGIN
		EXEC(@query)
	END
END
GO


CREATE PROCEDURE [Проверить значение]
(@tableName VARCHAR(50),@columnName VARCHAR(50),@value VARCHAR(50))
AS
BEGIN
	DECLARE @script NVARCHAR(300);
	SET @script=N'IF EXISTS(SELECT * FROM ['+@tableName+'] WHERE ['+@columnName+'] = '''+@value+''')'+
					'BEGIN SELECT CAST(1 AS BIT) END ELSE BEGIN SELECT CAST(0 AS BIT) END';
	EXECUTE sp_executesql @script;
END
GO


CREATE PROCEDURE [Получить поля, которые могут содержать NULL]
(@tableName VARCHAR(50))
AS
BEGIN
	SELECT syscolumns.name FROM syscolumns INNER JOIN sysobjects ON syscolumns.id = sysobjects.id
		WHERE sysobjects.name = @tableName AND syscolumns.isnullable = 1
END
GO


CREATE PROCEDURE [Получить версию таблицы]
(@tableName VARCHAR(50))
AS
BEGIN
	SELECT [версия],[дата] FROM [Версии таблиц] WHERE [таблица]=@tableName;
END 
GO


CREATE PROCEDURE [Изменить версию таблицы]
(@tableName VARCHAR(50), @date DATE)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Версии таблиц] 
		SET [версия]=[версия]+1,
		    [дата] = @date
		WHERE [таблица]=@tableName
	IF (SELECT [версия] FROM [Версии таблиц] WHERE [таблица]=@tableName)>1000000000
	BEGIN
		UPDATE [Версии таблиц] 
			SET [версия]=0,
			[дата] = @date
			WHERE [таблица]=@tableName
	END
	COMMIT TRANSACTION
END 
GO
/***********************************************************/
/*end_Системные процедуры*/
/***********************************************************/
CREATE TRIGGER [InD Следующее значение параметра] ON [Следующее значение параметра] INSTEAD OF DELETE
AS
BEGIN
        DECLARE @error VARCHAR(200)
	SELECT @error='Эти данные нельзя удалять, только редактировать!';
	RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
END
GO


CREATE TRIGGER [IU Следующее значение параметра] ON [Следующее значение параметра] FOR INSERT, UPDATE
AS
BEGIN
        DECLARE @numberBill INT, @maxBill INT

        SELECT @numberBill=[следующее значение] FROM INSERTED WHERE [параметр] = 'номер счёта'
	SELECT @maxBill=MAX([номер счёта]) FROM [Счета посетителей]
	IF (@numberBill <= @maxBill)
	BEGIN
	        DECLARE @error VARCHAR(200)
		SELECT @error='Данный номер счёта('+CAST(@numberBill AS VARCHAR)+') не может быть меньше, чем ('+CAST(@maxBill+1 AS VARCHAR)+')';
		RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
	END
	IF (@numberBill <= 0)
	BEGIN
		SELECT @error='Данный номер счёта('+CAST(@numberBill AS VARCHAR)+') не может быть меньше, чем (1)';
		RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
	END
END
GO
/***********************************************************/
/*endТриггер для поддержания корректности номера счёта*/
/***********************************************************/





/***********************************************************/
/*Триггеры для поддержания версии справочников*/
/***********************************************************/
CREATE TRIGGER [IUD Версия ингредиентов] ON [Ингредиенты] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Ингредиенты','19940507'
END
GO


CREATE TRIGGER [IUD Версия блюд1] ON [Блюда] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Блюда','19940705'
END
GO


CREATE TRIGGER [IUD Версия блюд2] ON [Рецепты] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Блюда','19940705'
END
GO


CREATE TRIGGER [IUD Версия напитков] ON [Напитки] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Напитки','19940705'
END
GO


CREATE TRIGGER [IUD Версия напитков2] ON [Напитки с группировкой] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Напитки','19940705'
END
GO


CREATE TRIGGER [IUD Версия ланч блюд] ON [Ланч блюда] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Ланч блюда','19940705'
END
GO


CREATE TRIGGER [IUD Версия ланч блюд2] ON [Ланч рецепты] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Ланч блюда','19940705'
END
GO


CREATE TRIGGER [IUD Версия ланч блюд3] ON [Ланч расписание] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Ланч блюда','19940705'
END
GO


CREATE TRIGGER [IUD типы блюд] ON [Типы блюд] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Типы','19940705'
	EXECUTE [Изменить версию таблицы] 'Блюда','19940705'
END
GO


CREATE TRIGGER [IUD типы напитков] ON [Типы напитков] AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	EXECUTE [Изменить версию таблицы] 'Типы','19940705'
	EXECUTE [Изменить версию таблицы] 'Напитки','19940705'
END
GO
/***********************************************************/
/*end Триггеры для поддержания версии справочников*/
/***********************************************************/




/***********************************************************/
/*Триггеры для поддержания вежливости ругательств на уникальные значения полей*/
/***********************************************************/
CREATE TRIGGER [IU Рецепты] ON [Рецепты] FOR INSERT, UPDATE
AS
BEGIN
        IF UPDATE([id блюда]) OR UPDATE([id ингредиента])
        BEGIN
	        DECLARE @error VARCHAR(200)
		DECLARE @id INT,@idMenu INT, @idIngr INT
		SELECT @id=[id],@idMenu=[id блюда],@idIngr=[id ингредиента] FROM INSERTED
		IF EXISTS(SELECT * FROM [Рецепты] WHERE [id]<>@id AND @idMenu=[id блюда] AND @idIngr=[id ингредиента])
		BEGIN
			SELECT @error='Блюдо('+CAST((SELECT [Русское название] FROM [Блюда] WHERE [id]=@idMenu) AS VARCHAR(80))+') уже содержит ингредиент('+CAST((SELECT [название ингредиента] FROM [Ингредиенты] WHERE [id]=@idIngr) AS VARCHAR(80))+')';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO


CREATE TRIGGER [IU Напитки уникальность] ON [Напитки] FOR INSERT, UPDATE
AS
BEGIN
        IF UPDATE([беи]) OR UPDATE([Русское название])
        BEGIN
	        DECLARE @error VARCHAR(200)
		DECLARE @idType INT,@id INT,@BEI VARCHAR(20), @name VARCHAR(50)
		SELECT @id=[id],@BEI=[беи],@name=[Русское название],@idType=[id типа напитка] FROM INSERTED

		IF EXISTS(SELECT * FROM [Напитки] WHERE [id]<>@id AND @BEI=[беи] AND @name=[Русское название])
		BEGIN
			SELECT @error='Напиток('+CAST(@name AS VARCHAR(80))+')  с таким беи('+@BEI+') уже существует';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
		IF (@BEI = '50' OR @BEI = '1бут')
		BEGIN
			IF EXISTS(SELECT * FROM [Напитки] WHERE [id]<>@id AND ([беи]='1шт' OR [беи]='100') AND @name=[Русское название])
			BEGIN
				SELECT @error='Напитку('+CAST(@name AS VARCHAR(80))+') нельзя задать такой беи('+@BEI+')';
				RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
			END
		END
		IF (@BEI = '100')
		BEGIN
			IF EXISTS(SELECT * FROM [Напитки] WHERE [id]<>@id AND ([беи]='1шт' OR [беи]='50' OR [беи]='1бут') AND @name=[Русское название])
			BEGIN
				SELECT @error='Напитку('+CAST(@name AS VARCHAR(80))+') нельзя задать такой беи('+@BEI+')';
				RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
			END
		END
		IF (@BEI = '1шт')
		BEGIN
			IF EXISTS(SELECT * FROM [Напитки] WHERE [id]<>@id AND ([беи]='100' OR [беи]='50' OR [беи]='1бут') AND @name=[Русское название])
			BEGIN
				SELECT @error='Напитку('+CAST(@name AS VARCHAR(80))+') нельзя задать такой беи('+@BEI+')';
				RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
			END
		END
		IF EXISTS(SELECT * FROM [Заказы напитков] WHERE [Объём] = (SELECT [БЕИ] FROM DELETED) AND [id напитка] = (SELECT [id] FROM DELETED) )
		BEGIN
			SELECT @error='Нельзя изменить БЕИ('+CAST((SELECT [БЕИ] FROM DELETED) AS VARCHAR(80))+'), т.к. она используется в сделанных заказах';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO
CREATE TRIGGER [IU Блюда уникальность] ON [Блюда] FOR INSERT, UPDATE
AS
BEGIN
        IF UPDATE([беи]) OR UPDATE([Русское название])
        BEGIN
	        DECLARE @error VARCHAR(200)
		DECLARE @idType INT,@id INT,@BEI VARCHAR(20), @name VARCHAR(50)
		SELECT @id=[id],@BEI=[беи],@name=[Русское название] FROM INSERTED

		IF EXISTS(SELECT * FROM [Блюда] WHERE [id]<>@id AND @BEI=[беи] AND @name=[Русское название])
		BEGIN
			SELECT @error='Блюдо('+CAST(@name AS VARCHAR(80))+')  с таким беи('+@BEI+') уже существует';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO
CREATE TRIGGER [IU Ланч блюда уникальность] ON [Ланч блюда] FOR INSERT, UPDATE
AS
BEGIN
        IF UPDATE([беи]) OR UPDATE([Русское название])
        BEGIN
	        DECLARE @error VARCHAR(200)
		DECLARE @idType INT,@id INT,@BEI VARCHAR(20), @name VARCHAR(50)
		SELECT @id=[id],@BEI=[беи],@name=[Русское название] FROM INSERTED

		IF EXISTS(SELECT * FROM [Ланч блюда] WHERE [id]<>@id AND @BEI=[беи] AND @name=[Русское название])
		BEGIN
			SELECT @error='Ланч блюдо('+CAST(@name AS VARCHAR(80))+')  с таким беи('+@BEI+') уже существует';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO
CREATE TRIGGER [U Блюда] ON [Блюда] FOR UPDATE
AS
BEGIN
	IF UPDATE([БЕИ])
	BEGIN
	        DECLARE @error VARCHAR(200)
		DECLARE @id INT, @idType INT,@BEI VARCHAR(20), @name VARCHAR(50)
		SELECT @id=[id], @BEI=[беи] FROM DELETED

		IF (@BEI = '1шт')
		BEGIN
			IF EXISTS(SELECT * FROM [Заказы блюд] WHERE [Вес] = '1шт' AND [id блюда] = @id )
			BEGIN
				SELECT @error='Нельзя изменить БЕИ(1шт), т.к. она используется в сделанных заказах';
				RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
			END
		END
		IF (@BEI <> '1шт')
		BEGIN
			IF EXISTS(SELECT * FROM [Заказы блюд] WHERE [Вес] <> '1шт'  AND [id блюда] = @id )
			BEGIN
				SELECT @error='Нельзя изменить БЕИ(за 100г), т.к. она используется в сделанных заказах';
				RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
			END
		END
	END
END
GO
CREATE TRIGGER [U Ланч Блюда] ON [Ланч блюда] FOR UPDATE
AS
BEGIN
	IF UPDATE([БЕИ])
	BEGIN
	    DECLARE @error VARCHAR(200)
		DECLARE @id INT, @idType INT,@BEI VARCHAR(20), @name VARCHAR(50)
		SELECT @id=[id],@BEI=[беи] FROM DELETED

		IF (@BEI = '1шт')
		BEGIN
			IF EXISTS(SELECT * FROM [Заказы ланч блюд] WHERE [Вес] = '1шт'  AND [id ланч блюда] = @id )
			BEGIN
				SELECT @error='Нельзя изменить БЕИ(1шт), т.к. она используется в сделанных заказах';
				RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
			END
		END
		IF (@BEI <> '1шт')
		BEGIN
			IF EXISTS(SELECT * FROM [Заказы ланч блюд] WHERE [Вес] <> '1шт'  AND [id ланч блюда] = @id )
			BEGIN
				SELECT @error='Нельзя изменить БЕИ(за 100г), т.к. она используется в сделанных заказах';
				RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
			END
		END
	END
END
GO



CREATE TRIGGER [IU Блюда] ON [Блюда] AFTER UPDATE, INSERT
AS
BEGIN
	IF (SELECT COUNT(*) FROM INSERTED)>1 RETURN
	IF UPDATE([id типа блюда])
	BEGIN
		UPDATE [Блюда] SET [Порядок] = 100000
			WHERE [id] = (SELECT [id] FROM INSERTED)
	END
	IF UPDATE([Название для чека]) OR UPDATE([Русское название])
	BEGIN
		UPDATE [Блюда] 
			SET [Название для чека] = dbo.UPCASE(INSERTED.[Название для чека]),
			[Русское название] = dbo.UPCASE(INSERTED.[Русское название])
			FROM INSERTED
			WHERE [Блюда].[id] = INSERTED.[id]
	END
END
GO

CREATE TRIGGER [I Напитки] ON [Напитки] AFTER INSERT
AS
BEGIN
	IF (SELECT COUNT(*) FROM INSERTED)>1 RETURN
	INSERT INTO [Напитки с группировкой]
		SELECT [id],[id типа напитка],100000
			FROM INSERTED

	IF UPDATE([Доступность])
	BEGIN
		UPDATE [Напитки]
			SET [Доступность]=(SELECT [Доступность] FROM INSERTED)
			WHERE [Русское название] = (SELECT [Русское название] FROM INSERTED)
	END
	UPDATE [Напитки] 
		SET [Название для чека] = dbo.UPCASE(INSERTED.[Название для чека]),
		[Русское название] = dbo.UPCASE(INSERTED.[Русское название])
		FROM INSERTED
		WHERE [Напитки].[id] = INSERTED.[id]
END
GO
DISABLE TRIGGER [I Напитки] ON [Напитки]
GO
CREATE TRIGGER [U Напитки] ON [Напитки] AFTER UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM INSERTED)>1 RETURN
	IF UPDATE([id типа напитка])
	BEGIN
	        UPDATE [Напитки с группировкой]
			SET [Напитки с группировкой].[id типа напитка] = DELETED.[id типа напитка],
		  	    [Порядок] = 100000
	        	FROM DELETED
			WHERE [Напитки с группировкой].[id] = DELETED.[id]
	END

	IF UPDATE([Доступность])
	BEGIN
		UPDATE [Напитки]
			SET [Доступность]=(SELECT [Доступность] FROM INSERTED)
			WHERE [Русское название] = (SELECT [Русское название] FROM INSERTED)
	END
	IF UPDATE([Название для чека]) OR UPDATE([Русское название])
	BEGIN
		UPDATE [Напитки] 
			SET [Название для чека] = dbo.UPCASE(INSERTED.[Название для чека]),
			[Русское название] = dbo.UPCASE(INSERTED.[Русское название])
			FROM INSERTED
			WHERE [Напитки].[id] = INSERTED.[id]
	END
END
GO
CREATE TRIGGER [IU Ингредиенты] ON [Ингредиенты] AFTER INSERT,UPDATE
AS
BEGIN
	IF UPDATE([Название ингредиента])
	BEGIN
		UPDATE [Ингредиенты] 
			SET [Название ингредиента] = dbo.UPCASE(INSERTED.[Название ингредиента])
			FROM INSERTED
			WHERE [Ингредиенты].[id] = INSERTED.[id]
	END	
END
GO
CREATE TRIGGER [IU Ланч блюда] ON [Ланч блюда] AFTER INSERT,UPDATE
AS
BEGIN
	IF UPDATE([Русское название])
	BEGIN
		UPDATE [Ланч блюда] 
			SET [Русское название] = dbo.UPCASE(INSERTED.[Русское название])
			FROM INSERTED
			WHERE [Ланч блюда].[id] = INSERTED.[id]
	END
END
GO

CREATE TRIGGER [D Напитки] ON [Напитки] AFTER DELETE
AS
BEGIN
	DELETE FROM [Напитки с группировкой]
		FROM DELETED
		WHERE [Напитки с группировкой].[id] = DELETED.[id]
END
GO



CREATE TRIGGER [IU Ланч рецепты уникальныость] ON [Ланч рецепты] FOR INSERT, UPDATE
AS
BEGIN
        IF UPDATE([id ланч блюда]) OR UPDATE([id ингредиента])
        BEGIN
	        DECLARE @error VARCHAR(200)
		DECLARE @id INT,@idMenu INT, @idIng INT
		SELECT @id=[id],@idMenu=[id ланч блюда],@idIng=[id ингредиента] FROM INSERTED
		IF EXISTS(SELECT * FROM [Ланч рецепты] WHERE [id]<>@id AND @idMenu=[id ланч блюда] AND @idIng=[id ингредиента])
		BEGIN
			SELECT @error='В ланч рецептах уже есть блюдо('+CAST((SELECT [Русское название] FROM [Ланч блюда] WHERE [id]=@idMenu) AS VARCHAR(80))+') с ингредиентом('+CAST((SELECT [название ингредиента] FROM [Ингредиенты] WHERE [id]=@idIng) AS VARCHAR(80))+')';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO


CREATE TRIGGER [IU Ланч расписание уникальность] ON [Ланч расписание] FOR INSERT, UPDATE
AS
BEGIN
        IF UPDATE([id ланч блюда])/*дату руками менять невозможно*/
        BEGIN
	        DECLARE @error VARCHAR(200)
		DECLARE @id INT,@idMenu INT, @idDate DATE
		SELECT @id=[id],@idMenu=[id ланч блюда],@idDate=[дата] FROM INSERTED
		IF EXISTS(SELECT * FROM [Ланч расписание] WHERE [id]<>@id AND @idMenu=[id ланч блюда] AND @idDate=[дата])
		BEGIN
			SELECT @error='В ланч расписании уже есть блюдо('+CAST((SELECT [Русское название] FROM [Ланч блюда] WHERE [id]=@idMenu) AS VARCHAR(80))+')';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO


CREATE TRIGGER [D Ланч расписание] ON [Ланч расписание] FOR DELETE
AS
BEGIN
        DECLARE @error VARCHAR(200)
	DECLARE @id INT,@idMenu INT, @idDate DATE
	SELECT @id=[id], @idMenu=[id ланч блюда], @idDate=[дата] FROM DELETED
                                                                 
        IF EXISTS(SELECT * FROM [Заказы ланч блюд] INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы ланч блюд].[id счёта посетителей]
			WHERE [Дата посещения] = @idDate AND [Время закрытия счёта] IS NULL AND [Заказы ланч блюд].[id ланч блюда] = @idMenu)
	BEGIN
			SELECT @error='Нельзя удалить блюдо('+CAST((SELECT [Русское название] FROM [Ланч блюда] WHERE [id]=@idMenu) AS VARCHAR(80))+') т.к. оно используется в незакрытом счёте';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
	END
END
GO


CREATE TRIGGER [I Забронированные столики] ON [Забронированные столики] INSTEAD OF INSERT
AS
BEGIN
        DECLARE @error VARCHAR(200)
	DECLARE @time1 TIME(0), @time2 TIME(0), @time3 TIME(0)
	DECLARE @date DATE, @idTable INT, @idWaiter INT, @date2 DATE, @idWaiter2 INT

	SELECT @idTable=[id столика],@idWaiter=[id забронировавшего официанта],@date=[дата брони],@time1=[время с],@time2=[время по],@idWaiter2=[id отменившего официанта], 
			@date2 = [Дата отмены], @time3=[Время отмены] FROM INSERTED
	IF @time2<@time1
	BEGIN
		SELECT @error='Время окончания брони('+CAST(@time2 AS VARCHAR)+') должно быть меньше, чем время начала брони('+CAST(@time1 AS VARCHAR)+')';
		RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
	END

	IF EXISTS(SELECT * FROM [Забронированные столики] WHERE [id столика]=@idTable AND [дата брони]=@date AND [Время отмены] IS NULL AND (([время с] <= @time1 AND @time1 <= [время по]) OR (@time1 <= [время с] AND [время с] <= @time2)))
	BEGIN
			SELECT @error='На время с '+CAST(@time1 AS VARCHAR)+' по '+CAST(@time2 AS VARCHAR)+' столик не может быть забронирован';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION	RETURN
	END
	INSERT INTO [Забронированные столики] VALUES(@idTable, @idWaiter, @date, @time1, @time2, @idWaiter2, @date2, @time3)
END
GO


CREATE TRIGGER [U Забронированные столики] ON [Забронированные столики] FOR UPDATE
AS
BEGIN
        DECLARE @error VARCHAR(200)
	DECLARE @time1 TIME(0), @time2 TIME(0), @time3 TIME(0)
	DECLARE @date DATE, @idTable INT

	IF UPDATE([Время отмены])
	BEGIN
		IF (SELECT [Время отмены] FROM DELETED) IS NOT NULL
		BEGIN
			SELECT @error='Нельзя отменить бронирование столика('+
				CAST((SELECT [Номер столика] FROM [Столики] WHERE [id]=(SELECT [id столика] FROM INSERTED)) AS VARCHAR(80))+
				') в зале ('+CAST((SELECT [Зал] FROM [Столики] WHERE [id]=(SELECT [id столика] FROM INSERTED)) AS VARCHAR(80))+
				') т.к. оно уже отменено';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO
/***********************************************************/
/*end_Триггеры для поддержания вежливости ругательств на уникальные значения полей*/
/***********************************************************/



/***********************************************************/
/*Триггеры для поддержания состояния столиков*/
/***********************************************************/
CREATE TRIGGER [I Счета посетителей] ON [Счета посетителей] AFTER INSERT, UPDATE
AS
BEGIN
	IF (SELECT [время закрытия счёта] FROM INSERTED) IS NULL
	BEGIN
		UPDATE [Столики] SET [состояние] = 1 WHERE [id]=(SELECT [id столика] FROM INSERTED)
        END
END
GO


CREATE TRIGGER [U Заказы блюд] ON [Заказы блюд] FOR UPDATE
AS
BEGIN
	IF UPDATE([Время отмены])
	BEGIN
	        DECLARE @error VARCHAR(200)
		IF (SELECT [Время отмены] FROM DELETED) IS NOT NULL
		BEGIN
			SELECT @error='Нельзя отменить заказ блюда('+
				CAST((SELECT [Русское название] FROM [Блюда] WHERE [id]=(SELECT [id блюда] FROM INSERTED)) AS VARCHAR(80))+
				') т.к. он уже отменён';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO


CREATE TRIGGER [U Заказы напитков] ON [Заказы напитков] FOR UPDATE
AS
BEGIN
	IF UPDATE([Время отмены])
	BEGIN
	        DECLARE @error VARCHAR(200)
		IF (SELECT [Время отмены] FROM DELETED) IS NOT NULL
		BEGIN
			SELECT @error='Нельзя отменить заказ напитка('+
				CAST((SELECT [Русское название] FROM [Напитки] WHERE [id]=(SELECT [id напитка] FROM INSERTED)) AS VARCHAR(80))+
				') т.к. он уже отменён';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO


CREATE TRIGGER [U Заказы ланч блюд] ON [Заказы ланч блюд] FOR UPDATE
AS
BEGIN
	IF UPDATE([Время отмены])
	BEGIN
	        DECLARE @error VARCHAR(200)
		IF (SELECT [Время отмены] FROM DELETED) IS NOT NULL
		BEGIN
			SELECT @error='Нельзя отменить заказ блюда('+
				CAST((SELECT [Русское название] FROM [Ланч блюда] WHERE [id]=(SELECT [id ланч блюда] FROM INSERTED)) AS VARCHAR(80))+
				') т.к. он уже отменён';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO



CREATE TRIGGER [U Заказы спецблюд] ON [Заказы спецблюд] FOR UPDATE
AS
BEGIN
	IF UPDATE([Время отмены])
	BEGIN
	        DECLARE @error VARCHAR(200)
		IF (SELECT [Время отмены] FROM DELETED) IS NOT NULL
		BEGIN
			SELECT @error='Нельзя отменить заказ блюда('+
				CAST((SELECT [Русское название] FROM DELETED) AS VARCHAR(100))+
				') т.к. он уже отменён';
			RAISERROR(@error,16,1)		ROLLBACK TRANSACTION		RETURN
		END
	END
END
GO
/***********************************************************/
/*end_Триггеры для поддержания состояния столиков и скидки в денормализованной таблице заказы блюд */
/***********************************************************/

/***********************************************************/
/*Триггеры для поддержания стоимостей заказов*/
/***********************************************************/
CREATE TRIGGER [IU Заказы блюд стоимость] ON [Заказы блюд] AFTER INSERT, UPDATE
AS
BEGIN
	IF UPDATE([Вес]) OR UPDATE([Количество])
	BEGIN
	        DECLARE @res MONEY
		DECLARE @sum MONEY
		DECLARE @id INT, @idOrderDish INT, @idDish INT, @BEI VARCHAR(20), @kol INT

		/*отнимаем удалённое*/
		SELECT @id = DELETED.[id], @idOrderDish=DELETED.[id], @idDish=DELETED.[id блюда],@BEI=DELETED.[Вес],@kol=DELETED.[Количество]
			FROM DELETED

		IF @BEI = '1шт'
		BEGIN
			SELECT @res=[стоимость] FROM [Блюда] WHERE [id]=@idDish
		END
		ELSE
		BEGIN
			SET @res = dbo.[Округление цены](CAST(@BEI AS MONEY) / CAST((SELECT [беи] FROM [Блюда] WHERE [id]=@idDish) AS MONEY) * (SELECT [стоимость] FROM [Блюда] WHERE [id]=@idDish))
		END

		UPDATE [Заказы блюд]
			SET [Заказы блюд].[Стоимость] = [Заказы блюд].[стоимость] - ISNULL(@res,0) * @kol
			WHERE [Заказы блюд].[id] = @id

		
		/*добавляем прибаленное*/
		SELECT @id = INSERTED.[id], @idOrderDish=INSERTED.[id], @idDish=INSERTED.[id блюда],@BEI=INSERTED.[Вес],@kol=INSERTED.[Количество]
			FROM INSERTED

		IF @BEI = '1шт'
		BEGIN
			SELECT @res=[стоимость] FROM [Блюда] WHERE [id]=@idDish
		END
		ELSE
		BEGIN
			SET @res = dbo.[Округление цены](CAST(@BEI AS MONEY) / CAST((SELECT [беи] FROM [Блюда] WHERE [id]=@idDish) AS MONEY) * (SELECT [стоимость] FROM [Блюда] WHERE [id]=@idDish))
		END

		UPDATE [Заказы блюд]
			SET [Заказы блюд].[стоимость] = [Заказы блюд].[стоимость] + ISNULL(@res,0) * @kol
			WHERE [Заказы блюд].[id] = @id
	END
END
GO

CREATE TRIGGER [I Изменение рецептов блюд стоимость] ON [Изменение рецептов блюд] AFTER INSERT /*UPDATE и DELETE невозможен*/
AS
BEGIN
	DECLARE @sum MONEY

	SELECT @sum=[Ингредиенты].[Стоимость]
		FROM INSERTED INNER JOIN [Ингредиенты] ON [Ингредиенты].[id] = INSERTED.[id ингредиента]
		WHERE INSERTED.[Добавить]='Добавить'
		
	UPDATE [Заказы блюд]
		SET [Заказы блюд].[Стоимость] = [Заказы блюд].[Стоимость] + ISNULL(@sum,0) * [Заказы блюд].[Количество]
		FROM INSERTED
		WHERE [Заказы блюд].[id] = INSERTED.[id заказа блюда]
END
GO

CREATE TRIGGER [IU Заказы ланч блюд стоимость] ON [Заказы ланч блюд] AFTER INSERT, UPDATE
AS
BEGIN
	IF UPDATE([Вес]) OR UPDATE([Количество])
	BEGIN
	        DECLARE @res MONEY
		DECLARE @sum MONEY
		DECLARE @id INT, @idOrderDish INT, @idDish INT, @BEI VARCHAR(20), @kol INT

		/*отнимаем удалённое*/
		SELECT @id = DELETED.[id], @idOrderDish=DELETED.[id], @idDish=DELETED.[id ланч блюда],@BEI=DELETED.[Вес],@kol=DELETED.[Количество]
			FROM DELETED

		IF @BEI = '1шт'
		BEGIN
			SELECT @res=[Стоимость] FROM [Ланч блюда] WHERE [id]=@idDish
		END
		ELSE
		BEGIN
			SET @res = dbo.[Округление цены](CAST(@BEI AS MONEY) / CAST((SELECT [беи] FROM [Ланч блюда] WHERE [id]=@idDish) AS MONEY) * (SELECT [стоимость] FROM [Ланч блюда] WHERE [id]=@idDish))
		END

		UPDATE [Заказы ланч блюд]
			SET [Заказы ланч блюд].[Стоимость] = [Заказы ланч блюд].[Стоимость] - ISNULL(@res,0) * @kol
			WHERE [Заказы ланч блюд].[id] = @id

		
		/*добавляем прибаленное*/
		SELECT @id = INSERTED.[id], @idOrderDish=INSERTED.[id], @idDish=INSERTED.[id ланч блюда],@BEI=INSERTED.[Вес],@kol=INSERTED.[Количество]
			FROM INSERTED

		IF @BEI = '1шт'
		BEGIN
			SELECT @res=[стоимость] FROM [Ланч блюда] WHERE [id]=@idDish
		END
		ELSE
		BEGIN
			SET @res = dbo.[Округление цены](CAST(@BEI AS MONEY) / CAST((SELECT [беи] FROM [Ланч блюда] WHERE [id]=@idDish) AS MONEY) * (SELECT [стоимость] FROM [Ланч блюда] WHERE [id]=@idDish))
		END

		UPDATE [Заказы ланч блюд]
			SET [Заказы ланч блюд].[стоимость] = [Заказы ланч блюд].[стоимость] + ISNULL(@res,0) * @kol
			WHERE [Заказы ланч блюд].[id] = @id
	END
END
GO

CREATE TRIGGER [I Изменение рецептов ланч блюд стоимость] ON [Изменение рецептов ланч блюд] AFTER INSERT /*UPDATE и DELETE невозможен*/
AS
BEGIN
	DECLARE @sum MONEY

	SELECT @sum=[Ингредиенты].[Стоимость]
		FROM INSERTED INNER JOIN [Ингредиенты] ON [Ингредиенты].[id] = INSERTED.[id ингредиента]
		WHERE INSERTED.[Добавить]='Добавить'
		
	UPDATE [Заказы ланч блюд]
		SET [Заказы ланч блюд].[Стоимость] = [Заказы ланч блюд].[Стоимость] + ISNULL(@sum,0) * [Заказы ланч блюд].[Количество]
		FROM INSERTED
		WHERE [Заказы ланч блюд].[id] = INSERTED.[id заказа ланч блюда]
END
GO

CREATE TRIGGER [IU Заказы напитков стоимость] ON [Заказы напитков] AFTER INSERT, UPDATE
AS
BEGIN
	IF UPDATE([Объём]) OR UPDATE([Количество]) OR UPDATE([Количество порций])
	BEGIN
	        DECLARE @res MONEY
		DECLARE @id INT, @idDish INT, @BEI VARCHAR(20), @kol INT, @kolP INT

		/*отнимаем удалённое*/
		SELECT @id=[id], @idDish = [id напитка], @BEI = [Объём], @kol = [Количество], @kolP = [Количество порций]
			FROM DELETED

	        IF @BEI = '1шт' OR @BEI = '1бут'
	        BEGIN
	        	SELECT @res=[стоимость] FROM [Напитки] WHERE [id]=@idDish
		END
		ELSE
		BEGIN
			SET @res = dbo.[Округление цены](CAST(@BEI AS MONEY) / CAST((SELECT [беи] FROM [Напитки] WHERE [id]=@idDish) AS MONEY) * (SELECT [стоимость] FROM [Напитки] WHERE [id]=@idDish))
		END

		UPDATE [Заказы напитков]
			SET [Заказы напитков].[Стоимость] = [Заказы напитков].[Стоимость] - ISNULL(@res,0) * @kol * @kolP
			WHERE [Заказы напитков].[id] = @id

		
		/*добавляем прибаленное*/
		SELECT @id=[id], @idDish = [id напитка], @BEI = [Объём], @kol = [Количество], @kolP = [Количество порций]
			FROM INSERTED

	        IF @BEI = '1шт' OR @BEI = '1бут'
	        BEGIN
	        	SELECT @res=[стоимость] FROM [Напитки] WHERE [id]=@idDish
		END
		ELSE
		BEGIN
			SET @res = dbo.[Округление цены](CAST(@BEI AS MONEY) / CAST((SELECT [беи] FROM [Напитки] WHERE [id]=@idDish) AS MONEY) * (SELECT [стоимость] FROM [Напитки] WHERE [id]=@idDish))
		END

		UPDATE [Заказы напитков]
			SET [Заказы напитков].[Стоимость] = [Заказы напитков].[Стоимость] + ISNULL(@res,0) * @kol * @kolP
			WHERE [Заказы напитков].[id] = @id
	END
END
GO
/***********************************************************/
/*end_Триггеры для поддержания стоимостей заказов*/
/***********************************************************/

CREATE PROCEDURE [Вставить данные в справочник]
(@tableName VARCHAR(50), @xmlData NVARCHAR(max))
AS
BEGIN
        /*выбираем название поля, тип(int) длина для задданной таблицы, чтоб построить описание полей и схему xml*/
	DECLARE cur CURSOR FOR 
		SELECT sc.name, sc.xtype, sc.length 
			FROM syscolumns sc INNER JOIN sysobjects ON sc.id = sysobjects.id
		WHERE sysobjects.Name = @tableName

	DECLARE @name VARCHAR(50),@type INT,@length INT
	DECLARE @fieldList VARCHAR(500), @shema VARCHAR(2000)

	SET @fieldList = '('
	SET @shema = '('

	OPEN cur
	FETCH cur INTO @name, @type, @length
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @fieldList = @fieldList + '['+@name+']'

		SET @shema = @shema + '['+@name+'] '+(SELECT name FROM systypes WHERE xtype=@type)
		/*если это varchar или VARCHAR добавляем длину поля*/
		IF @type=231 OR @type=167 SET @shema = @shema + '(' + CAST(@length AS VARCHAR) + ')'
		/*убираем пробел на xml константу*/
		SET @name = REPLACE(@name,' ','_x0020_')
		SET @shema = @shema + ' ''@'+@name+''''

		FETCH cur INTO @name, @type, @length
		/*если ещё есть записи добавляем запятую*/
		IF @@ROWCOUNT=1
		BEGIN 
			SET @fieldList = @fieldList + ','
			SET @shema = @shema + ','
		END
	END
	CLOSE cur
	DEALLOCATE cur
	SET @fieldList = @fieldList + ')'
	SET @shema = @shema + ')'

	DECLARE @script NVARCHAR(max);

	DECLARE @handle INT
	EXECUTE sp_xml_preparedocument @handle output,@xmlData

	/*выключаем identity и вставляем записи*/
	SET @script=N'SET IDENTITY_INSERT ['+@tableName+'] ON 
					INSERT INTO ['+@tableName+']'+@fieldList+' SELECT * FROM OPENXML(@handle_value,''/data/row'') WITH '+@shema+'
				  SET IDENTITY_INSERT ['+@tableName+'] OFF'		
	EXECUTE sp_executesql @script,N'@handle_value INT',@handle_value = @handle;
END
GO


CREATE PROCEDURE [Получить ланч расписание]
(@date DATE)
AS
BEGIN
	SELECT [Ланч расписание].[id],[id ланч блюда]AS [Русское название], [Дата]
		FROM [Ланч расписание]
		WHERE [дата] = @date
END
GO


CREATE PROCEDURE [Получить стоимость комплекса]
(@date DATE)
AS
BEGIN
	SELECT ISNULL(SUM([стоимость]),0)
		FROM [Ланч блюда]
		WHERE [id] IN (SELECT [id ланч блюда] FROM [Ланч расписание] WHERE [дата] = @date)
END
GO


CREATE PROCEDURE [Получить состояние столиков]
AS
BEGIN
	SELECT [зал],[номер столика],[состояние]
		FROM [Столики]
END
GO

/*если все параметры NULL-о всех столиах, иначе*/
/*если @idTable не NULL-о столике по его id, иначе*/
/*если @room и @table не NULL-о столике по его данным*/
/*если дата не указана - за сегодня*/
CREATE FUNCTION [Получить данные о бронировании столиков](@idTable INT,@room VARCHAR(15),@table INT,@date DATE)
	RETURNS @res TABLE(
		[зал] VARCHAR(20),
		[номер столика] INT,
		[время с] TIME(0),
		[время по] TIME(0)
       	)
AS
BEGIN
        IF @date IS NULL SET @date=GETDATE()
	IF (@idTable IS NULL AND @room IS NULL AND @table IS NULL)
	BEGIN
		INSERT INTO @res
		 SELECT [зал],
			[номер столика],
			[время с],
			[время по]
			FROM [Столики] INNER JOIN [Забронированные столики] ON [id столика]=[Столики].[id] 
			WHERE [дата брони]=@date
			ORDER BY [время с]
		RETURN
	END

	IF (@idTable IS NOT NULL)
	BEGIN
		INSERT INTO @res
		 SELECT [зал],
			[номер столика],
			[время с],
			[время по]
			FROM [Столики] INNER JOIN [Забронированные столики] ON [id столика]=[Столики].[id]
			WHERE [дата брони]=@date AND [Столики].[id]=@idTable
			ORDER BY [время с]
		RETURN
	END

	INSERT INTO @res
	 SELECT [зал],
		[номер столика],
		[время с],
		[время по]
		FROM [Столики] INNER JOIN [Забронированные столики] ON [id столика]=[Столики].[id]
		WHERE [дата брони]=@date AND [Столики].[номер столика]=@table AND [Столики].[зал] = @room
		ORDER BY [время с]
	RETURN
END     
/*если все параметры NULL-о всех столиах, иначе*/
/*если @idTable не NULL-о столике по его id, иначе*/
/*если @room и @table не NULL-о столике по его данным*/
GO


CREATE FUNCTION [Получить данные о бронировании столиков без отменённых](@idTable INT,@room VARCHAR(15),@table INT,@date DATE)
	RETURNS @res TABLE(
		[зал] VARCHAR(20),
		[номер столика] INT,
		[время с] TIME(0),
		[время по] TIME(0)
       	)
AS
BEGIN
        IF @date IS NULL SET @date=GETDATE()
	IF (@idTable IS NULL AND @room IS NULL AND @table IS NULL)
	BEGIN
		INSERT INTO @res
		 SELECT [зал],
			[номер столика],
			[время с],
			[время по]
			FROM [Столики] INNER JOIN [Забронированные столики] ON [id столика]=[Столики].[id] 
			WHERE [дата брони]=@date AND [Время отмены] IS NULL
			ORDER BY [время с]
		RETURN
	END

	IF (@idTable IS NOT NULL)
	BEGIN
		INSERT INTO @res
		 SELECT [зал],
			[номер столика],
			[время с],
			[время по]
			FROM [Столики] INNER JOIN [Забронированные столики] ON [id столика]=[Столики].[id]
			WHERE [дата брони]=@date AND [Столики].[id]=@idTable   AND [Время отмены] IS NULL
			ORDER BY [время с]
		RETURN
	END

	INSERT INTO @res
	 SELECT [зал],
		[номер столика],
		[время с],
		[время по]
		FROM [Столики] INNER JOIN [Забронированные столики] ON [id столика]=[Столики].[id]
		WHERE [дата брони]=@date AND [Столики].[номер столика]=@table AND [Столики].[зал] = @room  AND [Время отмены] IS NULL
		ORDER BY [время с]
	RETURN
END     
/*если все параметры NULL-о всех столиах, иначе*/
/*если @idTable не NULL-о столике по его id, иначе*/
/*если @room и @table не NULL-о столике по его данным*/
GO

CREATE FUNCTION [Получить данные о счетах столиков](@idTable INT,@room VARCHAR(15),@table INT)
	RETURNS @res TABLE(
		[номер счёта] INT,
		[зал] VARCHAR(20),
		[номер столика] INT,
		[время открытия счёта] TIME(0),
		[текущая стоимость без скидки] MONEY,
		[текущая стоимость со скидкой] MONEY,
		[скидка] INT
       	)
AS
BEGIN
	IF (@idTable IS NULL AND @room IS NULL AND @table IS NULL)
	BEGIN   
		INSERT INTO @res
		 SELECT [номер счёта],
		 	[зал],
		 	[номер столика],
			[время открытия счёта],
			(SELECT [общая стоимость без скидки] FROM [Получить стоимость счёта]([номер счёта])),
			(SELECT [общая стоимость со скидкой] FROM [Получить стоимость счёта]([номер счёта])),
			[скидка]
		FROM [Счета посетителей] INNER JOIN [Столики] ON [Счета посетителей].[id столика] = [Столики].[id]
		WHERE [время закрытия счёта] IS NULL
		RETURN
	END

	IF (@idTable IS NOT NULL)
	BEGIN
		INSERT INTO @res
		 SELECT [номер счёта],
		 	[зал],
		 	[номер столика],
			[время открытия счёта],
			(SELECT [общая стоимость без скидки] FROM [Получить стоимость счёта]([Счета посетителей].[id])),
			(SELECT [общая стоимость со скидкой] FROM [Получить стоимость счёта]([Счета посетителей].[id])),
			[скидка]
			FROM [Счета посетителей] INNER JOIN [Столики] ON [Счета посетителей].[id столика] = [Столики].[id]
			WHERE [id столика]=@idTable AND [время закрытия счёта] IS NULL
		RETURN
	END

	INSERT INTO @res
	 SELECT [номер счёта],
	 	@room,
	 	@table,
		[время открытия счёта],
		(SELECT [общая стоимость без скидки] FROM [Получить стоимость счёта]([Счета посетителей].[id])),
		(SELECT [общая стоимость со скидкой] FROM [Получить стоимость счёта]([Счета посетителей].[id])),
		[скидка]
		FROM [Счета посетителей]
		WHERE [id столика] = (SELECT [Столики].[id] FROM [Столики] WHERE [номер столика]=@table AND [зал]=@room)
			AND [время закрытия счёта] IS NULL
	RETURN
END
GO


CREATE FUNCTION [Получить счёта стоимость со скидкой](@numberBill INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @cost MONEY
	SELECT @cost=[общая стоимость со скидкой]
		FROM [Получить стоимость счёта](@numberBill)
	RETURN @cost
END	
GO
		

CREATE FUNCTION [Получить счёта стоимость без скидки](@numberBill INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @cost MONEY
	SELECT @cost=[общая стоимость без скидки]
		FROM [Получить стоимость счёта](@numberBill)
	RETURN @cost
END	
GO


CREATE FUNCTION [Получить счёта стоимость к оплате](@numberBill INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @cost MONEY
	SELECT @cost=[к оплате]
		FROM [Получить стоимость счёта](@numberBill)
	RETURN @cost
END	
GO


CREATE FUNCTION [Получить счёта стоимость оплаченную](@numberBill INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @cost MONEY
	SELECT @cost=[общая стоимость со скидкой]+[аванс]
		FROM [Получить стоимость счёта](@numberBill)
	RETURN @cost
END	
GO


CREATE FUNCTION [Получить стоимость счёта](@numberBill INT)
	RETURNS @res TABLE(
		[стоимость блюд] MONEY,
		[скидка] INT,
		[стоимость блюд со скидкой] MONEY,
		[стоимость напитков] MONEY,
		[общая стоимость без скидки] MONEY,
		[общая стоимость со скидкой] MONEY,
		[стоимость комплексов] MONEY,
		[аванс] MONEY,
		[к оплате] MONEY
		)
AS
BEGIN
	DECLARE @sum1 MONEY, @sum2 MONEY, @sum3 MONEY, @sk INT, @sum4 MONEY, @cost MONEY, @idBill INT, @sum5 MONEY, @sum7 MONEY

	SELECT @idBill=[id] FROM [Счета посетителей] WHERE [номер счёта]=@numberBill
	SELECT @sk=[скидка] FROM [Счета посетителей] WHERE [id] = @idBill

	/*стоимость обычных блюд в sum1*/
	SELECT @sum1=SUM([Заказы блюд].[Стоимость])
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
		WHERE [Заказы блюд].[id счёта посетителей]=@idBill AND [Заказы блюд].[время отмены] IS NULL AND [Блюда].[id цеха] <> (SELECT [id] FROM [Цеха] WHERE [Цех] = 'Бар')

	/*стоимость спецблюд в sum2*/
	SELECT @sum2=SUM([Стоимость]*[Количество])
		FROM [Заказы спецблюд]
		WHERE [id счёта посетителей]=@idBill AND [Время отмены] IS NULL AND [Тип] = 'Блюдо'
	
	/*в sum1 стоимость всех блюд кроме комплексов*/
	SET @sum1 = ISNULL(@sum1,0) + ISNULL(@sum2,0)

	/*в sum2 стоимость блюд со скидкой*/	
	SET @sum2 = @sum1
	IF @sk IS NOT NULL
	BEGIN
		SET @sum2 = @sum1 * (100-@sk)/100.0
	END
	SET @sum2 = dbo.[Округление цены](ISNULL(@sum2,0))

	/*стоимость комплексов в sum4*/
	SELECT @sum4=SUM([Заказы ланч блюд].[Стоимость])
		FROM [Заказы ланч блюд]
		WHERE [Заказы ланч блюд].[id счёта посетителей]=@idBill AND [Заказы ланч блюд].[время отмены] IS NULL

	SET @sum4 = ISNULL(@sum4,0)

	/*стоимость напитков в sum3*/
	SELECT @sum3=SUM([Заказы напитков].[Стоимость])
		FROM [Заказы напитков]
		WHERE [id счёта посетителей]=@idBill AND [время отмены] IS NULL

	/*стоимость напитков sum7*/
	SELECT @sum7=SUM([Заказы блюд].[Стоимость])
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
		WHERE [id счёта посетителей]=@idBill AND [время отмены] IS NULL AND [Блюда].[id цеха] = (SELECT [id] FROM [Цеха] WHERE [Цех] = 'Бар')
	
	SET @sum3 = ISNULL(@sum3,0) + ISNULL(@sum7,0)

	/*стоимость спецнапитков в sum7*/
	SELECT @sum7=SUM([Стоимость]*[Количество])
		FROM [Заказы спецблюд]
		WHERE [id счёта посетителей]=@idBill AND [Время отмены] IS NULL AND [Тип] = 'Напиток'

	SET @sum3 = ISNULL(@sum3,0) + ISNULL(@sum7,0)
	
	SELECT @sum5=[Аванс] FROM [Счета посетителей] WHERE [id] = @idBill
	SET @sum5 = ISNULL(@sum5,0)

	INSERT INTO @res VALUES(dbo.[Округление цены](@sum1+@sum4), 
				@sk, 
				dbo.[Округление цены](@sum2+@sum4), 
				dbo.[Округление цены](@sum3), 
				dbo.[Округление цены](@sum1+@sum3+@sum4),
				dbo.[Округление цены](@sum2+@sum3+@sum4),
				dbo.[Округление цены](@sum4),
				dbo.[Округление цены](@sum5),
				dbo.[Округление цены](@sum2+@sum3+@sum4-@sum5))
	RETURN
END
GO


CREATE FUNCTION [БЕИ объём напитка]
(@BEI VARCHAR(20), @porc INT)
RETURNS VARCHAR(20)
AS
BEGIN
	IF @BEI = '1шт' OR @BEI = '1бут'
	BEGIN
       		RETURN @BEI
	END

	RETURN CAST(@BEI AS INT) * @porc
END
GO


CREATE PROCEDURE [Забронировать столик](@Waiter VARCHAR(100), @idTable INT,  @room VARCHAR(20), @table INT, @date DATE, @time1 TIME(0), @time2 TIME(0))
AS
BEGIN
        IF @idTable IS NULL
        BEGIN
		SELECT @idTable=[Столики].[id] FROM [Столики]
			WHERE [зал]=@room AND [номер столика]=@table
        END
       	INSERT INTO [Забронированные столики] VALUES(@idTable, (SELECT [id] FROM [Официанты] WHERE [ФИО]=@Waiter), @date, @time1, @time2, NULL, NULL, NULL)
END
GO


CREATE PROCEDURE [Получить id столика](@room VARCHAR(20), @table INT)
AS                                              
BEGIN
	SELECT [Столики].[id] FROM [Столики]
		WHERE [зал]=@room AND [номер столика]=@table
END
GO

CREATE PROCEDURE [Получить официанта открывшего счёт]
(@numberBill INT)
AS
BEGIN
	SELECT [фио] 
		FROM [Официанты] 
		WHERE [id] = (
			      SELECT [id официанта] 
			      	   FROM [Счета посетителей] 
			      	   WHERE [номер счёта] = @numberBill
			     )
END	
GO


CREATE PROCEDURE [Получить записи для чека]
(@numberBill INT)
AS
BEGIN
        DECLARE @idBill INT
	SELECT @idBill=[id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill

	/*обычные блюда*/
	SELECT  [Заказы блюд].[id],
		[Название для чека],
		[Вес],
		[Количество],
		[Блюда].[Стоимость]+dbo.[Получить стоимость ингредиентов для заказа блюда]([Заказы блюд].[id]),
		[Заказы блюд].[Стоимость],
		0
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
		WHERE [id счёта посетителей] = @idBill AND [Время отмены] IS NULL AND [Блюда].[id цеха] <> (SELECT [id] FROM [Цеха] WHERE [Цех] = 'Бар')
	UNION ALL
	/*спец блюда*/
 	SELECT 	-1,
 		[Название для чека],
 		'1шт',
 		[Количество],
 		[Стоимость],
 		[Стоимость]*[Количество],
 		1
		FROM [Заказы спецблюд]
		WHERE [id счёта посетителей] = @idBill AND [Время отмены] IS NULL AND [Тип] = 'Блюдо'
	UNION ALL
	/*комплексы*/
	SELECT  -1,
		'Комплексный обед '+CAST([Номер комплекса] AS VARCHAR),
		'1шт',
		1,
		SUM([Стоимость]),
		SUM([Стоимость]),
		2
		FROM [Заказы ланч блюд]
		WHERE [id счёта посетителей] = @idBill AND [Время отмены] IS NULL
		GROUP BY [Номер комплекса]
	UNION ALL
	/*обычные напитки*/
	SELECT  [Заказы напитков].[id],
		[Название для чека],
		[Объём],
		[Количество]*[Количество порций],
		[Напитки].[Стоимость],
		[Заказы напитков].[Стоимость],
		3
		FROM [Заказы напитков] INNER JOIN [Напитки] ON [Заказы напитков].[id напитка] = [Напитки].[id]
		WHERE [id счёта посетителей] = @idBill AND [Время отмены] IS NULL
	UNION ALL
	/*напитки - блюда*/
	SELECT 	[Заказы блюд].[id],
		[Название для чека],
		[Вес],
		[Количество],
		[Блюда].[Стоимость]+dbo.[Получить стоимость ингредиентов для заказа блюда]([Заказы блюд].[id]),
		[Заказы блюд].[Стоимость],
		4
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
		WHERE [id счёта посетителей] = @idBill AND [Время отмены] IS NULL AND [Блюда].[id цеха] = (SELECT [id] FROM [Цеха] WHERE [Цех] = 'Бар')
	UNION ALL
	/*спец напитки*/
 	SELECT  -1,
 		[Название для чека],
 		'1шт',
 		[Количество],
 		[Стоимость],
 		[Стоимость]*[Количество],
 		5
		FROM [Заказы спецблюд]
		WHERE [id счёта посетителей] = @idBill AND [Время отмены] IS NULL AND [Тип]='Напиток'
	ORDER BY 7, 2, 3
END
GO


CREATE FUNCTION [Получить стоимость ингредиентов для заказа блюда]
(@idOrderDish INT)
RETURNS MONEY
AS
BEGIN
	RETURN ISNULL((SELECT SUM([Ингредиенты].[Стоимость])
		FROM [Изменение рецептов блюд] INNER JOIN [Ингредиенты] ON [Изменение рецептов блюд].[id ингредиента] = [Ингредиенты].[id]
		WHERE [Изменение рецептов блюд].[id заказа блюда] = @idOrderDish AND [Изменение рецептов блюд].[Добавить] = 'Добавить'),0)
END
GO


CREATE FUNCTION [Получить стоимость ингредиентов для заказа ланч блюда]
(@idOrderDish INT)
RETURNS MONEY
AS
BEGIN
	RETURN ISNULL((SELECT SUM([Ингредиенты].[Стоимость])
		FROM [Изменение рецептов ланч блюд] INNER JOIN [Ингредиенты] ON [Изменение рецептов ланч блюд].[id ингредиента] = [Ингредиенты].[id]
		WHERE [Изменение рецептов ланч блюд].[id заказа ланч блюда] = @idOrderDish AND [Изменение рецептов ланч блюд].[Добавить] = 'Добавить'),0)
END
GO


CREATE PROCEDURE [Получить изменение рецепта блюда]
(@idOrderDish INT, @type VARCHAR(15))
AS
BEGIN
	IF (@type IS NULL)
	BEGIN
		SELECT [Ингредиенты].[название ингредиента], [Изменение рецептов блюд].[добавить]
			FROM [Изменение рецептов блюд] INNER JOIN [Ингредиенты] ON [Изменение рецептов блюд].[id ингредиента] = [Ингредиенты].[id]
			WHERE [Изменение рецептов блюд].[id заказа блюда] = @idOrderDish
	END
	ELSE
	BEGIN
		SELECT [Ингредиенты].[название ингредиента], [Изменение рецептов блюд].[добавить]
			FROM [Изменение рецептов блюд]  INNER JOIN [Ингредиенты] ON [Изменение рецептов блюд].[id ингредиента] = [Ингредиенты].[id]
			WHERE [Изменение рецептов блюд].[id заказа блюда] = @idOrderDish AND [Изменение рецептов блюд].[добавить] = @type
				AND [Ингредиенты].[Стоимость] <> 0
	END
END
GO


CREATE PROCEDURE [Получить изменение рецепта ланч блюда]
(@idOrderDish INT, @type VARCHAR(15))
AS
BEGIN
	IF (@type IS NULL)
	BEGIN
		SELECT [Ингредиенты].[название ингредиента], [Изменение рецептов ланч блюд].[добавить]
			FROM [Изменение рецептов ланч блюд] INNER JOIN [Ингредиенты] ON [Изменение рецептов ланч блюд].[id ингредиента] = [Ингредиенты].[id]
			WHERE [Изменение рецептов ланч блюд].[id заказа ланч блюда] = @idOrderDish
	END
	ELSE
	BEGIN
		SELECT [Ингредиенты].[название ингредиента], [Изменение рецептов ланч блюд].[добавить]
			FROM [Изменение рецептов ланч блюд] INNER JOIN [Ингредиенты] ON [Изменение рецептов ланч блюд].[id ингредиента] = [Ингредиенты].[id]
			WHERE [Изменение рецептов ланч блюд].[id заказа ланч блюда] = @idOrderDish AND [Изменение рецептов ланч блюд].[добавить] = @type
				AND [Ингредиенты].[Стоимость] <> 0
	END
END
GO




CREATE FUNCTION [Округление цены](@cost MONEY)
RETURNS MONEY
AS
BEGIN
        IF @cost < 0 SET @cost = 0
	IF (@cost % 500 = 0) SET @cost = FLOOR((@cost / 500)) * 500
	ELSE SET @cost = FLOOR((@cost / 500)) * 500 + 500;
	RETURN ISNULL(@cost,0)
END		
GO


CREATE PROCEDURE [Получить id счёта]
(@numberBill INT)
AS
BEGIN
	SELECT [id] FROM [Счета посетителей] 
		WHERE [номер счёта] = @numberBill
END
GO


CREATE PROCEDURE [Получить открытые счета посетителей]
AS
BEGIN
	SELECT [Счета посетителей].[id],[Номер счёта],ISNULL([Зал],'С собой') AS [Зал],[Номер столика],[ФИО] AS [Открыл счёт],[Дата посещения],[Время открытия счёта],[Время закрытия счёта],[Скидка],dbo.[Получить счёта стоимость со скидкой]([Номер счёта]) AS [Стоимость счёта]
		FROM [Счета посетителей] LEFT JOIN [Столики] ON [Счета посетителей].[id столика] = [Столики].[id] 
			 		 INNER JOIN [Официанты] ON [Счета посетителей].[id официанта] = [Официанты].[id]
		WHERE [Счета посетителей].[Время закрытия счёта] IS NULL
END
GO

CREATE PROCEDURE [Получить счета посетителей]
(@numberBill INT)
AS
BEGIN
        IF @numberBill IS NULL
	BEGIN
		SELECT TOP 100 [Счета посетителей].[id],[Номер счёта],ISNULL([Зал],'С собой') AS [Зал],[Номер столика],t1.[ФИО] AS [Открыл счёт],[Дата посещения],
			[Время открытия счёта],[Время закрытия счёта],[Скидка],t2.[ФИО] AS [Установил скидку],[Аванс],t3.[ФИО] AS [Установил аванс],
			dbo.[Получить счёта стоимость без скидки]([Номер счёта]) AS [Стоимость счёта]
			FROM [Счета посетителей] LEFT JOIN [Столики] ON [Счета посетителей].[id столика] = [Столики].[id] 
				 		 INNER JOIN [Официанты] AS t1 ON [Счета посетителей].[id официанта] = t1.[id]
				 		 LEFT JOIN [Официанты] AS t2 ON [Счета посетителей].[id официанта установившего скидку] = t2.[id]
				 		 LEFT JOIN [Официанты] AS t3 ON [Счета посетителей].[id официанта установившего аванс] = t3.[id]
			ORDER BY [Номер счёта] DESC
	END
	ELSE
	BEGIN		
		SELECT [Счета посетителей].[id],[Номер счёта],ISNULL([Зал],'С собой'),ISNULL([Номер столика],0),t1.[ФИО] AS [открыл счёт],[Дата посещения],
			[Время открытия счёта],[Время закрытия счёта],[Скидка],t2.[ФИО] AS [Установил скидку],[Аванс],t3.[ФИО] AS [Установил аванс],
			dbo.[Получить счёта стоимость без скидки]([Номер счёта]) AS [Стоимость счёта]
			FROM [Счета посетителей] LEFT JOIN [Столики] ON [Счета посетителей].[id столика] = [Столики].[id] 
				 		 INNER JOIN [Официанты] AS t1 ON [Счета посетителей].[id официанта] = t1.[id]
				 		 LEFT JOIN [Официанты] AS t2 ON [Счета посетителей].[id официанта установившего скидку] = t2.[id]
				 		 LEFT JOIN [Официанты] AS t3 ON [Счета посетителей].[id официанта установившего аванс] = t3.[id]
			WHERE [Номер счёта] = @numberBill
	END
END
GO


CREATE PROCEDURE [Получить предыдущие счета посетителей]
(@startNumberBill INT)
AS
BEGIN
	SELECT TOP 1000 [Счета посетителей].[id],[Номер счёта],ISNULL([Зал],'С собой') AS [Зал],[Номер столика],t1.[ФИО] AS [Открыл счёт],[Дата посещения],
		[Время открытия счёта],[Время закрытия счёта],[Скидка],t2.[ФИО] AS [Установил скидку],[Аванс],t3.[ФИО] AS [Установил аванс],
		dbo.[Получить счёта стоимость без скидки]([Номер счёта]) AS [Стоимость счёта]
		FROM [Счета посетителей] LEFT JOIN [Столики] ON [Счета посетителей].[id столика] = [Столики].[id] 
			 		 INNER JOIN [Официанты] AS t1 ON [Счета посетителей].[id официанта] = t1.[id]
			 		 LEFT JOIN [Официанты] AS t2 ON [Счета посетителей].[id официанта установившего скидку] = t2.[id]
			 		 LEFT JOIN [Официанты] AS t3 ON [Счета посетителей].[id официанта установившего аванс] = t3.[id]
		WHERE [Номер счёта] < @startNumberBill
		ORDER BY [Номер счёта] DESC
END
GO

CREATE PROCEDURE [Получить следующие счета посетителей]
(@startNumberBill INT)
AS
BEGIN
	SELECT TOP 1000 [Счета посетителей].[id],[Номер счёта],ISNULL([Зал],'С собой') AS [Зал],[Номер столика],t1.[ФИО] AS [Открыл счёт],[Дата посещения],
		[Время открытия счёта],[Время закрытия счёта],[Скидка],t2.[ФИО] AS [Установил скидку],[Аванс],t3.[ФИО] AS [Установил аванс],
		dbo.[Получить счёта стоимость без скидки]([Номер счёта]) AS [Стоимость счёта]
		FROM [Счета посетителей] LEFT JOIN [Столики] ON [Счета посетителей].[id столика] = [Столики].[id] 
			 		 INNER JOIN [Официанты] AS t1 ON [Счета посетителей].[id официанта] = t1.[id]
			 		 LEFT JOIN [Официанты] AS t2 ON [Счета посетителей].[id официанта установившего скидку] = t2.[id]
			 		 LEFT JOIN [Официанты] AS t3 ON [Счета посетителей].[id официанта установившего аванс] = t3.[id]
		WHERE [Номер счёта] > @startNumberBill
		ORDER BY [Номер счёта] DESC
END
GO


CREATE PROCEDURE [Получить заказы блюд]
(@numberBill INT)
AS
BEGIN
	SELECT [Заказы блюд].[id], [Блюда].[Русское название], t1.[ФИО] AS [Принял заказ], [Заказы блюд].[Время заказа], [Заказы блюд].[Вес],
			[Заказы блюд].[Количество],[Заказы блюд].[Время отмены], t2.[ФИО] AS [Отменил заказ], [Позже] AS [Готовить позже],
			[Заказы блюд].[Стоимость] AS [Стоимость без скидки]
        	FROM [Заказы блюд] INNER JOIN [Блюда] ON [Блюда].[id] = [Заказы блюд].[id блюда]     
        			   INNER JOIN [Официанты] AS t1 ON [Заказы блюд].[id официанта] = t1.[id]
	      			   LEFT JOIN [Официанты] AS t2 ON [Заказы блюд].[id отменившего официанта] = t2.[id]
                WHERE [Заказы блюд].[id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Получить заказы спецблюд]
(@numberBill INT)
AS
BEGIN
	SELECT [Заказы спецблюд].[id], [Заказы спецблюд].[Тип], [Заказы спецблюд].[Русское название], [Заказы спецблюд].[Время заказа], 
		[Заказы спецблюд].[Количество], [Заказы спецблюд].[Время отмены], t1.[ФИО] AS [Отменил заказ], [Позже] AS [Готовить позже],
		[Заказы спецблюд].[Стоимость]*[Заказы спецблюд].[Количество] AS [Стоимость без скидки]
        	FROM [Заказы спецблюд] LEFT JOIN [Официанты] AS t1 ON [Заказы спецблюд].[id отменившего официанта] = t1.[id]
                WHERE [Заказы спецблюд].[id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Получить заказы напитков]
(@numberBill INT)
AS
BEGIN
	SELECT [Заказы напитков].[id],[Напитки].[Русское название], t1.[ФИО] AS [Принял заказ], [Заказы напитков].[Время заказа], [Заказы напитков].[Объём], 
		[Заказы напитков].[Количество], [Заказы напитков].[Количество порций], [Заказы напитков].[Время отмены], t2.[ФИО] AS [Отменил заказ], [Позже] AS [Готовить позже],
		[Заказы напитков].[Стоимость] AS [Стоимость без скидки]
		FROM [Заказы напитков] INNER JOIN [Напитки] ON [Напитки].[id] = [Заказы напитков].[id напитка]
        			   INNER JOIN [Официанты] AS t1 ON [Заказы напитков].[id официанта] = t1.[id]
        			   LEFT JOIN [Официанты] AS t2 ON [Заказы напитков].[id отменившего официанта] = t2.[id]
		WHERE [Заказы напитков].[id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Получить заказы ланч блюд]
(@numberBill INT)
AS
BEGIN
	SELECT [Заказы ланч блюд].[id], [Ланч блюда].[Русское название], t1.[ФИО] AS [Принял заказ], [Заказы ланч блюд].[Время заказа], 
		[Заказы ланч блюд].[Номер комплекса], [Заказы ланч блюд].[Вес], [Заказы ланч блюд].[Количество],[Заказы ланч блюд].[Время отмены], 
		t2.[ФИО] AS [Отменил заказ], [Позже] AS [Готовить позже],
		[Заказы ланч блюд].[Стоимость] AS [Стоимость без скидки]
        	FROM [Заказы ланч блюд] INNER JOIN [Ланч блюда] ON [Ланч блюда].[id] = [Заказы ланч блюд].[id ланч блюда]     
        			   INNER JOIN [Официанты] AS t1 ON [Заказы ланч блюд].[id официанта] = t1.[id]
        			   LEFT JOIN [Официанты] AS t2 ON [Заказы ланч блюд].[id отменившего официанта] = t2.[id]
                WHERE [Заказы ланч блюд].[id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Задать порядок]
(@id INT, @type VARCHAR(5), @order INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		IF @type = 'd' UPDATE [Типы блюд] SET [Порядок] = @order WHERE [id] = @id
		IF @type = 'v' UPDATE [Типы напитков] SET [Порядок] = @order WHERE [id] = @id
		IF @type = 'dd' UPDATE [Блюда] SET [Порядок] = @order WHERE [id] = @id
	COMMIT TRANSACTION
END
GO

CREATE PROCEDURE [Задать порядок напитка]
(@id INT, @type VARCHAR(5), @idVineType INT, @order INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		IF @type = 'vv' UPDATE [Напитки с группировкой] 
			SET [Порядок] = @order 
			WHERE [id типа напитка] = @idVineType AND 
			 [id] IN (SELECT [id] FROM [Напитки] WHERE [Русское название] = (SELECT [Русское название] FROM [Напитки] WHERE [id] = @id))
	COMMIT TRANSACTION
END
GO



CREATE PROCEDURE [Получить недоступные блюда]
AS
BEGIN
	SELECT [Блюда].[id],[Русское название],[Тип блюда],[Доступность]
		FROM [Блюда] INNER JOIN [Типы блюд] ON [Блюда].[id типа блюда] = [Типы блюд].[id]
END
GO


CREATE PROCEDURE [Получить недоступные напитки]
AS
BEGIN
	SELECT DISTINCT [Напитки].[Русское название],[Тип напитка],[Доступность]
		FROM [Напитки] INNER JOIN [Типы напитков] ON [Напитки].[id типа напитка] = [Типы напитков].[id]
END
GO


CREATE PROCEDURE [Получить недоступные ингредиенты]
AS
BEGIN
	SELECT [Ингредиенты].[id],[Название ингредиента],[Тип ингредиента],[Доступность]
		FROM [Ингредиенты] INNER JOIN [Типы ингредиентов] ON [Ингредиенты].[id типа ингредиента] = [Типы ингредиентов].[id]
END
GO


CREATE PROCEDURE [Изменить доступность блюда]
(@id INT, @type VARCHAR(12))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Блюда]
		SET [Доступность] = @type
		WHERE [id] = @id        
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Изменить доступность напитка]
(@vineName VARCHAR(80), @type VARCHAR(12))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Напитки]
		SET [Доступность] = @type
		WHERE [Русское название] = @vineName        
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Изменить доступность ингредиента]
(@id INT, @type VARCHAR(12))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Ингредиенты]
		SET [Доступность] = @type
		WHERE [id] = @id        
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Заказать спецблюдо]
(@numberBill INT, @type VARCHAR(20), @rusName VARCHAR(80), @receiptName VARCHAR(40), @cost MONEY, @count INT, @time TIME(0), @ceh VARCHAR(20), @later VARCHAR(15))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		INSERT INTO [Заказы спецблюд] VALUES((SELECT [id] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill),
						     @type,
						     @rusName,
						     @receiptName,
						     dbo.[Округление цены](@cost),
						     @count,
						     @time,
						     NULL,
						     NULL,
						     (SELECT [id] FROM [Цеха] WHERE [Цех] = @ceh),
						     @later)	
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Убрать ингредиент из рецепта]
(@idDish INT, @idIngr INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		DELETE FROM [Рецепты]
			WHERE [id блюда] = @idDish AND [id ингредиента] = @idIngr
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Добавить ингредиент в используемые рецепты]
(@idDish INT, @idIngr INT)
AS
BEGIN
	IF EXISTS(SELECT * FROM [Рецепты] WHERE [id блюда] = @idDish AND [id ингредиента] = @idIngr) RETURN

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		INSERT INTO [Рецепты] VALUES(@idDish,@idIngr,'1')
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Добавить ингредиент в добавляемые рецепты]
(@idDish INT, @idIngr INT)
AS
BEGIN
	IF EXISTS(SELECT * FROM [Рецепты] WHERE [id блюда] = @idDish AND [id ингредиента] = @idIngr) RETURN

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		INSERT INTO [Рецепты] VALUES(@idDish,@idIngr,'0')
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Убрать ингредиент из ланч рецепта]
(@idDish INT, @idIngr INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		DELETE FROM [Ланч рецепты]
			WHERE [id ланч блюда] = @idDish AND [id ингредиента] = @idIngr
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Добавить ингредиент в используемые ланч рецепты]
(@idDish INT, @idIngr INT)
AS
BEGIN
	IF EXISTS(SELECT * FROM [Ланч рецепты] WHERE [id ланч блюда] = @idDish AND [id ингредиента] = @idIngr) RETURN

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		INSERT INTO [Ланч рецепты] VALUES(@idDish,@idIngr,'1')
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Добавить ингредиент в добавляемые ланч рецепты]
(@idDish INT, @idIngr INT)
AS
BEGIN
	IF EXISTS(SELECT * FROM [Ланч рецепты] WHERE [id ланч блюда] = @idDish AND [id ингредиента] = @idIngr) RETURN

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		INSERT INTO [Ланч рецепты] VALUES(@idDish,@idIngr,'0')
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Получить напитки для группы]
(@idVineGroup INT)
AS
BEGIN
	SELECT DISTINCT [Русское название],[Тип напитка]
		FROM [Напитки с группировкой] INNER JOIN [Напитки] ON [Напитки с группировкой].[id] = [Напитки].[id]
						INNER JOIN [Типы напитков] ON [Типы напитков].[id] = [Напитки].[id типа напитка]
		WHERE [Напитки с группировкой].[id типа напитка] = @idVineGroup
END
GO


CREATE PROCEDURE [Убрать напиток из группы]
(@idGroup INT, @vine VARCHAR(80))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		DELETE FROM [Напитки с группировкой]
			WHERE [id типа напитка] = @idGroup AND [id] IN (SELECT [id] FROM [Напитки] WHERE [Русское название]= @vine)
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Добавить напиток в группу]
(@idGroup INT, @vine VARCHAR(80))
AS                                                                      
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		INSERT INTO [Напитки с группировкой] 
			SELECT [id],@idGroup,100000
				FROM [Напитки]
				WHERE [Русское название] = @vine
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Получить группы напитка]
(@vine VARCHAR(80))
AS
BEGIN
	SELECT [Типы напитков].[Тип напитка]
		FROM [Группировка напитков] INNER JOIN [Типы напитков] ON [Группировка напитков].[id типа напитка] = [Типы напитков].[id]
		WHERE [Название напитка] = @vine
END
GO


CREATE PROCEDURE [Получить блюда для типа блюд]
(@idDishType INT)
AS
BEGIN
	SELECT [id],[Русское название],666,[Блюда].[Порядок]
		FROM [Блюда]
		WHERE [id типа блюда] = @idDishType
		ORDER BY [Порядок]
END
GO


CREATE PROCEDURE [Получить напитки для типа напитков]
(@idVineType INT)
AS
BEGIN
	SELECT [Напитки].[id],[Русское название],@idVineType AS col3,[Порядок]
		INTO #res
		FROM [Напитки с группировкой] INNER JOIN [Напитки] ON [Напитки с группировкой].[id] = [Напитки].[id]
		WHERE [Напитки с группировкой].[id типа напитка] = @idVineType
		ORDER BY [Порядок]

	DELETE FROM #res
		WHERE EXISTS(SELECT * FROM #res AS t WHERE t.[Русское название] = #res.[Русское название] AND t.[id] < #res.[id])

	SELECT * FROM #res
		ORDER BY [Порядок]
END
GO


CREATE PROCEDURE [Переместить счёт на другой столик]
(@numberBill INT, @room VARCHAR(20), @table INT, @oldRoom VARCHAR(20), @oldTable INT)
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		UPDATE [Счета посетителей]
			SET [id столика] = (SELECT [id] FROM [Столики] WHERE [Зал] = @room AND [Номер столика] = @table)
			WHERE [Номер счёта] = @numberBill

		UPDATE [Столики] 
			SET [состояние]=1 
			WHERE [Зал] = @room AND [Номер столика] = @table

		IF NOT EXISTS(SELECT * FROM [Счета посетителей] 
					WHERE [id столика] = (SELECT [id] FROM [Столики] WHERE [Зал] = @oldRoom AND [Номер столика] = @oldTable)
					AND [Время закрытия счёта] IS NULL)
		BEGIN
			UPDATE [Столики] 
				SET [состояние]=0 
				WHERE [Зал] = @oldRoom AND [Номер столика] = @oldTable
		END
	COMMIT TRANSACTION	
END
GO
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/***********************************************************/
/*Процедуры для работы клиентов*/
/***********************************************************/
CREATE PROCEDURE [Проверить счёт]
(@numberBill INT)
AS
BEGIN
	IF (SELECT [Номер счёта] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill) IS NULL
	BEGIN
		SELECT 'error <?main?> <!Такого счёта нет!!>';
		RETURN
	END
	IF (SELECT [Время закрытия счёта] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill) IS NOT NULL
	BEGIN
		SELECT 'error <?main?> <!Счёт уже закрыт!!>';
		RETURN
	END
	SELECT 'done'
END
GO


CREATE PROCEDURE [Проверить официанта]
(@waiter VARCHAR(100))
AS
BEGIN
	IF (SELECT [ФИО] FROM [Официанты] WHERE [ФИО] = @waiter) IS NULL
	BEGIN
		SELECT 'error <?login?> <!Такого официанта не существует!!>';
		RETURN
	END
	SELECT 'done'
END
GO


CREATE PROCEDURE [Проверить блюдо]
(@dishName VARCHAR(80), @BEI VARCHAR(20))
AS
BEGIN
	IF @BEI = '' SET @BEI = '100'

	IF (SELECT [id] FROM [Блюда] WHERE [Русское название] = @dishName AND [БЕИ] = @BEI) IS NULL
	BEGIN
		SELECT 'error <?get?> <!Блюда с таким БЕИ не существует!!>';
		RETURN
	END
	SELECT 'done'
END
GO


CREATE PROCEDURE [Проверить ингредиент]
(@ingrName VARCHAR(50))
AS
BEGIN
	IF (SELECT [id] FROM [Ингредиенты] WHERE [Название ингредиента] = @ingrName) IS NULL
	BEGIN
		SELECT 'error <?get?> <!Такого ингредиента не существует!!>';
		RETURN
	END
	SELECT 'done'
END
GO


CREATE PROCEDURE [Проверить ланч блюдо]
(@dishName VARCHAR(80), @BEI VARCHAR(20))
AS
BEGIN
	IF @BEI = '' SET @BEI = '100'

	IF (SELECT [id] FROM [Ланч блюда] WHERE [Русское название] = @dishName AND [БЕИ] = @BEI) IS NULL
	BEGIN
		SELECT 'error <?get?> <!Ланч блюда с таким БЕИ не существует!!>';
		RETURN
	END
	SELECT 'done'
END
GO


CREATE PROCEDURE [Проверить напиток]
(@dishName VARCHAR(80), @BEI VARCHAR(20))
AS
BEGIN
	IF (SELECT [id] FROM [Напитки] WHERE [Русское название] = @dishName AND [БЕИ] = @BEI) IS NULL
	BEGIN
		SELECT 'error <?get?> <!Напитка с таким БЕИ не существует!!>';
		RETURN
	END
	SELECT 'done'
END
GO



/******/
CREATE PROCEDURE [Получить фио официантов]
AS
BEGIN
	SELECT [фио] 
		FROM [Официанты]
		WHERE [фио] <> 'admin'
		ORDER BY [фио]
END
GO
/******/


CREATE PROCEDURE [Получить открытые счета]
AS
BEGIN
	SELECT [зал],[номер столика],[номер счёта] 
		FROM [Счета посетителей] INNER JOIN [Столики] ON [Столики].[id] = [Счета посетителей].[id столика]
		WHERE [время закрытия счёта] IS NULL
		ORDER BY [зал],[номер столика],[номер счёта]
END
GO
/******/


CREATE PROCEDURE [Получить счета на вынос]
AS
BEGIN
	SELECT [номер счёта] 
		FROM [Счета посетителей]
		WHERE [время закрытия счёта] IS NULL
		 AND [id столика] IS NULL
END
GO
/******/


CREATE PROCEDURE [Получить новый счёт](
@room VARCHAR(20), @waiter VARCHAR(100), @table INT)
AS
BEGIN
	DECLARE @tableId INT
	SELECT @tableId=[Столики].[id] 
		FROM [Столики]
	        WHERE [зал]=@room AND [номер столика]=@table

	DECLARE @nextId INT
	
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		UPDATE [Следующее значение параметра] SET [следующее значение]=[следующее значение]+1 WHERE [параметр] = 'номер счёта'
		SELECT @nextId=[следующее значение]-1 FROM [Следующее значение параметра] WHERE [параметр]='номер счёта'

	INSERT INTO [Счета посетителей]([номер счёта],[id столика],[id официанта],[дата посещения],[время открытия счёта])
		VALUES(@nextId,
		       @tableId,
		       (SELECT [id] FROM [Официанты] WHERE [фио] = @waiter),
		       GETDATE(),
		       CURRENT_TIMESTAMP
		      )

	UPDATE [Столики] 
		SET [состояние]=1 
		WHERE [id]=@tableId
	COMMIT TRANSACTION
	SELECT @nextId
END
GO
/******/


CREATE PROCEDURE [Закрыть счёт]
(@numberBill INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	DECLARE @tableId INT
	UPDATE [Счета посетителей] 
		SET [время закрытия счёта]=CURRENT_TIMESTAMP 
		WHERE [номер счёта]=@numberBill
	COMMIT TRANSACTION

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	IF NOT EXISTS(SELECT * FROM [Счета посетителей] 
			WHERE [время закрытия счёта] IS NULL
			AND [id столика] = (SELECT [id столика] FROM [Счета посетителей] WHERE [номер счёта]=@numberBill)
		 )	
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
		BEGIN TRANSACTION
		UPDATE [Столики]
			SET [состояние] = 2
			WHERE [id] = (SELECT [id столика] FROM [Счета посетителей] WHERE [номер счёта]=@numberBill)
		COMMIT TRANSACTION
	END
END
GO
/******/


CREATE PROCEDURE [Получить счета официанта]
(@waiter VARCHAR(100))
AS
BEGIN
	SELECT [зал],[номер столика],[номер счёта] 
		FROM [Счета посетителей] INNER JOIN [Столики] ON [Столики].[id] = [Счета посетителей].[id столика]
		WHERE [id официанта] = (SELECT [id] FROM [Официанты] WHERE [фио] = @waiter)
		 AND [Счета посетителей].[время закрытия счёта] IS NULL
		ORDER BY [зал],[номер столика],[номер счёта]
END
GO
/******/


CREATE PROCEDURE [Освободить столик]
(@room VARCHAR(20), @table INT)
AS 
BEGIN
	IF (SELECT [состояние] FROM [Столики] WHERE [Номер столика] = @table AND [Зал] = @room) = 0
	BEGIN
		SELECT 'error <?main?> <!Данный столик уже свободен!!>';
		RETURN
	END
	IF (SELECT [состояние] FROM [Столики] WHERE [Номер столика] = @table AND [Зал] = @room) = 1
	BEGIN
		SELECT 'error <?login?> <!Данный столик занят!!>';
		RETURN
	END

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Столики]
		SET [состояние] = 0
		WHERE [Номер столика] = @table AND [Зал] = @room
	COMMIT TRANSACTION
	SELECT 'done'
END
GO
/******/


CREATE PROCEDURE [Получить уходящие столики]
AS
BEGIN
	SELECT [Зал],[Номер столика] 
		FROM [Столики]
		WHERE [состояние] = 2
		ORDER BY [Зал],[Номер столика]
END
GO
/******/


CREATE PROCEDURE [Получить ближайшие брони]
AS
BEGIN
	DECLARE @time TIME(0)
	SET @time=GETDATE()

	SELECT [зал],[номер столика],MIN([время с]),MIN([время по])
		FROM [Получить данные о бронировании столиков без отменённых](NULL,NULL,NULL,NULL)
		WHERE [время по]>=@time
		GROUP BY [зал],[номер столика]
		ORDER BY [зал],[номер столика]
END
GO
/******/
CREATE PROCEDURE [Получить список типов]
AS
BEGIN 
	SELECT [id],[Тип блюда],'d',[Порядок]
		FROM [Типы блюд]
		WHERE [Видимость] = 'Показывать'
	UNION
	SELECT [id],[Тип напитка],'v',[Порядок]
		FROM [Типы напитков]
		WHERE [Видимость] = 'Показывать'
	ORDER BY 4
END
GO


CREATE PROCEDURE [Получить список ингредиентов]
AS
BEGIN 
	SELECT [Название ингредиента],[Доступность],[Ингредиенты].[id] 
		FROM [Ингредиенты] INNER JOIN [Типы ингредиентов] ON [Ингредиенты].[id типа ингредиента] = [Типы ингредиентов].[id]
		WHERE [Типы ингредиентов].[Видимость] = 'Показывать'
END
GO


CREATE FUNCTION [Узнать цех назначения](@idCeh INT)
RETURNS VARCHAR(5)
BEGIN
        DECLARE @res VARCHAR(5)
	IF (SELECT [Цех] FROM [Цеха] WHERE [id] = @idCeh)<>'Бар' SET @res = 'k'
	ELSE SET @res = 'b'
	RETURN @res
END
GO


CREATE PROCEDURE [Получить список блюд]
AS
BEGIN
	SELECT [Блюда].[id], [Блюда].[Русское название], [Блюда].[беи], [Типы блюд].[Тип блюда],[Блюда].[Доступность],dbo.[Узнать цех назначения]([Блюда].[id цеха])
        	FROM [Блюда] INNER JOIN [Типы блюд] ON [Блюда].[id типа блюда] = [Типы блюд].[id]
        	WHERE [Типы блюд].[Видимость] = 'Показывать' AND [Блюда].[Доступность] = 'Доступно'
        	ORDER BY [Типы блюд].[Порядок],[Блюда].[Порядок],[тип блюда],[Русское название]
END
GO


CREATE PROCEDURE [Получить используемые ингредиенты для блюда]
(@idDish INT)
AS
BEGIN
	SELECT [Ингредиенты].[название ингредиента],[Ингредиенты].[id]
		FROM [Рецепты] INNER JOIN [Ингредиенты] ON [Ингредиенты].[id]=[Рецепты].[id ингредиента]
		WHERE [id блюда]=@idDish
		 AND [статус]=1
		 AND [Доступность] = 'Доступно'
END
GO


CREATE PROCEDURE [Получить добавляемые ингредиенты для блюда]
(@idDish INT)
AS
BEGIN
	SELECT [Ингредиенты].[название ингредиента],[Ингредиенты].[id]
		FROM [Рецепты] INNER JOIN [Ингредиенты] ON [Ингредиенты].[id]=[Рецепты].[id ингредиента]
		WHERE [id блюда]=@idDish 
		 AND [статус]=0
		 AND [Доступность] = 'Доступно'
END
GO


CREATE PROCEDURE [Получить список напитков]
AS
BEGIN
	SELECT [Напитки].[Русское название], [Напитки].[беи], [Типы напитков].[Тип напитка],[Напитки].[Доступность],'b'
		FROM [Напитки с группировкой] INNER JOIN [Напитки] ON [Напитки с группировкой].[id] = [Напитки].[id]
					      INNER JOIN [Типы напитков] ON [Напитки с группировкой].[id типа напитка] = [Типы напитков].[id]
        	WHERE [Типы напитков].[Видимость] = 'Показывать' AND [Напитки].[Доступность] = 'Доступно'
		ORDER BY [Типы напитков].[Порядок],[Напитки с группировкой].[Порядок],[Тип напитка],[Русское название]
END
GO


CREATE PROCEDURE [Получить список ланч блюд]
(@date DATE)
AS
BEGIN
        IF @date IS NOT NULL
        BEGIN
		SELECT [Ланч блюда].[id],[Ланч блюда].[Русское название], [Ланч блюда].[беи], [Ланч блюда].[тип ланч блюда],[Ланч блюда].[Доступность]
        		FROM [Ланч расписание] INNER JOIN [Ланч блюда] ON [Ланч расписание].[id ланч блюда] = [Ланч блюда].[id]
			WHERE [Ланч расписание].[дата] = @date
	END
	ELSE
	BEGIN
		SELECT [Ланч блюда].[id],[Ланч блюда].[Русское название], [Ланч блюда].[беи], [Ланч блюда].[тип ланч блюда],[Ланч блюда].[Доступность]
        		FROM [Ланч блюда]
	END
END
GO


CREATE PROCEDURE [Получить используемые ингредиенты для ланч блюда]
(@idDish INT)
AS
BEGIN
	SELECT [Ингредиенты].[название ингредиента],[Ингредиенты].[id]
		FROM [Ланч рецепты] INNER JOIN [Ингредиенты] ON [Ингредиенты].[id]=[Ланч рецепты].[id ингредиента]
		WHERE [id ланч блюда]=@idDish 
		 AND [статус]=1
		 AND [Доступность] = 'Доступно'
END
GO


CREATE PROCEDURE [Получить добавляемые ингредиенты для ланч блюда]
(@idDish INT)
AS
BEGIN
	SELECT [Ингредиенты].[название ингредиента],[Ингредиенты].[id]
		FROM [Ланч рецепты] INNER JOIN [Ингредиенты] ON [Ингредиенты].[id]=[Ланч рецепты].[id ингредиента]
		WHERE [id ланч блюда]=@idDish 
		 AND [статус]=0
		 AND [Доступность] = 'Доступно'
END
GO
/******/
CREATE PROCEDURE [Получить скидку для счёта]
(@numberBill INT)
AS
BEGIN
	SELECT ISNULL([Скидка],0)
        	FROM [Счета посетителей] WHERE [номер счёта] = @numberBill
END
GO


CREATE PROCEDURE [Получить аванс для счёта]
(@numberBill INT)
AS
BEGIN
	SELECT ISNULL([Аванс],0)
        	FROM [Счета посетителей] WHERE [номер счёта] = @numberBill
END
GO


CREATE PROCEDURE [Получить бронирование столиков]
(@room VARCHAR(20), @table INT)
AS
BEGIN
	IF @room IS NULL /*@table тогда тоже*/
	BEGIN
		SELECT [Забронированные столики].[id], [Зал],[Номер столика], t1.[ФИО]AS [Забронировал столик], [Дата брони],[Время с],[Время по],[Дата отмены],[Время отмены], t2.[ФИО] AS [Отменил бронь]
			FROM [Забронированные столики] INNER JOIN [Столики] ON [Забронированные столики].[id столика] = [Столики].[id]
							INNER JOIN [Официанты] AS t1 ON t1.[id] = [Забронированные столики].[id забронировавшего официанта]
							LEFT JOIN [Официанты] AS t2 ON t2.[id] = [Забронированные столики].[id отменившего официанта]
			ORDER BY [Дата брони] DESC,[Зал] DESC,[Номер столика],[Время с],[Время по]
	END
	ELSE
	BEGIN
		SELECT [Забронированные столики].[id], [Зал],[Номер столика],t1.[ФИО]AS [Забронировал столик], [Дата брони],[Время с],[Время по],[Дата отмены],[Время отмены],t2.[ФИО] AS [Отменил бронь]
			FROM [Забронированные столики] INNER JOIN [Столики] ON [Забронированные столики].[id столика] = [Столики].[id]
							INNER JOIN [Официанты] AS t1 ON t1.[id] = [Забронированные столики].[id забронировавшего официанта]
							LEFT JOIN [Официанты] AS t2 ON t2.[id] = [Забронированные столики].[id отменившего официанта]
			WHERE [Зал] = @room AND [Номер столика] = @table
			ORDER BY [Дата брони] DESC,[Зал] DESC,[Номер столика],[Время с],[Время по]
	END
END
GO


CREATE PROCEDURE [Получить заказы блюд для счёта]
(@numberBill INT)
AS
BEGIN
	SELECT [Заказы блюд].[id], [Блюда].[Русское название], [Заказы блюд].[вес], [Заказы блюд].[количество],[Заказы блюд].[время отмены],[Заказы блюд].[Позже]
        	FROM [Заказы блюд] INNER JOIN [Блюда] ON [Блюда].[id] = [Заказы блюд].[id блюда]     
                WHERE [Заказы блюд].[id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Получить изменение рецепта для заказа блюда]
(@idOrderDish INT)
AS
BEGIN
	SELECT [Ингредиенты].[название ингредиента], [Изменение рецептов блюд].[добавить]
		FROM [Ингредиенты] INNER JOIN [Изменение рецептов блюд] ON [Изменение рецептов блюд].[id ингредиента] = [Ингредиенты].[id]
		WHERE [Изменение рецептов блюд].[id заказа блюда] = @idOrderDish
END
GO


CREATE PROCEDURE [Получить заказы напитков для счёта]
(@numberBill INT)
AS
BEGIN
	SELECT [Заказы напитков].[id],[Напитки].[Русское название], [Заказы напитков].[объём], [Заказы напитков].[количество], [Заказы напитков].[время отмены], [Заказы напитков].[количество порций],[Заказы напитков].[Позже]
		FROM [Заказы напитков] INNER JOIN [Напитки] ON [Напитки].[id] = [Заказы напитков].[id напитка]
		WHERE [Заказы напитков].[id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Получить заказы ланч блюд для счёта]
(@numberBill INT)
AS
BEGIN
	SELECT [Заказы ланч блюд].[id], [Ланч блюда].[Русское название], [Заказы ланч блюд].[Номер комплекса], [Заказы ланч блюд].[вес], [Заказы ланч блюд].[количество],[Заказы ланч блюд].[время отмены],[Заказы ланч блюд].[Позже]
        	FROM [Заказы ланч блюд] INNER JOIN [Ланч блюда] ON [Ланч блюда].[id] = [Заказы ланч блюд].[id ланч блюда]     
                WHERE [Заказы ланч блюд].[id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Получить изменение рецепта для заказа ланч блюда]
(@idOrderDish INT)
AS
BEGIN
	SELECT [Ингредиенты].[название ингредиента], [Изменение рецептов ланч блюд].[добавить]
		FROM [Ингредиенты] INNER JOIN [Изменение рецептов ланч блюд] ON [Изменение рецептов ланч блюд].[id ингредиента] = [Ингредиенты].[id]
		WHERE [Изменение рецептов ланч блюд].[id заказа ланч блюда] = @idOrderDish
END
GO

CREATE PROCEDURE [Получить заказы спецблюд блюд для счёта]
(@numberBill INT)
AS
BEGIN
	SELECT [id], [Русское название], [Количество], [Время отмены], [Позже]
        	FROM [Заказы спецблюд]
                WHERE [id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
                 AND [Тип] = 'Блюдо'
END
GO


CREATE PROCEDURE [Получить заказы спецблюд напитков для счёта]
(@numberBill INT)
AS
BEGIN
	SELECT [id], [Русское название], [Количество], [Время отмены], [Позже]
        	FROM [Заказы спецблюд]
                WHERE [id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
                 AND [Тип] = 'Напиток'
END
GO
/*******/


CREATE PROCEDURE [Добавить в заказ блюдо]
(@numberBill INT, @waiter VARCHAR(100), @dishName VARCHAR(80), @bei VARCHAR(20), @dishCount INT, @later VARCHAR(15))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	INSERT INTO [Заказы блюд] VALUES((SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill),
					 (SELECT [id] FROM [Официанты] WHERE [фио]=@waiter),
					 (SELECT [id] FROM [Блюда] WHERE [Русское название] = @dishName),
					 @bei,
					 @dishCount,
					 0,
					 CURRENT_TIMESTAMP,
					 NULL,
					 NULL,
					 @later);
	SELECT CAST(SCOPE_IDENTITY() AS INT), [цех]
		FROM [цеха] WHERE [id] = (SELECT [id цеха] FROM [Блюда] WHERE [Русское название] = @dishName)
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Добавить в блюдо ингредиент]
(@idOrderDish INT, @ingredientName VARCHAR(80), @ingredientType VARCHAR(50))
AS                                	
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	INSERT INTO [Изменение рецептов блюд] VALUES(@idOrderDish,
						     (SELECT [id] FROM [Ингредиенты] WHERE [название ингредиента] = @ingredientName), 
						     @ingredientType
						    )
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Получить последний номер комплекса]
(@numberBill INT)
AS
BEGIN
	SELECT ISNULL(MAX([Номер комплекса]),0)
		FROM [Заказы ланч блюд]
		WHERE [id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill)
END
GO


CREATE PROCEDURE [Добавить в заказ ланч блюдо]
(@numberBill INT, @waiter VARCHAR(100), @dishName VARCHAR(80), @numberDish INT, @bei VARCHAR(20), @dishCount INT, @later VARCHAR(15))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	INSERT INTO [Заказы ланч блюд] VALUES((SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill),
					 (SELECT [id] FROM [Официанты] WHERE [фио]=@waiter),
					 (SELECT [id] FROM [Ланч блюда] WHERE [Русское название] = @dishName),
					 @numberDish,
					 @bei,
					 @dishCount,
					 0,
					 CURRENT_TIMESTAMP,
					 NULL,
					 NULL,
					 @later);
	SELECT CAST(SCOPE_IDENTITY() AS INT), [цех]
		FROM [цеха] WHERE [id] = (SELECT [id цеха] FROM [Ланч блюда] WHERE [Русское название] = @dishName)
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Добавить в ланч блюдо ингредиент]
(@idOrderDish INT, @ingredientName VARCHAR(80), @ingredientType VARCHAR(50))
AS                                	
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	INSERT INTO [Изменение рецептов ланч блюд] VALUES(@idOrderDish,
						     (SELECT [id] FROM [Ингредиенты] WHERE [название ингредиента] = @ingredientName), 
						     @ingredientType
						    )
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Получить зал и столик для счёта]
(@numberbill INT)
AS
BEGIN
        DECLARE @room VARCHAR(20), @table INT
	SELECT @room=[зал], @table=[номер столика]
		FROM [Счета посетителей] INNER JOIN [Столики] ON [Столики].[id] = [Счета посетителей].[id столика]
		WHERE [Счета посетителей].[номер счёта] = @numberBill

 	SELECT ISNULL(@room,'На вынос'), ISNULL(@table, 0)
END
GO


CREATE PROCEDURE [Добавить в заказ напиток]
(@numberBill INT, @waiter VARCHAR(100), @vineName VARCHAR(80), @bei VARCHAR(20), @vineCount INT, @vineQuantity INT, @later VARCHAR(15))
AS
BEGIN
	DECLARE @idNapitka INT	                                                         	
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	INSERT INTO [Заказы напитков] VALUES((SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill),
					 (SELECT [id] FROM [Официанты] WHERE [фио]=@waiter),
					 (SELECT [id] FROM [Напитки] WHERE [Русское название] = @vineName AND [беи] = @bei),
					 @bei,
					 @vineCount,
					 @vineQuantity,
					 0,
					 CURRENT_TIMESTAMP,
					 NULL,
					 NULL,
					 @later);
	SELECT CAST(SCOPE_IDENTITY() AS INT)
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Отменить заказ блюда]
(@waiterName VARCHAR(100), @idOrderDish INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Заказы блюд] 
		SET [время отмены]=CURRENT_TIMESTAMP,
		    [id отменившего официанта] = (SELECT [id] FROM [Официанты] WHERE [фио] = @waiterName)
		WHERE [id] = @idOrderDish
	COMMIT TRANSACTION
	SELECT [Русское название],[количество],[цех],[Позже]
		FROM [Заказы блюд] INNER JOIN [Блюда] ON [Блюда].[id] = [Заказы блюд].[id блюда]
					INNER JOIN [Цеха] ON [Цеха].[id] = [Блюда].[id цеха]
		WHERE [Заказы блюд].[id] = @idOrderDish
END
GO


CREATE PROCEDURE [Отменить заказ напитка]
(@waiterName VARCHAR(100), @idOrderDish INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Заказы напитков] 
		SET [время отмены]=CURRENT_TIMESTAMP,
		    [id отменившего официанта] = (SELECT [id] FROM [Официанты] WHERE [фио] = @waiterName)
		WHERE [id] = @idOrderDish
	COMMIT TRANSACTION
	SELECT [Русское название],[количество],[количество порций],[беи],[Позже]
		FROM [Заказы напитков] INNER JOIN [Напитки] ON [Напитки].[id] = [Заказы напитков].[id напитка]
		WHERE [Заказы напитков].[id] = @idOrderDish
END
GO


CREATE PROCEDURE [Отменить заказ ланч блюда]
(@waiterName VARCHAR(100), @idOrderDish INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Заказы ланч блюд] 
		SET [время отмены]=CURRENT_TIMESTAMP,
		    [id отменившего официанта] = (SELECT [id] FROM [Официанты] WHERE [фио] = @waiterName)
		WHERE [id] = @idOrderDish
	COMMIT TRANSACTION
	SELECT [Русское название],[количество],[цех],[Позже]
		FROM [Заказы ланч блюд] INNER JOIN [Ланч блюда] ON [Ланч блюда].[id] = [Заказы ланч блюд].[id ланч блюда]
					INNER JOIN [Цеха] ON [Цеха].[id] = [Ланч блюда].[id цеха]
		WHERE [Заказы ланч блюд].[id] = @idOrderDish
END
GO


CREATE PROCEDURE [Отменить заказ спецблюда]
(@waiterName VARCHAR(100), @idOrderDish INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Заказы спецблюд] 
		SET [время отмены]=CURRENT_TIMESTAMP,
		    [id отменившего официанта] = (SELECT [id] FROM [Официанты] WHERE [фио] = @waiterName)
		WHERE [id] = @idOrderDish
	COMMIT TRANSACTION
	SELECT [Русское название],[количество],[цех],[Позже]
		FROM [Заказы спецблюд] INNER JOIN [Цеха] ON [Цеха].[id] = [Заказы спецблюд].[id цеха]
		WHERE [Заказы спецблюд].[id] = @idOrderDish
END
GO


CREATE PROCEDURE [Задать вес блюда]
(@width VARCHAR(20), @dishId INT)
AS
BEGIN
	IF (SELECT [id] FROM [Заказы блюд] WHERE [id] = @dishId) IS NULL
	BEGIN
		SELECT 'error <?get?> <!Такого заказа блюда не существует!!>';
		RETURN
	END
	IF (SELECT [Время отмены] FROM [Заказы блюд] WHERE [id] = @dishId) IS NOT NULL
	BEGIN
		SELECT 'error <?this?> <!Заказ данного блюда отменён!!>';
		RETURN
	END

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Заказы блюд]
		SET [вес] = @width
		WHERE [id] = @dishId
	COMMIT TRANSACTION
	SELECT 'done'
END
GO


CREATE PROCEDURE [Задать вес ланч блюда]
(@width VARCHAR(20), @complexId INT)
AS
BEGIN
	IF (SELECT [id] FROM [Заказы ланч блюд] WHERE [id] = @complexId) IS NULL
	BEGIN
		SELECT 'error <?get?> <!Такого заказа ланч блюда не существует!!>';
		RETURN
	END
	IF (SELECT [Время отмены] FROM [Заказы ланч блюд] WHERE [id] = @complexId) IS NOT NULL
	BEGIN
		SELECT 'error <?this?> <!Заказ данного ланч блюда отменён!!>';
		RETURN
	END

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Заказы ланч блюд]
		SET [вес] = @width
		WHERE [id] = @complexId
	COMMIT TRANSACTION
	SELECT 'done'
END
GO


CREATE PROCEDURE [Задать скидку]
(@numberBill INT, @skidka INT, @waiter VARCHAR(100))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	UPDATE [Счета посетителей]
		SET [скидка] = @skidka, [id официанта установившего скидку] = (SELECT [id] FROM [Официанты] WHERE [ФИО] = @waiter)
		WHERE [номер счёта] = @numberBill
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Изменить номер счёта для блюда]
(@numberBill INT, @dishId INT, @dishCount INT)
AS
BEGIN
	DECLARE @scId INT

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		IF (@dishCount = 0)
		BEGIN
			UPDATE [Заказы блюд] SET [id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
				WHERE [id] = @dishId
		END
		ELSE
		BEGIN
			UPDATE [Заказы блюд] SET [Количество] = [Количество] - @dishCount
				WHERE [id] = @dishId

			INSERT INTO [Заказы блюд]
				SELECT (SELECT [id] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill),
					[id официанта],
					[id блюда],
					[Вес],
					@dishCount,
					0,
					[Время заказа],
					[id отменившего официанта],
					[Время отмены],
					[Позже]
				FROM [Заказы блюд] WHERE [Заказы блюд].[id] = @dishId

			SELECT @scId = CAST(SCOPE_IDENTITY() AS INT)
			INSERT INTO [Изменение рецептов блюд]
				SELECT @scId,
					[id ингредиента],
					[Добавить]
				FROM [Изменение рецептов блюд] WHERE [id заказа блюда] = @dishId						
		END
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Изменить номер счёта для напитка]
(@numberBill INT, @vineId INT, @vineCount INT)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		IF (@vineCount = 0)
		BEGIN
			UPDATE [Заказы напитков] SET [id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
				WHERE [id] = @vineId
		END
		ELSE
		BEGIN
			UPDATE [Заказы напитков] SET [Количество] = [Количество] - @vineCount
				WHERE [id] = @vineId

			INSERT INTO [Заказы напитков]
				SELECT (SELECT [id] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill),
					[id официанта],
					[id напитка],
					[Объём],
					@vineCount,
					[Количество порций],
					0,
					[Время заказа],
					[id отменившего официанта],
					[Время отмены],
					[Позже]
				FROM [Заказы напитков] WHERE [Заказы напитков].[id] = @vineId
		END
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Изменить номер счёта для комплекса]
(@numberBill INT, @complexId INT, @complexCount INT, @complexNumber INT)
AS
BEGIN
	DECLARE @idBill INT, @scId INT
	SELECT @idBill=[id] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		IF @complexCount = 0
		BEGIN
			INSERT INTO [Заказы ланч блюд]
				SELECT @idBill,
					[id официанта],
					[id ланч блюда],
					@complexNumber,
					[Вес],
					(SELECT [Количество] FROM [Заказы ланч блюд] WHERE [id] = @complexId),
					0,
					[Время заказа],
					[id отменившего официанта],
					[Время отмены],
					[Позже]
				FROM [Заказы ланч блюд] WHERE [Заказы ланч блюд].[id] = @complexId

			SELECT @scId = CAST(SCOPE_IDENTITY() AS INT)
			UPDATE [Изменение рецептов ланч блюд]
				SET [id заказа ланч блюда] = @scId
                                WHERE [id заказа ланч блюда] = @complexId						

			DELETE FROM [Заказы ланч блюд]
				WHERE [id] = @complexId

		END
		ELSE
		BEGIN
			UPDATE [Заказы ланч блюд] SET [Количество] = [Количество] - @complexCount
				WHERE [id] = @complexId

			INSERT INTO [Заказы ланч блюд]
				SELECT @idBill,
					[id официанта],
					[id ланч блюда],
					@complexNumber,
					[Вес],
					@complexCount,
					0,
					[Время заказа],
					[id отменившего официанта],
					[Время отмены],
					[Позже]
				FROM [Заказы ланч блюд] WHERE [Заказы ланч блюд].[id] = @complexId

			SELECT @scId = CAST(SCOPE_IDENTITY() AS INT)
			INSERT INTO [Изменение рецептов ланч блюд]
				SELECT @scId,
					[id ингредиента],
					[Добавить]
				FROM [Изменение рецептов ланч блюд] WHERE [id заказа ланч блюда] = @complexId						
		
		END
	COMMIT TRANSACTION
END
GO

CREATE PROCEDURE [Изменить номер счёта для спецблюда]
(@numberBill INT, @dishId INT, @dishCount INT, @type VARCHAR(20))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		IF (@dishCount = 0)
		BEGIN
			UPDATE [Заказы спецблюд] SET [id счёта посетителей] = (SELECT [id] FROM [Счета посетителей] WHERE [номер счёта] = @numberBill)
				WHERE [id] = @dishId
		END
		ELSE
		BEGIN
			UPDATE [Заказы спецблюд] SET [Количество] = [Количество] - @dishCount
				WHERE [id] = @dishId

			INSERT INTO [Заказы спецблюд]
				SELECT (SELECT [id] FROM [Счета посетителей] WHERE [Номер счёта] = @numberBill),
					@type,
					[Русское название],
					[Название для чека],
					[Стоимость],
					@dishCount,
					[Время заказа],
					[id отменившего официанта],
					[Время отмены],
					[id цеха],
					[Позже]
				FROM [Заказы спецблюд] 
				WHERE [Заказы спецблюд].[id] = @dishId
		END
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Установить аванс]
(@numberBill INT, @sum MONEY, @waiter VARCHAR(100))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		UPDATE [Счета посетителей]
			SET [Аванс] = dbo.[Округление цены](@sum), [id официанта установившего аванс] = (SELECT [id] FROM [Официанты] WHERE [ФИО] = @waiter)
			WHERE [Номер счёта]  = @numberBill
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Выполнить позже]
(@idOrder INT, @type VARCHAR(5), @later VARCHAR(15))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		IF @type = 'd' UPDATE [Заказы блюд] SET [Позже] = @later WHERE [id] = @idOrder
		IF @type = 'v' UPDATE [Заказы напитков] SET [Позже] = @later WHERE [id] = @idOrder
		IF @type = 'c' UPDATE [Заказы ланч блюд] SET [Позже] = @later WHERE [id] = @idOrder
		IF @type = 's' UPDATE [Заказы спецблюд] SET [Позже] = @later WHERE [id] = @idOrder
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Отменить бронь]
(@idBron INT, @waiter VARCHAR(100))
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		UPDATE [Забронированные столики] 
			SET [Дата отмены] = GETDATE(),
				[Время отмены] = CURRENT_TIMESTAMP,
				[id отменившего официанта] = (SELECT [id] FROM [Официанты] WHERE [ФИО] = @waiter)
			WHERE [id] = @idBron                                	
	COMMIT TRANSACTION
END
GO


CREATE PROCEDURE [Получить бронь столика]
(@room VARCHAR(20), @table INT)
AS
BEGIN
	SELECT [Забронированные столики].[id], [Дата брони],[Время с],[Время по]
		FROM [Забронированные столики] INNER JOIN [Столики] ON [Забронированные столики].[id столика] = [Столики].[id]
		WHERE [Время отмены] IS NULL AND [Дата брони]>=CAST(GETDATE() AS DATE)
			AND [Зал] = @room AND [Номер столика] = @table
		ORDER BY [Дата брони],[Время с],[Время по]
END