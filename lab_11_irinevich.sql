USE tempdb;
GO
DECLARE @SQL NVARCHAR(1000);
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = N'food_delivery')
BEGIN
SET @SQL = N'USE [food_delivery];

ALTER DATABASE food_delivery SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
USE [tempdb];

DROP DATABASE food_delivery;';
EXEC (@SQL);
END;
GO --Удалить базу данных, если она существует

USE master;
GO

CREATE DATABASE food_delivery
ON (NAME='food_delivery_dat', FILENAME='C:\databases\food_delivery\food_delivery_dat.mdf',
SIZE=10, MAXSIZE=50, FILEGROWTH=5%)
LOG ON (NAME='food_delivery_log', FILENAME='C:\databases\food_delivery\food_delivery_log.ldf',
SIZE=10, MAXSIZE=50, FILEGROWTH=5%);
GO

USE food_delivery;
GO

CREATE TABLE [client] (
[phone] CHAR(12) NOT NULL PRIMARY KEY,
second_name NVARCHAR(50) NOT NULL,
first_name NVARCHAR(35) NOT NULL,
patronymic NVARCHAR(50) NULL,
CONSTRAINT constraint_client1 CHECK ([phone] LIKE '+7%')
);
GO

CREATE TABLE [courier] (
[phone] CHAR(12) NOT NULL PRIMARY KEY,
second_name NVARCHAR(50) NOT NULL,
first_name NVARCHAR(35) NOT NULL,
patronymic NVARCHAR(50) NULL,
salary FLOAT NULL,
[deleted] BIT NOT NULL DEFAULT 0,
CONSTRAINT constraint_courier1 CHECK ([phone] LIKE '+7%')
);
GO

CREATE TABLE [order] (
orderID BIGINT NOT NULL PRIMARY KEY,
[address] NVARCHAR(200) NOT NULL,
order_cost FLOAT NOT NULL,
delivery_cost FLOAT NOT NULL,
order_datetime DATETIME NULL,
delivery_datetime DATETIME NULL,
client_phone CHAR(12) NOT NULL,
courier_phone CHAR(12) NOT NULL,
CONSTRAINT constraint_order1 FOREIGN KEY (client_phone) 
REFERENCES [client]([phone]) ON UPDATE CASCADE ON DELETE NO ACTION,
CONSTRAINT constraint_order2 FOREIGN KEY (courier_phone)
REFERENCES [courier]([phone]) ON UPDATE CASCADE
);
GO

CREATE TABLE [restaurant] (
restaurantID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
organization_name NVARCHAR(100) NOT NULL,
[address] NVARCHAR(200) NOT NULL,
[phone] CHAR(12) NULL,
e_mail VARCHAR(254) NULL,
[deleted] BIT NOT NULL DEFAULT 0,
CONSTRAINT constraint_restaurant1 CHECK ([phone] LIKE '+7%'),
CONSTRAINT constraint_restaurant2 UNIQUE (organization_name, [address])
);
GO

CREATE TABLE menu_item (
MenuItemID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
restaurantID INT NOT NULL,
product_name NVARCHAR(80) NOT NULL,
cost FLOAT NOT NULL,
ingredients NVARCHAR(1000) NULL,
nutritional_value NVARCHAR(1000) NULL,
energy INT NULL,
[weight] INT NULL,
[deleted] BIT NOT NULL DEFAULT 0,
CONSTRAINT constraint_menu_item1 UNIQUE (restaurantID, product_name),
CONSTRAINT constraint_menu_item2 FOREIGN KEY (restaurantID) REFERENCES [restaurant](restaurantID)
);
GO

CREATE TABLE order_item(
MenuItemID INT NOT NULL,
orderID BIGINT NOT NULL,
cost FLOAT NOT NULL,
[count] INT NOT NULL,
CONSTRAINT constraint_order_item1 PRIMARY KEY (MenuItemID, orderID),
CONSTRAINT constraint_order_item2 FOREIGN KEY (MenuItemID) REFERENCES menu_item(MenuItemID),
CONSTRAINT constraint_order_item3 FOREIGN KEY (orderID) REFERENCES [order](orderID)
);
GO

CREATE TRIGGER order_trigger1
ON [order]
AFTER DELETE
AS
BEGIN
	RAISERROR(N'Невозможно удалить заказ (Business rule)', 16, 1);
	ROLLBACK;
END;
GO

CREATE TRIGGER order_trigger2
ON [order]
AFTER UPDATE
AS
BEGIN
	IF UPDATE(client_phone) OR UPDATE(courier_phone)
		BEGIN
			RAISERROR(N'Невозможно изменить внешний ключ заказа', 16, 1);
			ROLLBACK;
		END;
	IF UPDATE(orderID)
		BEGIN
			RAISERROR(N'Невозможно изменить первичный ключ заказа', 16, 1);
			ROLLBACK;
		END;
END;
GO

CREATE TRIGGER courier_trigger1
ON [courier]
INSTEAD OF DELETE
AS
BEGIN
	UPDATE [courier] SET [deleted] = 1 WHERE [courier].phone IN (SELECT phone FROM deleted);
END;
GO

CREATE TRIGGER order_item_trigger1
ON order_item
AFTER DELETE
AS
BEGIN
	RAISERROR(N'Невозможно удалить пункт заказа (Business rule)', 16, 1);
	ROLLBACK;
END;
GO

CREATE TRIGGER order_item_trigger2
ON order_item
AFTER UPDATE
AS
BEGIN
	IF UPDATE(MenuItemID) OR UPDATE(orderID)
		BEGIN
			RAISERROR(N'Невозможно изменить внешний ключ пункта заказа', 16, 1);
			ROLLBACK;
		END
END;
GO

CREATE TRIGGER menu_item_trigger1
ON menu_item
AFTER UPDATE
AS
BEGIN
	IF UPDATE(restaurantID)
		BEGIN
			RAISERROR(N'Невозможно изменить внешний ключ пункта меню ресторана', 16, 1);
			ROLLBACK;
		END
END;
GO

CREATE TRIGGER restaurant_trigger1
ON [restaurant]
INSTEAD OF DELETE
AS
BEGIN
	UPDATE [restaurant] SET [deleted] = 1 WHERE restaurantID IN (SELECT restaurantID FROM deleted);
	UPDATE menu_item SET [deleted] = 1 WHERE restaurantID IN (SELECT restaurantID FROM deleted);
END;
GO

CREATE TRIGGER menu_item_trigger2
ON menu_item
INSTEAD OF DELETE
AS
BEGIN
	UPDATE menu_item SET [deleted] = 1 WHERE MenuItemID IN (SELECT MenuItemID FROM deleted);
END;
GO

INSERT INTO [client]([phone], second_name, first_name, patronymic) VALUES
('+78005553535', N'Иванов', N'Владимир', N'Михайлович'),
('+79163654400', N'Медведев', N'Валерий', N'Дмитриевич'),
('+79807432247', N'Пупкин', N'Василий', N'Иванович'),
('+79223411268', N'Иванова', N'Мария', N'Ивановна'),
('+79175552211', N'Кириллова', N'Дарья', N'Николаевна'),
('+79803476723', N'Смирнов', N'Михаил', N'Константинович'),
('+79182351726', N'Кузнецова', N'Юлия', N'Михайловна'),
('+79192223343', N'Сергеев', N'Сергей', N'Валентинович'),
('+78003431526', N'Сергеева', N'Валентина', N'Витальевна'),
('+79163542219', N'Иванов', N'Валентин', N'Юрьевич'),
('+74953211234', N'Ткачёва', N'Кристина', N'Владимировна');
GO

INSERT INTO [restaurant](organization_name, [address], [phone], e_mail) VALUES
(N'McDonald''s', N'Москва, Манежная площадь, 1, стр. 2', '+78006000770', 'mcduck@mail.ru'),
(N'McDonald''s', N'Москва, Никольская улица, 10', '+78006000770', 'mcduck@mail.ru'),
(N'McDonald''s', N'Москва, Газетный пер., 17', '+78006000770', 'mcduck_t@mail.ru'),
(N'McDonald''s', N'Москва, Большая Бронная улица, 29', '+78006000770', 'mcduck_t@mail.ru'),
(N'Вкусно - и точка', N'Москва, Театральный пр., 5, стр. 1, этаж 6', '+78006000770', 'vkustochka@yandex.ru'),
(N'Вкусно - и точка', N'Москва, улица Маросейка, 9', '+78006000770', 'vkustochka@yandex.ru'),
(N'Вкусно - и точка', N'Москва, улица Новый Арбат, 17', '+78006000770', 'vkustochka@yandex.ru'),
(N'Rostic''s', N'Москва, Измайловское шоссе, 71 А', '+79225000880', 'yurest@yandex.ru'),
(N'Rostic''s', N'Москва, шоссе Энтузиастов, 20', '+79225000880', 'yurest@yandex.ru'),
(N'Rostic''s', N'Москва, Верхняя Красносельская улица, 3', '+79225000880', 'yurest_ro@yandex.ru'),
(N'Шоколадница', N'Москва, Измайловское шоссе, 71 А', '+78002223231', 'marketing@shoko.ru'),
(N'Шоколадница', N'Москва, Большая Семёновская улица, 2', '+78002223231', 'marketing@shoko.ru'),
(N'Крошка Картошка', N'Москва, Семёновская площадь, 1', '+74951390200', 'kartoshka@gmail.com');
GO

INSERT INTO [courier]([phone], second_name, first_name, patronymic, salary) VALUES
('+74953223231', N'Рамзанов', N'Алибек', N'Нурсултанович', 40000),
('+79003488327', N'Цзухвиле', N'Азарбан', N'Магометович', 35000),
('+79253332325', N'Шумарев', N'Ахмед', N'Арбазанович', 38000),
('+79183261689', N'Назаров', N'Ахмед', NULL, 42000),
('+79802314767', N'Иванов', N'Василий', N'Дмитриевич', 45000),
('+79342185445', N'Кузнецов', N'Амир', N'Арамазанович', 41000),
('+78003211221', N'Шархимуллин', N'Юлдаш', NULL, 39000),
('+79162361600', N'Смирнова', N'Эльмира', 'Кирилловна', 38500);
GO

INSERT INTO menu_item(restaurantID, product_name, cost, ingredients, nutritional_value, energy, [weight]) VALUES
(1, N'Биг Мак', 200, N'Бифштекс, булочка, сыр, соус, горчица, листья салата, маринованные огурцы', 
N'Белки: 8г, Жиры: 20г, Углеводы: 40г', 500, 220),
(1, N'Биг Чикен Бургер', 190, N'Куриная грудка, булочка, сыр, помидоры, соус, листья салата',
N'Белки: 20г, Жиры: 35г, Углеводы: 50г', 450, 300),
(1, N'Картофель Фри', 70, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(1, N'МакФлурри', 100, N'Мороженое с клубничным топингом и кусочками ягод',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 180),
(2, N'Биг Мак', 212, N'Бифштекс, булочка, сыр, соус, горчица, листья салата, маринованные огурцы', 
N'Белки: 8г, Жиры: 20г, Углеводы: 40г', 500, 220),
(2, N'Картофель Фри', 80, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(2, N'МакФлурри', 120, N'Мороженое с клубничным топингом и кусочками ягод',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 180),
(2, N'Пирожок Вишнёвый', 70, N'Тесто, начинка из вишни',
N'Белки: 3г, Жиры: 10г, Углеводы: 30г', 230, 80),
(3, N'Биг Мак', 260, N'Бифштекс, булочка, сыр, соус, горчица, листья салата, маринованные огурцы', 
N'Белки: 8г, Жиры: 20г, Углеводы: 40г', 500, 220),
(3, N'Биг Чикен Бургер', 180, N'Куриная грудка, булочка, сыр, помидоры, соус, листья салата',
N'Белки: 20г, Жиры: 35г, Углеводы: 50г', 450, 320),
(3, N'Картофель Фри', 65, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(3, N'МакФлурри', 115, N'Мороженое с клубничным топингом и кусочками ягод',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 180),
(3, N'Молочный коктейль', 120, N'Молоко, Клубничный сироп',
N'Белки: 7г, Жиры: 5г, Углеводы: 45г', 180, 270),
(4, N'Биг Мак', 212, N'Бифштекс, булочка, сыр, соус, горчица, листья салата, маринованные огурцы', 
N'Белки: 8г, Жиры: 20г, Углеводы: 40г', 500, 220),
(4, N'Картофель Фри', 80, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(4, N'МакФлурри', 120, N'Мороженое с клубничным топингом и кусочками ягод',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 180),
(4, N'Пирожок Вишнёвый', 70, N'Тесто, начинка из вишни',
N'Белки: 3г, Жиры: 10г, Углеводы: 30г', 230, 80),
(5, N'Биг Хит', 210, N'Куриная грудка, булочка, сыр, соус, горчица, листья салата, маринованные огурцы', 
N'Белки: 8г, Жиры: 20г, Углеводы: 40г', 500, 250),
(5, N'Биг Чикен Бургер', 180, N'Куриная грудка, булочка, сыр, помидоры, соус, листья салата, маринованные огурцы',
N'Белки: 20г, Жиры: 35г, Углеводы: 50г', 450, 320),
(5, N'Картофель Фри', 50, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(5, N'Мороженое', 120, N'Мороженое с клубничным топингом и кусочками фруктов',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 170),
(6, N'Биг Хит', 215, N'Куриная грудка, булочка, сыр, соус, горчица, листья салата, маринованные огурцы', 
N'Белки: 8г, Жиры: 20г, Углеводы: 40г', 500, 250),
(6, N'Картофель Фри', 80, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(6, N'Мороженое', 120, N'Мороженое с клубничным топингом и кусочками фруктов',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 170),
(7, N'Биг Хит', 215, N'Куриная грудка, булочка, сыр, соус, горчица, листья салата, маринованные огурцы', 
N'Белки: 8г, Жиры: 20г, Углеводы: 40г', 500, 250),
(7, N'Картофель Фри', 80, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(7, N'Мороженое', 120, N'Мороженое с клубничным топингом и кусочками фруктов',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 170),
(7, N'Чай чёрный', 100, N'Чай чёрный Greenfield', N'Белки: 0г, Жиры: 0г, Углеводы: 15г', 50, 250),
(8, N'Чизбургер', 100, N'Стрипсы из куриного филе, булочка, сыр, кетчуп, маринованные огурцы',
N'Белки: 15г, Жиры: 10г, Углеводы: 25г', 230, 150),
(8, N'Острые крылышки', 350, N'Сочная курица, мука пшеничная, растительное масло, пищевая добавка',
N'Белки: 25г, Жиры: 21г, Углеводы: 10г', 300, 200),
(8, N'Наггетсы', 260, N'Наггетсы оригинальные, растительное масло', N'Белки: 12г, Жиры: 15г, Углеводы: 15г', 230, 100),
(8, N'Картофель Фри', 50, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(9, N'Чизбургер', 110, N'Стрипсы из куриного филе, булочка, сыр, кетчуп, маринованные огурцы',
N'Белки: 15г, Жиры: 10г, Углеводы: 25г', 230, 150),
(9, N'Острые крылышки', 340, N'Сочная курица, мука пшеничная, растительное масло, пищевая добавка',
N'Белки: 25г, Жиры: 21г, Углеводы: 10г', 300, 200),
(9, N'Картофель Фри', 60, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(9, N'Мороженое', 115, N'Мороженое с клубничным топингом и кусочками фруктов',
N'Белки: 10г, Жиры: 5г, Углеводы: 40г', 250, 170),
(10, N'Острые крылышки', 355, N'Сочная курица, мука пшеничная, растительное масло, пищевая добавка',
N'Белки: 25г, Жиры: 21г, Углеводы: 10г', 300, 200),
(10, N'Наггетсы', 265, N'Наггетсы оригинальные, растительное масло', N'Белки: 12г, Жиры: 15г, Углеводы: 15г', 230, 100),
(10, N'Картофель Фри', 70, N'Отборный картофель, соль, растительное масло',
N'Белки: 5г, Жиры: 10г, Углеводы: 40г', 200, 100),
(11, N'Борщ с говядиной', 200, N'Говядина отварная, свёкла, капуста, картофель, морковь, лук, сметана, укроп',
N'Белки: 5г, Жиры: 2г, Углеводы: 2г', 80, 250),
(11, N'Запеканка творожная с изюмом', 100, N'Творог, сахар, яйцо, изюм', N'Белки: 8г, Жиры: 2г, Углеводы: 5г', 100, 300),
(11, N'Горячий шоколад', 120, N'Какао-порошок, сахар, молоко', N'Белки: 6г, Жиры: 5г, Углеводы: 25г', 240, 250),
(11, N'Блинчик с шоколадом', 130, N'Мука, соль, сахар, яйцо, молоко, сливочное масло, шоколад',
N'Белки: 4г, Жиры: 10г, Углеводы: 23г', 195, 250),
(12, N'Борщ с говядиной', 210, N'Говядина отварная, свёкла, капуста, картофель, морковь, лук, сметана, укроп',
N'Белки: 5г, Жиры: 2г, Углеводы: 2г', 80, 250),
(12, N'Горячий шоколад', 110, N'Какао-порошок, сахар, молоко', N'Белки: 6г, Жиры: 5г, Углеводы: 25г', 240, 250),
(12, N'Блинчик с шоколадом', 135, N'Мука, соль, сахар, яйцо, молоко, сливочное масло, шоколад',
N'Белки: 4г, Жиры: 10г, Углеводы: 23г', 195, 250),
(13, N'Картошка с укропом и растительным маслом', 150, N'Картофель отварной, укроп, растительное масло',
N'Белки: 3г, Жиры: 8г, Углеводы: 10г', 160, 260),
(13, N'Суп лапша куриная', 130, N'Лапша отварная, растительное масло, соль, морковь, картофель, лук, петрушка, соль, курица',
N'Белки: 1г, Жиры: 2г, Углеводы: 3г', 28, 270),
(13, N'Пирожное картошка', 120, N'Мука пшеничная, сахар, какао-порошок, соль, масло сливочное, натуральные добавки',
N'Белки: 7г, Жиры: 10г, Углеводы: 45г', 300, 80);
GO

CREATE SEQUENCE seq1
START WITH 1 INCREMENT BY 1;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, Измайловское шоссе, 70', 800, 400, '2022-06-01T12:54:00', '2022-06-01T13:15:00', '+79163654400', '+79003488327');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(30, @id, 700, 2),
(32, @id, 100, 2);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, Большая Семёновская улица, 15', 345, 400, '2022-07-15T13:38:00', '2022-07-15T13:50:00', '+78003431526', '+74953223231');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(44, @id, 210, 1),
(46, @id, 135, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, Верхняя Красносельская улица, 19', 680, 350, '2022-07-28T15:40:00', '2022-07-28T16:03:00', '+79803476723', '+78003211221');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(5, @id, 410, 2),
(6, @id, 150, 2),
(7, @id, 120, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, Щёлковское шоссе, 23к1', 480, 350, '2022-08-01T18:15:00', '2022-08-01T18:32:00', '+79175552211', '+79802314767');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(2, @id, 380, 2),
(4, @id, 100, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, Бауманская улица, 18', 420, 380, '2022-08-03T19:25:00', '2022-08-03T19:53:00', '+74953211234', '+79253332325');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(47, @id, 300, 2),
(49, @id, 120, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, улица Земляной Вал, 32к1', 410, 350, '2022-08-05T10:29:00', '2022-08-05T10:46:00', '+79807432247', '+79183261689');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(18, @id, 210, 1),
(20, @id, 90, 2),
(21, @id, 110, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, 1-я останкинская улица, 15к3', 372, 380, '2022-08-09T11:15:00', '2022-08-09T11:43:00', '+79163654400', '+79802314767');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(5, @id, 212, 1),
(6, @id, 80, 2);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'Москва, проспект Мира, 3', 300, 380, '2022-08-12T16:17:00', '2022-08-12T16:31:00', '+79803476723', '+74953223231');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(1, @id, 200, 1),
(4, @id, 100, 1);
COMMIT;
GO

--Вывести телефоны и ФИО курьеров, которые не доставили ни одного заказа
SELECT c.[phone], c.first_name, c.second_name, c.patronymic FROM [order] o RIGHT JOIN [courier] c
ON c.[phone] = o.courier_phone
WHERE o.orderID IS NULL;
GO

--Вывести рестораны, в меню которых есть позиции, не попавшие ни в один заказ, и количество таких позиций
SELECT r.organization_name, r.[address], COUNT(*) AS [count] FROM [restaurant] r, menu_item m LEFT JOIN order_item o
ON m.MenuItemID = o.MenuItemID
WHERE r.restaurantID = m.restaurantID AND o.MenuItemID IS NULL
GROUP BY r.organization_name, r.[address];
GO

--Показать данные о заказах вместе с клиентами, сделавшими эти заказы, и курьерами, которые их доставляли
SELECT cl.[phone] AS client_phone, cl.second_name, cl.first_name, o.[address], o.order_cost, o.delivery_cost,
co.[phone] AS courier_phone, co.second_name, co.first_name
FROM client cl FULL OUTER JOIN [order] o
ON cl.[phone] = o.client_phone FULL OUTER JOIN courier co
ON co.[phone] = o.courier_phone;
GO

--Вывести среднюю стоимость заказ+доставка по каждому курьеру, отсортировав по убыванию
SELECT c.[phone], AVG(o.order_cost + o.delivery_cost) AS mean_cost FROM [courier] c INNER JOIN [order] o
ON c.[phone] = o.courier_phone
GROUP BY c.[phone]
ORDER BY mean_cost DESC;
GO

--Вывести данные курьеров с зарплатой между 38000 и 42000, отсортировав по зарплате по возрастанию
SELECT * FROM [courier]
WHERE salary BETWEEN 38000 AND 42000
ORDER BY salary ASC;
GO

--Вывести цену самого дешёвого товара в каждой из торговых точек, отсортировав по возрастанию
SELECT r.organization_name, r.[address], MIN(m.cost) AS min_cost FROM [restaurant] r INNER JOIN menu_item m 
ON r.restaurantID = m.restaurantID
GROUP BY r.organization_name, r.[address]
ORDER BY min_cost ASC;
GO

--Вывести суммарное количество калорий в каждом заказе, выбрав те заказы, для которых это значение больше 1000
SELECT o.orderID, o.client_phone, c.second_name, c.first_name, SUM(m.energy*i.[count]) AS sum_energy 
FROM client c, [order] o, order_item i, menu_item m 
WHERE c.[phone] = o.client_phone AND o.orderID = i.orderID AND i.MenuItemID = m.MenuItemID
GROUP BY o.orderID, o.client_phone, c.second_name, c.first_name
HAVING SUM(m.energy*i.[count]) > 1000;
GO

--Вывести самую высокую зарплату курьера
SELECT MAX(salary) AS max_salary FROM courier;
GO

--Вывести данные курьеров, которые доставляли заказы быстрее 20 минут
SELECT DISTINCT * FROM [courier]
WHERE [phone] IN 
		(SELECT courier_phone FROM [order] 
		WHERE DATEDIFF(MINUTE, order_datetime, delivery_datetime) < 20);
GO

--Вывести данные клиентов, которые совершили хотя бы один заказ
SELECT * FROM [client] c
WHERE EXISTS(SELECT * FROM [order] o WHERE c.[phone] = o.client_phone);

--Вывести данные курьеров, у которых фамилия начинается на "Ш" или имя начинается на "Э"
SELECT * FROM [courier]
WHERE second_name LIKE N'Ш%'
UNION
SELECT * FROM [courier]
WHERE first_name LIKE N'Э%';
GO

--Вывести данные клиентов с фамилией "Иванов(-а)", имя которых начинается на "В"
SELECT * FROM [client]
WHERE second_name LIKE N'Иванов%'
INTERSECT
SELECT * FROM [client]
WHERE first_name LIKE N'В%';
GO

--Показать пункты меню ресторанов, которые дешевле 120 рублей и калорийность которых не выше средней
SELECT * FROM menu_item
WHERE cost < 120
EXCEPT
SELECT * FROM menu_item
WHERE energy > (SELECT AVG(energy) FROM menu_item);
GO

--Вывести все рестораны, которые называются "McDonald's", и те, у которых рабочая почта в Яндексе
SELECT * FROM [restaurant]
WHERE organization_name = N'McDonald''s'
UNION ALL
SELECT * FROM [restaurant]
WHERE e_mail LIKE '%@yandex.ru';
GO