# BUSINESS CHEATSHEET — MỞ RỘNG: 30 CA CÓ THỂ RA + CODE DỰ ĐOÁN

> Nối tiếp `BUSINESS-CHEATSHEET.md`. File kia dạy **cách làm** 6 nhóm business đã gặp thật.
> File này là **catalog dự đoán**: các ca business khác có thể ra, kèm code dán được ngay.
>
> Phân nhóm theo taxonomy chuẩn của Business Rules Group (Structural / Derivation / Action Assertion),
> nhưng sắp xếp lại theo **cách nhận ra trong đề thi**, không theo lý thuyết.
>
> Cột **Khả năng**: ★★★ đã ra rồi hoặc gần như chắc chắn · ★★ hợp lý với khuôn đề này · ★ ít gặp.

---

## MỤC LỤC NHANH — TRA THEO CÂU CHỮ TRONG ĐỀ

| Đề viết gì | Ca số | Khả năng |
|---|---|---|
| `Computed = A × B` | 1 | ★★★ |
| `Computed = A × B × C` | 2 | ★★★ |
| `after discount`, `%` | 3 | ★★ |
| `including VAT/tax` | 4 | ★★ |
| `fine`, `penalty`, `overdue` | 5 | ★★ |
| `rate depends on`, bảng bậc thang | 6 | ★ |
| `total of all …`, `sum of` | 7 | ★★ |
| `remaining`, `available`, `left` | 8 | ★★ |
| `age`, `duration`, `days since` | 9 | ★ |
| `must be after <field>` | 10 | ★★★ |
| `not more than N days` | 11 | ★★★ |
| `at least N days` | 12 | ★★ |
| `A + B must not exceed C` | 13 | ★ |
| `required when …`, `if … then … is mandatory` | 14 | ★★ |
| `either … or …`, `one of` | 15 | ★ |
| `must not be in the past/future` | 16 | ★★★ |
| `must be a multiple of` | 17 | ★ |
| `unique combination of A and B` | 18 | ★★ |
| `overlapping`, `already booked`, `same period` | 19 | ★★★ |
| `maximum N per …` | 20 | ★★ |
| `total across all … must not exceed` | 21 | ★★ |
| `must exist` | 22 | ★★★ |
| `must have status X` | 23 | ★★★ |
| `must not exceed the <master>'s …` | 24 | ★★★ |
| `within the <master>'s period` | 25 | ★★ |
| `inherits`, `copied from` | 26 | ★ |
| `cannot be … after …`, `only … can be …` | 27 | ★★★ |
| `cannot be updated when` | 28 | ★★ |
| `cannot be deleted if …has…` | 29 | ★★ |
| `automatically becomes … when` | 30 | ★★ |

---

## PHẦN A — DERIVATION: FIELD SERVER TỰ TÍNH

> Nguyên tắc chung cho **cả 9 ca**: bỏ `@NotNull` ở DTO, xoá khỏi `applyPartialUpdate`,
> service ghi đè. Xem mục 1 của `BUSINESS-CHEATSHEET.md`.

### Ca 1 — Tích 2 thừa số ★★★

> `totalAmount = pricePerNight × number of nights` · `subTotal = unitPrice × quantity`

```java
private BigDecimal computeTotal(BigDecimal unitPrice, long units) {
    if (unitPrice == null || units <= 0) {
        return BigDecimal.ZERO;
    }
    return unitPrice.multiply(BigDecimal.valueOf(units));
}
```

### Ca 2 — Tích 3 thừa số ★★★

> `totalFee = dailyRate × number of days × numberOfCopies`

**Bẫy:** sửa thừa số **nào** ở PUT cũng phải tính lại. Đừng chỉ recompute khi đổi ngày.

```java
private BigDecimal computeTotalFee(BookDTO book, Date from, Date to, Integer copies) {
    if (book == null || book.getDailyRate() == null || from == null || to == null || copies == null) {
        return BigDecimal.ZERO;
    }
    long days = ChronoUnit.DAYS.between(toLocalDate(from), toLocalDate(to));
    if (days <= 0 || copies <= 0) {
        return BigDecimal.ZERO;
    }
    return book.getDailyRate()
            .multiply(BigDecimal.valueOf(days))
            .multiply(BigDecimal.valueOf(copies));
}
```

### Ca 3 — Có giảm giá theo phần trăm ★★

> `finalAmount = subTotal × (1 - discountPercent / 100)`

**Bắt buộc `setScale`** — không có là `ArithmeticException` → 500.

```java
private static final BigDecimal HUNDRED = new BigDecimal("100");

private BigDecimal applyDiscount(BigDecimal subTotal, BigDecimal discountPercent) {
    if (subTotal == null) {
        return BigDecimal.ZERO;
    }
    if (discountPercent == null || discountPercent.compareTo(BigDecimal.ZERO) <= 0) {
        return subTotal.setScale(2, RoundingMode.HALF_UP);
    }
    BigDecimal factor = BigDecimal.ONE.subtract(discountPercent.divide(HUNDRED, 6, RoundingMode.HALF_UP));
    return subTotal.multiply(factor).setScale(2, RoundingMode.HALF_UP);
}
```

### Ca 4 — Có thuế / VAT ★★

> `totalWithTax = subTotal × (1 + taxRate / 100)`

```java
private BigDecimal addTax(BigDecimal subTotal, BigDecimal taxPercent) {
    if (subTotal == null) {
        return BigDecimal.ZERO;
    }
    BigDecimal rate = (taxPercent == null) ? BigDecimal.ZERO : taxPercent;
    BigDecimal factor = BigDecimal.ONE.add(rate.divide(HUNDRED, 6, RoundingMode.HALF_UP));
    return subTotal.multiply(factor).setScale(2, RoundingMode.HALF_UP);
}
```

### Ca 5 — Phí phạt trễ hạn, có điều kiện ★★

> `fineAmount = overdue days × finePerDay` · *"0 if returned on time"*

```java
private BigDecimal computeFine(Date dueDate, Date returnDate, BigDecimal finePerDay) {
    if (dueDate == null || returnDate == null || finePerDay == null) {
        return BigDecimal.ZERO;
    }
    long overdue = ChronoUnit.DAYS.between(toLocalDate(dueDate), toLocalDate(returnDate));
    if (overdue <= 0) {
        return BigDecimal.ZERO;          // tra dung han hoac som -> KHONG am
    }
    return finePerDay.multiply(BigDecimal.valueOf(overdue)).setScale(2, RoundingMode.HALF_UP);
}
```

> **Bẫy:** quên chặn `overdue <= 0` là ra số âm → vi phạm `CHECK (fine >= 0)` → 500 thay vì 201.

### Ca 6 — Giá bậc thang ★

> *"first 3 days at normal rate, extra days at 50%"*

```java
private BigDecimal computeTiered(BigDecimal dailyRate, long days) {
    if (dailyRate == null || days <= 0) {
        return BigDecimal.ZERO;
    }
    long normal = Math.min(days, 3);
    long extra = Math.max(0, days - 3);
    return dailyRate.multiply(BigDecimal.valueOf(normal))
            .add(dailyRate.multiply(new BigDecimal("0.5")).multiply(BigDecimal.valueOf(extra)))
            .setScale(2, RoundingMode.HALF_UP);
}
```

### Ca 7 — Tổng của các dòng con ★★

> `orderTotal = sum of all order items`

Tính **ở DB**, đừng load hết rồi cộng trong Java.

```java
// repository
@Query("SELECT COALESCE(SUM(i.lineTotal), 0) FROM OrderItem i WHERE i.orderId = :orderId")
BigDecimal sumLineTotal(@Param("orderId") Long orderId);

// service
entity.setOrderTotal(itemRepository.sumLineTotal(entity.getOrderId()));
```

> `COALESCE(..., 0)` bắt buộc — không có thì đơn hàng chưa có dòng nào trả `null` → NPE → 500.

### Ca 8 — Số còn lại, lấy từ service kia ★★

> `availableCopies = totalCopies - số đang cho mượn`

```java
// repository ben Detail
@Query("SELECT COALESCE(SUM(l.numberOfCopies), 0) FROM Loan l "
     + "WHERE l.bookId = :bookId AND l.status = 'ACTIVE'")
Integer countActiveCopies(@Param("bookId") Long bookId);

// service
private void requireEnoughStock(Long bookId, int wanted, BookDTO book) {
    int used = repository.countActiveCopies(bookId);
    int available = book.getTotalCopies() - used;
    if (wanted > available) {
        throw new ValidationException("Only " + available + " copies available");
    }
}
```

> Ở **update** phải trừ ra chính bản ghi đang sửa, không thì tự chặn chính mình:
> `countActiveCopiesExcluding(bookId, currentLoanId)`.

### Ca 9 — Suy ra từ ngày tới hiện tại ★

> `age = years since birthDate` · `daysRemaining = dueDate - today`

```java
private int yearsSince(Date from) {
    return (int) ChronoUnit.YEARS.between(toLocalDate(from), LocalDate.now());
}
```

---

## PHẦN B — CONSTRAINT TRONG CÙNG MỘT BẢN GHI

> Tất cả đặt trong service. Ở **create** check trên `dto`, ở **update** check **sau** `applyPartialUpdate`.

### Ca 10 — b phải sau a ★★★

```java
private void requireAfter(Date a, Date b, String message) {
    if (a == null || b == null) {
        return;                                  // de @NotNull lo phan thieu field
    }
    if (!toLocalDate(b).isAfter(toLocalDate(a))) {
        throw new ValidationException(message);
    }
}
```

### Ca 11 — Khoảng cách tối đa ★★★

> *"not more than 30 days after borrowDate"*

```java
private void requireWithinDays(Date from, Date to, int maxDays, String message) {
    if (from == null || to == null) {
        return;
    }
    long days = ChronoUnit.DAYS.between(toLocalDate(from), toLocalDate(to));
    if (days > maxDays) {
        throw new ValidationException(message);
    }
}
```

> Đúng `maxDays` là **hợp lệ**. Viết `>=` là chặn nhầm biên trên.

### Ca 12 — Khoảng cách tối thiểu ★★

> *"stay must be at least 2 nights"*

```java
private void requireAtLeastDays(Date from, Date to, int minDays, String message) {
    if (from == null || to == null) {
        return;
    }
    if (ChronoUnit.DAYS.between(toLocalDate(from), toLocalDate(to)) < minDays) {
        throw new ValidationException(message);
    }
}
```

### Ca 13 — Tổng 2 field không vượt field thứ 3 ★

> *"adults + children must not exceed capacity"*

```java
private void requireSumWithin(Integer a, Integer b, Integer limit, String message) {
    if (limit == null) {
        return;
    }
    int total = (a == null ? 0 : a) + (b == null ? 0 : b);
    if (total > limit) {
        throw new ValidationException(message);
    }
}
```

### Ca 14 — Bắt buộc có điều kiện ★★

> *"cancelReason is required when status is CANCELLED"*

Annotation field-level bó tay vì nhìn 2 field. Check ở service **sau** merge:

```java
private void requireReasonWhenCancelled(Reservation entity) {
    if ("CANCELLED".equals(entity.getStatus())
            && (entity.getCancelReason() == null || entity.getCancelReason().isBlank())) {
        throw new ValidationException("cancelReason is required when status is CANCELLED");
    }
}
```

### Ca 15 — Bắt buộc đúng một trong hai ★

> *"either email or phone must be provided"*

```java
private void requireExactlyOne(String a, String b, String message) {
    boolean hasA = a != null && !a.isBlank();
    boolean hasB = b != null && !b.isBlank();
    if (hasA == hasB) {                          // ca hai deu co, hoac ca hai deu thieu
        throw new ValidationException(message);
    }
}
```

### Ca 16 — Ngày không được ở quá khứ / tương lai ★★★

Cái này **không** cần code service — bật hằng số trong `common/ValidDate.java`:

| Đề nói | Bật gì |
|---|---|
| `must not be in the future` | `NO_FUTURE = true` |
| `must be in the future` | `FUTURE_ONLY = true`, `FUTURE_ALLOW_TODAY = false` |
| `must be today or later` | `FUTURE_ONLY = true`, `FUTURE_ALLOW_TODAY = true` |
| `after 2000-01-01` | `MIN_DATE = LocalDate.of(2000,1,1)`, `MIN_EXCLUSIVE = true` |
| `before today + 360` | `MAX_DAYS_FROM_TODAY = 360` |

Rule chỉ áp cho **một** field trong khi field ngày khác không áp → dùng thuộc tính của annotation
thay vì hằng số global: `@ValidDate(noFuture = true, message = "...")`.

### Ca 17 — Bội số ★

> *"duration must be a multiple of 30 minutes"*

```java
private void requireMultipleOf(Integer value, int step, String message) {
    if (value == null) {
        return;
    }
    if (value % step != 0) {
        throw new ValidationException(message);
    }
}
```

---

## PHẦN C — CONSTRAINT GIỮA CÁC BẢN GHI CÙNG BẢNG

### Ca 18 — Unique tổ hợp 2 cột ★★

> *"a student cannot enroll in the same course twice"*

```java
// repository
boolean existsByStudentIdAndCourseId(Long studentId, Long courseId);
boolean existsByStudentIdAndCourseIdAndEnrollmentIdNot(Long studentId, Long courseId, Long id);

// service - create
if (repository.existsByStudentIdAndCourseId(dto.getStudentId(), dto.getCourseId())) {
    throw new DuplicateNameException("Student is already enrolled in this course");
}
// service - update: nho LOAI TRU chinh minh
if (repository.existsByStudentIdAndCourseIdAndEnrollmentIdNot(sid, cid, enrollmentId)) { ... }
```

### Ca 19 — Trùng khoảng thời gian (double booking) ★★★

Ca hay ra nhất trong nhóm này, và cũng dễ viết sai điều kiện nhất.

**Hai khoảng `[s1,e1)` và `[s2,e2)` giao nhau khi và chỉ khi `s1 < e2 AND s2 < e1`.**
Đừng liệt kê 4 trường hợp con — sai sót ngay.

```java
// repository
@Query("SELECT COUNT(r) FROM Reservation r "
     + "WHERE r.roomId = :roomId "
     + "  AND r.status <> 'CANCELLED' "
     + "  AND r.checkInDate < :checkOut "
     + "  AND :checkIn < r.checkOutDate")
long countOverlapping(@Param("roomId") Long roomId,
                      @Param("checkIn") Date checkIn,
                      @Param("checkOut") Date checkOut);

// ban cho UPDATE - bo qua chinh no
@Query("SELECT COUNT(r) FROM Reservation r "
     + "WHERE r.roomId = :roomId "
     + "  AND r.reservationId <> :selfId "
     + "  AND r.status <> 'CANCELLED' "
     + "  AND r.checkInDate < :checkOut "
     + "  AND :checkIn < r.checkOutDate")
long countOverlappingExcluding(@Param("roomId") Long roomId, @Param("selfId") Long selfId,
                               @Param("checkIn") Date checkIn, @Param("checkOut") Date checkOut);
```

```java
private void requireNoOverlap(Long roomId, Long selfId, Date checkIn, Date checkOut) {
    if (roomId == null || checkIn == null || checkOut == null) {
        return;
    }
    long n = (selfId == null)
            ? repository.countOverlapping(roomId, checkIn, checkOut)
            : repository.countOverlappingExcluding(roomId, selfId, checkIn, checkOut);
    if (n > 0) {
        throw new BusinessRuleException("Room is already booked for the selected period");
    }
}
```

Ba điều dễ quên:
- **Loại trừ bản ghi đã huỷ** (`status <> 'CANCELLED'`), không thì phòng đã huỷ vẫn chặn.
- **Update phải loại trừ chính mình**, không thì sửa mỗi tên khách cũng báo trùng.
- Mã trả về: đề coi đây là "validation" thì `ValidationException`, coi là nhánh nghiệp vụ riêng
  (có dòng status 5) thì `BusinessRuleException` — **đọc bảng Response Behavior**.

### Ca 20 — Tối đa N bản ghi cho mỗi cha ★★

> *"a student can enroll in at most 5 courses per semester"*

```java
private static final int MAX_PER_STUDENT = 5;

private void requireUnderLimit(Long studentId) {
    long current = repository.countByStudentIdAndStatusNot(studentId, "CANCELLED");
    if (current >= MAX_PER_STUDENT) {
        throw new BusinessRuleException("Student has reached the maximum of "
                + MAX_PER_STUDENT + " enrollments");
    }
}
```

### Ca 21 — Tổng trên nhiều dòng không vượt hạn mức ★★

> *"total booked seats must not exceed course capacity"*

```java
@Query("SELECT COALESCE(SUM(e.seats), 0) FROM Enrollment e "
     + "WHERE e.courseId = :courseId AND e.status <> 'CANCELLED'")
int sumSeats(@Param("courseId") Long courseId);
```

```java
private void requireSeatsAvailable(Long courseId, int wanted, CourseDTO course) {
    int used = repository.sumSeats(courseId);
    if (used + wanted > course.getCapacity()) {
        throw new BusinessRuleException("Course is full. Remaining seats: "
                + (course.getCapacity() - used));
    }
}
```

---

## PHẦN D — CONSTRAINT CHÉO SERVICE (FEIGN)

> Ca 22–24 đã có code đầy đủ ở mục 3 của `BUSINESS-CHEATSHEET.md`. Đây là 2 ca mở rộng.

### Ca 22–24 — tồn tại / đúng trạng thái / không vượt thuộc tính ★★★

Tóm tắt: `requireMasterExists` (404) → `fetchMasterForBooking` (thêm 400/5) →
`requireXWithinY(child, master)` (validation). Xem file kia.

### Ca 25 — Ngày con phải nằm trong khoảng của cha ★★

> *"enrollment date must be within the course period"*

```java
private void requireWithinMasterPeriod(Date childDate, CourseDTO course) {
    if (childDate == null || course == null
            || course.getStartDate() == null || course.getEndDate() == null) {
        return;
    }
    LocalDate d = toLocalDate(childDate);
    if (d.isBefore(toLocalDate(course.getStartDate()))
            || d.isAfter(toLocalDate(course.getEndDate()))) {
        throw new ValidationException("enrollmentDate must be within the course period");
    }
}
```

> Bản copy `CourseDTO` bên service con **phải** có cặp serializer/deserializer ngày, không thì
> `startDate` parse hỏng → `null` → hàm return sớm → rule im lặng không chạy.

### Ca 26 — Copy giá trị từ cha lúc tạo (snapshot) ★

> *"unitPrice is copied from the product at the time of order"*

```java
// Chot gia luc tao, KHONG doc lai tu master ve sau -> doi gia san pham
// khong lam thay doi don hang cu.
entity.setUnitPrice(product.getPrice());
```

---

## PHẦN E — ACTION ASSERTION: MÁY TRẠNG THÁI

### Ca 27 — Chỉ cho phép một số chuyển trạng thái ★★★

> *"a CHECKED_OUT reservation cannot be cancelled"* · *"only CONFIRMED can be CHECKED_IN"*

Khai báo bằng `Map`, đừng viết `if` lồng nhau:

```java
private static final Map<String, Set<String>> ALLOWED_TRANSITIONS = Map.of(
        "CONFIRMED",   Set.of("CHECKED_IN", "CANCELLED"),
        "CHECKED_IN",  Set.of("CHECKED_OUT"),
        "CHECKED_OUT", Set.of(),
        "CANCELLED",   Set.of()
);

private void requireValidTransition(String from, String to) {
    if (to == null || to.equals(from)) {
        return;                                  // khong doi status thi khong check
    }
    Set<String> allowed = ALLOWED_TRANSITIONS.getOrDefault(from, Set.of());
    if (!allowed.contains(to)) {
        throw new BusinessRuleException("Cannot change status from " + from + " to " + to);
    }
}
```

Gọi trong `update()`, **trước** `applyPartialUpdate` (vì cần biết trạng thái cũ):

```java
requireValidTransition(entity.getStatus(), dto.getStatus());
ReservationMapper.applyPartialUpdate(entity, dto);
```

Và trong `cancel()`:

```java
requireValidTransition(entity.getStatus(), "CANCELLED");
entity.setStatus("CANCELLED");
```

### Ca 28 — Cấm sửa khi đang ở trạng thái nào đó ★★

> *"a cancelled reservation cannot be modified"*

```java
private static final Set<String> LOCKED_STATUS = Set.of("CANCELLED", "CHECKED_OUT");

private void requireEditable(Reservation entity) {
    if (LOCKED_STATUS.contains(entity.getStatus())) {
        throw new BusinessRuleException("Reservation in status "
                + entity.getStatus() + " cannot be modified");
    }
}
```

Đặt **ngay sau `findOrThrow`**, trước mọi thứ khác.

### Ca 29 — Cấm xoá khi còn bản ghi con ★★

> *"a room with active reservations cannot be deleted"*

Nằm ở phía **Master**, mà Master không được gọi ngược sang Detail (Feign một chiều).
Hai cách, chọn theo lời đề:

```java
// Cach 1 - de cho phep Master goi nguoc: them mot Feign client o phia Master.
// Cach 2 (an toan hon, hay dung hon) - de KHONG noi gi -> khong lam gi ca,
//         xoa mem chi doi status, ban ghi con van tro toi duoc.
```

> Nếu đề **không** nói rõ, **đừng tự thêm** ràng buộc này. Thêm vào là tạo ra một mã lỗi
> không có trong bảng Response Behavior — mất điểm chắc chắn hơn là được.

### Ca 30 — Tự đổi trạng thái theo ngày ★★

> *"a loan becomes OVERDUE when dueDate has passed"*

Đừng viết job chạy nền. Tính **lúc đọc**:

```java
private String effectiveStatus(Loan entity) {
    if ("ACTIVE".equals(entity.getStatus())
            && entity.getDueDate() != null
            && toLocalDate(entity.getDueDate()).isBefore(LocalDate.now())) {
        return "OVERDUE";
    }
    return entity.getStatus();
}

// trong mapper: dto.setStatus(effectiveStatus(entity));
```

> Cân nhắc: cách này khiến filter `?status=OVERDUE` không khớp (DB vẫn lưu `ACTIVE`).
> Đề có filter theo status thì phải **ghi thật** vào DB lúc đọc, hoặc đưa điều kiện ngày vào `@Query`.
> Đề không nói gì về OVERDUE thì **bỏ qua ca này**.

---

## HAI THỨ ĐỀ THI NÀY GẦN NHƯ CHẮC CHẮN KHÔNG HỎI

Ghi ra để bạn **không tốn thời gian** làm:

- **Khoá lạc quan / tranh chấp đồng thời** (`@Version`, optimistic locking). Grader gọi API tuần tự,
  không có test race condition. Ca 19 (trùng lịch) trong thực tế cần khoá, nhưng trong đề thi
  chỉ cần một câu `COUNT` là đủ.
- **Giao dịch phân tán / saga / rollback chéo service.** Kiến trúc đề là Feign một chiều đọc dữ liệu,
  không có ghi hai phía cần rollback.

---

## SOÁT CUỐI CÙNG CHO PHẦN BUSINESS

Ba câu hỏi, mỗi rule business hỏi một lần:

1. **Mã trả về của rule này có trong bảng Response Behavior không?**
   Không có → bạn đang bịa ra một nhánh lỗi. Xoá đi hoặc đổi sang mã đã có.
2. **Ở `update()`, rule này check trên `dto` hay trên `entity` đã merge?**
   Nhìn 2 field trở lên → bắt buộc là `entity` sau merge.
3. **Rule này có tự chặn chính mình khi update không?**
   Mọi rule đếm/so với bản ghi khác (ca 18, 19, 20, 21) đều cần bản `...Excluding(selfId)`.

---

---

## CODE TRONG FILE NÀY ĐÃ ĐƯỢC CHẠY THẬT

Các hàm tính toán và điều kiện logic ở trên đã compile bằng JDK 21 và chạy qua **32 assertion**,
gồm cả các biên dễ sai:

| Kiểm tra | Kết quả |
|---|---|
| Ca 2: ngày ngược / `copies = 0` → `0`, không ra số âm | ✅ |
| Ca 3: giảm **33%** (phép chia vô hạn tuần hoàn) → `670.00`, **không** ném `ArithmeticException` | ✅ |
| Ca 5: trả **sớm** hơn hạn → `0`, không ra phí âm | ✅ |
| Ca 6: bậc thang 2 / 3 / 5 ngày → `200` / `300` / `400` | ✅ |
| Ca 11: **đúng** 30 ngày → hợp lệ; 31 ngày → chặn | ✅ |
| Ca 15: cả hai đều có → sai; cả hai đều thiếu → sai | ✅ |
| Ca 19: 7 tình huống giao khoảng, gồm **giáp ranh** (`checkOut` của A = `checkIn` của B) → **không** tính là trùng | ✅ |
| Ca 27: nhảy cóc `CONFIRMED → CHECKED_OUT` → chặn; set lại chính trạng thái cũ → cho qua | ✅ |

Ca 19 giáp ranh là chỗ đáng lưu ý nhất: khách trả phòng ngày 15 và khách khác nhận phòng **cũng**
ngày 15 là **hợp lệ**. Điều kiện `s1 < e2 AND s2 < e1` xử lý đúng; nếu đổi thành `<=` sẽ chặn nhầm.

---

### Nguồn tham khảo

- [Business Rules Group — Defining Business Rules: What Are They Really?](https://www.businessrulesgroup.org/first_paper/BRG-whatisBR_3ed.pdf) — phân loại Structural assertion / Action assertion / Derivation dùng cho phần A–E
- [IBM — What Are Business Rules?](https://www.ibm.com/think/topics/business-rules)
- [Flowwright — Types of Business Rules](https://flowwright.com/blog/types-of-business-rules) — nhóm constraint: stimulus/response, operation, structure
- [Oleg Potapov — How to design a booking system to avoid overlapping reservation](https://oleg0potapov.medium.com/how-to-design-a-booking-system-to-avoid-overlapping-reservation-fe17194c1337) — điều kiện giao khoảng ở ca 19
- [SDSU Registrar — Course Registration Restrictions](https://registrar.sdsu.edu/students/registration/course_registration_restrictions) và [USU — Solve Common Registration Errors](https://www.usu.edu/registrar/registration/common-errors) — ca 18, 20, 21 (trùng đăng ký, giới hạn số môn, hết chỗ)
- [DEV — Spring Boot DDD E-Commerce Order Management](https://dev.to/devcorner/spring-boot-ddd-e-commerce-order-management-system-detailed-walkthrough-12ie) — ca 8, 21 (kiểm tra tồn kho)
- [amrtechuniverse — State Machine Diagrams in Spring Boot](https://amrtechuniverse.com/state-machine-diagrams-in-spring-boot-usage-and-implementation) — ca 27 (bảng chuyển trạng thái)
