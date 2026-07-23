# PE2 — Đề Trial (Restaurant / Food / Foody Gateway)

Giải theo đúng "taste" PE1 để đối chiếu học tập. File này ghi lại **các chỗ đề Trial mâu thuẫn** và quyết định xử lý — đây chính là phần đáng học nhất của đề này.

## Mapping project ↔ PE1

| PE2 (Trial) | Port | Mirror của PE1 | Package |
|---|---|---|---|
| SE193114RestaurantService | 8081 | SE193114DepartmentService | `fu.se193114.restaurant` |
| SE193114FoodService | 8082 | SE193114EmployeeService (Feign) | `fu.se193114.food` |
| SE193114FoodyGateway | 8080 | SE193114EmployeeGateway | `fu.se193114.gateway` |

## Các quyết định tại chỗ đề mâu thuẫn (bẫy!)

1. **Bảng/cột theo SCRIPT SQL đề cho sẵn**, không theo bảng mô tả trong doc (doc ghi Nvarchar/Date, script là varchar/datetime2; doc ghi `ingredients`, script là `ingredient` số ít). Lý do: mục chấm "table/field name must follow" — script là thứ chạy thật. Entity map `ingredients` (field Java) → `@Column(name="ingredient")`.
2. **RestaurantDTO không có category** nhưng cột `category_id` NOT NULL → thêm field `categoryId` (Long) vào DTO. Create bắt buộc có categoryId hợp lệ (tồn tại trong bảng Category), sai → 400/2 (validation), vì đề không định nghĩa status riêng cho "category not found".
3. **DTO `owner` ↔ cột `owner_name`** — map trong entity/mapper, đừng đổi tên field DTO.
4. **FoodListDTO ≠ PageDTO**: list foods trả `pageSize, pageNo, totalPages, first, last, foods` (KHÔNG có totalElements) — theo đúng bảng FoodListDTO của đề; dòng "PageDTO" trong Response Behavior là lỗi copy-paste của đề.
5. **FoodDTO (phẳng) vs FoodResponseDTO (nested restaurant)**: create/update/get-detail trả FoodDTO phẳng; CHỈ list trả FoodResponseDTO nested (Feign per row) — ngược với PE1 (PE1 nested ở mọi chỗ). Theo đúng chữ của đề.
6. **"Department ID is not found"** trong đề Food = lỗi copy-paste → hiểu là **Restaurant ID is not found** (400/4, Feign verify khi create/update).
7. **CategoryDTO không được định nghĩa** → tự định nghĩa `{categoryId, name}`. GET /api/categories nằm trong RestaurantService, tách controller riêng `SE193114CategoryController` (đề chỉ nêu tên RestaurantController; tách để giữ base-path sạch).
8. **ApiResponseDTO giữ 4 field như PE1** (status, message, data, timestamp): bảng trial chỉ ghi status/message/data nhưng R04 vẫn yêu cầu ISO 8601 timestamp; sample có message. Thêm timestamp vô hại, đồng nhất taste PE1.
9. Status restaurant/food chỉ có **ACTIVE, INACTIVE** (không có CLOSED như PE1).
10. Gateway phải route **cả `/api/categories/**`** → 8081 (dễ quên vì categories nằm trong RestaurantService).
11. Password local `12345` — **trước khi nộp thật phải đổi `sa`** (mục chấm 0), giống PE1.
12. open_date: entity `java.util.Date` + `@Temporal(TIMESTAMP)` (cột datetime2), JSON `@JsonFormat(pattern="yyyy-MM-dd")` như PE1.

## Chạy

1. Chạy `init_trial_db.sql` (SSMS, sa/12345).
2. RestaurantService (8081) → FoodService (8082) → FoodyGateway (8080).
3. Test qua 8080; Swagger `/swagger-ui.html` cả 3 port.
