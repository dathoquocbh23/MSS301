# =============================================================
#    TEMPLATE THI PE MÔN MSS301 - MICROSERVICES WITH SPRING
#    (đúc từ PE1 Department/Employee + PE2 Restaurant/Food)
# =============================================================

Template này dùng 2 tên generic, vào phòng thi chỉ cần FIND-REPLACE:

| Placeholder | Vai trò | Ví dụ PE1 | Ví dụ PE2 |
|---|---|---|---|
| `Master` / `master` | Entity phía **1** (bị gọi), port **8081** | Department | Restaurant |
| `Detail` / `detail` | Entity phía **N** (đi gọi Feign), port **8082** | Employee | Food |
| `Gateway` | Cổng cho end-user, port **8080** | EmployeeGateway | FoodyGateway |
| `SE193114` | MSSV (đề ghi hoa/thường sao thì y vậy) | | |
| `MSS301_2026_PE` | Tên database theo đề | | |

Cách find-replace an toàn trong IntelliJ (Ctrl+Shift+R, scope: cả project, **Match case BẬT**):
1. `Master`  → `Department` (tên đề thật, viết Hoa đầu)
2. `master`  → `department` (chữ thường — package, biến)
3. `masters` sẽ tự thành `departments` nhờ bước 2 (tên table — kiểm lại với script SQL của đề!)
4. Lặp lại với `Detail` / `detail`.
5. Đổi tên folder project + refactor tên class Application/Controller (Shift+F6) cho khớp.
6. Kiểm tra lại `@Table(name=...)`, `@Column(name=...)` theo ĐÚNG script SQL đề cho (không theo bảng mô tả trong doc nếu 2 cái mâu thuẫn — xem mục VIII).

=============================================================
## I. ĐỀ THI CÓ GÌ LẠ?

1. Đề >= 10 trang, đọc kỹ từng chữ.

2. Có 2 file script SQL tạo table cho 2 service khác nhau, nhưng các table
   tạm ở CHUNG 1 DATABASE (cho tiện làm bài). 2 table quan hệ 1-N
   (masters ----< details) nhưng bài thi GIẢ LẬP chúng khác database:
   - KHÔNG kéo relationship trong DB.
   - KHÔNG dùng `@OneToMany` / `@ManyToOne` trong entity — phía Detail chỉ giữ
     cột `master_id` dạng `Long` trơn.
   - DATABASE FIRST: có table trước → suy ngược ra `@Entity`.

3. Tạo 3 REST-API project độc lập, 3 port khác nhau:
   - MasterService  → port 8081 → CRUD table `masters`
   - DetailService  → port 8082 → CRUD table `details`
   - Gateway        → port 8080 → port export cho end-user, Swagger-UI trên
     port này tự điều hướng vào 2 port kia.

4. DetailService (8082) --- dùng OPENFEIGN gọi ---> MasterService (8081)
   để xin thông tin Master (vì bị "chia cắt DB", không JOIN được).

5. Nộp 3 file .zip riêng lẻ, hoặc 1 .zip lớn chứa 3 .zip riêng lẻ.
   (Xóa folder `target/` trước khi zip cho nhẹ.)

=============================================================
## II. CODING CONVENTION — XEM ĐỀ, ĐẶT CHÍNH XÁC TỪNG CÂU CHỮ

Tên thường chứa MSSV, chú ý CHỮ HOA / CHỮ THƯỜNG y hệt đề!

1. Tên project:
   - `SE193114MasterService`  → 8081
   - `SE193114DetailService`  → 8082
   - `SE193114Gateway`        → 8080  (đề hay đặt kiểu SE193114XxxGateway — theo đề!)

2. Cấu trúc package (cả 2 service giống nhau):
   ```
   fu.se193114.master/            fu.se193114.detail/            fu.se193114.gateway/
       .common/                       .common/                        .config/
       .config/                       .config/
       .entity/                       .entity/
       .dto/                          .dto/
       .repository/                   .repository/   (chứa cả Feign client)
       .service/                      .service/
       .service.impl/                 .service.impl/
       .controller/                   .controller/
   ```

3. Tên controller thường phải chứa MSSV: `SE193114MasterController`.

=============================================================
## III. TẠO DATABASE VÀ CHẠY SCRIPT

1. Mở SQL Server Management Studio, tạo database theo tên trong đề
   (hoặc tên trong file .sql đính kèm):
   ```sql
   CREATE DATABASE MSS301_2026_PE
   ```
2. Mở 2 file script của đề (.txt → notepad copy-paste; .sql → tự mở SSMS),
   Ctrl+A / Ctrl+C → dán vào SSMS → Execute.
3. File `sql/init_db.sql` trong template này là ví dụ cấu trúc để tham khảo —
   THI THẬT PHẢI DÙNG SCRIPT CỦA ĐỀ.

=============================================================
## IV. TẠO 3 PROJECT (CẦN WIFI để tải dependency lúc tạo)

Cách A — nhanh nhất: copy 3 folder template này, đổi tên, find-replace như bảng đầu file.

Cách B — tạo mới bằng Spring Initializr (IntelliJ: New Project → Spring Boot):
- Java 21, Maven, Spring Boot 3.5.x, packaging Jar.
- **MasterService** chọn 6 dependency: Spring Web, Spring Data JPA, Validation,
  Lombok, MS SQL Server Driver, Spring Boot DevTools (tùy chọn).
- **DetailService**: 6 cái trên + **OpenFeign** (Spring Cloud).
- **Gateway**: Spring Web, Spring Security, **Gateway** (spring-cloud-starter-gateway-server-webmvc).
- Swagger-UI KHÔNG có trong Initializr — thêm tay vào pom.xml:
  ```xml
  <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>2.8.16</version>
  </dependency>
  ```

Chỉnh `application.properties` mỗi project (đã có sẵn trong template):
- template đang để đúng giá trị đề Trial yêu cầu: `sa` / `sa`. Máy mình password khác thì đổi tạm
  để chạy, **nhớ trả về đúng đề trước khi nộp** (mục chấm 0 điểm),
- tên database khớp đề,
- port: 8081 Master / 8082 Detail / 8080 Gateway.

RUN thử Tomcat từng project: **log đỏ chạy hoài không tắt = ĐÚNG** (app đang chạy).
Started ... in x.x seconds là OK. Nếu tắt ngay → sai connection string/password.

=============================================================
## V. CODE TỪNG PROJECT — THỨ TỰ LÀM

### 5.1 MasterService (8081) — làm TRƯỚC vì Detail cần gọi nó

1. Tạo cấu trúc package như mục II.
2. **@Entity** (quan trọng nhất — 2 cách):
   - Gõ tay theo template `entity/Master.java`.
   - **Suy ngược từ table (NÊN CHỌN)**: IntelliJ Ultimate → View → Tool Windows →
     Database → cắm SQL Server → chuột phải table → Scripted Extensions →
     Generate POJOs / hoặc dùng JPA Buddy. Sau đó sửa lại cho khớp convention
     (Lombok @Getter/@Setter, `@Column(name=...)` snake_case đúng script SQL).
   - KHÔNG `@OneToMany`/`@ManyToOne` (xem mục I.2). Khóa ngoại chỉ là `Long masterId`.
   - Cột DATE → `java.util.Date` + `@Temporal(TemporalType.DATE)`;
     cột datetime2 → `@Temporal(TemporalType.TIMESTAMP)`; JSON thì `@JsonFormat(pattern="yyyy-MM-dd")`.
3. `dto/` : MasterDTO, ApiResponseDTO, PageDTO, CategoryDTO.
   **Validation CHỈ đặt ở DTO và chỉ suy từ ràng buộc cột trong script SQL** — bảng quy đổi
   ràng buộc → annotation nằm ở đầu file `DOI-TEN-TUNG-BUOC.md`. Service không check lại field nào.
4. `repository/` : MasterRepository (JpaRepository + `existsByCode...` + @Query search).
5. `service/` + `service/impl/` : CRUD + phân trang + soft-delete (đổi status
   thành INACTIVE thay vì xóa thật — đọc đề xem yêu cầu gì).
6. `controller/` : SE193114MasterController — status code, message trả về
   **copy y nguyên câu chữ trong đề**.
7. `common/` : GlobalExceptionHandler + các exception + validation groups
   OnCreate/OnUpdate + custom validator ngày (nếu đề yêu cầu).
8. `config/OpenApiConfig` : đặt title theo đề.
9. Chạy → mở `http://localhost:8081/swagger-ui.html` test CRUD.

### 5.2 DetailService (8082)

1. Giống 5.1 cho phần CRUD Detail.
2. Main class thêm **`@EnableFeignClients`**.
3. `repository/MasterClient.java` — Feign gọi sang 8081:
   ```java
   @FeignClient(name = "master-service", url = "http://localhost:8081")
   public interface MasterClient {
       @GetMapping("/api/masters/{id}")
       MasterApiResponse getMasterById(@PathVariable("id") Long id);
   }
   ```
4. `dto/` thêm: MasterDTO (bản copy phía detail), MasterApiResponse (bóc vỏ
   ApiResponseDTO của bên kia — có `@JsonIgnoreProperties(ignoreUnknown = true)`).
5. Logic Feign trong ServiceImpl:
   - **create/update**: verify masterId qua Feign, không có → ném NotFound
     ("Master ID is not found" — câu chữ theo đề).
   - **get/list**: gọi Feign "safe" (try-catch trả null) để nhét object master
     nested vào response — đọc đề xem chỗ nào trả nested, chỗ nào trả phẳng
     (PE1 nested mọi chỗ, PE2 chỉ nested ở list!).
6. Chạy → `http://localhost:8082/swagger-ui.html`.

### 5.3 Gateway (8080)

1. Chỉ cần: main class + `config/SecurityConfig` (permitAll + CORS) +
   `application.properties` khai routes:
   ```properties
   spring.cloud.gateway.server.webmvc.routes[0].id=master-service
   spring.cloud.gateway.server.webmvc.routes[0].uri=http://localhost:8081
   spring.cloud.gateway.server.webmvc.routes[0].predicates[0]=Path=/api/masters/**
   spring.cloud.gateway.server.webmvc.routes[1].id=detail-service
   spring.cloud.gateway.server.webmvc.routes[1].uri=http://localhost:8082
   spring.cloud.gateway.server.webmvc.routes[1].predicates[0]=Path=/api/details/**
   ```
2. ⚠️ Nếu service 8081 có THÊM controller phụ (kiểu `/api/categories` của PE2)
   thì phải thêm route cho nó — RẤT DỄ QUÊN.

=============================================================
## VI. CHẠY & TEST

1. Thứ tự chạy: **Master (8081) → Detail (8082) → Gateway (8080)**.
2. Test toàn bộ qua **port 8080**; Swagger có ở cả 3 port.
3. Checklist chấm điểm tự test:
   - [ ] Create: 201, status=1, message đúng câu chữ đề.
   - [ ] Create trùng code: 400, status theo bảng lỗi của đề (PE1: 3=duplicate).
   - [ ] Validation fail: 400, status=2, message đúng đề.
   - [ ] Not found: 400 (không phải 404 — đọc đề!), status=4.
   - [ ] Detail create với masterId không tồn tại → lỗi qua Feign.
   - [ ] List có phân trang + filter name/status.
   - [ ] Delete = soft delete (status→INACTIVE) nếu đề yêu cầu.
   - [ ] ApiResponse đúng số field đề liệt kê (đề Trial chỉ có status/message/data — KHÔNG timestamp).

=============================================================
## VII. NỘP BÀI

1. Đổi password DB về `sa`/mặc định nếu đề yêu cầu (mục chấm 0 điểm nếu sai!).
2. Xóa `target/` cả 3 project.
3. Zip từng project riêng: `SE193114MasterService.zip`, `SE193114DetailService.zip`,
   `SE193114Gateway.zip` → (tùy đề) gói tiếp vào 1 zip lớn.
4. Giải nén thử ra chỗ khác, mở lại bằng IntelliJ chạy được mới nộp.

=============================================================
## VIII. CÁC BẪY THƯỜNG GẶP (rút từ PE1 + PE2/DECISIONS.md)

1. **Script SQL > bảng mô tả trong doc**: doc ghi Nvarchar/Date nhưng script là
   varchar/datetime2, doc ghi `ingredients` script ghi `ingredient` → THEO SCRIPT
   (vì mục chấm "table/field name must follow"). Field Java đặt theo doc thì map
   bằng `@Column(name="...")`.
2. **DTO field ≠ tên cột** (vd DTO `owner` ↔ cột `owner_name`) → map trong
   entity/mapper, KHÔNG đổi tên field DTO.
3. **DTO thiếu FK nhưng cột NOT NULL** → tự thêm field id đó vào DTO, create
   bắt buộc hợp lệ.
4. **PageDTO của mỗi đề mỗi khác** (PE2 list không có totalElements) → theo đúng
   bảng DTO của đề, đừng bê nguyên PageDTO cũ.
5. **Message lỗi đề ghi sai do copy-paste** (đề Food ghi "Department ID is not
   found") → hiểu theo ngữ cảnh nhưng giữ nguyên format đề yêu cầu.
6. **Nested vs phẳng**: chỗ nào response nested object, chỗ nào phẳng — đọc từng
   endpoint, đừng đoán theo đề cũ.
7. Enum status mỗi đề mỗi khác (ACTIVE/INACTIVE/CLOSED vs chỉ ACTIVE/INACTIVE).
8. Gateway thiếu route cho controller phụ.
9. Đề không định nghĩa DTO nào đó → tự định nghĩa tối thiểu, ghi chú.
10. `encrypt=false;` trong connection string — thiếu là không kết nối được SQL Server.
