# =====================================================================
#  gen-http.ps1 - Sinh bo file .http test tu DTO/entity/controller da co
#  Chay SAU gen-from-entity.ps1 (B5.5):
#    powershell -ExecutionPolicy Bypass -File .\gen-http.ps1
#  Tu phat hien project Master/Detail/controller phu trong $Root,
#  sinh vao $Root\http\ (nam NGOAI 3 project -> khong dinh bai nop):
#    http-client.env.json + <master>.http + <detail>.http (+ <phu>.http)
#  Mo bang IntelliJ, chon environment "gateway" (8080) de test dung duong cham.
#
#  V2 - tinh chinh tu 2 dot test that PE1 (Department/Employee) va PE2
#  (Restaurant/Food) ngay 27/07/2026. Cac cai tien so voi V1:
#    - Case 00 smoke: GET list dau tien; 500 tai day = entity/column lech
#      schema DB (vd cot 'ingredient' vs 'ingredients') hoac DB chua seed.
#    - Test trung (create + update) dung gia tri LUU TU RESPONSE
#      (client.global.set) -> chay lai bao nhieu lan cung dung, khong can
#      reset DB nhu bo test tay.
#    - Update: doi status hop le, status sai enum, doi unique trung row
#      khac, doi FK hop le / khong ton tai (Feign verify lai khi update
#      - PE1 case emp-12/13, PE2 case F09/F10).
#    - Create kem status trong body -> service phai ep ACTIVE.
#    - Detail: create theo ca 2 shape (FK phang + object nested) neu DTO
#      co field nested (bay PE1: employee nhan ca departmentId lan
#      department.departmentId).
#    - Field @Email -> test email sai format; field @Pattern d?ng enum
#      (A|B|C) ngoai status -> test gia tri ngoai enum (PE1 case emp-06);
#      field @Pattern charset -> test ky tu la (PE1 case dep-05).
#    - Bien ngay tu @ValidDate(min=..., maxDaysFromToday=...): dung bien
#      duoi (exclusive -> 400) va vuot bien tren (PE1 case dep-07/08).
#    - Get/list id-page sai kieu: /abc, ?page=xyz (deu 400/2).
#    - size=100 (bien hop le), size=101/1000 theo cong tac
#      SIZE_OVER_MAX_IS_ERROR, size=0, page=-1.
#  LUU Y CHAM DIEM: HTTP code + field "status" trong body la thu quyet
#  dinh pass/fail; message chi de doi chieu cau chu voi de (2 dot test
#  cho thay wording co the lech nhung van dung status map).
#  File ASCII thuan cho PowerShell 5.1.
# =====================================================================
param(
    [string]$Root = "e:\fpt_university\Semester8\MSS301\PE\EXAM",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$SidUpper = 'SE193114'
$SidLower = 'se193114'

if (-not (Test-Path $Root)) { Write-Host "LOI: khong thay $Root" -ForegroundColor Red; exit 1 }

function Get-Cap([string]$s) { return $s.Substring(0, 1).ToUpper() + $s.Substring(1) }

# --- Phat hien project ---
$services = @()
Get-ChildItem $Root -Directory | Where-Object { $_.Name -match "^$SidUpper(\w+)Service$" } | ForEach-Object {
    $name = [regex]::Match($_.Name, "^$SidUpper(\w+)Service$").Groups[1].Value
    $pkg = Join-Path $_.FullName "src\main\java\fu\$SidLower\$($name.ToLower())"
    if (Test-Path $pkg) {
        $client = Get-ChildItem (Join-Path $pkg 'repository') -Filter '*Client.java' -ErrorAction SilentlyContinue | Select-Object -First 1
        $services += [pscustomobject]@{ Name = $name; Pkg = $pkg; IsDetail = ($null -ne $client) }
    }
}
$master = $services | Where-Object { -not $_.IsDetail } | Select-Object -First 1
$detail = $services | Where-Object { $_.IsDetail } | Select-Object -First 1
if (-not $master) { Write-Host "LOI: khong tim thay project Master trong $Root" -ForegroundColor Red; exit 1 }

# --- Doc format ngay tu ValidDate cua Master ---
$datePattern = 'dd/MM/uuuu'; $goodDate = '20/05/2025'; $isoFallback = $true
$vd = Join-Path $master.Pkg 'common\ValidDate.java'
if (Test-Path $vd) {
    $t = [System.IO.File]::ReadAllText($vd)
    $m = [regex]::Match($t, 'ofPattern\("([^"]+)"\)')
    if ($m.Success) {
        $datePattern = $m.Groups[1].Value
        $goodDate = $datePattern.Replace('dd', '20').Replace('MM', '05').Replace('uuuu', '2025').Replace('yyyy', '2025')
    }
    $m = [regex]::Match($t, 'ACCEPT_ISO_FALLBACK\s*=\s*(true|false)')
    if ($m.Success) { $isoFallback = ($m.Groups[1].Value -eq 'true') }
}
# Spec format da la ISO thi khoi test "ISO fallback"
$specIsIso = $datePattern.StartsWith('uuuu') -or $datePattern.StartsWith('yyyy')

function Format-SpecDate([int]$d, [int]$mo, [int]$y) {
    return $datePattern.Replace('dd', ('{0:d2}' -f $d)).Replace('MM', ('{0:d2}' -f $mo)).Replace('uuuu', "$y").Replace('yyyy', "$y")
}

# --- Parse DTO ---
# Bat: mandatory, max length, regex, email, nested *DTO, @ValidDate args.
function Parse-Dto([string]$path) {
    $fields = New-Object System.Collections.ArrayList
    $buf = ''
    foreach ($line in ([System.IO.File]::ReadAllLines($path))) {
        $t = $line.Trim()
        if ($t.StartsWith('@')) { $buf += ' ' + $t; continue }
        # dong noi tiep cua annotation nhieu dong (vd "groups = {...})" cua @Pattern)
        if ($buf -ne '' -and $t -ne '' -and $t -notmatch '^(private|public|import|package|\})') { $buf += ' ' + $t; continue }
        $fm = [regex]::Match($t, '^private\s+(\w+)\s+(\w+)\s*;')
        if ($fm.Success) {
            $fname = $fm.Groups[2].Value; $ftype = $fm.Groups[1].Value
            $isNested = ($ftype -like '*DTO')
            $len = 0
            $lm = [regex]::Match($buf, '@Size\s*\([^)]*max\s*=\s*(\d+)')
            if ($lm.Success) { $len = [int]$lm.Groups[1].Value }
            $rx = ''
            $rm = [regex]::Match($buf, '@Pattern\s*\(\s*regexp\s*=\s*"((?:\\.|[^"\\])*)"')
            if ($rm.Success) { $rx = $rm.Groups[1].Value }
            $minDate = ''; $maxDays = 0
            $vm = [regex]::Match($buf, '@ValidDate\s*\(([^)]*)\)')
            if ($vm.Success) {
                $va = $vm.Groups[1].Value
                $mm = [regex]::Match($va, 'min\s*=\s*"([^"]+)"'); if ($mm.Success) { $minDate = $mm.Groups[1].Value }
                $md = [regex]::Match($va, 'maxDaysFromToday\s*=\s*(\d+)'); if ($md.Success) { $maxDays = [int]$md.Groups[1].Value }
            }
            [void]$fields.Add([pscustomobject]@{
                Name = $fname; Type = $ftype
                Mandatory = ($buf -match '@NotBlank|@NotNull'); MaxLen = $len
                IsStatus = ($fname -eq 'status'); IsDate = ($ftype -eq 'Date')
                IsEmail = (($buf -match '@Email') -or ($fname -imatch 'email'))
                IsNested = $isNested
                Regex = $rx; MinDate = $minDate; MaxDays = $maxDays
            })
            $buf = ''
        }
        elseif ($t -ne '' -and -not $t.StartsWith('import') -and -not $t.StartsWith('package')) { $buf = '' }
    }
    return $fields
}

function Get-UniqueField([string]$entityPath) {
    if (-not (Test-Path $entityPath)) { return $null }
    $t = [System.IO.File]::ReadAllText($entityPath)
    $m = [regex]::Match($t, 'unique\s*=\s*true[^;]*?private\s+\w+\s+(\w+);', 'Singleline')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

# Bat ca 2 kieu khai bao: @RequestParam(required=false) String x
# va @RequestParam(name="x", defaultValue="0") int page (kieu PE1)
function Get-ListParams([string]$controllerPath) {
    if (-not (Test-Path $controllerPath)) { return @() }
    $t = [System.IO.File]::ReadAllText($controllerPath)
    $names = @()
    foreach ($m in [regex]::Matches($t, '@RequestParam(?:\(([^)]*)\))?\s+(?:Integer|Long|String|int|long)\s+(\w+)')) {
        $n = $m.Groups[2].Value
        $inner = $m.Groups[1].Value
        $nm = [regex]::Match($inner, '(?:name|value)\s*=\s*"(\w+)"')
        if ($nm.Success) { $n = $nm.Groups[1].Value }
        if ($n -notin 'page', 'size') { $names += $n }
    }
    return ($names | Select-Object -Unique)
}

# Doc cong tac size>max trong ServiceImpl de sinh expect khop code
# (nhan ca code viet tay khong dung cong tac: throw thang khi pageSize > MAX)
function Get-SizeStrict([string]$pkg, [string]$name) {
    $svc = Join-Path $pkg "service\impl\${name}ServiceImpl.java"
    if (-not (Test-Path $svc)) { return $false }
    $t = [System.IO.File]::ReadAllText($svc)
    if ($t -match 'SIZE_OVER_MAX_IS_ERROR\s*=\s*true') { return $true }
    if ($t -notmatch 'SIZE_OVER_MAX_IS_ERROR' -and $t -match 'pageSize\s*>\s*MAX_PAGE_SIZE') { return $true }
    return $false
}

# Enum status: uu tien regex cua chinh field status, fallback quet file
function Get-StatusEnum($dtoFields, [string]$dtoPath) {
    $sf = $dtoFields | Where-Object { $_.IsStatus } | Select-Object -First 1
    if ($sf -and $sf.Regex -match '^[A-Z_]+(\|[A-Z_]+)+$') { return @($sf.Regex -split '\|') }
    $t = [System.IO.File]::ReadAllText($dtoPath)
    $m = [regex]::Match($t, '@Pattern\s*\(\s*regexp\s*=\s*"([A-Z_|]+)"')
    if ($m.Success) { return @($m.Groups[1].Value -split '\|') }
    return @('ACTIVE', 'INACTIVE')
}

function Get-SampleValue($f, [string]$svc) {
    if ($f.IsDate) { return '"' + $goodDate + '"' }
    if ($f.Type -in 'Integer', 'Long') {
        if ($f.Name -imatch 'id$') { return '1' }
        return '100'
    }
    if ($f.Type -eq 'String') {
        if ($f.Name -imatch 'phone') { $v = '0912345678' }
        elseif ($f.IsEmail) { $v = 'test@fpt.edu.vn' }
        elseif ($f.Regex -and $f.Regex -match '^[A-Za-z0-9_ ]+(\|[A-Za-z0-9_ ]+)+$') { $v = ($f.Regex -split '\|')[0] }
        elseif ($f.Regex) { $v = 'Abc123' }
        else { $v = 'Test ' + (Get-Cap $f.Name) }
        if ($f.MaxLen -gt 0 -and $v.Length -gt $f.MaxLen) { $v = $v.Substring(0, $f.MaxLen) }
        return '"' + $v + '"'
    }
    return '1'
}

function Build-Body($fields, [string]$svc, [hashtable]$override, [string[]]$skip, [string[]]$extraLines) {
    $lines = @()
    foreach ($f in $fields) {
        if ($f.IsNested) { continue }
        if ($f.Name -in $skip) { continue }
        if ($override.ContainsKey($f.Name)) { $v = $override[$f.Name] }
        else { $v = Get-SampleValue $f $svc }
        if ($null -eq $v) { continue }
        $lines += '  "' + $f.Name + '": ' + $v
    }
    if ($extraLines) { $lines += $extraLines }
    return "{`r`n" + ($lines -join ",`r`n") + "`r`n}"
}

$generated = New-Object System.Collections.ArrayList
function Out-File2([string]$path, [string]$content) {
    [void]$generated.Add($path)
    if ($DryRun) { Write-Host "----- [DRY] $path -----" -ForegroundColor Cyan; Write-Host $content }
    else { [System.IO.File]::WriteAllText($path, $content); Write-Host ("  + " + $path) -ForegroundColor Green }
}

# =====================================================================
function New-ServiceHttp($svc, [switch]$IsDetail) {
    $name = $svc.Name
    $lower = $name.ToLower()
    $ctrl = Join-Path $svc.Pkg "controller\$SidUpper${name}Controller.java"
    $ctext = [System.IO.File]::ReadAllText($ctrl)
    $base = [regex]::Match($ctext, '@RequestMapping\("([^"]+)"\)').Groups[1].Value
    $dtoPath = Join-Path $svc.Pkg "dto\${name}DTO.java"
    $dto = Parse-Dto $dtoPath
    $pk = ($dto | Where-Object { $_.Name -ieq ($lower + 'id') } | Select-Object -First 1)
    if ($pk) { $pkName = $pk.Name } else { $pkName = ($dto | Where-Object { $_.Name -imatch 'id$' -and -not $_.IsNested } | Select-Object -First 1).Name }
    $body = @($dto | Where-Object { $_.Name -ne $pkName })
    $uniqueField = Get-UniqueField (Join-Path $svc.Pkg "entity\$name.java")
    if (-not $uniqueField) {
        $repoFile = Join-Path $svc.Pkg "repository\${name}Repository.java"
        if (Test-Path $repoFile) {
            $rm2 = [regex]::Match([System.IO.File]::ReadAllText($repoFile), 'boolean existsBy(\w+?)\(')
            if ($rm2.Success) {
                $g = $rm2.Groups[1].Value
                $uniqueField = $g.Substring(0, 1).ToLower() + $g.Substring(1)
            }
        }
    }
    $uf = $dto | Where-Object { $_.Name -eq $uniqueField } | Select-Object -First 1
    # Gia tri unique ngau nhien moi lan chay -> khong can reset DB.
    # Field co @Pattern/max ngan thi dung random.alphanumeric cho khop rang buoc.
    $uniqueVal = '"AutoTest {{$timestamp}}"'
    if ($uf -and ($uf.Regex -or ($uf.MaxLen -gt 0 -and $uf.MaxLen -lt 22))) {
        $rnd = 8
        if ($uf.MaxLen -gt 0 -and $uf.MaxLen -lt 8) { $rnd = $uf.MaxLen }
        $uniqueVal = '"{{$random.alphanumeric(' + $rnd + ')}}"'
    }
    $fks = @($body | Where-Object { $_.Name -imatch 'id$' -and -not $_.IsNested })
    $nested = $body | Where-Object { $_.IsNested } | Select-Object -First 1
    $nestedFk = $null
    if ($nested) { $nestedFk = $fks | Where-Object { $_.Name -ieq ($nested.Name + 'Id') } | Select-Object -First 1 }
    $listParams = Get-ListParams $ctrl
    $sizeStrict = Get-SizeStrict $svc.Pkg $name
    $statusEnum = Get-StatusEnum $dto $dtoPath
    $statusField = $body | Where-Object { $_.IsStatus } | Select-Object -First 1
    $dateField = $body | Where-Object { $_.IsDate } | Select-Object -First 1
    $urlVar = '{{masterUrl}}'
    if ($IsDetail) { $urlVar = '{{detailUrl}}' }
    $skipCreate = @('status')
    $idVar = $lower + 'Id'
    $dupVar = $lower + 'Dup'

    # Field String "an toan" cho update partial: khong regex/email/unique/status
    $firstStr = $body | Where-Object { $_.Type -eq 'String' -and -not $_.IsStatus -and -not $_.IsEmail -and -not $_.Regex -and $_.Name -ne $uniqueField } | Select-Object -First 1
    if (-not $firstStr) { $firstStr = $body | Where-Object { $_.Type -eq 'String' -and -not $_.IsStatus } | Select-Object -First 1 }
    $updVal = 'Updated Value'
    if ($firstStr -and $firstStr.MaxLen -gt 0 -and $updVal.Length -gt $firstStr.MaxLen) { $updVal = $updVal.Substring(0, $firstStr.MaxLen) }

    $L = New-Object System.Collections.ArrayList
    [void]$L.Add('### ============================================================')
    [void]$L.Add("###  $name ($base) - SINH boi gen-http.ps1 V2")
    [void]$L.Add('###  Status map: 1=OK  2=validation  3=duplicate  4=not found  0=500')
    [void]$L.Add('###  Not-found tra HTTP 400 (khong phai 404). Chon env "gateway" (8080).')
    [void]$L.Add('###  PASS/FAIL quyet dinh boi HTTP code + "status"; message chi doi chieu.')
    [void]$L.Add('###  Bo test TU CHUA du lieu (unique random + luu id/du gia tri tu response)')
    [void]$L.Add('###  -> chay lai nhieu lan van dung, KHONG can reset DB.')
    if ($fks.Count -gt 0) {
        [void]$L.Add("###  LUU Y: cac FK (" + (($fks | ForEach-Object { $_.Name }) -join ', ') + ") dang de = 1 - can co san row id=1 trong DB.")
    }
    [void]$L.Add('### ============================================================')
    [void]$L.Add('')
    $n = 0

    # 00 smoke - bai hoc tu PE2: 500 o day la schema DB lech entity
    [void]$L.Add('### 00. SMOKE - list mac dinh phai song truoc khi test gi khac')
    [void]$L.Add('# Expect: 200, status=1.')
    [void]$L.Add('# Neu 500/status=0: entity/@Column lech schema DB (vd cot "ingredient" vs')
    [void]$L.Add('# "ingredients"), DB chua chay init_db.sql, hoac sai datasource. Sua truoc da!')
    [void]$L.Add("GET $urlVar$base")
    [void]$L.Add('')

    # 01 create hop le (luu id de update/delete)
    $n++
    $ov = @{}
    if ($uniqueField) { $ov[$uniqueField] = $uniqueVal }
    [void]$L.Add("### $('{0:d2}' -f $n). Create hop le")
    [void]$L.Add('# Expect: 201, status=1, data.status="ACTIVE" (service tu set)')
    [void]$L.Add("POST $urlVar$base")
    [void]$L.Add('Content-Type: application/json')
    [void]$L.Add('')
    [void]$L.Add((Build-Body $body $name $ov $skipCreate $null))
    [void]$L.Add('')
    [void]$L.Add('> {% client.global.set("' + $idVar + '", response.body.data.' + $pkName + '); %}')
    [void]$L.Add('')

    # create kem status trong body -> phai bi ep ACTIVE
    if ($statusField) {
        $n++
        $sVal = 'INACTIVE'
        if ($statusEnum -notcontains 'INACTIVE') { $sVal = $statusEnum[$statusEnum.Count - 1] }
        $ovs = @{ status = '"' + $sVal + '"' }
        if ($uniqueField) { $ovs[$uniqueField] = $uniqueVal }
        [void]$L.Add("### $('{0:d2}' -f $n). Create KEM status=`"$sVal`" trong body")
        [void]$L.Add('# Expect: 201, status=1 va data.status="ACTIVE" - service phai EP, khong nhan tu client.')
        [void]$L.Add('# (Neu de ghi ro cam gui status -> co the la 400/2, doc de.)')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ovs @() $null))
        [void]$L.Add('')
    }

    # detail: create theo shape NESTED (bay PE1 employee: nhan ca 2 shape).
    # Neu FK phang co @NotNull(OnCreate) thi bean validation chan body nested-only
    # TRUOC khi service fallback chay -> expect phai la 400/2, khong phai 201.
    if ($IsDetail -and $nested -and $nestedFk) {
        $n++
        $ovn = @{}
        if ($uniqueField) { $ovn[$uniqueField] = $uniqueVal }
        $extra = @('  "' + $nested.Name + '": { "' + $nestedFk.Name + '": 1 }')
        [void]$L.Add("### $('{0:d2}' -f $n). Create voi $($nested.Name) NESTED (khong gui $($nestedFk.Name) phang)")
        if ($nestedFk.Mandatory) {
            [void]$L.Add("# Expect: 400, status=2 `"$($nestedFk.Name) is required`" - vi $($nestedFk.Name) phang dang @NotNull(OnCreate)")
            [void]$L.Add('# nen bean validation chan truoc khi service doc nested. NEU DE yeu cau nhan ca 2 shape')
            [void]$L.Add("# (nhu PE1 employee): bo @NotNull khoi $($nestedFk.Name), check null trong SERVICE (doc ca nested)")
            [void]$L.Add('# roi sinh lai file nay -> expect se thanh 201.')
        }
        else {
            [void]$L.Add('# Expect: 201, status=1 - DTO nhan ca 2 shape (phang o case 01, nested o day),')
            [void]$L.Add('# service doc FK tu nested khi field phang null.')
        }
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ovn ($skipCreate + $nestedFk.Name) $extra))
        [void]$L.Add('')
    }

    # ngay: ISO fallback / rac / bien min / bien max
    if ($dateField) {
        if (-not $specIsIso) {
            $n++
            $ov2 = @{ $dateField.Name = '"2025-05-20"' }
            if ($uniqueField) { $ov2[$uniqueField] = $uniqueVal }
            [void]$L.Add("### $('{0:d2}' -f $n). Create - ngay dang ISO yyyy-MM-dd")
            if ($isoFallback) { [void]$L.Add('# Expect: 201, status=1, response tra ve dung format de (deserializer co fallback ISO)') }
            else { [void]$L.Add('# Expect: 400, status=2 (ACCEPT_ISO_FALLBACK=false - chi nhan format de)') }
            [void]$L.Add("POST $urlVar$base")
            [void]$L.Add('Content-Type: application/json')
            [void]$L.Add('')
            [void]$L.Add((Build-Body $body $name $ov2 $skipCreate $null))
            [void]$L.Add('')
        }

        $n++
        $ov3 = @{ $dateField.Name = '"99/99/9999"' }
        if ($uniqueField) { $ov3[$uniqueField] = $uniqueVal }
        [void]$L.Add("### $('{0:d2}' -f $n). Create - ngay rac")
        [void]$L.Add('# Expect: 400, status=2 (loi parse body -> "Request body is invalid" hoac tuong tu)')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ov3 $skipCreate $null))
        [void]$L.Add('')

        if ($dateField.MinDate) {
            $md = [datetime]::ParseExact($dateField.MinDate, 'yyyy-MM-dd', $null)
            $n++
            $ov4 = @{ $dateField.Name = '"' + (Format-SpecDate $md.Day $md.Month $md.Year) + '"' }
            if ($uniqueField) { $ov4[$uniqueField] = $uniqueVal }
            [void]$L.Add("### $('{0:d2}' -f $n). Create - $($dateField.Name) DUNG bien duoi $($dateField.MinDate)")
            [void]$L.Add('# Expect: 400, status=2 - min la EXCLUSIVE (phai after). De cho phep bang thi doi expect.')
            [void]$L.Add("POST $urlVar$base")
            [void]$L.Add('Content-Type: application/json')
            [void]$L.Add('')
            [void]$L.Add((Build-Body $body $name $ov4 $skipCreate $null))
            [void]$L.Add('')
        }
        if ($dateField.MaxDays -gt 0) {
            $n++
            $ov5 = @{ $dateField.Name = '"' + (Format-SpecDate 1 1 2035) + '"' }
            if ($uniqueField) { $ov5[$uniqueField] = $uniqueVal }
            [void]$L.Add("### $('{0:d2}' -f $n). Create - $($dateField.Name) qua xa (vuot today+$($dateField.MaxDays))")
            [void]$L.Add('# Expect: 400, status=2')
            [void]$L.Add("POST $urlVar$base")
            [void]$L.Add('Content-Type: application/json')
            [void]$L.Add('')
            [void]$L.Add((Build-Body $body $name $ov5 $skipCreate $null))
            [void]$L.Add('')
        }
    }

    # trung unique: tao row moi (random) -> luu gia tri THAT tu response -> gui lai
    if ($uniqueField) {
        $n++
        $dup = @{ $uniqueField = $uniqueVal }
        [void]$L.Add("### $('{0:d2}' -f $n). Create row rieng cho test trung (unique random)")
        [void]$L.Add('# Expect: 201, status=1')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $dup $skipCreate $null))
        [void]$L.Add('')
        [void]$L.Add('> {% client.global.set("' + $dupVar + '", response.body.data.' + $uniqueField + '); %}')
        [void]$L.Add('')
        $n++
        $dup2 = @{ $uniqueField = '"{{' + $dupVar + '}}"' }
        [void]$L.Add("### $('{0:d2}' -f $n). Create TRUNG $uniqueField (gia tri vua tao o tren)")
        [void]$L.Add('# Expect: 400, status=3, message copy y nguyen de')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $dup2 $skipCreate $null))
        [void]$L.Add('')
    }

    # thieu tung field bat buoc
    foreach ($f in ($body | Where-Object { $_.Mandatory -and -not $_.IsStatus -and -not $_.IsNested })) {
        $n++
        $ovm = @{}
        if ($uniqueField -and $f.Name -ne $uniqueField) { $ovm[$uniqueField] = $uniqueVal }
        [void]$L.Add("### $('{0:d2}' -f $n). Create thieu '$($f.Name)'")
        [void]$L.Add('# Expect: 400, status=2, message "' + $f.Name + ' is required" (doi chieu cau chu de)')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ovm ($skipCreate + $f.Name) $null))
        [void]$L.Add('')
    }

    # vuot max length
    foreach ($f in ($body | Where-Object { $_.MaxLen -gt 0 })) {
        $n++
        $ovl = @{ $f.Name = '"' + ('X' * ($f.MaxLen + 1)) + '"' }
        if ($uniqueField -and $f.Name -ne $uniqueField) { $ovl[$uniqueField] = $uniqueVal }
        [void]$L.Add("### $('{0:d2}' -f $n). Create '$($f.Name)' dai $($f.MaxLen + 1) ky tu (max $($f.MaxLen))")
        [void]$L.Add('# Expect: 400, status=2')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ovl $skipCreate $null))
        [void]$L.Add('')
    }

    # email sai format (PE1 case emp-07)
    foreach ($f in ($body | Where-Object { $_.IsEmail })) {
        $n++
        $ove = @{ $f.Name = '"not-an-email"' }
        if ($uniqueField -and $f.Name -ne $uniqueField) { $ove[$uniqueField] = $uniqueVal }
        [void]$L.Add("### $('{0:d2}' -f $n). Create '$($f.Name)' sai format email")
        [void]$L.Add('# Expect: 400, status=2')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ove $skipCreate $null))
        [void]$L.Add('')
    }

    # field @Pattern: enum A|B|C ngoai status -> gia tri ngoai enum (PE1 emp-06 position=Intern)
    # charset pattern -> ky tu la (PE1 dep-05 code="AB-01!")
    foreach ($f in ($body | Where-Object { $_.Regex -and -not $_.IsStatus -and -not $_.IsNested })) {
        $n++
        if ($f.Regex -match '^[A-Za-z0-9_ ]+(\|[A-Za-z0-9_ ]+)+$') {
            $ovp = @{ $f.Name = '"InvalidValue"' }
            [void]$L.Add("### $('{0:d2}' -f $n). Create '$($f.Name)' ngoai enum ($($f.Regex))")
        }
        else {
            $ovp = @{ $f.Name = '"Bad!@#"' }
            [void]$L.Add("### $('{0:d2}' -f $n). Create '$($f.Name)' co ky tu la (pattern $($f.Regex))")
        }
        if ($uniqueField -and $f.Name -ne $uniqueField) { $ovp[$uniqueField] = $uniqueVal }
        [void]$L.Add('# Expect: 400, status=2')
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ovp $skipCreate $null))
        [void]$L.Add('')
    }

    # FK khong ton tai (create)
    foreach ($f in $fks) {
        $n++
        $ovf = @{ $f.Name = '999999' }
        if ($uniqueField) { $ovf[$uniqueField] = $uniqueVal }
        [void]$L.Add("### $('{0:d2}' -f $n). Create voi $($f.Name) khong ton tai")
        if ($IsDetail) { [void]$L.Add('# Expect: 400, status=4 (verify qua Feign) - message copy y nguyen de') }
        else { [void]$L.Add('# Expect: 400, status=2 (FK noi bo) - de quy dinh khac thi theo de') }
        [void]$L.Add("POST $urlVar$base")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add((Build-Body $body $name $ovf $skipCreate $null))
        [void]$L.Add('')
    }

    # get
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Get theo id vua tao")
    if ($IsDetail -and $nested) { [void]$L.Add('# Expect: 200, status=1 - DOC DE: detail tra NESTED hay PHANG? (PE1 nested moi noi, PE2 chi list nested)') }
    else { [void]$L.Add('# Expect: 200, status=1') }
    [void]$L.Add("GET $urlVar$base/{{$idVar}}")
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Get id khong ton tai")
    [void]$L.Add('# Expect: 400 (KHONG 404), status=4')
    [void]$L.Add("GET $urlVar$base/999999")
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Get id sai kieu (/abc)")
    [void]$L.Add('# Expect: 400, status=2 (TypeMismatch phai duoc handler bat, khong duoc 500)')
    [void]$L.Add("GET $urlVar$base/abc")
    [void]$L.Add('')

    # update
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Update partial (chi 1 field)")
    [void]$L.Add('# Expect: 200, status=1, cac field khac KHONG doi (nhin response ma soat)')
    [void]$L.Add("PUT $urlVar$base/{{$idVar}}")
    [void]$L.Add('Content-Type: application/json')
    [void]$L.Add('')
    if ($firstStr) { [void]$L.Add('{' + "`r`n" + '  "' + $firstStr.Name + '": "' + $updVal + '"' + "`r`n" + '}') }
    else { [void]$L.Add('{}') }
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Get lai sau update partial - doi chieu field khac giu nguyen")
    [void]$L.Add('# Expect: 200, status=1; chi field vua sua doi, unique/FK/date giu nguyen gia tri cu')
    [void]$L.Add("GET $urlVar$base/{{$idVar}}")
    [void]$L.Add('')
    if ($statusField) {
        $validTarget = $statusEnum | Where-Object { $_ -ne 'ACTIVE' } | Select-Object -First 1
        if ($validTarget) {
            $n++
            [void]$L.Add("### $('{0:d2}' -f $n). Update status hop le -> $validTarget (PE1 case dep-14)")
            [void]$L.Add("# Expect: 200, status=1, data.status=`"$validTarget`"")
            [void]$L.Add("PUT $urlVar$base/{{$idVar}}")
            [void]$L.Add('Content-Type: application/json')
            [void]$L.Add('')
            [void]$L.Add('{' + "`r`n" + '  "status": "' + $validTarget + '"' + "`r`n" + '}')
            [void]$L.Add('')
        }
        $n++
        [void]$L.Add("### $('{0:d2}' -f $n). Update status sai enum (enum: $($statusEnum -join '|'))")
        [void]$L.Add('# Expect: 400, status=2. LUU Y: enum moi de moi khac (PE1 co CLOSED, PE2 khong)!')
        [void]$L.Add("PUT $urlVar$base/{{$idVar}}")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add('{' + "`r`n" + '  "status": "TOTALLY_WRONG"' + "`r`n" + '}')
        [void]$L.Add('')
    }
    if ($uniqueField) {
        $n++
        [void]$L.Add("### $('{0:d2}' -f $n). Update $uniqueField TRUNG voi row khac (PE1 dep-16, PE2 R10)")
        [void]$L.Add('# Expect: 400, status=3 - check trung khi update phai LOAI TRU chinh minh nhung bat row khac')
        [void]$L.Add("PUT $urlVar$base/{{$idVar}}")
        [void]$L.Add('Content-Type: application/json')
        [void]$L.Add('')
        [void]$L.Add('{' + "`r`n" + '  "' + $uniqueField + '": "{{' + $dupVar + '}}"' + "`r`n" + '}')
        [void]$L.Add('')
    }
    if ($IsDetail) {
        foreach ($f in $fks) {
            $n++
            [void]$L.Add("### $('{0:d2}' -f $n). Update doi $($f.Name) hop le (Feign verify LAI khi update - PE1 emp-12)")
            [void]$L.Add("# Expect: 200, status=1, data tra ve $($f.Name)=1 (hoac nested tuong ung)")
            [void]$L.Add("PUT $urlVar$base/{{$idVar}}")
            [void]$L.Add('Content-Type: application/json')
            [void]$L.Add('')
            [void]$L.Add('{' + "`r`n" + '  "' + $f.Name + '": 1' + "`r`n" + '}')
            [void]$L.Add('')
            $n++
            [void]$L.Add("### $('{0:d2}' -f $n). Update doi $($f.Name) khong ton tai (PE1 emp-13, PE2 F10)")
            [void]$L.Add('# Expect: 400, status=4 - quen verify Feign o nhanh update la mat diem cho nay')
            [void]$L.Add("PUT $urlVar$base/{{$idVar}}")
            [void]$L.Add('Content-Type: application/json')
            [void]$L.Add('')
            [void]$L.Add('{' + "`r`n" + '  "' + $f.Name + '": 999999' + "`r`n" + '}')
            [void]$L.Add('')
        }
    }
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Update id khong ton tai")
    [void]$L.Add('# Expect: 400, status=4')
    [void]$L.Add("PUT $urlVar$base/999999")
    [void]$L.Add('Content-Type: application/json')
    [void]$L.Add('')
    if ($firstStr) { [void]$L.Add('{' + "`r`n" + '  "' + $firstStr.Name + '": "X"' + "`r`n" + '}') }
    else { [void]$L.Add('{}') }
    [void]$L.Add('')

    # delete
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Delete (soft) id vua tao")
    [void]$L.Add('# Expect: 200, status=1; row van con trong DB voi status=INACTIVE')
    [void]$L.Add("DELETE $urlVar$base/{{$idVar}}")
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Get lai sau delete - status phai INACTIVE, row KHONG bien mat")
    [void]$L.Add('# Expect: 200, status=1, data.status="INACTIVE"')
    [void]$L.Add("GET $urlVar$base/{{$idVar}}")
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). Delete id khong ton tai")
    [void]$L.Add('# Expect: 400, status=4')
    [void]$L.Add("DELETE $urlVar$base/999999")
    [void]$L.Add('')

    # list
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). List mac dinh - SOAT SHAPE THEO DE, dung tin mat thuong")
    if ($IsDetail) { [void]$L.Add('# Expect: 200, status=1. DOC DE: ListDTO cua detail co the KHAC PageDTO (PE2: pageSize/pageNo/foods, KHONG co totalElements) va nested per row qua Feign.') }
    else { [void]$L.Add('# Expect: 200, status=1, shape PageDTO dung bang de (size/page/totalPages/totalElements/first/last/content)') }
    [void]$L.Add("GET $urlVar$base")
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). List phan trang")
    [void]$L.Add('# Expect: 200, dung size=2 va so trang khop totalElements')
    [void]$L.Add("GET $urlVar$base`?page=1&size=2")
    [void]$L.Add('')
    foreach ($p in $listParams) {
        if ($p -ieq 'status') {
            $n++
            [void]$L.Add("### $('{0:d2}' -f $n). List filter theo 'status' (Enum, exact match)")
            [void]$L.Add('# Expect: 200, MOI row trong content deu co status khop (soat bang mat)')
            [void]$L.Add("GET $urlVar$base`?status=$($statusEnum[0])")
            [void]$L.Add('')
            $n++
            [void]$L.Add("### $('{0:d2}' -f $n). List filter 'status' ngoai Enum")
            [void]$L.Add('# Expect: 400, status=2 - service PHAI validate, tra 200 rong la SAI (xem DOI-TEN 3.1)')
            [void]$L.Add("GET $urlVar$base`?status=BOGUS")
            [void]$L.Add('')
        }
        else {
            $n++
            [void]$L.Add("### $('{0:d2}' -f $n). List filter theo '$p' (partial match)")
            [void]$L.Add("# Expect: 200, CHI row co 'a' trong $p. BAY PE1: ten param controller phai")
            [void]$L.Add('# khop ten de dung (name vs fullName) - filter sai ten thi bi BO QUA va tra het!')
            [void]$L.Add("GET $urlVar$base`?$p=a")
            [void]$L.Add('')
            $n++
            [void]$L.Add("### $('{0:d2}' -f $n). List filter '$p' voi gia tri chac chan khong khop")
            [void]$L.Add('# Expect: 200, content RONG. Neu tra du het row -> filter dang bi bo qua (bug PE1 da gap)!')
            [void]$L.Add("GET $urlVar$base`?$p=zzzznomatchzzz")
            [void]$L.Add('')
        }
    }
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). List size=100 (bien tren, hop le)")
    [void]$L.Add('# Expect: 200, status=1')
    [void]$L.Add("GET $urlVar$base`?size=100")
    [void]$L.Add('')
    if ($sizeStrict) {
        $n++
        [void]$L.Add("### $('{0:d2}' -f $n). List size=101 (vua vuot max - SIZE_OVER_MAX_IS_ERROR=true)")
        [void]$L.Add('# Expect: 400, status=2')
        [void]$L.Add("GET $urlVar$base`?size=101")
        [void]$L.Add('')
        $n++
        [void]$L.Add("### $('{0:d2}' -f $n). List size=1000")
        [void]$L.Add('# Expect: 400, status=2')
        [void]$L.Add("GET $urlVar$base`?size=1000")
        [void]$L.Add('')
    }
    else {
        $n++
        [void]$L.Add("### $('{0:d2}' -f $n). List size=1000 (SIZE_OVER_MAX_IS_ERROR=false -> clamp)")
        [void]$L.Add('# Expect: 200, size bi cat xuong max 100. DE ghi "max: 100" o Query Parameters')
        [void]$L.Add('# ma cham 400 thi bat SIZE_OVER_MAX_IS_ERROR=true trong ServiceImpl roi sinh lai file nay.')
        [void]$L.Add("GET $urlVar$base`?size=1000")
        [void]$L.Add('')
    }
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). List size=0")
    [void]$L.Add('# Expect: 400, status=2 (size phai >= 1)')
    [void]$L.Add("GET $urlVar$base`?size=0")
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). List page am")
    [void]$L.Add('# Expect: 400, status=2')
    [void]$L.Add("GET $urlVar$base`?page=-1")
    [void]$L.Add('')
    $n++
    [void]$L.Add("### $('{0:d2}' -f $n). List page sai kieu (?page=xyz)")
    [void]$L.Add('# Expect: 400, status=2 (TypeMismatch cua query param cung phai bat, khong 500)')
    [void]$L.Add("GET $urlVar$base`?page=xyz")
    [void]$L.Add('')

    return ($L -join "`r`n")
}

# =====================================================================
$httpDir = Join-Path $Root 'http'
if (-not (Test-Path $httpDir) -and -not $DryRun) { New-Item -ItemType Directory -Force $httpDir | Out-Null }

$env = @"
{
  "gateway": {
    "masterUrl": "http://localhost:8080",
    "detailUrl": "http://localhost:8080"
  },
  "direct": {
    "masterUrl": "http://localhost:8081",
    "detailUrl": "http://localhost:8082"
  }
}
"@
Out-File2 (Join-Path $httpDir 'http-client.env.json') $env

Out-File2 (Join-Path $httpDir "$($master.Name.ToLower()).http") (New-ServiceHttp $master)
if ($detail) {
    Out-File2 (Join-Path $httpDir "$($detail.Name.ToLower()).http") (New-ServiceHttp $detail -IsDetail)
}

# controller phu (khong phai controller chinh) trong project Master
# Bay PE2: /api/categories nam trong RestaurantService - gateway PHAI route them path nay
Get-ChildItem (Join-Path $master.Pkg 'controller') -Filter '*.java' | Where-Object { $_.BaseName -ne "$SidUpper$($master.Name)Controller" } | ForEach-Object {
    $ctext = [System.IO.File]::ReadAllText($_.FullName)
    $base = [regex]::Match($ctext, '@RequestMapping\("([^"]+)"\)').Groups[1].Value
    if (-not $base) { return }
    $subName = $_.BaseName -replace "^$SidUpper", '' -replace 'Controller$', ''
    $L = @(
        "###  $subName ($base) - controller phu, SINH boi gen-http.ps1 V2",
        '###  BAY GATEWAY (PE2 da xac nhan): path nay phai co route rieng tren gateway.',
        '',
        '### 01. List mac dinh QUA GATEWAY (quen route la 404/503 o day)',
        '# Expect: 200, status=1',
        "GET {{masterUrl}}$base",
        '',
        '### 02. List phan trang',
        '# Expect: 200, size dung nhu request',
        "GET {{masterUrl}}$base`?page=0&size=2",
        ''
    )
    Out-File2 (Join-Path $httpDir "$($subName.ToLower()).http") ($L -join "`r`n")
}

Write-Host ''
if ($DryRun) { Write-Host "DRY RUN - $($generated.Count) file se sinh." -ForegroundColor Yellow }
else { Write-Host "XONG. $($generated.Count) file trong $httpDir" -ForegroundColor Green }
Write-Host 'Mo file .http bang IntelliJ -> goc phai chon environment "gateway" -> Run tung request TU TREN XUONG' -ForegroundColor Yellow
Write-Host '(thu tu quan trong: cac case sau dung id/gia tri luu tu case truoc bang client.global.set).' -ForegroundColor Yellow
Write-Host 'Case 00 (smoke) fail = service/DB chua san sang - dung test tiep, sua truoc.' -ForegroundColor Yellow
Write-Host 'FK dang de = 1: can INSERT it nhat 1 row bang cha/bang phu truoc (xem sql/init_db.sql).' -ForegroundColor Yellow
