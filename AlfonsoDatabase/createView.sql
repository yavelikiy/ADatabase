ENABLE TRIGGER [I Напитки] ON [Напитки]
GO

CREATE VIEW [СтоликиView] AS
	SELECT [id],[Зал],[Номер столика]
		FROM [Столики]
GO
CREATE VIEW [ЦехаView] AS
	SELECT [id],[Цех]
		FROM [Цеха]
GO




CREATE VIEW [ОфициантыView] AS
	SELECT [id],[ФИО],[Адрес],[Телефон]
		FROM [Официанты]
		WHERE [ФИО] <> 'admin'
GO
CREATE VIEW [Типы напитковView] AS
	SELECT [id],[Тип напитка],[Видимость]
		FROM [Типы напитков]
GO
CREATE VIEW [Типы блюдView] AS
	SELECT [id],[Тип блюда],[Видимость]
		FROM [Типы блюд]
GO
CREATE VIEW [Типы ингредиентовView] AS
	SELECT [id],[Тип ингредиента],[Видимость]
		FROM [Типы ингредиентов]
GO
CREATE VIEW [ИнгредиентыView] AS
	SELECT [id],[Название ингредиента],[id типа ингредиента]AS [Тип ингредиента],[Стоимость],[Доступность]
		FROM [Ингредиенты]
GO
CREATE VIEW [НапиткиView] AS
	SELECT [id],[Русское название],[Название для чека],[id типа напитка]AS [Тип напитка],[БЕИ],[Стоимость],[Доступность]
		FROM [Напитки]
GO
CREATE VIEW [БлюдаView] AS
	SELECT [id],[Русское название],[Название для чека],[id типа блюда]AS [Тип блюда],[БЕИ],[Стоимость],[id цеха]AS [Цех],[Доступность]
		FROM [Блюда]
GO
CREATE VIEW [РецептыView] AS
	SELECT [id],[id блюда]AS [Блюдо],[id ингредиента]AS [Ингредиент],[Статус]
		FROM [Рецепты]
GO
CREATE VIEW [Следующее значение параметраView] AS
	SELECT [id],[Параметр],[Следующее значение]
		FROM [Следующее значение параметра]
GO



CREATE VIEW [Ланч блюдаView] AS
	SELECT [id],[Русское название],[Тип ланч блюда],[БЕИ],[Стоимость],[id цеха]AS [Цех],[Доступность]
		FROM [Ланч блюда]
GO
CREATE VIEW [Ланч рецептыView] AS
	SELECT [id],[id ланч блюда]AS [Русское название],[id ингредиента]AS [Ингредиенты для блюда],CAST([Статус]AS VARCHAR(20))AS [Статус]
		FROM [Ланч рецепты]
GO
CREATE VIEW [Ланч расписаниеView] AS
	SELECT TOP 5000 [id],[id ланч блюда]AS [Русское название],[Дата]
		FROM [Ланч расписание]
		ORDER BY [Дата] DESC
GO


CREATE VIEW [Выгрузка блюдView]
AS
	SELECT [Счета посетителей].[Номер счёта], [Счета посетителей].[Дата посещения] AS [Дата заказа], [Заказы блюд].[Время заказа], [Блюда].[Русское название], [Заказы блюд].[Вес], [Заказы блюд].[Количество], [Официанты].[ФИО] AS [Официант], [Заказы блюд].[Время отмены] 
		FROM [Заказы блюд] INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы блюд].[id счёта посетителей]
					 INNER JOIN [Блюда] ON [Заказы блюд].[id блюда] = [Блюда].[id]
					 INNER JOIN [Официанты] ON [Заказы блюд].[id официанта] = [Официанты].[id]
		WHERE [Счета посетителей].[Время закрытия счёта] IS NOT NULL
GO
CREATE VIEW [Выгрузка напитковView]
AS
	SELECT [Счета посетителей].[Номер счёта], [Счета посетителей].[Дата посещения] AS [Дата заказа], [Заказы напитков].[Время заказа], [Напитки].[Русское название], [Заказы напитков].[Объём], [Заказы напитков].[Количество], [Заказы напитков].[Количество порций],[Официанты].[ФИО] AS [Официант], [Заказы напитков].[Время отмены]
		FROM [Заказы напитков] INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы напитков].[id счёта посетителей]
					 INNER JOIN [Напитки] ON [Заказы напитков].[id напитка] = [Напитки].[id]
					 INNER JOIN [Официанты] ON [Заказы напитков].[id официанта] = [Официанты].[id]							 
		WHERE [Счета посетителей].[Время закрытия счёта] IS NOT NULL
GO
CREATE VIEW [Выгрузка ланч блюдView]
AS
	SELECT [Счета посетителей].[Номер счёта], [Счета посетителей].[Дата посещения] AS [Дата заказа], [Заказы ланч блюд].[Время заказа], [Ланч блюда].[Русское название], [Заказы ланч блюд].[Вес], [Заказы ланч блюд].[Количество], [Официанты].[ФИО] AS [Официант], [Заказы ланч блюд].[время отмены]
		FROM [Заказы ланч блюд] INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы ланч блюд].[id счёта посетителей]
					 INNER JOIN [Ланч блюда] ON [Заказы ланч блюд].[id ланч блюда] = [Ланч блюда].[id]
					 INNER JOIN [Официанты] ON [Заказы ланч блюд].[id официанта] = [Официанты].[id]	
		WHERE [Счета посетителей].[Время закрытия счёта] IS NOT NULL
GO
CREATE VIEW [Выгрузка спецблюдView]
AS
	SELECT [Счета посетителей].[Номер счёта], [Счета посетителей].[Дата посещения] AS [Дата заказа], [Заказы спецблюд].[Время заказа], [Заказы спецблюд].[Русское название], [Заказы спецблюд].[Количество], [Заказы спецблюд].[Время отмены] 
		FROM [Заказы спецблюд] INNER JOIN [Счета посетителей] ON [Счета посетителей].[id] = [Заказы спецблюд].[id счёта посетителей]
		WHERE [Счета посетителей].[Время закрытия счёта] IS NOT NULL