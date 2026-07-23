-- MSS301 PE 2026 — database bootstrap (run once, before starting the apps)
IF DB_ID('MSS301_2026_PE') IS NULL
    CREATE DATABASE MSS301_2026_PE;
GO
USE MSS301_2026_PE;
GO

IF OBJECT_ID('employees','U') IS NOT NULL DROP TABLE employees;
IF OBJECT_ID('departments','U') IS NOT NULL DROP TABLE departments;
GO

CREATE TABLE departments (
    department_id  INT IDENTITY(1,1) PRIMARY KEY,
    name           NVARCHAR(50)  NOT NULL,
    code           NVARCHAR(10)  NOT NULL UNIQUE,
    effective_date DATE          NULL,
    status         NVARCHAR(10)  NULL,
    location       NVARCHAR(100) NULL,
    parent_id      INT           NULL
);
GO

CREATE TABLE employees (
    employee_id   INT IDENTITY(1,1) PRIMARY KEY,
    full_name     NVARCHAR(100) NOT NULL,
    email         NVARCHAR(100) NOT NULL,
    position      NVARCHAR(30)  NOT NULL,
    status        NVARCHAR(10)  NOT NULL,
    start_date    DATE          NOT NULL,
    end_date      DATE          NULL,
    department_id INT           NOT NULL,
    CONSTRAINT FK_employees_departments
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
GO

INSERT INTO departments (name, code, effective_date, status, location, parent_id) VALUES
(N'Company HQ',      'HQ01', '2024-01-01', 'ACTIVE',   N'Hoa Lac Park', NULL),
(N'HR Department',   'HR01', '2024-06-01', 'ACTIVE',   N'Hoa Lac Park', 1),
(N'IT Department',   'IT01', '2025-01-15', 'ACTIVE',   N'Q9 Campus',    1),
(N'Old Department',  'OD01', '2020-03-01', 'INACTIVE', N'Ha Noi',       1);
GO

INSERT INTO employees (full_name, email, position, status, start_date, end_date, department_id) VALUES
(N'Nguyen Van A', 'a@fpt.edu.vn', 'Manager',   'ACTIVE', '2024-01-10', NULL,         2),
(N'Tran Thi B',   'b@fpt.edu.vn', 'Developer', 'ACTIVE', '2024-05-20', NULL,         3),
(N'Le Van C',     'c@fpt.edu.vn', 'Staff',     'LEFT',   '2023-02-01', '2025-06-30', 3);
GO
