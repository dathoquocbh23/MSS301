# VALIDATION CHEATSHEET — REGEX + CÁC CASE PHỔ BIẾN

> Mọi validation đặt ở **DTO** (nguyên tắc số 1 của `DOI-TEN-TUNG-BUOC.md`).
> File này để đọc hiểu + copy sửa nhanh lúc thi. Message luôn **copy y nguyên câu chữ đề**.

---

## 1. BỘ ANNOTATION CƠ BẢN — KHI NÀO DÙNG CÁI NÀO

| Annotation | Dùng cho | Null thì sao? | Ghi chú |
|---|---|---|---|
| `@NotNull` | số, ngày, FK id | **chặn** null | không quan tâm rỗng |
| `@NotBlank` | chuỗi bắt buộc | **chặn** null, `""`, `"   "` | mạnh nhất cho String |
| `@NotEmpty` | chuỗi/list | chặn null, `""` nhưng **cho** `"   "` | hiếm khi cần, ưu tiên @NotBlank |
| `@Size(min=, max=)` | độ dài chuỗi / list | **bỏ qua** null | map từ `varchar(n)` → `max = n` |
| `@Pattern(regexp=)` | chuỗi theo format | **bỏ qua** null | regex phải match **TOÀN BỘ** chuỗi (tự anchor `^...$`) |
| `@Min` / `@Max` | số nguyên biên | **bỏ qua** null | "from 1 to 5" → `@Min(1) @Max(5)` |
| `@DecimalMin` / `@DecimalMax` | BigDecimal/Double | bỏ qua null | `@DecimalMin(value="0.0", inclusive=false)` = phải > 0 |
| `@Positive` / `@PositiveOrZero` | số > 0 / >= 0 | bỏ qua null | gọn hơn @Min(1)/@Min(0) với nghĩa "dương" |
| `@Email` | email | bỏ qua null | lỏng — đề ghi format cụ thể thì dùng @Pattern |
| `@Digits(integer=, fraction=)` | cột `decimal(m,n)` | bỏ qua null | `decimal(10,2)` → `@Digits(integer=8, fraction=2)` (integer = m−n) |
| `@AssertTrue` | getter boolean tự viết | bỏ qua null | check chéo 2 field ở DTO — nhưng xem cảnh báo mục 7 |
| `@Past` / `@PastOrPresent` | ngày quá khứ | bỏ qua null | template dùng `ValidDate` thay thế — xem mục 6 |
| `@Future` / `@FutureOrPresent` | ngày tương lai | bỏ qua null | như trên |

**Điểm mấu chốt:** trừ `@NotNull`/`@NotBlank`, mọi annotation khác **coi null là hợp lệ**.
Đây chính là lý do partial update (PUT) chạy được: field vắng mặt = null = qua hết
`@Size`/`@Pattern`, chỉ cần `@NotBlank`/`@NotNull` gắn `groups = OnCreate.class` là PUT thoát.

```java
// Mẫu chuẩn cho 1 field chuỗi NOT NULL varchar(100):
@NotBlank(message = "name is required", groups = OnCreate.class)
@Size(max = 100, message = "name must not exceed 100 characters",
      groups = {OnCreate.class, OnUpdate.class})
private String name;
```

---

## 2. REGEX — HIỂU 90% CHỈ VỚI BẢNG NÀY

| Ký hiệu | Nghĩa | Ví dụ |
|---|---|---|
| `[abc]` | 1 ký tự trong tập | `[AI]` khớp `A` hoặc `I` |
| `[a-z]` `[A-Z]` `[0-9]` | khoảng ký tự | `[A-Za-z0-9]` = chữ + số |
| `[^0-9]` | 1 ký tự KHÔNG thuộc tập | khác số |
| `\d` `\D` | số / không phải số | trong Java string viết `\\d` |
| `\s` `\S` | khoảng trắng / không | `\\s` |
| `\w` | chữ, số, `_` | `\\w` |
| `.` | ký tự bất kỳ | |
| `*` | 0 lần trở lên | `[a-z]*` cho phép rỗng |
| `+` | 1 lần trở lên | `[a-z]+` ít nhất 1 |
| `?` | 0 hoặc 1 lần | `(\\.\\d+)?` phần thập phân tùy chọn |
| `{n}` `{n,m}` `{n,}` | đúng n / từ n tới m / từ n | `\\d{10}` đúng 10 số |
| `A\|B` | hoặc | `ACTIVE\|INACTIVE` |
| `( )` | nhóm | `(ACTIVE\|INACTIVE)` khi ghép với phần khác |
| `\\.` | dấu chấm literal | `.` trần = ký tự bất kỳ, muốn dấu chấm thật phải escape |
| `(?=...)` | lookahead — "phía trước PHẢI có" | `(?=.*\\d)` = đâu đó trong chuỗi có số; dùng cho password "ít nhất 1..." |
| `(?i)` | bật case-insensitive từ chỗ đó | `(?i)(active\|inactive)` |

**2 điều hay quên với `@Pattern` trong Java:**
1. Regex tự match **toàn bộ chuỗi** — không cần viết `^` `$` (viết thêm cũng không sai).
2. Trong Java string, backslash phải **nhân đôi**: regex `\d` → viết `"\\d"`.

---

## 3. KHO PATTERN COPY-SỬA

### 3.1 Enum / tập giá trị cố định (case gặp NHIỀU NHẤT)

```java
// CHECK (status IN ('ACTIVE','INACTIVE'))
@Pattern(regexp = "ACTIVE|INACTIVE",
         message = "status must be ACTIVE or INACTIVE",
         groups = {OnCreate.class, OnUpdate.class})
private String status;

// 3+ giá trị (đề 27/07 kiểu Employee) — regex và message PHẢI cùng danh sách:
@Pattern(regexp = "ACTIVE|LEFT|RETIRED|INACTIVE",
         message = "status must be one of ACTIVE, LEFT, RETIRED, INACTIVE")

// Enum ngoài status (position):
@Pattern(regexp = "Manager|Developer|Staff",
         message = "position must be Manager, Developer or Staff")
// LƯU Ý: phân biệt hoa thường! Đề ghi 'Manager' mà client gửi 'manager' là 400 — đúng ý đề.
// Nếu đề nói không phân biệt: regexp = "(?i)(manager|developer|staff)"
```

### 3.2 Code / mã chỉ gồm chữ + số

```java
// "code only contains characters (A-Z, a-z) and digits (0-9)"
@Pattern(regexp = "[A-Za-z0-9]+",
         message = "code only contains character (A-Z, a-z) and digits (0-9)")
private String code;

// Biến thể hay gặp:
// - Bắt đầu bằng chữ, sau đó chữ/số:        "[A-Za-z][A-Za-z0-9]*"
// - Chữ hoa + số, đúng 6 ký tự:              "[A-Z0-9]{6}"
// - Prefix cố định + 3 số (VD: EMP001):      "EMP\\d{3}"
// - Chữ, số, gạch ngang, gạch dưới:          "[A-Za-z0-9_-]+"
```

### 3.3 Số điện thoại

```java
// varchar(11) + đề chỉ nói "phone number" → thường chỉ cần @Size(max = 11)
// Đề nói RÕ "only digits":
@Pattern(regexp = "\\d+", message = "phone must contain only digits")

// 10-11 số:                       "\\d{10,11}"
// Bắt đầu bằng 0, 10 số:          "0\\d{9}"
// Cho phép +84 hoặc 0:            "(\\+84|0)\\d{9}"
```

### 3.4 Tên người / chữ và khoảng trắng

```java
// "name contains only letters and spaces"
@Pattern(regexp = "[A-Za-z ]+", message = "name must contain only letters and spaces")

// Có tiếng Việt (dùng Unicode letter class):
@Pattern(regexp = "[\\p{L} ]+", message = "name must contain only letters and spaces")
// \p{L} = mọi chữ cái Unicode (kể cả ă, ơ, đ...). An toàn hơn [A-Za-z] khi data mẫu có dấu.
```

### 3.5 Email

```java
// Đề chỉ ghi "valid email" → dùng luôn:
@Email(message = "email is invalid")

// Đề mô tả format cụ thể (VD: phải đuôi @fpt.edu.vn):
@Pattern(regexp = "[A-Za-z0-9._%+-]+@fpt\\.edu\\.vn", message = "email must be @fpt.edu.vn")

// Email tự viết mức vừa đủ (khi không tin @Email):
@Pattern(regexp = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
```

### 3.6 Số dạng chuỗi / tiền tệ

```java
// Số nguyên dương dạng chuỗi:    "\\d+"
// Số thập phân (2 chữ số lẻ):    "\\d+(\\.\\d{1,2})?"

// Cột decimal(m,n) mà DTO để BigDecimal → KHÔNG dùng @Pattern, dùng @Digits:
@Digits(integer = 8, fraction = 2,
        message = "price must have at most 8 integer digits and 2 fraction digits")
private BigDecimal price;   // decimal(10,2): integer = 10 - 2 = 8
// Thiếu check này thì giá trị quá dài lọt xuống DB → SQL truncation error → 500/0.
```

### 3.7 Password / chuỗi "ít nhất 1 loại ký tự" (lookahead)

```java
// "at least 1 uppercase, 1 lowercase, 1 digit, min 8 chars"
@Pattern(regexp = "(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}",
         message = "password must contain at least 1 uppercase, 1 lowercase, 1 digit and be at least 8 characters")
// Đọc: mỗi (?=...) là một điều kiện "nhìn trước" độc lập, KHÔNG tiêu thụ ký tự.
// (?=.*[a-z]) = đâu đó có chữ thường; .{8,} = tổng thể dài >= 8.
// Thêm ký tự đặc biệt bắt buộc:   (?=.*[@#$%^&+=!])
// Cấm khoảng trắng:               (?=\\S+$)  hoặc thêm class [^\\s] thay cho .
```

### 3.8 Giờ / thời gian dạng chuỗi (checkIn "14:30")

```java
// HH:mm 24h:
@Pattern(regexp = "([01]\\d|2[0-3]):[0-5]\\d", message = "time must be in HH:mm format")
// HH:mm:ss:  "([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d"
// Chỉ dùng khi cột là varchar; cột time/datetime thật thì đi đường ValidDate/Jackson.
```

### 3.9 Chặn khoảng trắng thừa (đề khó tính "must not start/end with space")

```java
// Không bắt đầu/kết thúc bằng space, giữa các từ đúng 1 space:
@Pattern(regexp = "\\S+( \\S+)*", message = "name must not have leading, trailing or double spaces")
// Chỉ cần cấm đầu/cuối:  "\\S(.*\\S)?"
```

### 3.10 URL / năm / các mảnh lặt vặt

```java
// URL http/https (đề kiểu "website"):
@Pattern(regexp = "https?://[\\w.-]+(/.*)?", message = "website must be a valid URL")
// Năm 4 số:            "\\d{4}"
// Mã đúng N ký tự:     "[A-Z0-9]{6}"        // độ dài cứng nằm luôn trong regex
// Username 6-12 ký tự: "[a-zA-Z0-9]{6,12}"  // khỏi cần @Size riêng
```

---

## 4. SỐ — BIÊN GIÁ TRỊ

```java
// "star rating from 1 to 5"
@Min(value = 1, message = "star rating must be from 1 to 5")
@Max(value = 5, message = "star rating must be from 1 to 5")
private Integer starRating;

// "price must be greater than 0" — Integer/Long:
@Min(value = 1, message = "price must be greater than 0")
// hoặc rõ nghĩa hơn:
@Positive(message = "price must be greater than 0")

// BigDecimal/Double > 0 (Min/Max không dùng cho số thực được chuẩn):
@DecimalMin(value = "0.0", inclusive = false, message = "price must be greater than 0")

// ">= 0":
@PositiveOrZero(message = "quantity must be >= 0")

// "salary between 1000 and 100000":
@DecimalMin(value = "1000")  @DecimalMax(value = "100000")
```

**Chú ý kiểu dữ liệu:** client gửi `"abc"` cho field `Integer` → Jackson fail parse →
rơi vào handler `HttpMessageNotReadableException` → 400/2. KHÔNG cần @Pattern chặn chữ
cho field số — kiểu dữ liệu tự chặn rồi.

---

## 5. TỔ HỢP HAY GẶP — DTO MẪU ĐẦY ĐỦ

```java
public class HotelDTO {

    private Long hotelId;                       // PK: không validation

    @NotBlank(message = "hotel name is required", groups = OnCreate.class)
    @Size(max = 100, message = "hotel name must not exceed 100 characters",
          groups = {OnCreate.class, OnUpdate.class})
    private String name;

    @NotBlank(message = "code is required", groups = OnCreate.class)
    @Size(max = 20, groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = "[A-Za-z0-9]+",
             message = "code only contains character (A-Z, a-z) and digits (0-9)",
             groups = {OnCreate.class, OnUpdate.class})
    private String code;                        // UNIQUE → check trùng ở SERVICE (400/3), không phải ở đây

    @Size(max = 11, groups = {OnCreate.class, OnUpdate.class})
    private String phone;                       // cột cho NULL → không @NotBlank

    @NotNull(message = "star rating is required", groups = OnCreate.class)
    @Min(value = 1, message = "star rating must be from 1 to 5",
         groups = {OnCreate.class, OnUpdate.class})
    @Max(value = 5, message = "star rating must be from 1 to 5",
         groups = {OnCreate.class, OnUpdate.class})
    private Integer starRating;

    @Pattern(regexp = "ACTIVE|INACTIVE",
             message = "status must be ACTIVE or INACTIVE",
             groups = {OnCreate.class, OnUpdate.class})
    private String status;                      // create thì service tự ép ACTIVE

    @ValidDate                                  // mọi rule ngày nằm trong ValidDate.java
    private Date openedDate;

    @NotNull(message = "categoryId is required", groups = OnCreate.class)
    private Long categoryId;                    // FK: tồn tại hay không → check ở SERVICE
}
```

Một field có thể **xếp chồng nhiều annotation** — chạy hết, gom mọi lỗi trả về 1 lần.
Thứ tự khai báo không quan trọng.

---

## 6. NGÀY — ĐỪNG TỰ VIẾT, DÙNG BẢNG ĐIỀU KHIỂN `ValidDate.java`

Template đã gắn `@ValidDate` sẵn lên mọi field ngày. Chỉ chỉnh hằng số:

| Đề nói | Chỉnh gì |
|---|---|
| format `dd/MM/yyyy` | `SPEC_FORMAT = "dd/MM/uuuu"` — **luôn viết `uuuu` thay `yyyy`** (STRICT + yyyy đòi era → fail mọi request) |
| "after 2000/01/01" | `MIN_DATE = "2000-01-01"`, `MIN_EXCLUSIVE = true` |
| "not in the future" | `NO_FUTURE = true` |
| `col >= getdate()` trong CHECK | `FUTURE_ONLY = true` |
| "before current date + 360" | `MAX_DAYS_FROM_TODAY = 360` |
| rule riêng 1 field khác field còn lại | rule `@{ f='...'; dateMin=...; }` trong gen-all — đè config global cho field đó |

Vì sao không dùng `@Past`/`@Future` trần: chúng chỉ check sau khi parse THÀNH CÔNG,
còn bẫy thật nằm ở **format parse** (400/2 chứ không phải 500) — `ValidDate` gom cả hai.

---

## 7. NHỮNG THỨ ANNOTATION *KHÔNG* LÀM ĐƯỢC → CHECK Ở SERVICE

| Rule | Vì sao annotation chịu | Làm ở đâu | Status |
|---|---|---|---|
| UNIQUE (`name`/`code` trùng) | phải query DB | `existsBy...` trong service, update thì `existsBy...And<Pk>Not` | 400/**3** |
| FK tồn tại | phải query DB / Feign | `requireXxxExists()` / `fetchMasterOrThrow()` | 400/2 nội bộ, 400/**4** qua Feign |
| CHECK chéo 2 cột (`endDate >= startDate`) | annotation là field-level | service, **SAU `applyPartialUpdate`** (để PUT gửi 1 field vẫn so với giá trị cũ) | 400/2 |
| Query param enum (`?status=BOGUS`) | param `String` trần không validate | `ALLOWED_STATUS` check trong `list()` | 400/2 |
| `size` vượt max 100 | tương tự | `SIZE_OVER_MAX_IS_ERROR` trong service | 400/2 |
| Ép `status = ACTIVE` lúc create | không phải validate mà là gán | service set đè trước khi save | — |

```java
// Mẫu check chéo 2 cột trong update() — đặt SAU applyPartialUpdate:
mapper.applyPartialUpdate(entity, dto);
if (entity.getEndDate() != null && entity.getStartDate() != null
        && entity.getEndDate().before(entity.getStartDate())) {
    throw new ValidationException("end date must be after or equal to start date");
}
```

**Vì sao KHÔNG dùng `@AssertTrue` cho check chéo dù nó làm được ở DTO:**

```java
// Trên mạng hay chỉ cách này:
@AssertTrue(message = "end date must be after start date")
public boolean isDateRangeValid() {
    return endDate == null || startDate == null || !endDate.before(startDate);
}
```

Trông gọn nhưng **chết với PUT partial**: client chỉ gửi `endDate` thì `startDate` trong DTO
là null → getter trả `true` → lọt qua, trong khi giá trị cũ trong DB có thể vi phạm.
Check ở service SAU `applyPartialUpdate` mới nhìn thấy dữ liệu đã trộn (mới + cũ). Đây là
lý do template chọn service — không phải vì không biết `@AssertTrue`. (POST-only thì
`@AssertTrue` dùng được, nhưng thống nhất một chỗ đỡ nhớ hai luật.)

**Validator của Hibernate (`@Length`, `@Range`, `@URL`, `@CreditCardNumber`) — ĐỪNG dùng:**
`@Length` = `@Size`, `@Range` = `@Min`+`@Max`, `@URL` thay được bằng `@Pattern`.
Chúng nằm ở package `org.hibernate.validator.constraints` — bài chấm theo chuẩn jakarta,
dùng đồ chuẩn (`jakarta.validation.constraints.*`) cho an toàn import + đỡ lệ thuộc version.

---

## 8. BẪY KIỂM TRA NHANH TRƯỚC KHI NỘP

1. **`@Pattern`/`@Size` mà thiếu `@NotBlank`** → gửi thiếu field vẫn 201 dù đề nói mandatory.
   Soát: cột NOT NULL nào cũng phải có `@NotBlank`/`@NotNull` + `groups = OnCreate.class`.
2. **Quên `groups`** → annotation không thuộc group nào chỉ chạy với group Default —
   controller đang `@Validated(OnCreate.class)` thì nó **bị bỏ qua im lặng**. Mọi annotation
   trong DTO đều phải khai `groups`.
3. **Regex và message lệch nhau** (regex 3 giá trị, message kể 2) → sinh cả hai từ một nguồn
   (`-StatusEnum`), hoặc sửa thì sửa cặp.
4. **Message không đúng câu chữ đề** → mất điểm dù logic đúng. Kể cả `"Name is duplicated"`
   cứng trong ServiceImpl khi field unique là `code` — grep `is duplicated` sau khi đổi.
5. **Escape thiếu trong Java string**: `\d` phải viết `"\\d"`, dấu chấm literal là `"\\."`.
6. **`@Pattern` với field cho phép rỗng**: null qua được nhưng `""` thì KHÔNG match `[A-Za-z0-9]+`.
   Nếu đề cho phép chuỗi rỗng (hiếm) thì đổi `+` thành `*`.
7. Đề mô tả rule trong **DOC** mà script SQL không có CHECK (starRating 1-5 chỉ ghi trong bảng
   mô tả) → vẫn PHẢI validate — nguồn là "constraints defined for columns and tables", doc là
   một phần của định nghĩa đó.
8. **Cột `decimal(m,n)` không có `@Digits`** → số quá dài lọt xuống DB → truncation → 500/0.
   Soát script SQL: thấy `decimal`/`numeric` là thêm `@Digits(integer = m-n, fraction = n)`.
9. **Lookahead `(?=...)` đặt SAU phần match chính thì vô dụng** — mọi `(?=...)` phải đứng
   ĐẦU regex, phần "hình dạng tổng thể" (`.{8,}`) đứng cuối.
