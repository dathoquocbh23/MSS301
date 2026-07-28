# HTTP request test cho PE1 + PE2

Mở file `.http` trong IntelliJ → góc phải trên chọn **Environment**:

| Env | Ý nghĩa |
|---|---|
| `gateway` | Mọi request đi qua port **8080** — chế độ CHẤM ĐIỂM, luôn test bằng cái này trước khi nộp |
| `direct` | Gọi thẳng Master 8081 / Detail 8082 — debug khi gateway lỗi |

PE1 và PE2 dùng chung port (8080/8081/8082) nên **chỉ chạy 1 bộ service tại 1 thời điểm**:

- **PE1** (Department/Employee): chạy `PE1/init_db.sql` → DepartmentService → EmployeeService → Gateway → dùng `pe1-*.http`
- **PE2** (Restaurant/Food): chạy `PE2/init_trial_db.sql` → RestaurantService → FoodService → FoodyGateway → dùng `pe2-*.http`

Mỗi request có comment `# Expect:` ghi HTTP code + `status` trong body để đối chiếu.
Thứ tự trong file là thứ tự nên chạy (create trước, các case not-found dùng id 99999 nên chạy lúc nào cũng được).

Lưu ý format ngày:
- **PE1**: `dd/MM/yyyy` (spec sample `20/05/2025`) — response cũng trả dd/MM/yyyy; input nhận cả 2 format.
- **PE2**: `yyyy-MM-dd` (đề Trial dùng `@JsonFormat yyyy-MM-dd`).
