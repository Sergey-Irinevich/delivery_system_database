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
GO --������� ���� ������, ���� ��� ����������

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
	RAISERROR(N'���������� ������� ����� (Business rule)', 16, 1);
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
			RAISERROR(N'���������� �������� ������� ���� ������', 16, 1);
			ROLLBACK;
		END;
	IF UPDATE(orderID)
		BEGIN
			RAISERROR(N'���������� �������� ��������� ���� ������', 16, 1);
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
	RAISERROR(N'���������� ������� ����� ������ (Business rule)', 16, 1);
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
			RAISERROR(N'���������� �������� ������� ���� ������ ������', 16, 1);
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
			RAISERROR(N'���������� �������� ������� ���� ������ ���� ���������', 16, 1);
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
('+78005553535', N'������', N'��������', N'����������'),
('+79163654400', N'��������', N'�������', N'����������'),
('+79807432247', N'������', N'�������', N'��������'),
('+79223411268', N'�������', N'�����', N'��������'),
('+79175552211', N'���������', N'�����', N'����������'),
('+79803476723', N'�������', N'������', N'��������������'),
('+79182351726', N'���������', N'����', N'����������'),
('+79192223343', N'�������', N'������', N'������������'),
('+78003431526', N'��������', N'���������', N'����������'),
('+79163542219', N'������', N'��������', N'�������'),
('+74953211234', N'�������', N'��������', N'������������');
GO

INSERT INTO [restaurant](organization_name, [address], [phone], e_mail) VALUES
(N'McDonald''s', N'������, �������� �������, 1, ���. 2', '+78006000770', 'mcduck@mail.ru'),
(N'McDonald''s', N'������, ���������� �����, 10', '+78006000770', 'mcduck@mail.ru'),
(N'McDonald''s', N'������, �������� ���., 17', '+78006000770', 'mcduck_t@mail.ru'),
(N'McDonald''s', N'������, ������� ������� �����, 29', '+78006000770', 'mcduck_t@mail.ru'),
(N'������ - � �����', N'������, ����������� ��., 5, ���. 1, ���� 6', '+78006000770', 'vkustochka@yandex.ru'),
(N'������ - � �����', N'������, ����� ���������, 9', '+78006000770', 'vkustochka@yandex.ru'),
(N'������ - � �����', N'������, ����� ����� �����, 17', '+78006000770', 'vkustochka@yandex.ru'),
(N'Rostic''s', N'������, ������������ �����, 71 �', '+79225000880', 'yurest@yandex.ru'),
(N'Rostic''s', N'������, ����� �����������, 20', '+79225000880', 'yurest@yandex.ru'),
(N'Rostic''s', N'������, ������� �������������� �����, 3', '+79225000880', 'yurest_ro@yandex.ru'),
(N'�����������', N'������, ������������ �����, 71 �', '+78002223231', 'marketing@shoko.ru'),
(N'�����������', N'������, ������� ���������� �����, 2', '+78002223231', 'marketing@shoko.ru'),
(N'������ ��������', N'������, ���������� �������, 1', '+74951390200', 'kartoshka@gmail.com');
GO

INSERT INTO [courier]([phone], second_name, first_name, patronymic, salary) VALUES
('+74953223231', N'��������', N'������', N'�������������', 40000),
('+79003488327', N'��������', N'�������', N'�����������', 35000),
('+79253332325', N'�������', N'�����', N'�����������', 38000),
('+79183261689', N'�������', N'�����', NULL, 42000),
('+79802314767', N'������', N'�������', N'����������', 45000),
('+79342185445', N'��������', N'����', N'������������', 41000),
('+78003211221', N'�����������', N'�����', NULL, 39000),
('+79162361600', N'��������', N'�������', '����������', 38500);
GO

INSERT INTO menu_item(restaurantID, product_name, cost, ingredients, nutritional_value, energy, [weight]) VALUES
(1, N'��� ���', 200, N'��������, �������, ���, ����, �������, ������ ������, ������������ ������', 
N'�����: 8�, ����: 20�, ��������: 40�', 500, 220),
(1, N'��� ����� ������', 190, N'������� ������, �������, ���, ��������, ����, ������ ������',
N'�����: 20�, ����: 35�, ��������: 50�', 450, 300),
(1, N'��������� ���', 70, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(1, N'���������', 100, N'��������� � ���������� �������� � ��������� ����',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 180),
(2, N'��� ���', 212, N'��������, �������, ���, ����, �������, ������ ������, ������������ ������', 
N'�����: 8�, ����: 20�, ��������: 40�', 500, 220),
(2, N'��������� ���', 80, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(2, N'���������', 120, N'��������� � ���������� �������� � ��������� ����',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 180),
(2, N'������� �������', 70, N'�����, ������� �� �����',
N'�����: 3�, ����: 10�, ��������: 30�', 230, 80),
(3, N'��� ���', 260, N'��������, �������, ���, ����, �������, ������ ������, ������������ ������', 
N'�����: 8�, ����: 20�, ��������: 40�', 500, 220),
(3, N'��� ����� ������', 180, N'������� ������, �������, ���, ��������, ����, ������ ������',
N'�����: 20�, ����: 35�, ��������: 50�', 450, 320),
(3, N'��������� ���', 65, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(3, N'���������', 115, N'��������� � ���������� �������� � ��������� ����',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 180),
(3, N'�������� ��������', 120, N'������, ���������� �����',
N'�����: 7�, ����: 5�, ��������: 45�', 180, 270),
(4, N'��� ���', 212, N'��������, �������, ���, ����, �������, ������ ������, ������������ ������', 
N'�����: 8�, ����: 20�, ��������: 40�', 500, 220),
(4, N'��������� ���', 80, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(4, N'���������', 120, N'��������� � ���������� �������� � ��������� ����',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 180),
(4, N'������� �������', 70, N'�����, ������� �� �����',
N'�����: 3�, ����: 10�, ��������: 30�', 230, 80),
(5, N'��� ���', 210, N'������� ������, �������, ���, ����, �������, ������ ������, ������������ ������', 
N'�����: 8�, ����: 20�, ��������: 40�', 500, 250),
(5, N'��� ����� ������', 180, N'������� ������, �������, ���, ��������, ����, ������ ������, ������������ ������',
N'�����: 20�, ����: 35�, ��������: 50�', 450, 320),
(5, N'��������� ���', 50, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(5, N'���������', 120, N'��������� � ���������� �������� � ��������� �������',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 170),
(6, N'��� ���', 215, N'������� ������, �������, ���, ����, �������, ������ ������, ������������ ������', 
N'�����: 8�, ����: 20�, ��������: 40�', 500, 250),
(6, N'��������� ���', 80, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(6, N'���������', 120, N'��������� � ���������� �������� � ��������� �������',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 170),
(7, N'��� ���', 215, N'������� ������, �������, ���, ����, �������, ������ ������, ������������ ������', 
N'�����: 8�, ����: 20�, ��������: 40�', 500, 250),
(7, N'��������� ���', 80, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(7, N'���������', 120, N'��������� � ���������� �������� � ��������� �������',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 170),
(7, N'��� ������', 100, N'��� ������ Greenfield', N'�����: 0�, ����: 0�, ��������: 15�', 50, 250),
(8, N'���������', 100, N'������� �� �������� ����, �������, ���, ������, ������������ ������',
N'�����: 15�, ����: 10�, ��������: 25�', 230, 150),
(8, N'������ ��������', 350, N'������ ������, ���� ���������, ������������ �����, ������� �������',
N'�����: 25�, ����: 21�, ��������: 10�', 300, 200),
(8, N'��������', 260, N'�������� ������������, ������������ �����', N'�����: 12�, ����: 15�, ��������: 15�', 230, 100),
(8, N'��������� ���', 50, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(9, N'���������', 110, N'������� �� �������� ����, �������, ���, ������, ������������ ������',
N'�����: 15�, ����: 10�, ��������: 25�', 230, 150),
(9, N'������ ��������', 340, N'������ ������, ���� ���������, ������������ �����, ������� �������',
N'�����: 25�, ����: 21�, ��������: 10�', 300, 200),
(9, N'��������� ���', 60, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(9, N'���������', 115, N'��������� � ���������� �������� � ��������� �������',
N'�����: 10�, ����: 5�, ��������: 40�', 250, 170),
(10, N'������ ��������', 355, N'������ ������, ���� ���������, ������������ �����, ������� �������',
N'�����: 25�, ����: 21�, ��������: 10�', 300, 200),
(10, N'��������', 265, N'�������� ������������, ������������ �����', N'�����: 12�, ����: 15�, ��������: 15�', 230, 100),
(10, N'��������� ���', 70, N'�������� ���������, ����, ������������ �����',
N'�����: 5�, ����: 10�, ��������: 40�', 200, 100),
(11, N'���� � ���������', 200, N'�������� ��������, �����, �������, ���������, �������, ���, �������, �����',
N'�����: 5�, ����: 2�, ��������: 2�', 80, 250),
(11, N'��������� ��������� � ������', 100, N'������, �����, ����, ����', N'�����: 8�, ����: 2�, ��������: 5�', 100, 300),
(11, N'������� �������', 120, N'�����-�������, �����, ������', N'�����: 6�, ����: 5�, ��������: 25�', 240, 250),
(11, N'������� � ���������', 130, N'����, ����, �����, ����, ������, ��������� �����, �������',
N'�����: 4�, ����: 10�, ��������: 23�', 195, 250),
(12, N'���� � ���������', 210, N'�������� ��������, �����, �������, ���������, �������, ���, �������, �����',
N'�����: 5�, ����: 2�, ��������: 2�', 80, 250),
(12, N'������� �������', 110, N'�����-�������, �����, ������', N'�����: 6�, ����: 5�, ��������: 25�', 240, 250),
(12, N'������� � ���������', 135, N'����, ����, �����, ����, ������, ��������� �����, �������',
N'�����: 4�, ����: 10�, ��������: 23�', 195, 250),
(13, N'�������� � ������� � ������������ ������', 150, N'��������� ��������, �����, ������������ �����',
N'�����: 3�, ����: 8�, ��������: 10�', 160, 260),
(13, N'��� ����� �������', 130, N'����� ��������, ������������ �����, ����, �������, ���������, ���, ��������, ����, ������',
N'�����: 1�, ����: 2�, ��������: 3�', 28, 270),
(13, N'�������� ��������', 120, N'���� ���������, �����, �����-�������, ����, ����� ���������, ����������� �������',
N'�����: 7�, ����: 10�, ��������: 45�', 300, 80);
GO

CREATE SEQUENCE seq1
START WITH 1 INCREMENT BY 1;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'������, ������������ �����, 70', 800, 400, '2022-06-01T12:54:00', '2022-06-01T13:15:00', '+79163654400', '+79003488327');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(30, @id, 700, 2),
(32, @id, 100, 2);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'������, ������� ���������� �����, 15', 345, 400, '2022-07-15T13:38:00', '2022-07-15T13:50:00', '+78003431526', '+74953223231');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(44, @id, 210, 1),
(46, @id, 135, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'������, ������� �������������� �����, 19', 680, 350, '2022-07-28T15:40:00', '2022-07-28T16:03:00', '+79803476723', '+78003211221');
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
(@id, N'������, ٸ�������� �����, 23�1', 480, 350, '2022-08-01T18:15:00', '2022-08-01T18:32:00', '+79175552211', '+79802314767');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(2, @id, 380, 2),
(4, @id, 100, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'������, ���������� �����, 18', 420, 380, '2022-08-03T19:25:00', '2022-08-03T19:53:00', '+74953211234', '+79253332325');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(47, @id, 300, 2),
(49, @id, 120, 1);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'������, ����� �������� ���, 32�1', 410, 350, '2022-08-05T10:29:00', '2022-08-05T10:46:00', '+79807432247', '+79183261689');
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
(@id, N'������, 1-� ������������ �����, 15�3', 372, 380, '2022-08-09T11:15:00', '2022-08-09T11:43:00', '+79163654400', '+79802314767');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(5, @id, 212, 1),
(6, @id, 80, 2);
COMMIT;
GO

BEGIN TRANSACTION
DECLARE @id INT;
SET @id = NEXT VALUE FOR seq1;
INSERT INTO [order](orderID, [address], order_cost, delivery_cost, order_datetime, delivery_datetime, client_phone, courier_phone) VALUES
(@id, N'������, �������� ����, 3', 300, 380, '2022-08-12T16:17:00', '2022-08-12T16:31:00', '+79803476723', '+74953223231');
INSERT INTO order_item(MenuItemID, orderID, cost, [count]) VALUES
(1, @id, 200, 1),
(4, @id, 100, 1);
COMMIT;
GO

--������� �������� � ��� ��������, ������� �� ��������� �� ������ ������
SELECT c.[phone], c.first_name, c.second_name, c.patronymic FROM [order] o RIGHT JOIN [courier] c
ON c.[phone] = o.courier_phone
WHERE o.orderID IS NULL;
GO

--������� ���������, � ���� ������� ���� �������, �� �������� �� � ���� �����, � ���������� ����� �������
SELECT r.organization_name, r.[address], COUNT(*) AS [count] FROM [restaurant] r, menu_item m LEFT JOIN order_item o
ON m.MenuItemID = o.MenuItemID
WHERE r.restaurantID = m.restaurantID AND o.MenuItemID IS NULL
GROUP BY r.organization_name, r.[address];
GO

--�������� ������ � ������� ������ � ���������, ���������� ��� ������, � ���������, ������� �� ����������
SELECT cl.[phone] AS client_phone, cl.second_name, cl.first_name, o.[address], o.order_cost, o.delivery_cost,
co.[phone] AS courier_phone, co.second_name, co.first_name
FROM client cl FULL OUTER JOIN [order] o
ON cl.[phone] = o.client_phone FULL OUTER JOIN courier co
ON co.[phone] = o.courier_phone;
GO

--������� ������� ��������� �����+�������� �� ������� �������, ������������ �� ��������
SELECT c.[phone], AVG(o.order_cost + o.delivery_cost) AS mean_cost FROM [courier] c INNER JOIN [order] o
ON c.[phone] = o.courier_phone
GROUP BY c.[phone]
ORDER BY mean_cost DESC;
GO

--������� ������ �������� � ��������� ����� 38000 � 42000, ������������ �� �������� �� �����������
SELECT * FROM [courier]
WHERE salary BETWEEN 38000 AND 42000
ORDER BY salary ASC;
GO

--������� ���� ������ �������� ������ � ������ �� �������� �����, ������������ �� �����������
SELECT r.organization_name, r.[address], MIN(m.cost) AS min_cost FROM [restaurant] r INNER JOIN menu_item m 
ON r.restaurantID = m.restaurantID
GROUP BY r.organization_name, r.[address]
ORDER BY min_cost ASC;
GO

--������� ��������� ���������� ������� � ������ ������, ������ �� ������, ��� ������� ��� �������� ������ 1000
SELECT o.orderID, o.client_phone, c.second_name, c.first_name, SUM(m.energy*i.[count]) AS sum_energy 
FROM client c, [order] o, order_item i, menu_item m 
WHERE c.[phone] = o.client_phone AND o.orderID = i.orderID AND i.MenuItemID = m.MenuItemID
GROUP BY o.orderID, o.client_phone, c.second_name, c.first_name
HAVING SUM(m.energy*i.[count]) > 1000;
GO

--������� ����� ������� �������� �������
SELECT MAX(salary) AS max_salary FROM courier;
GO

--������� ������ ��������, ������� ���������� ������ ������� 20 �����
SELECT DISTINCT * FROM [courier]
WHERE [phone] IN 
		(SELECT courier_phone FROM [order] 
		WHERE DATEDIFF(MINUTE, order_datetime, delivery_datetime) < 20);
GO

--������� ������ ��������, ������� ��������� ���� �� ���� �����
SELECT * FROM [client] c
WHERE EXISTS(SELECT * FROM [order] o WHERE c.[phone] = o.client_phone);

--������� ������ ��������, � ������� ������� ���������� �� "�" ��� ��� ���������� �� "�"
SELECT * FROM [courier]
WHERE second_name LIKE N'�%'
UNION
SELECT * FROM [courier]
WHERE first_name LIKE N'�%';
GO

--������� ������ �������� � �������� "������(-�)", ��� ������� ���������� �� "�"
SELECT * FROM [client]
WHERE second_name LIKE N'������%'
INTERSECT
SELECT * FROM [client]
WHERE first_name LIKE N'�%';
GO

--�������� ������ ���� ����������, ������� ������� 120 ������ � ������������ ������� �� ���� �������
SELECT * FROM menu_item
WHERE cost < 120
EXCEPT
SELECT * FROM menu_item
WHERE energy > (SELECT AVG(energy) FROM menu_item);
GO

--������� ��� ���������, ������� ���������� "McDonald's", � ��, � ������� ������� ����� � �������
SELECT * FROM [restaurant]
WHERE organization_name = N'McDonald''s'
UNION ALL
SELECT * FROM [restaurant]
WHERE e_mail LIKE '%@yandex.ru';
GO