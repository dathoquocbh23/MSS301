-- MSS301 PE Trial (Restaurant/Food) — dùng chung database MSS301_2026_PE
-- Bảng/cột lấy THEO SCRIPT ĐỀ CHO SẴN (authoritative), không theo bảng mô tả trong doc.
IF DB_ID('MSS301_2026_PE') IS NULL
    CREATE DATABASE MSS301_2026_PE;
GO
USE MSS301_2026_PE;
GO

IF OBJECT_ID('dbo.Foods','U')       IS NOT NULL DROP TABLE dbo.Foods;
IF OBJECT_ID('dbo.restaurants','U') IS NOT NULL DROP TABLE dbo.restaurants;
IF OBJECT_ID('dbo.Category','U')    IS NOT NULL DROP TABLE dbo.Category;
GO

CREATE TABLE [dbo].[Category] (
    [category_id] INT IDENTITY(1,1) NOT NULL,
    [name]        NVARCHAR(100)     NOT NULL,
    CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED ([category_id] ASC),
    CONSTRAINT [UQ_Category_Name] UNIQUE NONCLUSTERED ([name] ASC)
);
GO

CREATE TABLE [dbo].[restaurants](
    [restaurant_id] [int] IDENTITY(1,1) NOT NULL,
    [address]       [varchar](100) NOT NULL,
    [open_date]     [datetime2](7) NOT NULL,
    [name]          [varchar](100) NOT NULL,
    [owner_name]    [varchar](100) NOT NULL,
    [phone]         [varchar](11)  NOT NULL,
    [price_from]    [int],
    [price_to]      [int],
    [status]        [varchar](10)  NOT NULL,
    [category_id]   [int]          NOT NULL,
    PRIMARY KEY CLUSTERED ([restaurant_id] ASC),
    CONSTRAINT [UK_restaurants_name] UNIQUE NONCLUSTERED ([name] ASC)
);
GO

CREATE TABLE [dbo].[Foods] (
    [food_id]       INT IDENTITY(1,1) NOT NULL,
    [name]          NVARCHAR(100)     NOT NULL,
    [price]         INT               NOT NULL,
    [ingredient]    NVARCHAR(500)     NOT NULL, -- LƯU Ý: cột số ít 'ingredient', DTO là 'ingredients'
    [restaurant_id] INT               NOT NULL,
    [status]        NVARCHAR(20)      NOT NULL,
    CONSTRAINT [PK_Foods] PRIMARY KEY CLUSTERED ([food_id] ASC),
    CONSTRAINT [CK_Foods_Status] CHECK ([status] IN ('ACTIVE', 'INACTIVE'))
);
GO

-- Seed data
INSERT INTO dbo.Category (name) VALUES (N'BBQ'), (N'Hotpot'), (N'Fast Food');
GO

INSERT INTO dbo.restaurants (address, open_date, name, owner_name, phone, price_from, price_to, status, category_id) VALUES
('Hoa Lac Park', '2024-01-15', 'BBQ Hoa Lac',   'ABC Company', '02418282882', 2000, 3000, 'ACTIVE',   1),
('Q9 Campus',    '2024-06-01', 'Hotpot Q9',     'Tran Thi B',  '0912345678',  5000, 9000, 'ACTIVE',   2),
('Ha Noi',       '2020-03-01', 'Old Diner',     'Le Van C',    '0987654321',  NULL, NULL, 'INACTIVE', 3);
GO

INSERT INTO dbo.Foods (name, price, ingredient, restaurant_id, status) VALUES
(N'Grilled Pork',  120, N'pork, honey, garlic',      1, 'ACTIVE'),
(N'Beef Hotpot',   350, N'beef, mushroom, tofu',     2, 'ACTIVE'),
(N'Fried Chicken',  90, N'chicken, flour, oil',      1, 'INACTIVE');
GO
