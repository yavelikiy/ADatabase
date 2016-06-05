ALTER TABLE [Ингредиенты] ADD CONSTRAINT [FK_Ингредиенты_Типы ингредиентов]
	FOREIGN KEY ([id типа ингредиента]) REFERENCES [Типы ингредиентов](id)
GO
ALTER TABLE [Напитки] ADD CONSTRAINT [FK_Напитки_Типы напитков]
	FOREIGN KEY ([id типа напитка]) REFERENCES [Типы напитков](id)
GO
ALTER TABLE [Блюда] ADD CONSTRAINT [FK_Блюда_Типы блюд] 
	FOREIGN KEY ([id типа блюда])REFERENCES [Типы блюд](id)
GO
ALTER TABLE [Блюда] ADD CONSTRAINT [FK_Блюда_Цеха] 
	FOREIGN KEY ([id цеха])REFERENCES [Цеха](id)
GO
ALTER TABLE [Рецепты] ADD CONSTRAINT [FK_Рецепты_Блюда]
	FOREIGN KEY ([id блюда]) REFERENCES [Блюда](id) ON DELETE CASCADE
GO
ALTER TABLE [Рецепты] ADD CONSTRAINT [FK_Рецепты_Ингредиенты]
	FOREIGN KEY ([id ингредиента]) REFERENCES [Ингредиенты](id)
GO
ALTER TABLE [Ланч блюда] ADD CONSTRAINT [FK_Ланч блюда_Цеха]
	FOREIGN KEY ([id цеха]) REFERENCES [Цеха](id)
GO
ALTER TABLE [Ланч рецепты] ADD CONSTRAINT [FK_Ланч рецепты_Ингредиенты]
	FOREIGN KEY ([id ингредиента]) REFERENCES [Ингредиенты](id)
GO
ALTER TABLE [Ланч рецепты] ADD CONSTRAINT [FK_Ланч рецепты_Ланч блюда]
	FOREIGN KEY ([id ланч блюда]) REFERENCES [Ланч блюда](id) ON DELETE CASCADE
GO
ALTER TABLE [Ланч расписание] ADD CONSTRAINT [FK_Ланч расписание_Ланч блюда]
	FOREIGN KEY ([id ланч блюда]) REFERENCES [Ланч блюда](id)	
GO
ALTER TABLE [Заказы ланч блюд] ADD CONSTRAINT [FK_Заказы ланч блюд_Счета посетителей]
	FOREIGN KEY ([id счёта посетителей]) REFERENCES [Счета посетителей](id) ON DELETE CASCADE
GO
ALTER TABLE [Заказы ланч блюд] ADD CONSTRAINT [FK_Заказы ланч блюд_Ланч блюда]
	FOREIGN KEY ([id ланч блюда]) REFERENCES [Ланч блюда](id)
GO
ALTER TABLE [Заказы ланч блюд] ADD CONSTRAINT [FK_Заказы ланч блюд_Официанты]
	FOREIGN KEY ([id официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Заказы ланч блюд] ADD CONSTRAINT [FK_Заказы ланч блюд_Отменивший Официанты]
	FOREIGN KEY ([id отменившего официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Изменение рецептов ланч блюд] ADD CONSTRAINT [FK_Изменение рецептов ланч блюд_Заказы ланч блюд]
	FOREIGN KEY ([id заказа ланч блюда]) REFERENCES [Заказы ланч блюд](id) ON DELETE CASCADE
GO
ALTER TABLE [Изменение рецептов ланч блюд] ADD CONSTRAINT [FK_Изменение рецептов ланч блюд_Ингредиенты]
	FOREIGN KEY ([id ингредиента]) REFERENCES [Ингредиенты](id)
GO
ALTER TABLE [Забронированные столики] ADD CONSTRAINT [FK_Забронированные столики_Столики]
	FOREIGN KEY ([id столика]) REFERENCES [Столики](id)
GO
ALTER TABLE [Забронированные столики] ADD CONSTRAINT [FK_Забронированные столики_Отменивший Официанты]
	FOREIGN KEY ([id отменившего официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Забронированные столики] ADD CONSTRAINT [FK_Забронированные столики_Забронировавший Официанты]
	FOREIGN KEY ([id забронировавшего официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Счета посетителей] ADD CONSTRAINT [FK_Счета посетителей_Столики] 
	FOREIGN KEY ([id столика]) REFERENCES [Столики](id)
GO
ALTER TABLE [Счета посетителей] ADD CONSTRAINT [FK_Счета посетителей_Официанты] 
	FOREIGN KEY ([id официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Счета посетителей] ADD CONSTRAINT [FK_Счета посетителей_Официанты скидки] 
	FOREIGN KEY ([id официанта установившего скидку]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Заказы блюд] ADD CONSTRAINT [FK_Заказы блюд_Счета посетителей]
	FOREIGN KEY ([id счёта посетителей]) REFERENCES [Счета посетителей](id) ON DELETE CASCADE
GO
ALTER TABLE [Заказы блюд] ADD CONSTRAINT [FK_Заказы блюд_Блюда]
	FOREIGN KEY ([id блюда]) REFERENCES [Блюда](id)
GO
ALTER TABLE [Заказы блюд] ADD CONSTRAINT [FK_Заказы блюд_Официанты]
	FOREIGN KEY ([id официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Заказы блюд] ADD CONSTRAINT [FK_Заказы блюд_Отменивший Официанты]
	FOREIGN KEY ([id отменившего официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Заказы спецблюд] ADD CONSTRAINT [FK_Заказы спецблюд_Счета посетителей]
	FOREIGN KEY ([id счёта посетителей]) REFERENCES [Счета посетителей](id) ON DELETE CASCADE
GO
ALTER TABLE [Заказы спецблюд] ADD CONSTRAINT [FK_Заказы спецблюд_Отменивший Официанты]
	FOREIGN KEY ([id отменившего официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Заказы спецблюд] ADD CONSTRAINT [FK_Заказы спецблюд_Цеха] 
	FOREIGN KEY ([id цеха])REFERENCES [Цеха](id)
GO
ALTER TABLE [Заказы напитков] ADD CONSTRAINT [FK_Заказы напитков_Счета посетителей] 
	FOREIGN KEY ([id счёта посетителей]) REFERENCES [Счета посетителей](id) ON DELETE CASCADE
GO
ALTER TABLE [Заказы напитков] ADD CONSTRAINT [FK_Заказы напитков_Напитки]
	FOREIGN KEY ([id напитка]) REFERENCES [Напитки](id)
GO
ALTER TABLE [Заказы напитков] ADD CONSTRAINT [FK_Заказы напитков_Официанты]
	FOREIGN KEY ([id официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Заказы напитков] ADD CONSTRAINT [FK_Заказы напитков_Отменивший Официанты]
	FOREIGN KEY ([id отменившего официанта]) REFERENCES [Официанты](id)
GO
ALTER TABLE [Изменение рецептов блюд] ADD CONSTRAINT [FK_Изменение рецептов блюд_Заказы блюд]
	FOREIGN KEY ([id заказа блюда]) REFERENCES [Заказы блюд](id) ON DELETE CASCADE
GO
ALTER TABLE [Изменение рецептов блюд] ADD CONSTRAINT [FK_Изменение рецептов блюд_Ингредиенты]
	FOREIGN KEY ([id ингредиента]) REFERENCES [Ингредиенты](id)