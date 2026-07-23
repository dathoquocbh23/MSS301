-- MSS301 PE — database bootstrap TEMPLATE (thi thật DÙNG SCRIPT CỦA ĐỀ)
-- Master (phía 1) ----< Detail (phía N) — cùng 1 DB cho tiện, KHÔNG kéo FK nếu đề giả lập tách DB
IF DB_ID('MSS301_2026_PE') IS NULL
    CREATE DATABASE MSS301_2026_PE;
GO
USE MSS301_2026_PE;
GO

IF OBJECT_ID('details','U') IS NOT NULL DROP TABLE details;
IF OBJECT_ID('masters','U') IS NOT NULL DROP TABLE masters;
GO

CREATE TABLE masters (
    master_id      INT IDENTITY(1,1) PRIMARY KEY,
    name           NVARCHAR(50)  NOT NULL,
    code           NVARCHAR(10)  NOT NULL UNIQUE,
    effective_date DATE          NULL,
    status         NVARCHAR(10)  NULL,
    description    NVARCHAR(100) NULL
);
GO

CREATE TABLE details (
    detail_id   INT IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(100) NOT NULL,
    description NVARCHAR(100) NULL,
    status      NVARCHAR(10)  NOT NULL,
    start_date  DATE          NOT NULL,
    end_date    DATE          NULL,
    master_id   INT           NOT NULL
    -- đề PE thường KHÔNG kéo FK vì giả lập 2 database khác nhau
);
GO

INSERT INTO masters (name, code, effective_date, status, description) VALUES
(N'Master One',   'M01', '2024-01-01', 'ACTIVE',   N'Sample master 1'),
(N'Master Two',   'M02', '2024-06-01', 'ACTIVE',   N'Sample master 2'),
(N'Master Old',   'M03', '2020-03-01', 'INACTIVE', N'Sample master 3');
GO

INSERT INTO details (name, description, status, start_date, end_date, master_id) VALUES
(N'Detail A', N'Sample detail A', 'ACTIVE',   '2024-01-10', NULL,         1),
(N'Detail B', N'Sample detail B', 'ACTIVE',   '2024-05-20', NULL,         2),
(N'Detail C', N'Sample detail C', 'INACTIVE', '2023-02-01', '2025-06-30', 2);
GO
