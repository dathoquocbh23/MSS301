-- MSS301 PE - database TEMPLATE. THI THAT: CHAY SCRIPT CUA DE, khong chay file nay.
-- Cau truc mo phong dung 3 bang cua de Trial (restaurants / Category / Foods)
-- nhung dat ten theo placeholder rooms / categories / reservations.
IF DB_ID('MSS301_2026_PE') IS NULL
    CREATE DATABASE MSS301_2026_PE;
GO
USE MSS301_2026_PE;
GO

IF OBJECT_ID('reservations','U')    IS NOT NULL DROP TABLE reservations;
IF OBJECT_ID('rooms','U')    IS NOT NULL DROP TABLE rooms;
IF OBJECT_ID('categories','U') IS NOT NULL DROP TABLE categories;
GO

CREATE TABLE categories (
    category_id INT IDENTITY(1,1) NOT NULL,
    name        NVARCHAR(100)     NOT NULL,
    CONSTRAINT PK_categories PRIMARY KEY CLUSTERED (category_id ASC),
    CONSTRAINT UQ_categories_name UNIQUE NONCLUSTERED (name ASC)
);
GO

CREATE TABLE rooms (
    room_id   INT IDENTITY(1,1) NOT NULL,
    address     VARCHAR(100)      NOT NULL,
    open_date   DATETIME2(7)      NOT NULL,
    name        VARCHAR(100)      NOT NULL,
    owner_name  VARCHAR(100)      NOT NULL,
    phone       VARCHAR(11)       NOT NULL,
    price_from  INT,
    price_to    INT,
    status      VARCHAR(10)       NOT NULL,
    category_id INT               NOT NULL,
    CONSTRAINT PK_rooms PRIMARY KEY CLUSTERED (room_id ASC),
    CONSTRAINT UQ_rooms_name UNIQUE NONCLUSTERED (name ASC)
);
GO

-- De PE gia lap 2 database khac nhau -> KHONG khai bao FOREIGN KEY sang rooms
CREATE TABLE reservations (
    reservation_id   INT IDENTITY(1,1) NOT NULL,
    name        NVARCHAR(100)     NOT NULL,
    price       INT               NOT NULL,
    ingredients NVARCHAR(500)     NOT NULL,
    room_id   INT               NOT NULL,
    status      NVARCHAR(20)      NOT NULL,
    CONSTRAINT PK_reservations PRIMARY KEY CLUSTERED (reservation_id ASC),
    CONSTRAINT CK_reservations_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
);
GO

INSERT INTO categories (name) VALUES (N'BBQ'), (N'Hotpot'), (N'Fast Food');
GO

INSERT INTO rooms (address, open_date, name, owner_name, phone, price_from, price_to, status, category_id) VALUES
('Hoa Lac Park', '2024-01-15', 'Room One', 'ABC Company', '02418282882', 2000, 3000, 'ACTIVE',   1),
('Q9 Campus',    '2024-06-01', 'Room Two', 'Tran Thi B',  '0912345678',  5000, 9000, 'ACTIVE',   2),
('Ha Noi',       '2020-03-01', 'Room Old', 'Le Van C',    '0987654321',  NULL, NULL, 'INACTIVE', 3);
GO

INSERT INTO reservations (name, price, ingredients, room_id, status) VALUES
(N'Reservation A', 120, N'pork, honey, garlic',  1, 'ACTIVE'),
(N'Reservation B', 350, N'beef, mushroom, tofu', 2, 'ACTIVE'),
(N'Reservation C',  90, N'chicken, flour, oil',  1, 'INACTIVE');
GO
