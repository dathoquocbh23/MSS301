# ĐỔI TEMPLATE → BÀI THI: TỪNG BƯỚC, TỪNG FILE

> **KHÔNG tạo module mới trong lúc thi.** Copy 3 project template → đổi tên → rà từng file theo đề.
> Template này là **lời giải đúng của đề Trial** (Restaurant/Food/Category) nhưng đặt tên placeholder
> `Master` / `Detail` / `Category`, nên vào đề thật chỉ còn việc đổi tên + nắn field.
>
> **Source template + code gen-from-entity sinh ra KHÔNG có comment** (chủ ý — bài nộp sạch).
> Toàn bộ hướng dẫn/bẫy nằm trong file .md này, đừng tìm trong code.

---

## NGUYÊN TẮC SỐ 1 — VALIDATION CHỈ NẰM Ở DTO

Đề mục 2.4 R01: *"The input data must be validated based on the constraints (mandatory, max length,
format…) **defined for columns and tables in database**"*. Tức là:

- **Nguồn** của validation = SCRIPT SQL của đề (không phải bảng mô tả trong doc, không phải tự nghĩ ra).
- **Nơi đặt** = file `dto/MasterDTO.java` / `dto/DetailDTO.java`. **Chỉ một nơi.**
  Service KHÔNG check lại field nào; entity KHÔNG có annotation validation nào.

Bảng quy đổi — mỗi ràng buộc trong script SQL đúng **một** annotation:

| Trong script SQL | Annotation trong DTO |
|---|---|
| cột `NOT NULL`, kiểu chuỗi | `@NotBlank(groups = OnCreate.class)` |
| cột `NOT NULL`, kiểu số/ngày | `@NotNull(groups = OnCreate.class)` |
| cột có độ dài `varchar(n)` | `@Size(max = n, groups = {OnCreate.class, OnUpdate.class})` |
| cột cho `NULL` | **không annotation nào** |
| tập giá trị cố định (CHECK / doc ghi ACTIVE,INACTIVE) | `@Pattern(regexp = "ACTIVE\|INACTIVE")` — **regex và message phải cùng danh sách** (gen-from-entity có `-StatusEnum 'A,B,C'` sinh cả hai từ một nguồn) |
| cột số có khoảng giá trị trong DOC (Mock01: starRating "From 1 to 5") | `@Min` + `@Max` — điền rule `@{ f='starRating'; numMin=1; numMax=5; msg='...' }` vào `$...Rules` của gen-all (range nằm trong doc nên PHẢI tự đọc rồi điền, script không đoán được) |
| cột chỉ cho phép ký tự nhất định trong DOC (code: chữ + số) | `@Pattern` — rule `@{ f='code'; pattern='[A-Za-z0-9]+'; msg='câu chữ đề' }` |
| cột email | `@Email` — rule `@{ f='email'; email=$true; msg='...' }` |
| cột enum NGOÀI status (position: Manager/Developer/Staff) | `@Pattern` — rule `@{ f='position'; enum='Manager,Developer,Staff' }` (message tự sinh "position must be one of ..." hoặc điền msg) |
| rule ngày RIÊNG 1 field (after X and before today+N) | rule `@{ f='effectiveDate'; dateMin='2000-01-01'; dateMaxDays=360; msg='câu chữ đề' }` — đè lên config global của `ValidDate.java`, message dùng chung cho cả 2 biên |
| CHECK ngày so với hôm nay (`col >= getdate()`) | `FUTURE_ONLY = true` trong `ValidDate.java` (27/07: `effective_date >= getdate()` mà quên → lọt xuống DB → 500/0) |
| CHECK **chéo 2 cột** (`end_date >= start_date`) | annotation field-level làm không được → check ở Service, **đặt SAU `applyPartialUpdate`** để PUT chỉ gửi 1 trong 2 field vẫn so được với giá trị cũ trong DB |
| rule NGÀY (format dd/MM/yyyy, after mốc, not future, today+N) | bật hằng số trong `common/ValidDate.java` — `@ValidDate` đã gắn sẵn mọi field ngày |
| cột `UNIQUE` | annotation làm không được → check ở Service → 400/3 |
| khóa ngoại | `@NotNull` + Service verify tồn tại → 400/2 (nội bộ) hoặc 400/4 (qua Feign) |

**Quy tắc soát:** mở script SQL của đề, đếm số `CHECK`/`UNIQUE`/`NOT NULL` — mỗi cái phải chỉ được
vào đúng một dòng code chặn nó **trước khi tới `repository.save()`**. Ràng buộc nào chỉ tồn tại ở DB
là một quả 500/0 chờ nổ. `GlobalExceptionHandler` đã có handler `DataIntegrityViolationException`
trả 400/2 làm **lưới cuối** — nhưng nó trả message chung chung, không đúng câu chữ đề, nên chỉ để
đỡ đạn chứ không thay được check ở code.

Vì sao chia group `OnCreate`/`OnUpdate`: PUT là partial update, field vắng mặt là hợp lệ →
`@NotBlank`/`@NotNull` chỉ bật ở `OnCreate`; `@Size`/`@Pattern` bật cả hai. Công tắc nằm ở controller:
`@Validated(OnCreate.class)` cho POST, `@Validated(OnUpdate.class)` cho PUT.

Vì sao KHÔNG đặt ở entity: `@Column(nullable=false)` chỉ là metadata DDL. Nếu để Hibernate phát hiện
lúc flush thì lỗi bay ra từ tầng persistence → handler trả **500/0**, trong khi đề đòi **400/2**.

---

## NGUYÊN TẮC SỐ 0 — MÃ HTTP KHÔNG CỐ ĐỊNH GIỮA CÁC ĐỀ

> **Đề Trial và PE1 dùng `400` cho mọi lỗi. Đề SU26 PE1 (Room/Reservation) dùng `406` / `226` / `404` / `400`.**
> Template mặc định `400` cho tất cả. **Không đổi = sai HTTP code ở gần như MỌI DÒNG của MỌI bảng
> Response Behavior**, dù logic đúng hết.

Việc đầu tiên khi mở đề: nhìn cột **HTTP Code** của bảng Response Behavior, điền vào `gen-all.ps1`:

```powershell
$HttpValidation = 406   # status 2
$HttpDuplicate  = 226   # status 3
$HttpNotFound   = 404   # status 4
$HttpBusiness   = 400   # status 5 - nhánh nghiệp vụ riêng của đề
$HttpError      = 500   # status 0
```

rồi `powershell -ExecutionPolicy Bypass -File .\gen-all.ps1 -HttpOnly`.

Script ghi thẳng vào 5 hằng số đầu `common/GlobalExceptionHandler.java` của **cả hai** service.
Trong file đó **không có** `HttpStatus.XXX` nào rải rác ở dưới — mọi handler đều trỏ về 5 hằng số này,
nên không có chuyện sửa sót một chỗ.

**Status 5 trở lên**: đề SU26 PE1 có thêm dòng `400 / status 5 — "Room is not AVAILABLE for reservation"`.
Template có sẵn `common/BusinessRuleException.java` cho việc này — ném nó ra từ service, handler tự map.
Đề nào không có status 5 thì để nguyên, class thừa vô hại (hoặc xoá).

---

## BƯỚC 0 — ĐỌC ĐỀ, ĐIỀN BẢNG NÀY (5 phút đầu, chưa gõ code)

| # | Câu hỏi với đề | Template đang là | Đề Trial (ví dụ) | ĐỀ THẬT (điền) |
|---|---|---|---|---|
| 0a | **HTTP code cho status 2 / 3 / 4 / 0?** | 400/400/400/500 | 400/400/400/500 | ______ |
| 0b | **Có status 5 trở lên không? Nhánh nào?** | không | không | ______ |
| 0c | **Field nào là COMPUTED (server tự tính)?** | không | không | ______ |
| 0d | **Ràng buộc CHÉO SERVICE nào?** (field bên Detail so với field của Master lấy qua Feign) | không | không | ______ |
| 0e | **Message của nhánh validation: câu cố định hay chi tiết từng field?** | chi tiết | — | ______ |
| 1 | Entity phía **1** (bị gọi qua Feign)? | `Master` | `Restaurant` | ______ |
| 2 | Entity phía **N** (đi gọi Feign)? | `Detail` | `Food` | ______ |
| 3 | Có entity **phụ** không? | `Category` | `Category` | ______ |
| 4 | Tên project gateway (phần sau MSSV)? | `Gateway` | `FoodyGateway` | ______ |
| 5 | MSSV viết hoa/thường thế nào? | `SE193114` / `se193114` | y vậy | ______ |
| 6 | Port Master / Detail / Gateway? | 8081 / 8082 / 8080 | 8081 / 8082 / 8080 | ______ |
| 7 | Tên database? | `MSS301_2026_PE` | `MSS301_2026_PE` | ______ |
| 8 | username / password datasource? | sa / sa | sa / sa | ______ |
| 9 | Tên **table** theo SCRIPT SQL? | `masters`,`details`,`categories` | `restaurants`,`Foods`,`Category` | ______ |
| 10 | Base path 3 controller? | `/api/masters`,`/api/details`,`/api/categories` | `/api/restaurants`,`/api/foods`,`/api/categories` | ______ |
| 11 | Số nhiều có bất quy tắc không? | — | `Category`→`categories` | ______ |
| 12 | Format ngày trong sample JSON? | `dd/MM/yyyy` | `20/05/2025` = dd/MM/yyyy | ______ |
| 13 | Enum status? | ACTIVE/INACTIVE | ACTIVE/INACTIVE | ______ |
| 13b | **Status lúc CREATE / lúc DELETE?** Quy tắc đúng cho cả 4 đề đã gặp: **phần tử ĐẦU** của `$…Status` = create, **phần tử CUỐI** = delete. gen-from-entity tự patch cả 2 chỗ; đề nào lệch thì truyền `-StatusOnCreate` / `-StatusOnDelete`. | ACTIVE / INACTIVE | ACTIVE / INACTIVE | ______ |
| 14 | Bảng status code của đề? | 1/2/3/4/0 | 1/2/3/4/0 | ______ |
| 15 | ApiResponse có field nào? | status, message, data | y vậy | ______ |
| 16 | Phía Detail dùng PageDTO hay DTO list riêng? | `DetailListDTO` riêng | `FoodListDTO` riêng | ______ |
| 16c | **Đề có câu "PageDTO: See the definition in ... section" không?** Có → **XOÁ** `DetailListDTO`, copy `PageDTO` sang, dùng chung 2 service (đề SU26 PE1). Không → giữ DTO riêng. | DTO riêng | DTO riêng | ______ |
| 16d | **GET detail và GET list trả DTO NÀO?** Đề SU26 PE1: create/update trả DTO **phẳng**, get-by-id và list trả DTO **nested** — 4 endpoint 2 loại DTO khác nhau. | phẳng / nested | y vậy | ______ |
| 16b | **Shape DTO Detail: A / B / C?** (nhìn bảng DTO: có `masterId` phẳng? có object nested? list dùng DTO riêng?) | B | B (DTO phẳng + FoodResponseDTO nested cho list) | ______ |
| 17 | Liệt kê **mọi CHECK constraint** trong script SQL? | — | status IN (...) | ______ |
| 18 | Query param list: cái nào **Enum**, cái nào partial? | name/ownerName partial | y vậy | ______ |
| 19 | `size` vượt max → **lỗi (400)** hay **clamp (200)**? | **400** (mặc định) | 400 — đề ghi "max: 100" + endpoint list CÓ row 400/2 → đọc là strict (27/07 chấm strict thật) | ______ |

---

## BƯỚC 1 — CHẠY SCRIPT ĐỔI TÊN (~1 phút)

```powershell
cd "e:\fpt_university\Semester8\MSS301\PE\template PE"
# Mở rename-template.ps1, sửa các biến đầu file theo BẢNG BƯỚC 0, rồi:
powershell -ExecutionPolicy Bypass -File .\rename-template.ps1
```

Script làm 4 việc: copy sang folder bài làm (bỏ `target/`) → đổi tên thư mục → đổi tên file →
thay nội dung mọi `.java .xml .properties .sql .md`. Có biến `$MasterPlural`/`$DetailPlural`/`$CategoryPlural`
để xử lý số nhiều bất quy tắc — điền tay khi tên mới không phải chỉ thêm `s`.

Có thêm `$MasterTable`/`$DetailTable`/`$CategoryTable`: điền khi tên **table** trong script SQL khác
với số nhiều trên URL (Mock01: URL `/api/hotel-types` nhưng table tên `HotelType` → `$CategoryTable = "HotelType"`,
không điền là `@Table(name = "hotel-types")` sai luôn SQL). Để `""` nếu table = số nhiều URL.
(Entity chính thì BƯỚC 2.5 sinh lại `@Table` từ DB nên tự đúng — biến này chủ yếu cứu entity phụ.)

**Đề KHÔNG có entity phụ (kiểu PE1)**: đặt `$HasCategory = $false` — script tự xóa 7 file `Category*`,
gỡ route category khỏi gateway, và tự cắt mọi code Category trong `MasterServiceImpl`
(import, `@Autowired` field, 2 chỗ gọi check, cả hàm `requireCategoryExists`).
Không phải xóa tay gì cả. (Field `categoryId` còn sót trong entity/DTO/mapper sẽ tự biến mất
ở BƯỚC 2.5 khi gen-from-entity sinh lại từ DB thật không có cột đó.)

Package gateway **giữ nguyên** `fu.se193114.gateway` (đề mục 2.5 quy định `<servicename>` = master, detail, **gateway**).

Sau khi chạy: mở IntelliJ → Maven reload → chạy thử cả 3 → mới bắt đầu Bước 3.

Nếu script trục trặc: IntelliJ `Ctrl+Shift+R`, scope Project, **bật Match Case**, chạy theo thứ tự
`masters`→số nhiều mới, `Master`→`Tên`, `master`→`tên`, rồi lặp cho Detail/Category; đổi tên package
và class bằng `Shift+F6`.

---

## BƯỚC 2 — CHẠY SCRIPT SQL CỦA ĐỀ

`sql/init_db.sql` trong template **chỉ là mẫu**. Thi thật chạy script của đề trong SSMS
(`CREATE DATABASE <tên đề>` trước nếu script không tự tạo). Table/field phải theo script đề —
mục chấm 2.5 y 6: *"If not follow, the result will not be graded"*.

---

## BƯỚC 2.5 — SINH ENTITY/DTO/MAPPER TỰ ĐỘNG (`gen-from-entity.ps1`)

Thay vì sửa tay field trong template, dùng IntelliJ generate entity từ DB rồi để script sinh phần còn lại:

1. IntelliJ → Database tool → cắm SQL Server → chuột phải table → **Generate Persistence Mapping**
   (có Lombok trong project thì nó tự dùng `@Getter/@Setter`). Lưu ý: table `Foods` có thể ra class
   tên `Foods` — sửa tên class ngay trong dialog thành `Food`.
2. Dán class vừa sinh **đè lên** `entity/<Tên>.java` của project đã rename.
3. Chạy — **cách khuyên dùng: `gen-all.ps1`** — mở file, điền một lần cả 3 service ngay đầu file
   (`$MasterRename/Filter/Unique/Status`, `$SubEntity`, `$Detail...` — đọc từ bảng DTO + Query Parameters
   + CHECK constraint của đề), rồi:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\gen-all.ps1
   ```
   Nó gọi gen-from-entity theo đúng thứ tự Master → entity phụ → Detail, service nào **chưa dán entity
   thì bỏ qua có báo** — dán xong chạy lại file y nguyên (chạy lại không hỏng gì). Khớp nhịp thi:
   dán Hotel → chạy → làm Master; lát sau dán Booking → chạy lại → làm Detail.

   Hoặc chạy lẻ từng service qua terminal:
   ```powershell
   # phía Master (ví dụ đề Trial):
   powershell -ExecutionPolicy Bypass -File .\gen-from-entity.ps1 -Service Restaurant -Rename "owner_name=owner" -Filter "name,ownerName=owner" -Unique name
   # phía Detail (script tự thấy Feign client -> sinh thêm ResponseDTO + bản copy RestaurantDTO):
   powershell -ExecutionPolicy Bypass -File .\gen-from-entity.ps1 -Service Food -Rename "ingredient=ingredients" -Filter "name,ingredients"
   ```

Script làm gì:
- **Chuẩn hóa entity**: `Integer` → `Long` cho PK và cột `_id`; `Instant/LocalDateTime` → `Date + @Temporal(TIMESTAMP)`,
  `LocalDate` → `DATE`; bỏ noise `schema=`/`@NotNull/@Size`; `@ManyToOne` → cột `Long` trơn; ép Lombok;
  giữ nguyên `@Table(name=...)` + `nullable/length/unique` từ DB.
- **Sinh DTO**: validation theo đúng bảng quy đổi ở đầu file này (không comment — bài nộp sạch).
- **Sinh Mapper**: `toDTO` / `toEntity` / `applyPartialUpdate` (+ `toResponseDTO` nested nếu là phía Detail).
- **Sinh Repository** (chỉ entity chính): `existsBy<FieldUnique>` + `existsBy...And<Pk>Not` theo `-Unique`
  (không điền thì đoán từ cột UNIQUE của DB), `@Query` search theo `-Filter` (không điền thì đoán từ
  field String của entity, ưu tiên `name`, tối đa 2). Hết cảnh `m.owner` ma làm Hibernate chết ngay lúc boot.
- **Patch Service + ServiceImpl + Controller cho khớp**: đổi tên tham số filter, đề ít param hơn thì cắt,
  **nhiều hơn thì thêm** (cả @RequestParam, chữ ký list, repository.search), đổi cặp `existsByName(dto.getName())`
  theo field UNIQUE mới, `entity.set<Pk>(null)` và `require...Exists(dto.get<Fk>())` theo PK/FK thật.
  Chạy lại lần nữa không hỏng gì (idempotent) — đọc sót đề thì sửa tham số chạy lại.
- **Phía Detail** sinh thêm bản copy `<Master>DTO` từ DTO thật bên 8081 (file mà Shift+F6 không với tới).

**`-DetailShape A|B|C`** (BẢNG BƯỚC 0 dòng 16b) — cách DTO phía Detail mang thông tin Master, nhìn **bảng DTO của đề** mà chọn:

| Shape | Nhận diện trong đề | Sinh ra |
|---|---|---|
| **B** (mặc định, Trial) | DTO có `masterId` phẳng, **list** dùng DTO nested riêng | DetailDTO phẳng + `<X>ResponseDTO` nested cho list |
| **C** (kiểu đề 27/07 Employee) | **một** DTO duy nhất, chỉ có `department: DepartmentDTO`, KHÔNG có `departmentId` | 1 DTO: field nested 2 chiều + FK id `WRITE_ONLY` (nhận input phẳng vẫn chạy, response ẩn id — đúng bảng đề) |
| **A** | phẳng tuốt, kể cả list | 1 DTO phẳng, list không gọi Feign |

Mọi shape đều nhận **cả hai kiểu input** (`"masterId": 2` lẫn `"master": {"masterId": 2}`) nhờ
`resolveMasterId()` trong ServiceImpl + field ẩn `WRITE_ONLY`; `create()` giữ luôn kết quả Feign
(`fetchMasterOrThrow`) nên POST và GET trả master giống hệt nhau. Chọn nhầm shape thì chạy lại
với shape khác (riêng C/A đã xóa ResponseDTO — quay về B thì sửa tay theo cảnh báo script in ra).

**`$MasterRules` / `$DetailRules` trong gen-all** — rule validation **theo từng field**, chép từ cột Description
của bảng Database Structure/DTO trong đề. Mỗi rule một dòng `@{ f='tênField'; ... }`:

```powershell
$MasterRules = @(
    @{ f = 'code';          pattern = '[A-Za-z0-9]+'; msg = 'code only contains character (A-Z, a-z) and digits (0-9)' }
    @{ f = 'effectiveDate'; dateMin = '2000-01-01'; dateMaxDays = 360; msg = 'effective date must be after 2000/01/01 and before current date + 360' }
    @{ f = 'starRating';    numMin = 1; numMax = 5; msg = 'star rating must be from 1 to 5' }
    @{ f = 'email';         email = $true }
    @{ f = 'position';      enum = 'Manager,Developer,Staff' }
)
```

Key: `pattern` (regex) · `email=$true` · `enum='A,B,C'` (exact list → @Pattern) · `numMin/numMax` (@Min/@Max) ·
`dateMin='yyyy-MM-dd'` (after, exclusive) · `dateMax` (before) · `dateMaxDays=N` (before today+N) ·
`noFuture/futureOnly=$true` · `msg='copy Y NGUYÊN câu chữ đề'`. **Không điền `msg` thì message mặc định
sinh từ tên field** (không bao giờ dính message field khác kiểu "openedDate must be after..." cho effectiveDate —
message lạc đề = 0 điểm câu đó). Rule date đè lên config global `ValidDate.java` chỉ cho field đó;
rule sai tên field/kiểu → script chặn ngay không sinh file. Chỉ điền được qua gen-all (hashtable),
không truyền qua terminal `powershell -File` được.

**`-Filter "param1,param2=field"`** — chép từ bảng **Query Parameters** của đề. **Chiều của dấu `=`:
TRÁI = tên query param trên URL, PHẢI = field entity nó tìm** (Mock01: `directorName=director` — đề filter
theo `directorName` nhưng field là `director`). Đây KHÔNG phải cú pháp đổi tên kiểu `-Rename` — muốn param
tên `status` thì ghi `status`, đừng ghi `ingredients=status` (ra param `ingredients` tìm trên cột status!).
Filter String sinh LIKE partial-match; **riêng field `status` sinh EXACT match + tự tiêm check
`ALLOWED_STATUS` vào `list()`** (giá trị bậy → 400/2 "Data validation failed", danh sách lấy từ `-StatusEnum`).
Param dạng khác — `minStar` (số ≥), `checkInFrom` (ngày ≥) — vẫn phải thêm tay ở repository + service.
**`-Unique name`** — field check trùng theo đề, điền khi đề nói rõ (không điền script đoán từ UNIQUE của DB).

**`-Rename "ten_cot=tenDTO"`** (nhớ **dấu nháy** — nhiều cặp cách nhau dấu phẩy: `-Rename "a=b,c=d"`;
không nháy thì PowerShell nuốt dấu phẩy thành mảng lỗi) dùng khi bảng DTO của đề đặt tên field khác tên cột
(Trial: `owner_name`→`owner`, `ingredient`→`ingredients`). Dùng `-Rename` ngay lúc sinh, **đừng** chạy
`rename-field.ps1` sau đó cho mấy ngoại lệ này — rename-field sẽ đổi nhầm cả tên query param trùng chữ.

**`-StatusEnum 'ACTIVE,LEFT,RETIRED,INACTIVE'`** khi CHECK constraint của đề không phải 2 giá trị mặc định —
sinh `@Pattern` regex **và** message từ cùng một danh sách (27/07 dính bug regex 3 giá trị mà message
liệt kê 2 vì sửa tay hai chỗ).

**Cột tên trùng từ khóa SQL** (`position`, `level`, `value`, `date`...): IntelliJ generate ra
`@Column(name = "\"position\"")` (quoted identifier). Script đã tự bóc quote; nếu vẫn còn tên field
không hợp lệ nó **dừng và không sinh file nào** thay vì đẻ ra code chứa `\` không compile được
(vụ 27/07: 4 file dính field tên `\`, mất thời gian dò). Thấy lỗi này → mở entity sửa tay
`@Column(name = "position")` rồi chạy lại.

`-EntityName Category` để sinh cho entity phụ trong cùng project. `-DryRun` in nội dung, chưa ghi.
**Thứ tự bắt buộc: chạy Master trước Detail** (bản copy Feign lấy từ DTO Master đã sinh).

## BƯỚC 3 — RÀ TỪNG FILE THEO ĐỀ (phần ăn điểm thật sự)

### 3.1 MasterService (project bị gọi — 8081) — làm TRƯỚC

| File | Script đã đổi hộ | PHẢI RÀ THEO ĐỀ |
|---|---|---|
| `application.properties` | app name | **Đối chiếu bảng Configuration của đề từng dòng**: url (databaseName + `encrypt=false;`), username, password, port. Mục 3 Grading Policies: sai file này = **0 điểm cả bài** |
| `entity/Master.java` | tên class, `@Table` | Mở SCRIPT SQL, dò từng cột: đúng tên `@Column`, đúng kiểu (`date`→`@Temporal(DATE)`, `datetime2`→`TIMESTAMP`), thêm/xóa field cho khớp. **DTO field ≠ tên cột** (`owner` ↔ `owner_name`) thì đặt field theo DTO, map bằng `@Column(name=...)` |
| `dto/MasterDTO.java` | tên class | Chép đúng bảng DTO của đề, rồi gắn validation theo **bảng quy đổi ở đầu file này**. Field FK không có trong bảng DTO nhưng cột NOT NULL → **tự thêm** (bẫy `categoryId`) |
| `dto/ApiResponseDTO.java` | — | 4 field status/message/data/**timestamp** (bật sẵn, ISO 8601 theo R04 — thừa vô hại, thiếu mất điểm). Đối chiếu bảng ApiResponse của đề: đề gọi field là `time`/`responseTime` thì đổi tên; format khác thì sửa dòng `Instant.now()...` — ở **cả 2 service** |
| `dto/PageDTO.java` | — | **Mỗi đề mỗi khác!** Đối chiếu từng field và từng tên field (size/page hay pageSize/pageNo, có totalElements không) |
| `dto/CategoryDTO.java` | tên class | Đề không có entity phụ → xóa. Có → theo bảng của đề, đề không định nghĩa thì tối thiểu `{id, name}` |
| `repository/MasterRepository.java` | **gen-from-entity sinh lại cả file**: `existsBy` theo cột UNIQUE thật, search theo field String thật | `@Query` search đổi theo đúng **query param của đề** nếu khác field đoán (sửa 4 chỗ cùng tên: repo/service/impl/controller) |
| `service/impl/MasterServiceImpl.java` | tên class; **gen-from-entity patch sẵn**: tên filter trong `list()`, cặp `existsBy...`+getter theo field UNIQUE mới, `set<Pk>(null)`, getter FK | Check FK tồn tại, check not-found (400/4), status mặc định lúc create. **BẪY 27/07 khi đổi field UNIQUE tay `name`→`code`: đổi tên method repository mà quên đổi getter — `existsByCodeAnd...(dto.getName(), ...)` compile ngon lành, chạy sai lặng lẽ (status 2 hoặc 500 thay vì 3). Gen đã patch cả cặp cùng lúc; nếu sau đó sửa tay thì grep lại cả cặp.** **BẪY MESSAGE TRÙNG: `throw new DuplicateNameException("Name is duplicated")` là chuỗi CỨNG trong template — gen-from-entity chỉ đổi method + getter theo `-Unique`, KHÔNG đổi message. Đổi field unique sang `code`/`title`/`email` mà quên thì API trả đúng 400/3 nhưng message vẫn "Name is duplicated" → lệch câu chữ đề = mất điểm câu đó. Sửa TAY cả 2 chỗ (create + update) trong ServiceImpl theo câu chữ đề.** Query param dạng **Enum** (`status`) phải validate trong `list()` → 400/2 `"Data validation failed"`, không được thả xuống query trả 200 rỗng. `SIZE_OVER_MAX_IS_ERROR` bật theo BẢNG BƯỚC 0 dòng 19. CHECK chéo 2 cột (end≥start) check **sau** `applyPartialUpdate` |
| `controller/SE193114MasterController.java` | tên class, base path | Đối chiếu TỪNG endpoint: method, path, HTTP code (create 201, còn lại 200), **message copy y nguyên câu chữ đề**, tên query param |
| `common/GlobalExceptionHandler.java` | — | Đối chiếu bảng status của đề: 1/2/3/4/0. Nhớ not-found là HTTP **400** không phải 404. Handler `DataIntegrityViolationException` → 400/2 có sẵn (lưới cuối cho constraint DB lọt qua code) — **đừng xóa** |
| `common/MasterMapper.java` | tên class | Thêm/bớt dòng map + dòng trong `applyPartialUpdate` theo field mới |
| `common/ValidDate.java` | package | **Bảng điều khiển ngày — MỌI rule ngày sửa ở đúng 1 file này** (file không có comment, tra bảng dưới): `SPEC_FORMAT` = format theo sample đề — **viết `uuuu` thay chỗ đề ghi `yyyy`** (`yyyy`+STRICT đòi era → mọi request fail; Trial `"dd/MM/uuuu"`, PE1 `"uuuu-MM-dd"`); `ACCEPT_ISO_FALLBACK=false` = siết format kiểu D01; `MIN_DATE`+`MIN_EXCLUSIVE` = "after mốc" kiểu D02 (`null`=tắt); `NO_FUTURE` = kiểu D03; `FUTURE_ONLY`+`FUTURE_ALLOW_TODAY`; `MAX_DAYS_FROM_TODAY` = "before today+N" (PE1: 360; `0`=tắt). Message sửa đúng câu chữ đề. `@ValidDate` đã gắn sẵn lên mọi field ngày trong DTO |
| `common/DateOnly*.java` | package | Không sửa gì — serializer/deserializer đọc config từ `ValidDate.java`. Serializer đã chống bẫy `java.sql.Date`: Hibernate trả `java.sql.Date` cho cột `date`, mà `java.sql.Date.toInstant()` **luôn ném UnsupportedOperationException** → nếu tự viết serializer khác thì đi qua `getTime()`, đừng gọi `toInstant()` (27/07: POST chạy ngon, mọi GET đọc từ DB nổ 500 lúc ghi JSON response) |
| `common/OnCreate/OnUpdate/NotFoundException/ValidationException/DuplicateNameException` | package | Không sửa gì (trừ khi đề bắt trùng field khác thì đổi tên exception cho dễ đọc) |
| `config/OpenApiConfig.java` | title | Đề không yêu cầu Swagger, nhưng giữ để tự test |

### 3.2 DetailService (project đi gọi Feign — 8082)

| File | Script đã đổi hộ | PHẢI RÀ THEO ĐỀ |
|---|---|---|
| `application.properties` | app name | Như 3.1 nhưng **port 8082**. **Sửa password xong bên Master thì sửa luôn bên này** — 27/07 quên, 8082 chết ngay khi start với `Login failed for user 'sa'` |
| `entity/Detail.java` | class, `@Table`, cột `master_id` | Dò script SQL như 3.1. FK chỉ là `Long`, **KHÔNG** `@ManyToOne`. Bẫy: doc ghi `ingredients`, script ghi `ingredient` → `@Column` theo SCRIPT |
| `dto/DetailDTO.java` | class; **shape theo `-DetailShape`** (field `master` nested + `WRITE_ONLY` đúng chiều) | Bảng DTO của đề + validation theo bảng quy đổi. Shape C: FK id là `WRITE_ONLY`, **required check nằm ở service** (`resolveMasterId` null → 400/2) chứ không phải `@NotNull` |
| `dto/DetailResponseDTO.java` | class; **chỉ tồn tại ở shape B** (C/A script tự xóa) | Bản **nested** cho list (thay `masterId` bằng object `master`). Đề Trial: FoodResponseDTO không có `status` — đừng tự thêm |
| `dto/DetailListDTO.java` | class | Theo đúng bảng list DTO của đề. Đề dùng chung PageDTO → xóa file này, copy `PageDTO` từ MasterService sang |
| `dto/MasterDTO.java` (bản copy) | class | Field khớp JSON mà 8081 trả về. Không cần validation |
| `dto/MasterApiResponse.java` | class | Vỏ bọc ApiResponse bên kia, có `@JsonIgnoreProperties` — thường không sửa |
| `repository/MasterClient.java` | class, path | Port đúng 8081, path đúng số nhiều mới. Gọi **thẳng 8081**, không qua gateway |
| `repository/DetailRepository.java` | **gen-from-entity sinh lại cả file** theo field String thật | `@Query` search theo đúng query param của đề nếu khác field đoán (sửa 4 chỗ cùng tên) |
| `service/impl/DetailServiceImpl.java` | class; list/getter FK/PK theo shape | `resolveMasterId` nhận input phẳng **lẫn** nested; `fetchMasterOrThrow` vừa verify FK qua Feign (NotFound **400/4, message theo đề**) vừa giữ data cho response — POST/GET trả master giống nhau. Message `"masterId is required"` trong create sửa theo câu chữ đề. List gọi Feign "safe" (lỗi → null) |
| `common/DetailMapper.java` | class | Hai hàm `toDTO` (phẳng) và `toResponseDTO` (nested) — sửa field cho khớp |
| `Se193114DetailServiceApplication.java` | class | Liếc lại còn `@EnableFeignClients` |

### 3.3 Gateway (8080)

| File | Script đã đổi hộ | PHẢI RÀ THEO ĐỀ |
|---|---|---|
| `pom.xml` | artifactId | Không sửa thêm |
| `config/SecurityConfig.java` | — | permitAll + CORS allow all hosts (đề mục 2.3 yêu cầu rõ CORS) — có sẵn |
| `application.properties` | app name, routes | Port 8080. Route controller phụ (`routes[4]`, để cuối cùng) đã có sẵn — `$HasCategory=$false` tự gỡ; đề có controller khác nữa thì thêm route mới. Quên route = endpoint đó chết trên 8080. **Swagger tổng hợp có sẵn**: `routes[2]/[3]` kéo api-docs 2 service qua gateway + `springdoc.swagger-ui.urls` → mở `http://localhost:8080/swagger-ui.html`, dropdown chọn service, Try-it-out bắn vào 8080 (đúng đường grader chấm). ĐỪNG đặt `springdoc.api-docs.enabled=false` — nó tắt luôn swagger-config làm UI chết |
| Package `fu.se193114.gateway` | — | **GIỮ NGUYÊN** |

### 3.4 Sửa field lẻ sau khi đã sinh (rename-field / clone-field)

Cách chính để có bộ field đúng là **BƯỚC 2.5** (sinh lại từ entity — đổi gì trong DB thì generate lại
entity rồi chạy lại `gen-from-entity.ps1`, nhanh hơn mọi kiểu sửa tay). Hai script dưới chỉ dùng cho
chỉnh lẻ khi không muốn sinh lại:

**Đổi tên field** — `owner` → `manager`, cột SQL vẫn `owner_name`:
```powershell
powershell -ExecutionPolicy Bypass -File .\rename-field.ps1 -Old owner -New manager -Column owner_name -DryRun
```
Chạy trên cả 3 project, tự né `OpenApiConfig.java`. **Cẩn thận**: nó đổi mù mọi chỗ trùng chữ —
tên trùng với query param trong repo/controller (kiểu `ownerName`) sẽ bị đổi theo; ngoại lệ tên DTO
thì dùng `-Rename` của gen-from-entity thay vì script này.

**Thêm field mới** — nhân bản field cùng kiểu:
```powershell
powershell -ExecutionPolicy Bypass -File .\clone-field.ps1 -From address -To note -DryRun
```
Sau đó sửa tay kiểu/`length`/`nullable`/validation theo bảng quy đổi.

Cả 2 mặc định `-Root e:\…\PE\EXAM`, luôn `-DryRun` trước.

---

## BƯỚC 4 — CHẠY & TỰ CHẤM

Thứ tự chạy: **Master 8081 → Detail 8082 → Gateway 8080**. Test toàn bộ qua **8080** —
đề chấm qua gateway, test ở 8081/8082 là test trượt mục tiêu (không đi qua routing).
Swagger tổng hợp: `http://localhost:8080/swagger-ui.html` → dropdown chọn service → Try-it-out
tự bắn vào 8080. (Swagger riêng từng service ở 8081/8082 vẫn có, chỉ dùng khi debug.)

**Sinh bộ test .http tự động** (sau khi gen-from-entity xong):
```powershell
powershell -ExecutionPolicy Bypass -File .\gen-http.ps1
```
Đọc DTO (field + validation) + entity (unique/FK) + controller (query param) + ValidDate (format ngày),
sinh vào `EXAM\http\` (ngoài 3 project → không dính bài nộp): mỗi service ~20-30 request phủ đúng
checklist dưới — create hợp lệ (tên unique dùng `{{$timestamp}}` nên chạy lại không đụng), trùng unique,
thiếu từng field bắt buộc, vượt từng max-length, ngày rác/ISO, FK ma, get/update/delete + id ma,
soft-delete rồi get lại, list filter/phân trang/size=1000/page âm. Mở bằng IntelliJ → chọn env
**gateway** → chạy từ trên xuống. FK để `= 1` nên cần INSERT tối thiểu 1 row bảng cha/bảng phụ trước.
Request create đầu tiên tự lưu id vào biến (`{{restaurantId}}`) cho các request update/delete sau.

- [ ] Create: **201**, status=1, message đúng từng chữ đề
- [ ] Create trùng field UNIQUE: **400**, status=3 — **đọc kỹ MESSAGE**: mặc định là `"Name is duplicated"` (cứng trong template), field unique không phải `name` thì phải sửa tay 2 chỗ trong ServiceImpl
- [ ] Create thiếu field mandatory: **400**, status=2
- [ ] Create sai format ngày / JSON hỏng: **400**, status=2 (không được 500)
- [ ] Update partial: gửi 1 field, các field khác giữ nguyên giá trị cũ
- [ ] Update chỉ gửi 1 field ngắn: không bị đòi các field mandatory khác
- [ ] Get/Update/Delete id không tồn tại: **400** (không 404), status=4
- [ ] Detail create với FK không tồn tại: 400/4 qua Feign
- [ ] List: phân trang đúng, filter đúng 2 query param của đề, shape đúng bảng DTO
- [ ] List filter Enum (`status=BOGUS`): **400/2** — không phải 200 rỗng
- [ ] List size vượt max: theo BẢNG BƯỚC 0 dòng 19 (clamp→200 tối đa 100 row; strict→400/2); `size=100` luôn 200
- [ ] **GET đọc row có cột ngày từ DB không nổ 500** (bẫy `java.sql.Date` — POST xong phải GET lại ngay)
- [ ] Vi phạm từng CHECK constraint của đề (ngày, end≥start...): **400/2** — không được 500
- [ ] Update trùng UNIQUE: 400/**3** (nếu ra 2 là đang dính bẫy getter sai field)
- [ ] Delete = đổi status INACTIVE, row vẫn còn trong DB
- [ ] Controller phụ hoạt động **qua gateway 8080**
- [ ] Ngày trong response đúng format sample đề

## BƯỚC 5 — NỘP

```powershell
powershell -ExecutionPolicy Bypass -File .\zip-submit.ps1           # 3 zip rieng
powershell -ExecutionPolicy Bypass -File .\zip-submit.ps1 -Bundle   # + 1 zip tong (EOS chi cho 1 file)
```

Script tự: kiểm `application.properties` (password ≠ `sa` hoặc ddl-auto ≠ none là **chặn lại**, vì mục 3
Grading Policies = 0 điểm) → xóa `target/`, `.idea/`, `*.iml` → zip **nguyên folder** từng project
(giải nén ra thấy `SE193114<Tên>Service/pom.xml` đúng tầng — đề mục 4 bắt zip theo folder) → ra `EXAM\submit\`.

Việc còn lại làm tay: **giải nén thử 1 zip ra chỗ khác, mở IntelliJ, Maven reload, chạy được rồi mới nộp.**
Nộp 3 zip riêng hay 1 zip tổng: đọc submit guideline đính kèm đề thật.

## SỔ TAY LỖI THỰC CHIẾN 28/07 (đề SU26 PE1 — Room/Reservation) — ĐỌC TRƯỚC KHI THI

Bài làm thật hôm 28/07 chạy qua bộ 101 test tự chấm chỉ đạt **85%**, và 3 trong 10 endpoint hỏng nặng.
Điều đáng sợ nhất: **cả 3 endpoint hỏng đều không hề báo lỗi lúc chạy** — app lên bình thường,
Swagger đẹp, chỉ khác cái là trả sai thứ. Dưới đây là đúng 5 nguyên nhân.

### 1. Coi field COMPUTED là input bắt buộc → chết cả endpoint

Đề: `totalAmount | BigDecimal | Computed = pricePerNight × number of nights`.
Bài làm để `@NotNull(message = "totalAmount is required", groups = OnCreate.class)`.

Hậu quả dây chuyền: **mọi** request create đúng đặc tả (không gửi `totalAmount`) đều bị `406`.
Endpoint create chết → hai nhánh `404/4` (room không tồn tại) và `400/5` (room không AVAILABLE)
**không bao giờ chạm tới được** → mất luôn cả 3 dòng của bảng.

> **Nhận diện**: cột Description ghi "Computed", "Calculated", "Generated", "System-generated"
> → field đó **KHÔNG** có `@NotNull`, service tự set, và phải **ghi đè** giá trị client gửi lên
> (đừng tin client). Xem `$MasterRules`/`$DetailRules` trong gen-all — phần này script **không sinh được**,
> phải gõ tay vào ServiceImpl.

Bẫy kèm theo: test "gửi `totalAmount` bậy → server phải tính lại" và "đổi ngày → phải tính lại".

### 2. `java.util.Date.getDay()` là THỨ TRONG TUẦN, không phải ngày trong tháng

```java
// SAI - getDay() tra 0..6 (Sun..Sat)
int number = dto.getCheckOutDate().getDay() - dto.getCheckInDate().getDay();
int total  = number * room.getPricePerNight().intValue();   // bien nay khong duoc dung
dto.setTotalAmount(BigDecimal.valueOf(number));             // gan SO DEM, khong phai tien
```
`01/08/2026` (thứ 7 → 6) và `05/08/2026` (thứ 4 → 3) ra `-3`. Số âm vi phạm `CK_Reservations_Amount`
→ DB chặn → `406` thay vì `201`.

```java
// DUNG
long nights = ChronoUnit.DAYS.between(
        DateOnlySerializer.toLocalDate(checkInDate),
        DateOnlySerializer.toLocalDate(checkOutDate));
entity.setTotalAmount(room.getPricePerNight().multiply(BigDecimal.valueOf(nights)));
```
`toLocalDate` trong `DateOnlySerializer` đã xử lý sẵn bẫy `java.sql.Date` — **nhớ đổi nó thành `public`**
khi gọi từ package `service.impl`.

### 3. Giữ `DetailListDTO` của template khi đề nói dùng chung PageDTO

Đề ghi đúng một dòng: *"PageDTO: See the definition in Room Service section."*
Bài làm giữ nguyên `ReservationListDTO` (`pageSize`/`pageNo`/`reservations`, **thiếu hẳn `totalElements`**).

JSON trả về sai 3 tên field + thiếu 1 field, dù dữ liệu hoàn toàn đúng. Sửa: copy `PageDTO.java` từ
project Master sang, **xoá** file ListDTO, đổi kiểu trả về ở interface + impl + controller.

### 4. Bốn endpoint, hai loại DTO — trả nhầm loại

| Endpoint | DTO đúng |
|---|---|
| POST create | `ReservationDTO` — **phẳng**, có `roomId` |
| PUT update | `ReservationDTO` — **phẳng** |
| GET /{id} | `ReservationDetailDTO` — **nested**, có `room`, KHÔNG có `roomId` |
| GET list | `ReservationDetailDTO` trong `content` |

Bài làm để `getById()` trả `ReservationDTO`. Tệ hơn: mapper có sẵn overload
`toDTO(Reservation entity, RoomDTO room)` **nhận tham số `room` rồi vứt đi không dùng** — gọi Feign
tốn công mà dữ liệu bị bỏ. Và `toResponseDTO()` **quên `dto.setStatus(...)`** → mọi row trong list
có `"status": null`.

> **Phản xạ**: sau khi sửa mapper, đếm số `dto.setXxx(...)` và so với số field của DTO đích.
> Thiếu một dòng là mất một field, không có lỗi compile nào báo cho bạn.

### 5. `@Min` / `@Max` / `@DecimalMin` quên `groups` → KHÔNG BAO GIỜ CHẠY

```java
@NotNull(message = "capacity is required", groups = OnCreate.class)
@Min(1)     // <- thuoc group Default -> @Validated(OnCreate.class) BO QUA
@Max(10)    // <- y het
private Integer capacity;
```
Đây là lỗi im lặng nhất trong cả template: annotation nằm đó, đọc code thấy đủ, nhưng không chạy.
Nó chỉ *tình cờ* không mất điểm vì CHECK constraint dưới DB chặn lại rồi
`DataIntegrityViolationException` → cùng mã. Đừng dựa vào may mắn đó: đề nào có rule chỉ nằm trong
**doc** mà không có CHECK trong SQL (ví dụ `numberOfGuests` "Must be >= 1 and <= 10" trong khi SQL chỉ
`>= 1`) thì giá trị `99` **lọt thẳng vào DB**.

> **Phản xạ soát**: `grep -n "@Min\|@Max\|@DecimalMin\|@Digits\|@Pattern\|@Size\|@Email" dto/*.java`
> — dòng nào không có chữ `groups` là dòng chết. gen-from-entity sinh đúng, chỉ khi **sửa tay** mới sót.

### 6. `@NotBlank` chỉ ở `OnCreate` → PUT ghi đè được chuỗi rỗng

`PUT {"roomNumber": ""}` đi qua sạch (`@Size(max=20)` chấp nhận rỗng, DB chỉ cấm NULL chứ không cấm `""`)
→ ghi đè `room_number` thành rỗng, trả `200/1`. Không thể vá bằng `@NotBlank(groups = OnUpdate.class)`
vì `@NotBlank` **từ chối null**, mà null chính là "field không gửi" của partial update.

```java
@NotBlank(message = "roomNumber is required", groups = OnCreate.class)
@Size(max = 20, groups = {OnCreate.class, OnUpdate.class})
@Pattern(regexp = ".*\\S.*", message = "roomNumber must not be blank", groups = OnUpdate.class)
```
`@Pattern` **bỏ qua null** nhưng chặn rỗng/toàn khoảng trắng — đúng thứ cần cho PUT.

### 7. Query param khai kiểu `Enum` mà chỉ validate một cái

Đề SU26 PE1 có **hai** param Enum ở `GET /api/rooms`: `roomType` và `status`. Bài làm chỉ validate
`status` → `?roomType=BOGUS` trả `200` rỗng thay vì `406/2`. Đếm lại bảng Query Parameters,
mỗi dòng ghi `Enum` phải có đúng một danh sách `ALLOWED_*` tương ứng trong `list()`.

---

## SỔ TAY LỖI THỰC CHIẾN 27/07 (đề Department/Employee) — ĐỌC TRƯỚC KHI THI

Mỗi lỗi dưới đây đã ăn thời gian thật trong buổi làm thử 27/07/2026. Template + script đã vá hết,
nhưng cần hiểu **vì sao** để lúc thi nhìn triệu chứng là biết bệnh.

### Nhóm "500 thay vì 400" — lỗi nghiệp vụ bị biến thành lỗi hệ thống

| Triệu chứng | Bệnh | Đã vá ở |
|---|---|---|
| POST date hợp lệ format nhưng 500/0 | CHECK `effective_date >= getdate()` chỉ có ở DB, `ValidDate` tắt hết rule (`MIN_DATE=null`, `FUTURE_ONLY=false`) → lọt xuống `save()` → SQL error 547 → rơi vào `handleAll` | Bật đúng hằng số `ValidDate` theo CHECK của đề (BẢNG BƯỚC 0 dòng 17); lưới cuối `DataIntegrityViolationException` → 400/2 |
| GET/List nổ 500 `HttpMessageNotWritableException`, log chỉ có dòng controller rồi im | `java.sql.Date.toInstant()` ném `UnsupportedOperationException` — Hibernate trả `java.sql.Date` cho cột `date`, lỗi nổ **sau khi controller return**, lúc Jackson ghi body. POST không dính vì date lúc đó là `java.util.Date` thật từ deserializer | `DateOnlySerializer.toLocalDate()` đi qua `getTime()`/`sqlDate.toLocalDate()`; `ValidDate.Validator` dùng chung helper |
| PUT trùng UNIQUE ra 400/**2** (hoặc 500 khi chưa có lưới) thay vì 400/3 | Đổi `name`→`code` sửa method repository mà quên getter: `existsByCodeAnd...(dto.getName(),...)` → body chỉ gửi `code` thì `getName()==null` → **skip luôn check trùng** → DB chặn bằng UNIQUE index | Grep cả cặp method+getter sau khi đổi field UNIQUE; test "update trùng UNIQUE" trong checklist |

### Nhóm "lệch câu chữ / lệch hành vi với đề"

- **DTO Detail chỉ có object nested (shape C) mà làm ngây thơ thì input phẳng và input nested
  luôn chết một trong hai**: bỏ `departmentId` chỉ giữ `department` → client gửi `"departmentId": 2`
  bị Jackson bỏ rơi → "departmentId is required" oan; giữ `departmentId` → response lòi field thừa
  so với bảng đề. Vá bằng cặp field + `@JsonProperty(access = WRITE_ONLY)` cho chiều vào +
  `resolveMasterId()` ở service — `-DetailShape C` sinh sẵn toàn bộ (đề 27/07: test 01 phẳng và
  test 02 nested đều phải 201).
- **POST trả `"department": null` trong khi GET có data**: create() gọi Feign chỉ để verify rồi
  vứt kết quả. Đã vá: `fetchMasterOrThrow` trả về MasterDTO, create nhét thẳng vào response —
  hai endpoint khớp nhau, không tốn thêm lượt gọi.

- **Query param Enum trả 200 rỗng thay vì 400**: `status` khai `Enum` trong bảng Query Parameters của đề
  → service phải validate (`ALLOWED_STATUS`), message `"Data validation failed"` theo bảng Response Behavior.
  Đừng suy từ code cũ — param `String` trần không tự validate gì cả.
- **`size` max 100**: đề ghi `max: 100` trong bảng Query Parameters + người chấm coi 101 là lỗi → strict 400.
  Trial ghi Y HỆT ("max: 100" + row 400/2 ngay trong Response Behavior của list) → cùng cách đọc, KHÔNG phải clamp
  như từng ghi nhầm ở đây. Template giờ mặc định `SIZE_OVER_MAX_IS_ERROR=true` và gen-all có `$SizeOverMax`
  ("error"/"clamp") — chỉ đổi sang clamp khi đề MÔ TẢ RÕ hành vi ép về max. gen-http tự sinh expect khớp theo cờ.
- **Message trùng unique vẫn nói "Name" trong khi field unique là `code`**: `DuplicateNameException("Name is duplicated")`
  nằm cứng trong `MasterServiceImpl` (cả `create` lẫn `update`), `-Unique code` chỉ patch `existsByCode...` + getter
  chứ không đụng vào chuỗi. Status code đúng (3) nên test dễ pass mắt thường — chỉ lệch câu chữ. Grep
  `is duplicated` sau khi đổi field unique, sửa cả 2 chỗ theo message của đề.
- **`@Pattern` regex 3 giá trị, message liệt kê 2**: sửa tay hai chỗ thì lệch. Dùng `-StatusEnum` của
  gen-from-entity để cả hai sinh từ một danh sách.
- **Message nhiều nhánh 400 trong cùng endpoint phải thống nhất** theo bảng Response Behavior
  (page/size/status đều `"Data validation failed"`).

### Nhóm "app không chạy nổi"

- **Field tên `\` trong 4 file sinh ra, compile fail hàng chục lỗi `illegal character`**: cột `position`
  trùng từ khóa SQL → IntelliJ sinh `@Column(name = "\"position\"")` → regex cũ của gen-from-entity bắt
  ra `\`. Script giờ tự bóc quote + **từ chối sinh** khi tên field không hợp lệ.
- **`Login failed for user 'sa'` lúc start 8082**: đổi password ở Master mà quên Detail.
  `application.properties` là 2 file — sửa cặp.
- **JPQL trỏ field đã xóa** (`d.ingredients` khi entity đã thành Employee): app chết ngay lúc boot vì
  Hibernate validate query lúc tạo repository. **Đã vá**: gen-from-entity giờ sinh lại repository từ
  field thật của entity + patch service/controller cho khớp. Chỉ còn phải đổi tên filter khi query param
  của ĐỀ khác field đoán — sửa 4 chỗ cùng tên, xong **chạy lại app ngay** để Hibernate bắt lỗi sớm.

### Phản xạ đọc log 500

1. Mở stack trace, tìm dòng `Caused by` **cuối cùng** — đó mới là bệnh, các dòng trên là vỏ bọc
   (`HttpMessageNotWritable` ← `JsonMappingException` ← `UnsupportedOperationException`).
2. `SqlExceptionHelper`/`error 547`/`unique index` trong log → thiếu check ở code, xem bảng quy đổi.
3. Log dừng ở dòng controller, không có dòng service → lỗi nổ lúc serialize response, nghi ngay date/mapper.

## PHÂN BỔ 85 PHÚT

| Phút | Việc |
|---|---|
| 0–5 | Đọc đề, điền BẢNG BƯỚC 0 |
| 5–10 | Chạy rename-template + script SQL của đề + mở 3 project, chạy thử cả 3 |
| 10–35 | Master: IntelliJ gen entity → gen-from-entity → repo/controller/message → **TEST Master + Gateway qua 8080** |
| 35–60 | Detail: IntelliJ gen entity → gen-from-entity → Feign → nested vs phẳng → message |
| 60–70 | Entity phụ (nếu có) + route gateway + CORS |
| 70–80 | Tự chấm checklist Bước 4 qua port 8080 |
| 80–85 | Kiểm properties, xóa target, zip, nộp |
