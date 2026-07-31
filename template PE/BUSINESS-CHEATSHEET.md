# BUSINESS CHEATSHEET — RULE NÀO KHÔNG ĐẶT ĐƯỢC Ở DTO

> Anh em với `VALIDATION-CHEATSHEET.md`. File kia lo phần **annotation đặt ở DTO**.
> File này lo phần **còn lại**: những rule mà annotation làm không được, phải gõ tay trong Service —
> và đó cũng chính là chỗ mất điểm nhiều nhất, vì `gen-from-entity.ps1` **không sinh được**.

---

## 0. LUẬT PHÂN CÔNG — RULE NÀY ĐẶT Ở ĐÂU?

Hỏi đúng 3 câu, theo thứ tự:

| Câu hỏi | Nếu ĐÚNG → đặt ở |
|---|---|
| Chỉ nhìn **một field**, không cần biết gì khác? | **DTO** (annotation) |
| Cần nhìn **field khác của cùng row**, hoặc **row khác trong DB**? | **Service** |
| Cần **gọi service kia** (Feign) mới biết? | **Service**, sau khi Feign trả về |

Hệ quả thực dụng: bất cứ chỗ nào cột Description của đề nhắc tới **một thứ khác** (`another`, `the room`,
`the book`, `checkInDate`, `current`, `Computed`) → rule đó **không** phải annotation.

**Mã trả về** (đối chiếu bảng Response Behavior của đề, chứ đừng mặc định 400):

| Loại | Exception ném ra | status |
|---|---|---|
| Sai dữ liệu (kể cả cross-field, cross-service) | `ValidationException` | 2 |
| Trùng field UNIQUE | `DuplicateNameException` | 3 |
| Không tìm thấy (kể cả FK bên service kia) | `NotFoundException` | 4 |
| Nhánh nghiệp vụ riêng của đề | `BusinessRuleException` | 5+ |

---

## 1. FIELD COMPUTED — SERVER TỰ TÍNH

**Nhận diện trong đề:** cột Description ghi `Computed = ...`, `Calculated`, `Auto generated`,
`System-generated`, `Derived from`, hoặc một công thức.

### Ba việc phải làm, thiếu một là hỏng

```java
// (1) DTO: BO @NotNull. Field nay la OUTPUT, khong phai input bat buoc.
//     De @NotNull -> moi request dung dac ta deu 406 -> CHET CA ENDPOINT.
@DecimalMin(value = "0.0", groups = {OnCreate.class, OnUpdate.class})
@Digits(integer = 16, fraction = 2, groups = {OnCreate.class, OnUpdate.class})
private BigDecimal totalAmount;

// (2) MAPPER: XOA nhanh set no trong applyPartialUpdate,
//     khong thi client tu dat gia tri duoc.
//     if (dto.getTotalAmount() != null) { entity.setTotalAmount(...); }   <-- XOA DONG NAY

// (3) SERVICE: tinh va GHI DE, khong tin gia tri client gui.
entity.setTotalAmount(computeTotalAmount(room, dto.getCheckInDate(), dto.getCheckOutDate()));
```

### Công thức: luôn giữ BigDecimal

```java
private BigDecimal computeTotalAmount(RoomDTO room, Date from, Date to) {
    if (room == null || room.getPricePerNight() == null || from == null || to == null) {
        return BigDecimal.ZERO;
    }
    long nights = nightsBetween(from, to);
    if (nights <= 0) {
        return BigDecimal.ZERO;
    }
    return room.getPricePerNight().multiply(BigDecimal.valueOf(nights));
}
```

**Đừng** `.intValue()` — cột `DECIMAL(18,2)` mà ép về `int` là mất phần thập phân và tràn số với tiền lớn.

### Biến thể hay gặp

| Đề nói | Công thức |
|---|---|
| `price × number of nights` | `price.multiply(valueOf(DAYS.between(in, out)))` |
| `price × quantity` | `price.multiply(valueOf(quantity))` |
| `price × quantity × (1 - discount/100)` | tính discount cuối, `setScale(2, RoundingMode.HALF_UP)` |
| `fee × overdue days` (0 nếu chưa quá hạn) | `long od = DAYS.between(due, actual); if (od <= 0) return ZERO;` |
| `sum của các dòng con` | query bên repository, đừng load hết rồi cộng trong Java |

Có chia hoặc phần trăm thì **bắt buộc** `setScale(2, RoundingMode.HALF_UP)` — không thì
`BigDecimal.divide` ném `ArithmeticException` với số vô hạn tuần hoàn → 500.

---

## 2. RÀNG BUỘC CHÉO 2 FIELD (thường là NGÀY)

**Nhận diện:** `Must be after X`, `must be greater than`, `end must be >= start`, và trong SQL là
`CHECK ([a] > [b])` — CHECK nhắc **2 cột** thì annotation field-level bó tay.

```java
private void requireCheckOutAfterCheckIn(Date checkInDate, Date checkOutDate) {
    if (checkInDate == null || checkOutDate == null) {
        return;                       // de @NotNull lo phan thieu field
    }
    if (nightsBetween(checkInDate, checkOutDate) <= 0) {
        throw new ValidationException("checkOutDate must be after checkInDate");
    }
}
```

**Vị trí gọi khác nhau giữa create và update — đây là điểm dễ sai nhất:**

```java
// CREATE: check trên dto, TRƯỚC khi map
requireCheckOutAfterCheckIn(dto.getCheckInDate(), dto.getCheckOutDate());
Reservation entity = ReservationMapper.toEntity(dto);

// UPDATE: check trên entity, SAU khi merge
ReservationMapper.applyPartialUpdate(entity, dto);
requireCheckOutAfterCheckIn(entity.getCheckInDate(), entity.getCheckOutDate());
```

Vì sao: PUT là partial. Client gửi **mỗi** `checkOutDate` — nếu check trên `dto` thì `checkInDate` là
`null` → hàm return sớm → lọt. Phải so với giá trị **cũ trong DB đã merge vào entity**.

> Kiểm tra nhanh: gửi `PUT {"checkOutDate": "<ngày trước checkIn hiện tại>"}`. Phải ra mã validation.
> Ra 200 là bạn đang check nhầm trên dto.

### Bảng đối chiếu cách viết

| Đề nói | Code |
|---|---|
| `b must be after a` | `DAYS.between(a, b) <= 0` → lỗi |
| `b must be after or equal a` | `DAYS.between(a, b) < 0` → lỗi |
| `b - a <= 30 days` | `DAYS.between(a, b) > 30` → lỗi |
| `b - a >= 1 day` | giống "after" |
| `total >= sum(...)` | so `BigDecimal.compareTo(...) < 0` (**đừng** dùng `equals`) |

`BigDecimal.equals` so cả scale: `1.0` **không** equals `1.00`. Luôn `compareTo(...) == 0`.

---

## 3. RÀNG BUỘC CHÉO SERVICE (qua Feign) — ĐẶC SẢN CỦA MÔN NÀY

**Nhận diện:** Description của field bên Detail nhắc tới thuộc tính của Master:
`Must not exceed the room capacity`, `Check available by RoomService`, `must be less than stock`.

Đây là lý do `fetchRoom...` phải **trả về DTO**, không phải chỉ verify rồi vứt:

```java
private RoomDTO requireRoomExists(Long roomId) {
    RoomApiResponse response;
    try {
        response = roomClient.getRoomById(roomId);
    } catch (FeignException.NotFound | FeignException.BadRequest ex) {
        throw new NotFoundException("Room ID is not found");     // status 4
    }
    if (response == null || response.getData() == null) {
        throw new NotFoundException("Room ID is not found");
    }
    return response.getData();                                    // <-- GIU LAI, dung vut
}

private RoomDTO fetchRoomForBooking(Long roomId) {
    RoomDTO room = requireRoomExists(roomId);
    if (!"AVAILABLE".equals(room.getStatus())) {
        throw new BusinessRuleException("Room is not AVAILABLE for reservation");   // status 5
    }
    return room;
}

private void requireGuestsWithinCapacity(Integer numberOfGuests, RoomDTO room) {
    if (numberOfGuests == null || room == null || room.getCapacity() == null) {
        return;
    }
    if (numberOfGuests > room.getCapacity()) {
        throw new ValidationException("numberOfGuests must not exceed the room capacity");  // status 2
    }
}
```

### Ba hàm fetch, ba mục đích khác nhau — đừng dùng nhầm

| Hàm | Dùng ở | Ném gì |
|---|---|---|
| `fetchRoomForBooking` | **create** | 404/4 nếu không có, **400/5** nếu sai trạng thái |
| `requireRoomExists` | **update** | chỉ 404/4 |
| `fetchRoomOrNull` | **get / list** (chỉ để hiển thị) | không ném, lỗi → `null` |

> **Bẫy chết người:** bảng Response Behavior của **UPDATE** thường **không có** dòng status 5.
> Dùng `fetchRoomForBooking` trong `update()` là trả ra mã không tồn tại trong bảng của đề.
> Kịch bản dễ dính: client sửa mỗi ngày tháng nhưng gửi kèm `roomId` cũ, phòng đó giờ đã `OCCUPIED`.

> **Bẫy thứ hai:** `list()` gọi Feign cho **từng** row. Phải dùng bản `OrNull` — một row lỗi mà ném
> exception là hỏng cả trang. Đổi lại, service kia chết thì `room` ra `null`, không phải 500.

---

## 4. STATUS — MÁY TRẠNG THÁI

### Giá trị mặc định

Quy tắc đúng cho cả 4 đề đã gặp: **phần tử ĐẦU** của danh sách enum = lúc create,
**phần tử CUỐI** = lúc delete (xoá mềm).

| Đề | Enum | create | delete |
|---|---|---|---|
| Trial / PE1 | `ACTIVE, INACTIVE` | ACTIVE | INACTIVE |
| SU26 Room | `AVAILABLE, OCCUPIED, MAINTENANCE` | AVAILABLE | MAINTENANCE |
| SU26 Reservation | `CONFIRMED, CHECKED_IN, CHECKED_OUT, CANCELLED` | CONFIRMED | CANCELLED |

`gen-from-entity.ps1` tự patch cả 2 chỗ theo quy tắc này. **Vẫn phải đọc lại đề** — nó chỉ là quy nạp
từ 4 mẫu; đề luôn ghi rõ *"Default status is X"* và *"Sets the ... status to Y"*.

### Ba câu hỏi phải trả lời cho status

1. **Create có nhận status từ client không?** Đề ghi *"Default status is X"* → service **ép** X, bỏ qua
   giá trị client gửi. (Test: POST kèm `"status":"<khác>"` vẫn phải ra X.)
2. **Delete là xoá mềm hay xoá thật?** Đề ghi *"Sets the ... status to Y"* → `setStatus(Y)` + `save`,
   **row vẫn còn**. Đừng `repository.delete()`.
3. **Có cấm chuyển trạng thái nào không?** Nếu đề ghi *"cannot be cancelled after check-in"* thì:

```java
if ("CHECKED_OUT".equals(entity.getStatus())) {
    throw new BusinessRuleException("Reservation cannot be cancelled after check-out");
}
```

### Delete có phải idempotent không

Đề không nói thì gọi DELETE hai lần vẫn `200/1` (lần 2 set lại cùng giá trị) — an toàn nhất.
Đề ghi *"already cancelled"* có mã riêng thì mới thêm nhánh.

---

## 5. PARTIAL UPDATE — THỨ TỰ THAO TÁC LÀ TẤT CẢ

Khung chuẩn, học thuộc đúng thứ tự này:

```java
public XxxDTO update(Long id, XxxDTO dto) {
    // 1. TIM - khong thay -> 404/4, message theo dung cau chu cua bang UPDATE
    Xxx entity = findOrThrow(id, "Xxx ID is not found");

    // 2. CHECK TRUNG - phai LOAI TRU chinh minh
    if (dto.getCode() != null && repository.existsByCodeAndXxxIdNot(dto.getCode(), id)) {
        throw new DuplicateNameException("Code is duplicated");
    }

    // 3. CHECK FK MOI - chi kiem tra TON TAI (khong check trang thai, xem muc 3)
    if (dto.getMasterId() != null) {
        requireMasterExists(dto.getMasterId());
    }

    // 4. MERGE
    XxxMapper.applyPartialUpdate(entity, dto);

    // 5. CHECK CHEO - tren entity DA MERGE, khong phai tren dto
    requireEndAfterStart(entity.getStartDate(), entity.getEndDate());
    MasterDTO master = fetchMasterOrNull(entity.getMasterId());
    requireQuantityWithinStock(entity.getQuantity(), master);

    // 6. TINH LAI FIELD COMPUTED - doi ngay/doi master thi tien phai doi theo
    if (master != null) {
        entity.setTotalAmount(computeTotalAmount(master, entity.getStartDate(), entity.getEndDate()));
    }

    return XxxMapper.toDTO(repository.save(entity));
}
```

### Bốn bẫy của partial update

| Bẫy | Triệu chứng | Cách chặn |
|---|---|---|
| Check UNIQUE quên loại trừ chính mình | Gửi lại chính `code` cũ → báo trùng | `existsByCodeAndIdNot(code, id)` |
| Đổi field UNIQUE mà quên đổi getter | `existsByCodeAndIdNot(dto.getName(), id)` — **compile ngon**, chạy sai lặng lẽ | Sau khi đổi field UNIQUE, grep cả cặp method + getter |
| Check chéo trên `dto` thay vì `entity` | Gửi 1 trong 2 field thì lọt | Check **sau** `applyPartialUpdate` |
| `@NotBlank` chỉ ở `OnCreate` | `PUT {"name":""}` ghi đè thành rỗng, trả 200 | Thêm `@Pattern(regexp = ".*\\S.*", groups = OnUpdate.class)` |

Dòng cuối cần giải thích: **không** vá được bằng `@NotBlank(groups = OnUpdate.class)`, vì `@NotBlank`
từ chối `null` — mà `null` chính là "field không gửi" của partial update. `@Pattern` **bỏ qua null**
nhưng chặn rỗng/toàn khoảng trắng, đúng thứ cần.

---

## 6. NGÀY THÁNG GIỮA 2 SERVICE

### Luật vàng: không bao giờ dùng API cũ của `java.util.Date`

| Đừng dùng | Vì | Dùng thay |
|---|---|---|
| `date.getDay()` | trả **THỨ TRONG TUẦN** 0–6, không phải ngày trong tháng | `LocalDate.getDayOfMonth()` |
| `date.getMonth()` | trả 0–11 | `LocalDate.getMonthValue()` (1–12) |
| `date.getYear()` | trả `năm - 1900` | `LocalDate.getYear()` |
| `date.toInstant()` | **ném `UnsupportedOperationException`** nếu là `java.sql.Date` | helper bên dưới |
| trừ 2 `getTime()` rồi chia 86400000 | sai vào ngày đổi giờ (DST) | `ChronoUnit.DAYS.between` |

Luôn đi qua helper này (đã có sẵn trong `common/DateOnlySerializer.java`):

```java
public static LocalDate toLocalDate(Date value) {
    if (value instanceof java.sql.Date sqlDate) {
        return sqlDate.toLocalDate();                 // Hibernate tra java.sql.Date cho cot DATE
    }
    return Instant.ofEpochMilli(value.getTime()).atZone(ZoneId.systemDefault()).toLocalDate();
}
```

> Gọi từ `service.impl` thì nhớ đổi nó thành **`public`** (mặc định là package-private).

### Bẫy `java.sql.Date` — triệu chứng rất đặc trưng

POST chạy ngon, **mọi GET đọc từ DB nổ 500** với `HttpMessageNotWritableException`, log dừng ở dòng
controller rồi im. Nguyên nhân: POST thì `Date` là `java.util.Date` thật từ deserializer, còn GET thì
Hibernate trả `java.sql.Date`, mà `java.sql.Date.toInstant()` **luôn** ném exception — nổ **sau khi**
controller đã return, lúc Jackson ghi body.

### Ngày đi qua Feign

Service kia trả JSON dạng chuỗi theo `SPEC_FORMAT` của **nó**. Nếu DTO bản copy bên này không khai
`@JsonDeserialize(using = DateOnlyDeserializer.class)` thì Jackson parse hỏng → Feign ném →
`fetchOrNull` nuốt thành `null` → field ngày trong response nested biến mất **không báo lỗi gì**.

> Bản copy `MasterDTO` bên Detail: field ngày phải có **cùng** cặp serializer/deserializer.
> Cách kiểm tra nhanh nhất: `GET /api/details/{id}` rồi nhìn object nested — có `null` bất thường không.

### Múi giờ

Cả 2 service chạy cùng máy nên `ZoneId.systemDefault()` khớp nhau. **Đừng** đổi một bên sang `UTC`
mà quên bên kia — lệch 1 ngày ở các mốc quanh nửa đêm.

`timestamp` của `ApiResponseDTO` thì khác: đề đòi ISO 8601 có chữ `Z` → phải là UTC:

```java
this.timestamp = Instant.now().truncatedTo(ChronoUnit.SECONDS).toString();   // 2026-07-31T08:15:30Z
```

`truncatedTo(SECONDS)` là bắt buộc — không có nó ra `...30.123456Z`, lệch format `hh:mm:ssZ` của đề.

---

## 7. ĐỌC ĐỀ → NHẬN DIỆN BUSINESS

Quét cột Description của **cả 2 bảng DTO** và tìm các cụm này:

| Cụm chữ trong đề | Loại | Xử lý |
|---|---|---|
| `Computed = ...`, `Calculated`, `Auto generated` | computed | mục 1 |
| `Must be after/before <field khác>` | chéo 2 field | mục 2 |
| `Must not exceed the <thứ của Master>` | chéo service | mục 3 |
| `Check available by <Service>` | chéo service | mục 3, ném status 5 |
| `must exist and have status X` | chéo service | `fetchForBooking` |
| `Default status is X` | status | service ép X lúc create |
| `Sets the ... status to Y` | status | delete = xoá mềm sang Y |
| `cannot be ... when/after ...` | máy trạng thái | `BusinessRuleException` |
| `Only provided fields are updated` | partial | mục 5 |
| `(partial match)` ở Query Parameters | filter | `LIKE %x%`, không phải `=` |
| kiểu `Enum` ở Query Parameters | filter | `ALLOWED_*` → mã validation, **không** trả 200 rỗng |

---

## 8. CHECKLIST SOÁT TRƯỚC KHI NỘP

- [ ] Mọi field `Computed` đã **bỏ `@NotNull`**, đã **xoá** khỏi `applyPartialUpdate`, service **ghi đè**
- [ ] Gửi giá trị bậy cho field computed → response trả giá trị **server tính**, không phải giá trị gửi lên
- [ ] Mọi `CHECK` nhắc 2 cột trong SQL → có một `require...` trong service, gọi **sau** `applyPartialUpdate`
- [ ] PUT chỉ gửi **một** trong 2 field của ràng buộc chéo → vẫn chặn được
- [ ] `update()` **không** ném status 5 (nếu bảng UPDATE của đề không có dòng đó)
- [ ] `list()` dùng bản Feign `OrNull` — tắt service kia thì list vẫn `200`, chỉ nested ra `null`
- [ ] Create ép status mặc định; gửi kèm status khác vẫn ra giá trị mặc định
- [ ] Delete = đổi status, `GET` lại vẫn thấy row
- [ ] Không còn `getDay()` / `getMonth()` / `getYear()` / `toInstant()` nào trong code
- [ ] POST xong **GET lại ngay** — không nổ 500 (bẫy `java.sql.Date`)
- [ ] Field ngày trong object nested hiển thị đúng, không `null`
- [ ] `timestamp` có chữ `Z`, không có mili giây
- [ ] Field UNIQUE: method repository **và** getter truyền vào **cùng** trỏ về một field
- [ ] `PUT {"<field mandatory>": ""}` → mã validation, không phải 200
