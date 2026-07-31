# =====================================================================
#  gen-all.ps1 - Dien MOT LAN o day roi chay, khoi go tham so terminal.
#
#  Goi gen-from-entity.ps1 theo dung thu tu: Master -> entity phu -> Detail,
#  VA ap bang ma HTTP cua de vao GlobalExceptionHandler cua ca 2 service.
#
#  Service nao CHUA dan entity (IntelliJ generate) thi BO QUA voi thong bao
#  - dan xong chay lai file nay, cac phan da sinh chay lai khong hong gi.
#
#  Cach dung:  powershell -ExecutionPolicy Bypass -File .\gen-all.ps1 [-DryRun]
#              powershell -ExecutionPolicy Bypass -File .\gen-all.ps1 -HttpOnly
#                 ^ chi ap lai bang ma HTTP, khong sinh lai entity/DTO
# =====================================================================
param([switch]$DryRun, [switch]$HttpOnly)

# ================= DIEN THEO DE (xem BUOC 0 trong DOI-TEN-TUNG-BUOC.md) =================
$Root = "e:\fpt_university\Semester8\MSS301\PE\EXAM"
$SizeOverMax = "error"   # size vuot max: "error" = <ma validation>/2 | "clamp" = ep ve max | "" = giu nguyen

# --- BANG MA HTTP: CHEP TU COT "HTTP Code" TRONG BANG Response Behavior CUA DE ---
#     De Trial + PE1 dung 400 cho TAT CA. De SU26 PE1 (Room/Reservation) dung 406/226/404/400.
#     DIEN SO NGUYEN cho de doc; script tu doi sang hang so HttpStatus cua Spring.
#     Ma la dong nao trong bang -> status trong body la so nao:
$HttpValidation = 406   # status 2 - Data validation failed
$HttpDuplicate  = 226   # status 3 - ... is duplicated
$HttpNotFound   = 404   # status 4 - ... is not found
$HttpBusiness   = 400   # status 5 - nhanh nghiep vu rieng cua de (vd "Room is not AVAILABLE")
$HttpError      = 500   # status 0 - internal server error

# Message cua nhanh 406/validation: $true = luon tra dung cau chu duoi day (khop de),
# $false = tra chi tiet loi tung field (de debug nhung lech cau chu de).
$ValidationMessageIsFixed = $true
$ValidationMessage        = "Data validation failed"

# --- Master (project bi goi, 8081) ---
$MasterService = "Room"
$MasterRename  = ""   # bang DTO cua de: ten_cot=tenFieldDTO, "" neu khong co
$MasterFilter  = "roomType,status"                # bang Query Parameters: param hoac param=field (TRAI=ten param URL, PHAI=field entity), "" = tu doan
$MasterUnique  = "roomNumber"                     # field check trung theo de, "" = tu doan tu UNIQUE cua DB
$MasterStatus  = "AVAILABLE,OCCUPIED,MAINTENANCE" # CHECK constraint status, "" = ACTIVE,INACTIVE
$MasterRules   = @(                               # rule validation THEO FIELD tu bang mo ta cua de, @() neu khong co
    @{ f = 'roomType';      enum = 'SINGLE,DOUBLE,SUITE,DELUXE' }
    @{ f = 'pricePerNight'; numMinExclusive = 0; msg = 'pricePerNight must be greater than 0' }
    @{ f = 'capacity';      numMin = 1; numMax = 10; msg = 'capacity must be between 1 and 10' }
    @{ f = 'floor';         numMin = 1; msg = 'floor must be greater than or equal to 1' }
)

# --- Entity phu trong project Master ("" neu de khong co) ---
$SubEntity     = ""

# --- Detail (project goi Feign, 8082) ---
$DetailService = "Reservation"
$DetailRename  = ""
$DetailFilter  = "guestName,status"
$DetailUnique  = ""
$DetailStatus  = "CONFIRMED,CHECKED_IN,CHECKED_OUT,CANCELLED"
$DetailShape   = "B"   # bang DTO cua de: B = phang + DTO nested rieng | C = 1 DTO chi co object nested | A = phang het
$DetailRules   = @(
    @{ f = 'guestEmail';     email = $true; msg = 'guestEmail is invalid' }
    @{ f = 'numberOfGuests'; numMin = 1; numMax = 10; msg = 'numberOfGuests must be between 1 and 10' }
)
# Cac key rule: pattern='regex' | email=$true | enum='A,B,C' | numMin=N | numMax=N | numMinExclusive=N
#               dateMin='yyyy-MM-dd' (after, exclusive) | dateMax='yyyy-MM-dd' (before)
#               dateMaxDays=N (before today+N) | noFuture=$true | futureOnly=$true
#               msg='message copy Y NGUYEN cau chu de' (khong dien thi dung message mac dinh theo ten field)
#
# KHONG TU SINH DUOC - PHAI GO TAY VAO ServiceImpl (xem BUOC 3.5 trong DOI-TEN-TUNG-BUOC.md):
#   - Field COMPUTED (vd totalAmount = pricePerNight x so dem): server tu tinh, BO @NotNull o DTO.
#   - Rang buoc CHEO 2 FIELD (vd checkOutDate > checkInDate): check trong service.
#   - Rang buoc CHEO SERVICE (vd numberOfGuests <= room.capacity): check sau khi Feign tra ve.
#   - Nhanh status 5 rieng cua de: nem BusinessRuleException(...) trong service.
# =========================================================================================

$ErrorActionPreference = 'Stop'
$gen = Join-Path $PSScriptRoot 'gen-from-entity.ps1'
$ok = 0; $skip = 0; $fail = 0

# ---------------------------------------------------------------- bang ma HTTP

$HttpStatusName = @{
    200 = 'OK'; 201 = 'CREATED'; 202 = 'ACCEPTED'; 204 = 'NO_CONTENT'
    226 = 'IM_USED'
    400 = 'BAD_REQUEST'; 401 = 'UNAUTHORIZED'; 403 = 'FORBIDDEN'; 404 = 'NOT_FOUND'
    405 = 'METHOD_NOT_ALLOWED'; 406 = 'NOT_ACCEPTABLE'; 409 = 'CONFLICT'
    410 = 'GONE'; 415 = 'UNSUPPORTED_MEDIA_TYPE'; 422 = 'UNPROCESSABLE_ENTITY'
    500 = 'INTERNAL_SERVER_ERROR'; 501 = 'NOT_IMPLEMENTED'; 503 = 'SERVICE_UNAVAILABLE'
}

function Resolve-HttpName($code) {
    if ($code -is [string] -and $code -notmatch '^\d+$') { return $code }   # da la ten hang so
    $n = [int]$code
    if ($HttpStatusName.ContainsKey($n)) { return $HttpStatusName[$n] }
    throw "Ma HTTP $n chua co trong bang \$HttpStatusName - them vao dau file gen-all.ps1."
}

function Set-HttpCodes {
    $names = @{
        HTTP_VALIDATION = Resolve-HttpName $HttpValidation
        HTTP_DUPLICATE  = Resolve-HttpName $HttpDuplicate
        HTTP_NOT_FOUND  = Resolve-HttpName $HttpNotFound
        HTTP_BUSINESS   = Resolve-HttpName $HttpBusiness
        HTTP_ERROR      = Resolve-HttpName $HttpError
    }

    $handlers = @(Get-ChildItem -Path $Root -Recurse -Filter 'GlobalExceptionHandler.java' -ErrorAction SilentlyContinue)
    if ($handlers.Count -eq 0) {
        Write-Host "KHONG TIM THAY GlobalExceptionHandler.java nao duoi $Root" -ForegroundColor Yellow
        return
    }

    foreach ($h in $handlers) {
        $text = Get-Content -LiteralPath $h.FullName -Raw
        $orig = $text
        $missing = @()

        foreach ($k in $names.Keys) {
            $pattern = "(private static final HttpStatus $k = HttpStatus\.)[A-Z_]+;"
            if ($text -match $pattern) {
                $text = [regex]::Replace($text, $pattern, "`${1}$($names[$k]);")
            } else {
                $missing += $k
            }
        }

        $text = [regex]::Replace($text,
            '(private static final boolean VALIDATION_MESSAGE_IS_FIXED = )(?:true|false);',
            "`${1}$(if ($ValidationMessageIsFixed) { 'true' } else { 'false' });")
        $text = [regex]::Replace($text,
            '(private static final String VALIDATION_MESSAGE = ")[^"]*(";)',
            "`${1}$ValidationMessage`${2}")

        if ($missing.Count -gt 0) {
            Write-Host ("  ! {0}: khong thay hang so {1} - file nay chua theo mau bang dieu khien, sua tay." -f $h.Directory.Parent.Name, ($missing -join ', ')) -ForegroundColor Yellow
        }

        if ($text -ne $orig) {
            if ($DryRun) {
                Write-Host ("  [DryRun] se sua {0}" -f $h.FullName) -ForegroundColor DarkGray
            } else {
                # PHAI ghi UTF-8 KHONG BOM: Set-Content -Encoding UTF8 cua PowerShell 5.1 chen BOM,
                # javac khong nuot duoc BOM truoc tu khoa "package" -> ca file khong compile duoc.
                [System.IO.File]::WriteAllText($h.FullName, $text, (New-Object System.Text.UTF8Encoding($false)))
            }
            Write-Host ("  OK {0}" -f $h.FullName) -ForegroundColor Green
        } else {
            Write-Host ("  = {0} (da dung roi)" -f $h.FullName) -ForegroundColor DarkGray
        }
    }

    Write-Host ("  Bang ma: validation={0}/2  duplicate={1}/3  notFound={2}/4  business={3}/5  error={4}/0" -f `
        $HttpValidation, $HttpDuplicate, $HttpNotFound, $HttpBusiness, $HttpError) -ForegroundColor Cyan
}

# ---------------------------------------------------------------- sinh code

function Invoke-Gen([string]$svc, [string]$entity, [string]$ren, [string]$flt, [string]$uniq, [string]$status, [string]$shape, $rules) {
    $entityName = $entity
    if ($entityName -eq '') { $entityName = $svc }
    $file = Join-Path $Root "SE193114${svc}Service\src\main\java\fu\se193114\$($svc.ToLower())\entity\$entityName.java"
    if (-not (Test-Path $file)) {
        Write-Host "BO QUA $entityName - chua dan entity vao $file" -ForegroundColor Yellow
        Write-Host '        (IntelliJ generate tu DB, dan vao do, chay lai file nay)' -ForegroundColor Yellow
        $script:skip++
        return
    }
    $p = @{ Root = $Root; Service = $svc }
    if ($entity -ne '') { $p.EntityName = $entity }
    if ($ren -ne '')    { $p.Rename = $ren }
    if ($flt -ne '')    { $p.Filter = $flt }
    if ($uniq -ne '')   { $p.Unique = $uniq }
    if ($status -ne '') { $p.StatusEnum = $status }
    if ($shape -ne '')  { $p.DetailShape = $shape }
    if ($rules -and @($rules).Count -gt 0) { $p.Rules = @($rules) }
    if ($SizeOverMax -ne '') { $p.SizeOverMax = $SizeOverMax }
    if ($DryRun)        { $p.DryRun = $true }
    Write-Host ''
    Write-Host ("================ GEN " + $entityName + " ================") -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & $gen @p
    if ($LASTEXITCODE -ne 0) {
        Write-Host "LOI o $entityName - dung lai, sua roi chay lai." -ForegroundColor Red
        $script:fail++
    }
    else { $script:ok++ }
}

if (-not $HttpOnly) {
    Invoke-Gen $MasterService '' $MasterRename $MasterFilter $MasterUnique $MasterStatus '' $MasterRules
    if ($fail -eq 0 -and $SubEntity -ne '') { Invoke-Gen $MasterService $SubEntity '' '' '' '' '' @() }
    if ($fail -eq 0) { Invoke-Gen $DetailService '' $DetailRename $DetailFilter $DetailUnique $DetailStatus $DetailShape $DetailRules }
}

Write-Host ''
Write-Host '================ BANG MA HTTP ================' -ForegroundColor Cyan
Set-HttpCodes

if (-not $HttpOnly) {
    Write-Host ''
    Write-Host ("TONG KET: $ok sinh xong, $skip bo qua (chua co entity), $fail loi.") -ForegroundColor $(if ($fail -gt 0) { 'Red' } elseif ($skip -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host 'NHO GO TAY: field computed, rang buoc cheo 2 field, rang buoc cheo service, nhanh status 5.' -ForegroundColor Yellow
}
