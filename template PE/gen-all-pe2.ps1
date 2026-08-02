# =====================================================================
#  gen-all-pe2.ps1 - Ban rieng cho bai TRIAL (PE2 Restaurant/Food/Category).
#  Cung bo may voi gen-all.ps1 - file kia da chay muot cho de PE1, DUNG dung lai.
#
#  Goi gen-from-entity.ps1 theo dung thu tu: Master -> entity phu -> Detail.
#  Service nao CHUA dan entity (IntelliJ generate) thi BO QUA voi thong bao
#  - dan xong chay lai file nay, cac phan da sinh chay lai khong hong gi.
#
#  Cach dung:  powershell -ExecutionPolicy Bypass -File .\gen-all-pe2.ps1 [-DryRun]
# =====================================================================
param([switch]$DryRun)

# ================= DIEN THEO DE (xem BUOC 0 trong DOI-TEN-TUNG-BUOC.md) =================
$Root = "e:\fpt_university\Semester8\MSS301\PE\EXAM"   # doi neu rename-template do ra folder khac
$SizeOverMax = "error"   # size vuot max: "error" = 400/2 (mac dinh, Trial + 27/07 deu strict) | "clamp" = ep ve max | "" = giu nguyen

# --- Master (project bi goi, 8081) ---
$MasterService = "Restaurant"
$MasterRename  = "owner_name=owner"      # bang DTO cua de: "ten_cot=tenFieldDTO,cot2=field2", "" neu khong co (vd Trial: "owner_name=owner")
$MasterFilter  = "name,ownerName=owner"      # bang Query Parameters: "param" hoac "param=fieldEntity" (TRAI=ten param URL, PHAI=field), "" = tu doan
$MasterUnique  = "name"      # field check trung theo de, "" = tu doan tu cot UNIQUE cua DB
$MasterStatus  = "ACTIVE,INACTIVE"      # CHECK constraint status, "" = ACTIVE,INACTIVE
$MasterRules   = @(      # rule validation THEO FIELD tu cot Description cua de, @() neu khong co. Vi du cu phap:
    # @{ f = 'code';          pattern = '[A-Za-z0-9]+'; msg = 'copy y nguyen cau chu de' }
    # @{ f = 'email';         email = $true }
    # @{ f = 'position';      enum = 'Manager,Developer,Staff' }
    # @{ f = 'starRating';    numMin = 1; numMax = 5; msg = '...' }
    # @{ f = 'effectiveDate'; dateMin = '2000-01-01'; dateMaxDays = 360; msg = '...' }
)

# --- Entity phu trong project Master ("" neu de khong co) ---
$SubEntity     = "Category"

# --- Detail (project goi Feign, 8082) ---
$DetailService = "Food"
$DetailRename  = "ingredient=ingredients"      # vd Trial: "ingredient=ingredients"
$DetailFilter  = "name,ingredients"
$DetailUnique  = ""
$DetailStatus  = "ACTIVE,INACTIVE"
$DetailShape   = "B"     # bang DTO cua de: B = phang + list nested rieng (Trial) | C = 1 DTO chi co object nested | A = phang het
$DetailRules   = @()
# Cac key rule: pattern='regex' | email=$true | enum='A,B,C' | numMin=N | numMax=N
#               dateMin='yyyy-MM-dd' (after, exclusive) | dateMax='yyyy-MM-dd' (before) | dateMaxDays=N (before today+N)
#               noFuture=$true | futureOnly=$true
#               msg='message copy Y NGUYEN cau chu de' (khong dien thi dung message mac dinh theo ten field)
# =========================================================================================

$ErrorActionPreference = 'Stop'
$gen = Join-Path $PSScriptRoot 'gen-from-entity.ps1'
$ok = 0; $skip = 0; $fail = 0

function Invoke-Gen([string]$svc, [string]$entity, [string]$ren, [string]$flt, [string]$uniq, [string]$status, [string]$shape, $rules) {
    $entityName = $entity
    if ($entityName -eq '') { $entityName = $svc }
    $sid = Get-StudentId $Root
    $file = Join-Path $Root "$sid${svc}Service\src\main\java\fu\$($sid.ToLower())\$($svc.ToLower())\entity\$entityName.java"
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

Invoke-Gen $MasterService '' $MasterRename $MasterFilter $MasterUnique $MasterStatus '' $MasterRules
if ($fail -eq 0 -and $SubEntity -ne '') { Invoke-Gen $MasterService $SubEntity '' '' '' '' '' @() }
if ($fail -eq 0) { Invoke-Gen $DetailService '' $DetailRename $DetailFilter $DetailUnique $DetailStatus $DetailShape $DetailRules }

Write-Host ''
Write-Host ("TONG KET: $ok sinh xong, $skip bo qua (chua co entity), $fail loi.") -ForegroundColor $(if ($fail -gt 0) { 'Red' } elseif ($skip -gt 0) { 'Yellow' } else { 'Green' })
