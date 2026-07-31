# =====================================================================================
# MSS301 SU26 PE1 - BO TEST TU CHAM (chay qua GATEWAY 8080, dung duong grader cham)
# Moi test case doi chieu voi MOT dong trong bang "Response Behavior" cua de.
#
#   powershell -ExecutionPolicy Bypass -File .\run-tests.ps1
#   powershell -ExecutionPolicy Bypass -File .\run-tests.ps1 -Only R      # chi RoomService
#   powershell -ExecutionPolicy Bypass -File .\run-tests.ps1 -Only V      # chi ReservationService
#   powershell -ExecutionPolicy Bypass -File .\run-tests.ps1 -Verbose2    # in ca body tra ve
#
# Yeu cau: 3 service dang chay (8081, 8082, 8080) + SQL Server co DB MSS301_2026_PE.
# Script tu RESEED DB truoc moi nhom test nen chay lai bao nhieu lan cung ra ket qua giong nhau.
#
# !!! PASSWORD !!!
#   application.properties dang de password = "sa" theo DUNG bang Configuration cua de
#   (muc 3 Grading Policies: sai bang do = 0 diem ca bai).
#   SQL Server tren may nay lai dung password "12345", nen MUON CHAY THU O NHA:
#     1. Doi tam password trong 2 file application.properties (Room + Reservation) thanh 12345
#     2. mvn clean package -> chay lai 3 service -> chay file nay
#     3. DOI LAI THANH "sa" TRUOC KHI ZIP NOP
# =====================================================================================

param(
    [string]$Base = 'http://localhost:8080',
    [string]$SqlServer = 'localhost,1433',
    [string]$SqlUser = 'sa',
    [string]$SqlPass = '12345',
    [string]$Only = '',
    [switch]$Verbose2
)

$ErrorActionPreference = 'Continue'
$SeedFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'sql\seed_test_db.sql'

$script:Results = New-Object System.Collections.ArrayList
$script:Section = ''

# ------------------------------------------------------------------ helpers

function Reset-Db {
    $null = & sqlcmd -S $SqlServer -U $SqlUser -P $SqlPass -C -i $SeedFile 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "  ! Reseed DB that bai" -ForegroundColor Red }
}

function Invoke-Api {
    param([string]$Method, [string]$Path, [string]$Body)
    $tmp = $null
    $cargs = @('-s', '-w', "`n%{http_code}", '-X', $Method, '-H', 'Content-Type: application/json')
    if ($null -ne $Body -and $Body -ne '') {
        $tmp = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($tmp, $Body, (New-Object System.Text.UTF8Encoding($false)))
        $cargs += @('--data-binary', "@$tmp")
    }
    $cargs += "$Base$Path"

    $raw = (& curl.exe @cargs) -join "`n"
    if ($tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }

    $lines = $raw -split "`n"
    $code = 0
    if ($lines.Count -ge 1) { [int]::TryParse($lines[-1].Trim(), [ref]$code) | Out-Null }
    $bodyText = if ($lines.Count -ge 2) { ($lines[0..($lines.Count - 2)] -join "`n") } else { '' }
    $json = $null
    if ($bodyText.Trim()) { try { $json = $bodyText | ConvertFrom-Json } catch { } }

    return [pscustomobject]@{ Code = $code; Body = $bodyText; Json = $json }
}

function Section { param([string]$Name) $script:Section = $Name; Write-Host ""; Write-Host "== $Name" -ForegroundColor Cyan }

function T {
    param(
        [string]$Id, [string]$Desc,
        [string]$Method, [string]$Path, [string]$Body,
        [int]$ExpCode, $ExpStatus = $null,
        [scriptblock]$Check
    )
    if ($Only -and -not $Id.StartsWith($Only)) { return }

    $r = Invoke-Api -Method $Method -Path $Path -Body $Body
    $problems = New-Object System.Collections.ArrayList

    if ($r.Code -ne $ExpCode) { [void]$problems.Add("HTTP=$($r.Code) can $ExpCode") }

    if ($null -ne $ExpStatus) {
        $actual = if ($null -ne $r.Json) { $r.Json.status } else { '<khong parse duoc JSON>' }
        if ("$actual" -ne "$ExpStatus") { [void]$problems.Add("status=$actual can $ExpStatus") }
    }

    if ($Check) {
        try {
            $msg = & $Check $r.Json $r
            foreach ($m in @($msg)) { if ($m) { [void]$problems.Add($m) } }
        } catch {
            [void]$problems.Add("check loi: $($_.Exception.Message)")
        }
    }

    $ok = ($problems.Count -eq 0)
    [void]$script:Results.Add([pscustomobject]@{
        Section = $script:Section; Id = $Id; Desc = $Desc; Ok = $ok
        Detail  = ($problems -join '; '); Http = $r.Code; Body = $r.Body
    })

    if ($ok) {
        Write-Host ("  [PASS] {0,-7} {1}" -f $Id, $Desc) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] {0,-7} {1}" -f $Id, $Desc) -ForegroundColor Red
        Write-Host ("          -> {0}" -f ($problems -join '; ')) -ForegroundColor Yellow
        if ($Verbose2) { Write-Host ("          body: {0}" -f $r.Body) -ForegroundColor DarkGray }
    }
    return $r
}

function Has { param($obj, [string]$name) return ($null -ne $obj) -and ($null -ne $obj.PSObject.Properties[$name]) }

# ------------------------------------------------------------------ smoke

Write-Host "MSS301 SU26 PE1 - TU CHAM" -ForegroundColor White
Write-Host "Gateway: $Base"

$smoke = Invoke-Api -Method GET -Path '/api/rooms'
if ($smoke.Code -eq 0) {
    Write-Host "KHONG KET NOI DUOC GATEWAY $Base - kiem tra 3 service da chay chua." -ForegroundColor Red
    exit 1
}

# =====================================================================================
# ROOM SERVICE
# =====================================================================================

# ---------------------------------------------------------- R5. GET /api/rooms (list)
Section 'R5. GET /api/rooms - Get Room List'
Reset-Db

T 'R5.1' 'default -> 200/1, PageDTO du 7 field, size=10 page=0 totalElements=12' `
    GET '/api/rooms' $null 200 1 {
    param($j)
    $p = $j.data
    $bad = @()
    foreach ($f in 'size', 'page', 'totalPages', 'totalElements', 'first', 'last', 'content') {
        if (-not (Has $p $f)) { $bad += "PageDTO thieu field '$f'" }
    }
    if ((Has $p 'size') -and $p.size -ne 10) { $bad += "size=$($p.size) can 10" }
    if ((Has $p 'page') -and $p.page -ne 0) { $bad += "page=$($p.page) can 0" }
    if ((Has $p 'totalElements') -and $p.totalElements -ne 12) { $bad += "totalElements=$($p.totalElements) can 12" }
    if ((Has $p 'totalPages') -and $p.totalPages -ne 2) { $bad += "totalPages=$($p.totalPages) can 2" }
    if ((Has $p 'first') -and $p.first -ne $true) { $bad += "first=$($p.first) can true" }
    if ((Has $p 'last') -and $p.last -ne $false) { $bad += "last=$($p.last) can false" }
    if ((Has $p 'content') -and $p.content.Count -ne 10) { $bad += "content.Count=$($p.content.Count) can 10" }
    return $bad
} | Out-Null

T 'R5.2' 'RoomDTO trong content du 7 field dung ten' `
    GET '/api/rooms?size=1' $null 200 1 {
    param($j)
    $row = $j.data.content[0]
    $bad = @()
    foreach ($f in 'roomId', 'roomNumber', 'roomType', 'pricePerNight', 'capacity', 'floor', 'status') {
        if (-not (Has $row $f)) { $bad += "RoomDTO thieu '$f'" }
    }
    return $bad
} | Out-Null

T 'R5.3' 'ApiResponseDTO co timestamp ISO 8601 YYYY-MM-DDThh:mm:ssZ' `
    GET '/api/rooms' $null 200 1 {
    param($j)
    if (-not (Has $j 'timestamp')) { return 'thieu field timestamp' }
    if ($j.timestamp -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') { return "timestamp='$($j.timestamp)' sai format" }
    return $null
} | Out-Null

T 'R5.4' 'page=1&size=5 -> 200/1, page=1 size=5' `
    GET '/api/rooms?page=1&size=5' $null 200 1 {
    param($j)
    $bad = @()
    if ($j.data.page -ne 1) { $bad += "page=$($j.data.page) can 1" }
    if ($j.data.size -ne 5) { $bad += "size=$($j.data.size) can 5" }
    return $bad
} | Out-Null

T 'R5.5' 'roomType=SUITE -> chi tra row SUITE (3 row)' `
    GET '/api/rooms?roomType=SUITE' $null 200 1 {
    param($j)
    $bad = @()
    if ($j.data.totalElements -ne 3) { $bad += "totalElements=$($j.data.totalElements) can 3" }
    foreach ($r in $j.data.content) { if ($r.roomType -ne 'SUITE') { $bad += "lot row roomType=$($r.roomType)" } }
    return $bad
} | Out-Null

T 'R5.6' 'status=AVAILABLE -> chi tra row AVAILABLE (8 row)' `
    GET '/api/rooms?status=AVAILABLE' $null 200 1 {
    param($j)
    $bad = @()
    if ($j.data.totalElements -ne 8) { $bad += "totalElements=$($j.data.totalElements) can 8" }
    foreach ($r in $j.data.content) { if ($r.status -ne 'AVAILABLE') { $bad += "lot row status=$($r.status)" } }
    return $bad
} | Out-Null

T 'R5.7' 'roomType=BOGUS (Enum sai) -> 406/2, KHONG duoc 200 rong' `
    GET '/api/rooms?roomType=BOGUS' $null 406 2 $null | Out-Null

T 'R5.8' 'status=BOGUS (Enum sai) -> 406/2' `
    GET '/api/rooms?status=BOGUS' $null 406 2 $null | Out-Null

T 'R5.9'  'size=100 (bang max) -> 200/1' GET '/api/rooms?size=100' $null 200 1 $null | Out-Null
T 'R5.10' 'size=101 (vuot max) -> 406/2' GET '/api/rooms?size=101' $null 406 2 $null | Out-Null
T 'R5.11' 'size=0 -> 406/2'              GET '/api/rooms?size=0'   $null 406 2 $null | Out-Null
T 'R5.12' 'page=-1 -> 406/2'             GET '/api/rooms?page=-1'  $null 406 2 $null | Out-Null
T 'R5.13' 'page=xyz (sai kieu) -> 406/2' GET '/api/rooms?page=xyz' $null 406 2 $null | Out-Null

# ---------------------------------------------------------- R1. POST /api/rooms
Section 'R1. POST /api/rooms - Create Room'
Reset-Db

T 'R1.1' 'day du hop le -> 201/1, tra RoomDTO, status mac dinh AVAILABLE' `
    POST '/api/rooms' '{"roomNumber":"Z-901","roomType":"DELUXE","pricePerNight":1234567.89,"capacity":4,"floor":9}' 201 1 {
    param($j)
    $bad = @()
    if ($null -eq $j.data) { return 'data null, phai tra RoomDTO' }
    if ($j.data.status -ne 'AVAILABLE') { $bad += "status=$($j.data.status) can AVAILABLE" }
    if ($null -eq $j.data.roomId) { $bad += 'roomId null' }
    if ($j.data.roomNumber -ne 'Z-901') { $bad += "roomNumber=$($j.data.roomNumber)" }
    return $bad
} | Out-Null

T 'R1.2' 'co gui status=OCCUPIED nhung create van phai ra AVAILABLE (Default status is AVAILABLE)' `
    POST '/api/rooms' '{"roomNumber":"Z-902","roomType":"SINGLE","pricePerNight":100000,"capacity":1,"floor":1,"status":"OCCUPIED"}' 201 1 {
    param($j)
    if ($j.data.status -ne 'AVAILABLE') { return "status=$($j.data.status) can AVAILABLE" }
    return $null
} | Out-Null

T 'R1.3'  'trung roomNumber -> 226/3'                POST '/api/rooms' '{"roomNumber":"A-101","roomType":"SINGLE","pricePerNight":100000,"capacity":1,"floor":1}' 226 3 $null | Out-Null
T 'R1.4'  'thieu roomNumber -> 406/2'                POST '/api/rooms' '{"roomType":"SINGLE","pricePerNight":100000,"capacity":1,"floor":1}' 406 2 $null | Out-Null
T 'R1.5'  'thieu roomType -> 406/2'                  POST '/api/rooms' '{"roomNumber":"Z-903","pricePerNight":100000,"capacity":1,"floor":1}' 406 2 $null | Out-Null
T 'R1.6'  'thieu pricePerNight -> 406/2'             POST '/api/rooms' '{"roomNumber":"Z-904","roomType":"SINGLE","capacity":1,"floor":1}' 406 2 $null | Out-Null
T 'R1.7'  'thieu capacity -> 406/2'                  POST '/api/rooms' '{"roomNumber":"Z-905","roomType":"SINGLE","pricePerNight":100000,"floor":1}' 406 2 $null | Out-Null
T 'R1.8'  'thieu floor -> 406/2'                     POST '/api/rooms' '{"roomNumber":"Z-906","roomType":"SINGLE","pricePerNight":100000,"capacity":1}' 406 2 $null | Out-Null
T 'R1.9'  'roomNumber 21 ky tu (max 20) -> 406/2'    POST '/api/rooms' '{"roomNumber":"XXXXXXXXXXXXXXXXXXXXX","roomType":"SINGLE","pricePerNight":100000,"capacity":1,"floor":1}' 406 2 $null | Out-Null
T 'R1.10' 'roomType=KING (ngoai enum) -> 406/2'      POST '/api/rooms' '{"roomNumber":"Z-907","roomType":"KING","pricePerNight":100000,"capacity":1,"floor":1}' 406 2 $null | Out-Null
T 'R1.11' 'pricePerNight=0 (CHECK >0) -> 406/2'      POST '/api/rooms' '{"roomNumber":"Z-908","roomType":"SINGLE","pricePerNight":0,"capacity":1,"floor":1}' 406 2 $null | Out-Null
T 'R1.12' 'pricePerNight=-5 -> 406/2'                POST '/api/rooms' '{"roomNumber":"Z-909","roomType":"SINGLE","pricePerNight":-5,"capacity":1,"floor":1}' 406 2 $null | Out-Null
T 'R1.13' 'capacity=0 (CHECK 1..10) -> 406/2'        POST '/api/rooms' '{"roomNumber":"Z-910","roomType":"SINGLE","pricePerNight":100000,"capacity":0,"floor":1}' 406 2 $null | Out-Null
T 'R1.14' 'capacity=11 (CHECK 1..10) -> 406/2'       POST '/api/rooms' '{"roomNumber":"Z-911","roomType":"SINGLE","pricePerNight":100000,"capacity":11,"floor":1}' 406 2 $null | Out-Null
T 'R1.15' 'floor=0 (CHECK >=1) -> 406/2'             POST '/api/rooms' '{"roomNumber":"Z-912","roomType":"SINGLE","pricePerNight":100000,"capacity":1,"floor":0}' 406 2 $null | Out-Null
T 'R1.16' 'capacity sai kieu ("abc") -> 406/2'       POST '/api/rooms' '{"roomNumber":"Z-913","roomType":"SINGLE","pricePerNight":100000,"capacity":"abc","floor":1}' 406 2 $null | Out-Null
T 'R1.17' 'JSON hong -> 406/2, khong duoc 500'       POST '/api/rooms' '{"roomNumber":' 406 2 $null | Out-Null
T 'R1.18' 'status ngoai enum -> 406/2'               POST '/api/rooms' '{"roomNumber":"Z-914","roomType":"SINGLE","pricePerNight":100000,"capacity":1,"floor":1,"status":"BROKEN"}' 406 2 $null | Out-Null

# ---------------------------------------------------------- R3. GET /api/rooms/{id}
Section 'R3. GET /api/rooms/{roomId} - Get Room Detail'
Reset-Db

T 'R3.1' 'id ton tai -> 200/1, RoomDTO dung du lieu seed' `
    GET '/api/rooms/1' $null 200 1 {
    param($j)
    $bad = @()
    if ($j.data.roomNumber -ne 'A-101') { $bad += "roomNumber=$($j.data.roomNumber) can A-101" }
    if ($j.data.roomType -ne 'DOUBLE') { $bad += "roomType=$($j.data.roomType) can DOUBLE" }
    if ([decimal]$j.data.pricePerNight -ne [decimal]850000) { $bad += "pricePerNight=$($j.data.pricePerNight) can 850000" }
    if ($j.data.capacity -ne 2) { $bad += "capacity=$($j.data.capacity) can 2" }
    return $bad
} | Out-Null

T 'R3.2' 'id khong ton tai -> 404/4'   GET '/api/rooms/999999' $null 404 4 $null | Out-Null
T 'R3.3' 'id sai kieu (/abc) -> 406/2' GET '/api/rooms/abc'    $null 406 2 $null | Out-Null

# ---------------------------------------------------------- R2. PUT /api/rooms/{id}
Section 'R2. PUT /api/rooms/{roomId} - Update Room'
Reset-Db

T 'R2.1' 'partial update 1 field -> 200/1, field khac GIU NGUYEN' `
    PUT '/api/rooms/1' '{"pricePerNight":999000}' 200 1 {
    param($j)
    $bad = @()
    if ([decimal]$j.data.pricePerNight -ne [decimal]999000) { $bad += "pricePerNight=$($j.data.pricePerNight) can 999000" }
    if ($j.data.roomNumber -ne 'A-101') { $bad += "roomNumber bi mat: $($j.data.roomNumber)" }
    if ($j.data.roomType -ne 'DOUBLE') { $bad += "roomType bi mat: $($j.data.roomType)" }
    if ($j.data.capacity -ne 2) { $bad += "capacity bi mat: $($j.data.capacity)" }
    if ($j.data.floor -ne 1) { $bad += "floor bi mat: $($j.data.floor)" }
    return $bad
} | Out-Null

T 'R2.2' 'update status -> 200/1'                        PUT '/api/rooms/2' '{"status":"OCCUPIED"}' 200 1 { param($j) if ($j.data.status -ne 'OCCUPIED') { return "status=$($j.data.status)" } } | Out-Null
T 'R2.3' 'giu nguyen roomNumber cua chinh minh -> 200/1' PUT '/api/rooms/1' '{"roomNumber":"A-101","floor":5}' 200 1 $null | Out-Null
T 'R2.4' 'doi roomNumber trung row khac -> 226/3'        PUT '/api/rooms/1' '{"roomNumber":"A-102"}' 226 3 $null | Out-Null
T 'R2.5' 'id khong ton tai -> 404/4'                     PUT '/api/rooms/999999' '{"floor":2}' 404 4 $null | Out-Null
T 'R2.6' 'roomType ngoai enum -> 406/2'                  PUT '/api/rooms/1' '{"roomType":"KING"}' 406 2 $null | Out-Null
T 'R2.7' 'capacity=11 -> 406/2'                          PUT '/api/rooms/1' '{"capacity":11}' 406 2 $null | Out-Null
T 'R2.8' 'pricePerNight=0 -> 406/2'                      PUT '/api/rooms/1' '{"pricePerNight":0}' 406 2 $null | Out-Null
T 'R2.9' 'floor=0 -> 406/2'                              PUT '/api/rooms/1' '{"floor":0}' 406 2 $null | Out-Null
T 'R2.10' 'roomNumber 21 ky tu -> 406/2'                 PUT '/api/rooms/1' '{"roomNumber":"XXXXXXXXXXXXXXXXXXXXX"}' 406 2 $null | Out-Null
T 'R2.11' 'id sai kieu (/abc) -> 406/2'                  PUT '/api/rooms/abc' '{"floor":2}' 406 2 $null | Out-Null

# ---------------------------------------------------------- R4. DELETE /api/rooms/{id}
Section 'R4. DELETE /api/rooms/{roomId} - Set Room to Maintenance'
Reset-Db

T 'R4.1' 'xoa mem -> 200/1 va data phai NULL (No data returned)' `
    DELETE '/api/rooms/1' $null 200 1 {
    param($j)
    if ($null -ne $j.data) { return "data khong null: $($j.data | ConvertTo-Json -Compress)" }
    return $null
} | Out-Null

T 'R4.2' 'get lai sau delete -> status = MAINTENANCE, row VAN CON' `
    GET '/api/rooms/1' $null 200 1 {
    param($j)
    if ($j.data.status -ne 'MAINTENANCE') { return "status=$($j.data.status) can MAINTENANCE" }
    return $null
} | Out-Null

T 'R4.3' 'id khong ton tai -> 404/4' DELETE '/api/rooms/999999' $null 404 4 $null | Out-Null

# =====================================================================================
# RESERVATION SERVICE
# =====================================================================================

# ---------------------------------------------------------- V5. GET /api/reservations
Section 'V5. GET /api/reservations - Get Reservation List'
Reset-Db

T 'V5.1' 'default -> 200/1, PageDTO du 7 field (KHONG phai DTO list rieng), totalElements=5' `
    GET '/api/reservations' $null 200 1 {
    param($j)
    $p = $j.data
    $bad = @()
    foreach ($f in 'size', 'page', 'totalPages', 'totalElements', 'first', 'last', 'content') {
        if (-not (Has $p $f)) { $bad += "PageDTO thieu field '$f'" }
    }
    if ((Has $p 'totalElements') -and $p.totalElements -ne 5) { $bad += "totalElements=$($p.totalElements) can 5" }
    if ((Has $p 'size') -and $p.size -ne 10) { $bad += "size=$($p.size) can 10" }
    return $bad
} | Out-Null

T 'V5.2' 'content phai la ReservationDetailDTO: co room NESTED, KHONG co roomId, co status' `
    GET '/api/reservations?size=1' $null 200 1 {
    param($j)
    $row = $j.data.content[0]
    $bad = @()
    foreach ($f in 'reservationId', 'guestName', 'guestEmail', 'guestPhone', 'checkInDate', 'checkOutDate', 'numberOfGuests', 'totalAmount', 'status', 'room') {
        if (-not (Has $row $f)) { $bad += "ReservationDetailDTO thieu '$f'" }
    }
    if (Has $row 'roomId') { $bad += "co field thua 'roomId' (DetailDTO chi duoc co 'room')" }
    if ((Has $row 'status') -and $null -eq $row.status) { $bad += 'status = null (mapper quen set)' }
    if ((Has $row 'room') -and $null -eq $row.room) { $bad += 'room = null (khong goi duoc RoomService)' }
    if ((Has $row 'room') -and $null -ne $row.room -and $null -eq $row.room.roomNumber) { $bad += 'room.roomNumber null' }
    return $bad
} | Out-Null

T 'V5.3' 'checkInDate trong response dung format dd/MM/yyyy' `
    GET '/api/reservations?size=1' $null 200 1 {
    param($j)
    $d = $j.data.content[0].checkInDate
    if ("$d" -notmatch '^\d{2}/\d{2}/\d{4}$') { return "checkInDate='$d' sai format dd/MM/yyyy" }
    return $null
} | Out-Null

T 'V5.4' 'guestName=van an (partial, khong phan biet hoa thuong) -> 2 row' `
    GET '/api/reservations?guestName=van%20an' $null 200 1 {
    param($j)
    if ($j.data.totalElements -ne 2) { return "totalElements=$($j.data.totalElements) can 2 (Nguyen Van An + Hoang Van An)" }
    return $null
} | Out-Null

T 'V5.4b' 'guestName=an khop 4 row (partial match that su, khong phai prefix/exact)' `
    GET '/api/reservations?guestName=an' $null 200 1 {
    param($j)
    if ($j.data.totalElements -ne 4) { return "totalElements=$($j.data.totalElements) can 4 (An, Tran, Van, Hoang Van An)" }
    return $null
} | Out-Null

T 'V5.5' 'guestName khong khop -> 200/1 rong' `
    GET '/api/reservations?guestName=zzzznomatch' $null 200 1 {
    param($j)
    if ($j.data.totalElements -ne 0) { return "totalElements=$($j.data.totalElements) can 0 (filter dang bi bo qua)" }
    return $null
} | Out-Null

T 'V5.6' 'status=CONFIRMED -> 2 row' `
    GET '/api/reservations?status=CONFIRMED' $null 200 1 {
    param($j)
    $bad = @()
    if ($j.data.totalElements -ne 2) { $bad += "totalElements=$($j.data.totalElements) can 2" }
    foreach ($r in $j.data.content) { if ($r.status -ne 'CONFIRMED') { $bad += "lot row status=$($r.status)" } }
    return $bad
} | Out-Null

T 'V5.7'  'status=BOGUS (Enum sai) -> 406/2' GET '/api/reservations?status=BOGUS' $null 406 2 $null | Out-Null
T 'V5.8'  'size=101 -> 406/2'                GET '/api/reservations?size=101'     $null 406 2 $null | Out-Null
T 'V5.9'  'size=0 -> 406/2'                  GET '/api/reservations?size=0'       $null 406 2 $null | Out-Null
T 'V5.10' 'page=-1 -> 406/2'                 GET '/api/reservations?page=-1'      $null 406 2 $null | Out-Null
T 'V5.11' 'page=xyz -> 406/2'                GET '/api/reservations?page=xyz'     $null 406 2 $null | Out-Null

# ---------------------------------------------------------- V1. POST /api/reservations
Section 'V1. POST /api/reservations - Create Reservation'
Reset-Db

T 'V1.1' 'hop le room 1 (AVAILABLE, price 850000, 01/08->05/08 = 4 dem) -> 201/1, CONFIRMED, totalAmount=3400000' `
    POST '/api/reservations' '{"guestName":"Test Guest","guestEmail":"guest@example.com","guestPhone":"0912345678","checkInDate":"01/08/2026","checkOutDate":"05/08/2026","numberOfGuests":2,"roomId":1}' 201 1 {
    param($j)
    $bad = @()
    if ($null -eq $j.data) { return 'data null, phai tra ReservationDTO' }
    if ($j.data.status -ne 'CONFIRMED') { $bad += "status=$($j.data.status) can CONFIRMED" }
    if ([decimal]$j.data.totalAmount -ne [decimal]3400000) { $bad += "totalAmount=$($j.data.totalAmount) can 3400000 (850000 x 4 dem)" }
    if (-not (Has $j.data 'roomId')) { $bad += "ReservationDTO (create) phai co roomId PHANG" }
    if ($null -eq $j.data.reservationId) { $bad += 'reservationId null' }
    return $bad
} | Out-Null

T 'V1.2' 'KHONG gui totalAmount van phai 201 (server tu tinh)' `
    POST '/api/reservations' '{"guestName":"No Amount","guestEmail":"na@example.com","guestPhone":"0912345679","checkInDate":"10/08/2026","checkOutDate":"12/08/2026","numberOfGuests":1,"roomId":2}' 201 1 {
    param($j)
    if ([decimal]$j.data.totalAmount -ne [decimal]1000000) { return "totalAmount=$($j.data.totalAmount) can 1000000 (500000 x 2 dem)" }
    return $null
} | Out-Null

T 'V1.3' 'client gui totalAmount bay -> server phai TINH LAI, khong tin client' `
    POST '/api/reservations' '{"guestName":"Fake Amount","guestEmail":"fa@example.com","guestPhone":"0912345680","checkInDate":"10/08/2026","checkOutDate":"12/08/2026","numberOfGuests":1,"totalAmount":1,"roomId":2}' 201 1 {
    param($j)
    if ([decimal]$j.data.totalAmount -ne [decimal]1000000) { return "totalAmount=$($j.data.totalAmount) can 1000000" }
    return $null
} | Out-Null

T 'V1.4' 'roomId khong ton tai -> 404/4' `
    POST '/api/reservations' '{"guestName":"Ghost Room","guestEmail":"gr@example.com","guestPhone":"0912345681","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":999999}' 404 4 $null | Out-Null

T 'V1.5' 'room 3 dang OCCUPIED -> 400/5' `
    POST '/api/reservations' '{"guestName":"Occupied","guestEmail":"oc@example.com","guestPhone":"0912345682","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":3}' 400 5 $null | Out-Null

T 'V1.6' 'room 4 dang MAINTENANCE -> 400/5' `
    POST '/api/reservations' '{"guestName":"Maint","guestEmail":"mt@example.com","guestPhone":"0912345683","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":4}' 400 5 $null | Out-Null

T 'V1.7' 'numberOfGuests=5 VUOT capacity cua room 1 (=2) -> 406/2' `
    POST '/api/reservations' '{"guestName":"Too Many","guestEmail":"tm@example.com","guestPhone":"0912345684","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":5,"roomId":1}' 406 2 $null | Out-Null

T 'V1.8' 'numberOfGuests=2 = dung capacity room 1 -> 201/1 (bien tren hop le)' `
    POST '/api/reservations' '{"guestName":"Exact Cap","guestEmail":"ec@example.com","guestPhone":"0912345685","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":2,"roomId":1}' 201 1 $null | Out-Null

T 'V1.9'  'checkOutDate = checkInDate -> 406/2'      POST '/api/reservations' '{"guestName":"Same Day","guestEmail":"sd@example.com","guestPhone":"0912345686","checkInDate":"01/08/2026","checkOutDate":"01/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.10' 'checkOutDate TRUOC checkInDate -> 406/2'  POST '/api/reservations' '{"guestName":"Reverse","guestEmail":"rv@example.com","guestPhone":"0912345687","checkInDate":"05/08/2026","checkOutDate":"01/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.11' 'ngay sai format (2026-08-01) -> 406/2'    POST '/api/reservations' '{"guestName":"Bad Fmt","guestEmail":"bf@example.com","guestPhone":"0912345688","checkInDate":"2026-08-01","checkOutDate":"05/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.12' 'ngay khong ton tai (31/02/2026) -> 406/2' POST '/api/reservations' '{"guestName":"Bad Day","guestEmail":"bd@example.com","guestPhone":"0912345689","checkInDate":"31/02/2026","checkOutDate":"05/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.13' 'thieu guestName -> 406/2'                 POST '/api/reservations' '{"guestEmail":"x@example.com","guestPhone":"0912345690","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.14' 'thieu guestEmail -> 406/2'                POST '/api/reservations' '{"guestName":"No Mail","guestPhone":"0912345691","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.15' 'email sai format -> 406/2'                POST '/api/reservations' '{"guestName":"Bad Mail","guestEmail":"khong-phai-email","guestPhone":"0912345692","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.16' 'thieu guestPhone -> 406/2'                POST '/api/reservations' '{"guestName":"No Phone","guestEmail":"np@example.com","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.17' 'thieu checkInDate -> 406/2'               POST '/api/reservations' '{"guestName":"No In","guestEmail":"ni@example.com","guestPhone":"0912345693","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.18' 'thieu checkOutDate -> 406/2'              POST '/api/reservations' '{"guestName":"No Out","guestEmail":"no@example.com","guestPhone":"0912345694","checkInDate":"01/08/2026","numberOfGuests":1,"roomId":1}' 406 2 $null | Out-Null
T 'V1.19' 'thieu numberOfGuests -> 406/2'            POST '/api/reservations' '{"guestName":"No Guests","guestEmail":"ng@example.com","guestPhone":"0912345695","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","roomId":1}' 406 2 $null | Out-Null
T 'V1.20' 'numberOfGuests=0 (CHECK >=1) -> 406/2'    POST '/api/reservations' '{"guestName":"Zero","guestEmail":"zr@example.com","guestPhone":"0912345696","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":0,"roomId":1}' 406 2 $null | Out-Null
T 'V1.21' 'thieu roomId -> 406/2'                    POST '/api/reservations' '{"guestName":"No Room","guestEmail":"nr@example.com","guestPhone":"0912345697","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1}' 406 2 $null | Out-Null
T 'V1.22' 'guestName 101 ky tu (max 100) -> 406/2'   POST ('/api/reservations') ('{"guestName":"' + ('X' * 101) + '","guestEmail":"gn@example.com","guestPhone":"0912345698","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":1}') 406 2 $null | Out-Null
T 'V1.23' 'guestPhone 21 ky tu (max 20) -> 406/2'    POST ('/api/reservations') ('{"guestName":"Long Phone","guestEmail":"lp@example.com","guestPhone":"' + ('9' * 21) + '","checkInDate":"01/08/2026","checkOutDate":"03/08/2026","numberOfGuests":1,"roomId":1}') 406 2 $null | Out-Null
T 'V1.24' 'JSON hong -> 406/2, khong duoc 500'       POST '/api/reservations' '{"guestName":' 406 2 $null | Out-Null

# ---------------------------------------------------------- V3. GET /api/reservations/{id}
Section 'V3. GET /api/reservations/{reservationId} - Get Reservation Detail'
Reset-Db

T 'V3.1' 'id ton tai -> 200/1, tra ReservationDetailDTO (room NESTED, khong co roomId)' `
    GET '/api/reservations/1' $null 200 1 {
    param($j)
    $d = $j.data
    $bad = @()
    if ($null -eq $d) { return 'data null' }
    if (-not (Has $d 'room')) { $bad += "thieu field 'room' - dang tra ReservationDTO phang thay vi ReservationDetailDTO" }
    if (Has $d 'roomId') { $bad += "co field thua 'roomId' - DetailDTO chi duoc co 'room'" }
    if ((Has $d 'room') -and $null -ne $d.room) {
        if ($d.room.roomNumber -ne 'A-101') { $bad += "room.roomNumber=$($d.room.roomNumber) can A-101" }
        if ($d.room.capacity -ne 2) { $bad += "room.capacity=$($d.room.capacity) can 2" }
    }
    if ($d.status -ne 'CONFIRMED') { $bad += "status=$($d.status) can CONFIRMED" }
    if ($d.guestName -ne 'Nguyen Van An') { $bad += "guestName=$($d.guestName)" }
    return $bad
} | Out-Null

T 'V3.2' 'id khong ton tai -> 404/4'   GET '/api/reservations/999999' $null 404 4 $null | Out-Null
T 'V3.3' 'id sai kieu (/abc) -> 406/2' GET '/api/reservations/abc'    $null 406 2 $null | Out-Null

# ---------------------------------------------------------- V2. PUT /api/reservations/{id}
Section 'V2. PUT /api/reservations/{reservationId} - Update Reservation'
Reset-Db

T 'V2.1' 'partial update guestName -> 200/1, tra ReservationDTO PHANG, field khac giu nguyen' `
    PUT '/api/reservations/1' '{"guestName":"Da Doi Ten"}' 200 1 {
    param($j)
    $d = $j.data
    $bad = @()
    if ($d.guestName -ne 'Da Doi Ten') { $bad += "guestName=$($d.guestName)" }
    if ($d.guestEmail -ne 'an@example.com') { $bad += "guestEmail bi mat: $($d.guestEmail)" }
    if ($d.numberOfGuests -ne 2) { $bad += "numberOfGuests bi mat: $($d.numberOfGuests)" }
    if (-not (Has $d 'roomId')) { $bad += "update phai tra ReservationDTO co roomId PHANG" }
    return $bad
} | Out-Null

T 'V2.2' 'update status -> CHECKED_IN -> 200/1' `
    PUT '/api/reservations/1' '{"status":"CHECKED_IN"}' 200 1 {
    param($j) if ($j.data.status -ne 'CHECKED_IN') { return "status=$($j.data.status)" }
} | Out-Null

T 'V2.3' 'update ngay -> 200/1' PUT '/api/reservations/1' '{"checkInDate":"10/09/2026","checkOutDate":"15/09/2026"}' 200 1 $null | Out-Null
T 'V2.4' 'id khong ton tai -> 404/4' PUT '/api/reservations/999999' '{"guestName":"X"}' 404 4 $null | Out-Null
T 'V2.5' 'status ngoai enum -> 406/2' PUT '/api/reservations/1' '{"status":"BROKEN"}' 406 2 $null | Out-Null
T 'V2.6' 'checkOut truoc checkIn -> 406/2' PUT '/api/reservations/1' '{"checkInDate":"20/09/2026","checkOutDate":"10/09/2026"}' 406 2 $null | Out-Null
T 'V2.7' 'guestName 101 ky tu -> 406/2' PUT ('/api/reservations/1') ('{"guestName":"' + ('X' * 101) + '"}') 406 2 $null | Out-Null
T 'V2.8' 'email sai format -> 406/2' PUT '/api/reservations/1' '{"guestEmail":"sai-email"}' 406 2 $null | Out-Null
T 'V2.9' 'numberOfGuests=0 -> 406/2' PUT '/api/reservations/1' '{"numberOfGuests":0}' 406 2 $null | Out-Null
T 'V2.10' 'doi sang roomId khong ton tai -> 404/4' PUT '/api/reservations/1' '{"roomId":999999}' 404 4 $null | Out-Null
T 'V2.11' 'id sai kieu (/abc) -> 406/2' PUT '/api/reservations/abc' '{"guestName":"X"}' 406 2 $null | Out-Null

# ---------------------------------------------------------- V4. DELETE /api/reservations/{id}
Section 'V4. DELETE /api/reservations/{reservationId} - Cancel Reservation'
Reset-Db

T 'V4.1' 'huy -> 200/1 va data phai NULL (No data returned)' `
    DELETE '/api/reservations/1' $null 200 1 {
    param($j) if ($null -ne $j.data) { return "data khong null" }
} | Out-Null

T 'V4.2' 'get lai sau huy -> status = CANCELLED, row VAN CON' `
    GET '/api/reservations/1' $null 200 1 {
    param($j) if ($j.data.status -ne 'CANCELLED') { return "status=$($j.data.status) can CANCELLED" }
} | Out-Null

T 'V4.3' 'id khong ton tai -> 404/4' DELETE '/api/reservations/999999' $null 404 4 $null | Out-Null

# =====================================================================================
# TONG KET
# =====================================================================================
Reset-Db

$pass = @($script:Results | Where-Object { $_.Ok }).Count
$fail = @($script:Results | Where-Object { -not $_.Ok }).Count
$total = $script:Results.Count

Write-Host ""
Write-Host "=======================================================" -ForegroundColor White
Write-Host ("TONG: {0} test | PASS {1} | FAIL {2}" -f $total, $pass, $fail) -ForegroundColor White
if ($total -gt 0) {
    $pct = [math]::Round(100.0 * $pass / $total, 1)
    Write-Host ("Ti le dat: {0}%" -f $pct) -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
}
Write-Host "=======================================================" -ForegroundColor White

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "DANH SACH FAIL:" -ForegroundColor Red
    $script:Results | Where-Object { -not $_.Ok } | ForEach-Object {
        Write-Host ("  {0,-7} [{1}] {2}" -f $_.Id, $_.Section.Split('.')[0], $_.Desc) -ForegroundColor Red
        Write-Host ("          {0}" -f $_.Detail) -ForegroundColor Yellow
    }
}

$outCsv = Join-Path $PSScriptRoot 'test-results.csv'
$script:Results | Select-Object Section, Id, Desc, Ok, Http, Detail | Export-Csv -Path $outCsv -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "Chi tiet da ghi ra: $outCsv" -ForegroundColor DarkGray

if ($fail -gt 0) { exit 1 } else { exit 0 }
