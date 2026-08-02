-- Reset du lieu test cho pe1-department.http + pe1-employee.http (EXAM Department/Employee)
-- Chay truoc moi lan chay FULL bo test:
--   sqlcmd -S localhost -U sa -P 12345 -d MSS301_2026_PE -i reset-test-data.sql
-- Bo test tham chieu id co dinh:
--   departments: id1=HQ01 (test dep-10 get, dep-03 dup), id2 (update 13/15/16),
--                id3 (delete 18), id4 (status->CLOSED 14), id5=IT01 (nguon trung cho 16)
--   employees:   id1 (get 09, filter Nguyen 20), id2 (update 11-14), id3 (delete 16), id4 LEFT (filter 21)
USE MSS301_2026_PE;

DELETE FROM employees;
DELETE FROM departments;
DBCC CHECKIDENT ('employees', RESEED, 0);
DBCC CHECKIDENT ('departments', RESEED, 0);

INSERT INTO departments (name, code, effective_date, status, location, parent_id) VALUES
 (N'Head Quarter',          'HQ01',  '2026-08-01', 'ACTIVE', N'Hanoi',    NULL),
 (N'Finance Department',    'FIN01', '2026-09-01', 'ACTIVE', N'HCM City', 1),
 (N'Operations Department', 'OPS01', NULL,         'ACTIVE', N'Da Nang',  1),
 (N'Marketing Department',  'MKT01', NULL,         'ACTIVE', N'Hue',      1),
 (N'IT Department',         'IT01',  '2026-10-01', 'ACTIVE', N'Hanoi',    1);

INSERT INTO employees (full_name, email, position, status, start_date, end_date, department_id) VALUES
 (N'Nguyen Van A', 'a@fpt.edu.vn', N'Developer', 'ACTIVE', '2026-06-01', NULL,         1),
 (N'Tran Van B',   'b@fpt.edu.vn', N'Staff',     'ACTIVE', '2026-06-15', NULL,         2),
 (N'Le Thi C',     'c@fpt.edu.vn', N'Manager',   'ACTIVE', '2026-05-01', NULL,         1),
 (N'Pham Thi D',   'd@fpt.edu.vn', N'Staff',     'LEFT',   '2026-01-01', '2026-06-30', 3);
