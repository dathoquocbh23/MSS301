-- MSS301 SU26 PE1 - SEED DATA CO DINH DE CHAY BO TEST
-- Chay lai file nay truoc moi lan chay test-runner de ket qua on dinh (id 1..12 / 1..5).
USE [MSS301_2026_PE];
GO

DELETE FROM [dbo].[reservations];
DELETE FROM [dbo].[rooms];
GO

DBCC CHECKIDENT ('[dbo].[rooms]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[reservations]', RESEED, 0);
GO

SET IDENTITY_INSERT [dbo].[rooms] OFF;
INSERT INTO [dbo].[rooms] (room_number, room_type, price_per_night, capacity, floor, status) VALUES
 (N'A-101', N'DOUBLE',  850000.00,  2, 1, N'AVAILABLE'),    -- id 1  happy path (price 850000, cap 2)
 (N'A-102', N'SINGLE',  500000.00,  1, 1, N'AVAILABLE'),    -- id 2
 (N'A-103', N'SUITE',  2000000.00,  4, 1, N'OCCUPIED'),     -- id 3  -> test 400/5
 (N'A-104', N'DELUXE', 1500000.00,  3, 1, N'MAINTENANCE'),  -- id 4  -> test 400/5
 (N'B-201', N'DOUBLE',  900000.00,  2, 2, N'AVAILABLE'),    -- id 5
 (N'B-202', N'SINGLE',  550000.00,  1, 2, N'AVAILABLE'),    -- id 6
 (N'B-203', N'SUITE',  2100000.00, 10, 2, N'AVAILABLE'),    -- id 7  capacity max
 (N'B-204', N'DELUXE', 1600000.00,  3, 2, N'OCCUPIED'),     -- id 8
 (N'C-301', N'DOUBLE',  950000.00,  2, 3, N'AVAILABLE'),    -- id 9
 (N'C-302', N'SINGLE',  600000.00,  1, 3, N'AVAILABLE'),    -- id 10
 (N'C-303', N'SUITE',  2200000.00,  4, 3, N'AVAILABLE'),    -- id 11
 (N'C-304', N'DELUXE', 1700000.00,  3, 3, N'MAINTENANCE');  -- id 12
GO

INSERT INTO [dbo].[reservations]
 (guest_name, guest_email, guest_phone, check_in_date, check_out_date, number_of_guests, total_amount, status, room_id) VALUES
 (N'Nguyen Van An',  N'an@example.com',    N'0901000001', '2026-08-01', '2026-08-05', 2, 3400000.00, N'CONFIRMED',   1),
 (N'Tran Thi Binh',  N'binh@example.com',  N'0901000002', '2026-08-02', '2026-08-04', 1, 1000000.00, N'CHECKED_IN',  2),
 (N'Le Van Cuong',   N'cuong@example.com', N'0901000003', '2026-08-03', '2026-08-06', 2, 2700000.00, N'CHECKED_OUT', 5),
 (N'Pham Thi Dung',  N'dung@example.com',  N'0901000004', '2026-08-04', '2026-08-07', 1, 1650000.00, N'CANCELLED',   6),
 (N'Hoang Van An',   N'an2@example.com',   N'0901000005', '2026-08-05', '2026-08-08', 4, 6600000.00, N'CONFIRMED',  11);
GO

SELECT 'rooms' AS tbl, COUNT(*) AS n FROM [dbo].[rooms]
UNION ALL
SELECT 'reservations', COUNT(*) FROM [dbo].[reservations];
GO
