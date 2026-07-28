# =====================================================================
#  gen-from-entity.ps1 - Sinh DTO + Mapper + Repository tu entity IntelliJ generate tu DB
#
#  Workflow thi (xem DOI-TEN-TUNG-BUOC.md):
#    B1. rename-template.ps1
#    B2. Chay script SQL cua de trong SSMS
#    B3. IntelliJ: generate entity tu DB -> dan de vao entity/<Ten>.java
#        powershell -ExecutionPolicy Bypass -File .\gen-from-entity.ps1 -Service Restaurant -Rename "owner_name=owner"
#    B4. Doi chieu query param + message voi DE -> test Master + Gateway
#    B5. Nhu B3 cho Detail:  ... -Service Food -Rename "ingredient=ingredients"
#        (tu phat hien Feign client, sinh them ResponseDTO + ban copy DTO cua Master)
#
#  Script CHUAN HOA entity (Integer -> Long cho PK/_id, Instant/LocalDateTime -> Date,
#  bo noise schema/@NotNull, ep Lombok) roi SINH DTO (validation theo bang quy doi)
#  + Mapper (toDTO/toEntity/applyPartialUpdate)
#  + Repository (existsBy theo cot UNIQUE that, search theo field String that - het m.owner ma)
#  + PATCH Service/ServiceImpl/Controller cho khop (ten filter, cap existsBy+getter, setPk(null), getter FK).
#
#  -Rename "cot=tenDTO" : dat ten field DTO khac ten cot (map bang @Column). NHO DAU NHAY.
#                       Vi du de Trial: -Rename "owner_name=owner"  |  nhieu cap: -Rename "a=b,c=d"
#  -Filter "p1,p2=field": query param search theo bang Query Parameters cua DE (thay cho doan tu DB).
#                       param khac ten field DTO thi ghi param=field: -Filter "name,directorName=director"
#                       Chi nhan filter String partial-match; minStar/checkInFrom/status exact -> lam tay.
#  -Unique field       : field check trung theo DE (thay cho doan tu cot UNIQUE): -Unique name
#  -DetailShape A|B|C : shape DTO phia Detail theo bang DTO cua DE (chi tiet trong DOI-TEN-TUNG-BUOC.md):
#                       A = phang het (chi co masterId, ke ca list)
#                       B = mac dinh, kieu Trial: DTO phang + <X>ResponseDTO nested rieng cho list
#                       C = kieu PE1: MOT DTO dung moi endpoint, chi co object nested (khong co masterId
#                           trong response nhung van NHAN masterId phang nho WRITE_ONLY)
#  -EntityName X      : sinh cho entity phu (vd Category) trong cung project.
#  -DryRun            : in ra noi dung se sinh, chua ghi file.
#
#  File ASCII thuan cho PowerShell 5.1.
# =====================================================================
param(
    [string]$Root = "e:\fpt_university\Semester8\MSS301\PE\EXAM",
    [Parameter(Mandatory = $true)][string]$Service,   # ten entity chinh cua project: Restaurant / Food...
    [string]$EntityName = "",                          # mac dinh = $Service; dat khac cho entity phu
    [string[]]$Rename = @(),                           # "ten_cot=tenFieldDTO", nhieu cai cach nhau dau phay
    [string[]]$Filter = @(),                           # query param search theo DE: "param" hoac "param=fieldDTO", cach nhau phay
    [string]$Unique = "",                              # field DTO de check trung theo DE (override doan tu cot UNIQUE)
    [string]$DetailShape = "B",                        # A=phang het | B=DTO phang + ResponseDTO nested cho list | C=1 DTO nested
    [string]$StatusEnum = "ACTIVE,INACTIVE",           # tap gia tri status theo CHECK constraint cua DE
    [object[]]$Rules = @(),                            # rule validation theo field (hashtable, dien qua gen-all.ps1)
    [string]$SizeOverMax = "",                         # "error" = size>max tra 400/2 | "clamp" = ep ve max | "" = giu nguyen
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$SidUpper = 'SE193114'
$SidLower = 'se193114'

if ([string]::IsNullOrEmpty($EntityName)) { $EntityName = $Service }
$svcLower = $Service.ToLower()
$proj = Join-Path $Root "$SidUpper${Service}Service"
if (-not (Test-Path $proj)) { Write-Host "LOI: khong thay project $proj" -ForegroundColor Red; exit 1 }
$pkgDir = Join-Path $proj "src\main\java\fu\$SidLower\$svcLower"
if (-not (Test-Path $pkgDir)) { Write-Host "LOI: khong thay package $pkgDir" -ForegroundColor Red; exit 1 }
$entityFile = Join-Path $pkgDir "entity\$EntityName.java"
if (-not (Test-Path $entityFile)) {
    Write-Host "LOI: khong thay $entityFile - dan entity IntelliJ sinh vao do truoc." -ForegroundColor Red
    exit 1
}

$renameMap = @{}
# Goi qua "powershell -File" thi -Rename a=b,c=d ve day la MOT chuoi -> phai tu tach dau phay
$renamePairs = @()
foreach ($r in $Rename) { $renamePairs += ($r -split ',') }
foreach ($r in $renamePairs) {
    if ($r.Trim() -eq '') { continue }
    $kv = $r -split '=', 2
    if ($kv.Count -ne 2) { Write-Host "LOI: -Rename '$r' phai co dang ten_cot=tenFieldDTO" -ForegroundColor Red; exit 1 }
    $renameMap[$kv[0].Trim()] = $kv[1].Trim()
}

$filterSpecsRaw = @()
foreach ($f in $Filter) { $filterSpecsRaw += ($f -split ',') }
$filterSpecsRaw = @($filterSpecsRaw | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
foreach ($raw in $filterSpecsRaw) {
    if ($raw -notmatch '^[A-Za-z_]\w*(=[A-Za-z_]\w*)?$') {
        Write-Host "LOI: -Filter '$raw' phai co dang param hoac param=tenFieldDTO" -ForegroundColor Red; exit 1
    }
}

$DetailShape = $DetailShape.Trim().ToUpper()
if ($DetailShape -notin 'A', 'B', 'C') {
    Write-Host "LOI: -DetailShape '$DetailShape' phai la A, B hoac C (xem bang DTO cua DE)." -ForegroundColor Red
    exit 1
}

$SizeOverMax = $SizeOverMax.Trim().ToLower()
if ($SizeOverMax -notin '', 'error', 'clamp') {
    Write-Host "LOI: -SizeOverMax '$SizeOverMax' phai la 'error', 'clamp' hoac bo trong." -ForegroundColor Red
    exit 1
}

$rulesMap = @{}
foreach ($r in $Rules) {
    if ($null -eq $r) { continue }
    if (-not ($r -is [hashtable]) -or -not $r.ContainsKey('f')) {
        Write-Host "LOI: moi rule phai la hashtable co key 'f' (ten field DTO), vd @{ f='code'; pattern='[A-Za-z0-9]+' }" -ForegroundColor Red
        exit 1
    }
    $rulesMap[[string]$r['f']] = $r
}

function ConvertTo-JavaString([string]$s) {
    return $s.Replace('\', '\\').Replace('"', '\"')
}

$warnings = New-Object System.Collections.ArrayList

# --- Phat hien phia Detail: project co Feign client -> sinh them ResponseDTO + copy DTO Master
$masterName = $null
if ($EntityName -eq $Service) {
    $repoDir = Join-Path $pkgDir 'repository'
    if (Test-Path $repoDir) {
        $cf = Get-ChildItem $repoDir -Filter '*Client.java' | Select-Object -First 1
        if ($cf) { $masterName = $cf.BaseName -replace 'Client$', '' }
    }
}
$isDetail = ($null -ne $masterName)

# ---------------------------------------------------------------------
function ConvertTo-Camel([string]$snake) {
    if ($snake -notmatch '_') { return $snake }
    $parts = @($snake -split '_' | Where-Object { $_ -ne '' })
    $out = $parts[0].ToLower()
    for ($i = 1; $i -lt $parts.Count; $i++) {
        $p = $parts[$i]
        $out += $p.Substring(0, 1).ToUpper() + $p.Substring(1).ToLower()
    }
    return $out
}

function ConvertTo-Snake([string]$camel) {
    return ([regex]::Replace($camel, '(?<=[a-z0-9])([A-Z])', '_$1')).ToLower()
}

function Get-Cap([string]$s) { return $s.Substring(0, 1).ToUpper() + $s.Substring(1) }

# Cot ten trung tu khoa SQL (position, level, value...) bi IntelliJ sinh thanh
# @Column(name = "\"position\"") - phai boc vo quote/bracket, khong thi regex bat ra '\'
# va ca 4 file sinh ra deu chua field ten '\' (khong compile noi).
function Clean-SqlName([string]$s) {
    if ($null -eq $s) { return $s }
    return ($s -replace '[\\"\[\]`]', '').Trim()
}

# --- Doc file entity (IntelliJ hoac template) ra model field
function Read-EntityModel([string]$path) {
    $text = [System.IO.File]::ReadAllText($path)

    $table = $null
    $m = [regex]::Match($text, '@Table\s*\(\s*name\s*=\s*"((?:\\.|[^"\\])+)"')
    if ($m.Success) { $table = Clean-SqlName $m.Groups[1].Value }
    if (-not $table) {
        $table = (ConvertTo-Snake $EntityName) + 's'
        [void]$warnings.Add("Khong doc duoc @Table(name=...) - doan la '$table', KIEM LAI voi script SQL de!")
    }

    $uniqueCols = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($um in [regex]::Matches($text, 'columnNames\s*=\s*\{([^}]*)\}')) {
        foreach ($cm in [regex]::Matches($um.Groups[1].Value, '"([^"]+)"')) { [void]$uniqueCols.Add((Clean-SqlName $cm.Groups[1].Value)) }
    }
    foreach ($um in [regex]::Matches($text, 'columnNames\s*=\s*"([^"]+)"')) { [void]$uniqueCols.Add((Clean-SqlName $um.Groups[1].Value)) }

    $fields = New-Object System.Collections.ArrayList
    $buf = ''
    foreach ($line in ($text -split "`r?`n")) {
        $trim = $line.Trim()
        if ($trim -match '(?:^|\s)(?:private|protected)\s+static') { $buf = ''; continue }

        # khong neo dau dong: bat ca truong hop annotation + field nam CHUNG mot dong
        $fm = [regex]::Match($trim, '(?:^|\s)(?:private|protected)\s+([\w\.]+(?:<[^>]+>)?)\s+(\w+)\s*;')
        if ($trim.StartsWith('@')) {
            $buf += ' ' + $trim
            if (-not $fm.Success) { continue }
        }
        if (-not $fm.Success) {
            if ($trim -ne '' -and -not $trim.StartsWith('//') -and -not $trim.StartsWith('*') -and -not $trim.StartsWith('/*') -and -not $trim.StartsWith('import') -and -not $trim.StartsWith('package')) { $buf = '' }
            elseif ($trim.StartsWith('import') -or $trim.StartsWith('package')) { $buf = '' }
            continue
        }

        $rawType = $fm.Groups[1].Value
        $fname   = $fm.Groups[2].Value
        $simple  = $rawType -replace '^.*\.', ''

        if ($simple -match '^(List|Set|Collection|Map)\b' -or $rawType -match '<') {
            [void]$warnings.Add("BO field collection '$fname' ($rawType) - quan he nguoc, bai PE khong dung.")
            $buf = ''; continue
        }

        $isId  = $buf -match '@Id\b'
        $isRel = $buf -match '@(ManyToOne|OneToOne)\b'

        $col = $null
        $cm = [regex]::Match($buf, '@Column\s*\([^)]*name\s*=\s*"((?:\\.|[^"\\])+)"')
        if (-not $cm.Success) { $cm = [regex]::Match($buf, '@JoinColumn\s*\([^)]*name\s*=\s*"((?:\\.|[^"\\])+)"') }
        if ($cm.Success) { $col = Clean-SqlName $cm.Groups[1].Value } else { $col = ConvertTo-Snake $fname }

        $nullable = $true
        if ($buf -match 'nullable\s*=\s*false' -or $buf -match '@NotNull\b' -or $buf -match '@NotBlank\b') { $nullable = $false }

        $len = 0
        $lm = [regex]::Match($buf, 'length\s*=\s*(\d+)')
        if ($lm.Success) { $len = [int]$lm.Groups[1].Value }
        else { $lm = [regex]::Match($buf, '@Size\s*\([^)]*max\s*=\s*(\d+)'); if ($lm.Success) { $len = [int]$lm.Groups[1].Value } }

        $unique = ($buf -match 'unique\s*=\s*true') -or $uniqueCols.Contains($col)

        $temporal = ''
        $tm = [regex]::Match($buf, '@Temporal\s*\(\s*TemporalType\.(\w+)')
        if ($tm.Success) { $temporal = $tm.Groups[1].Value }

        $isDate = $false
        $javaType = $simple
        if ($isRel) {
            $javaType = 'Long'
            [void]$warnings.Add("Chuyen quan he '$fname' ($simple) thanh cot Long '$col' - bai PE khong dung @ManyToOne. Kiem lai nullable.")
        }
        elseif ($simple -in 'Instant', 'LocalDateTime', 'OffsetDateTime', 'ZonedDateTime', 'Timestamp') { $javaType = 'Date'; $isDate = $true; $temporal = 'TIMESTAMP' }
        elseif ($simple -eq 'LocalDate') { $javaType = 'Date'; $isDate = $true; $temporal = 'DATE' }
        elseif ($simple -eq 'Date') { $isDate = $true; if (-not $temporal) { $temporal = 'TIMESTAMP' } }
        elseif ($simple -in 'Integer', 'int') {
            if ($isId -or $col.EndsWith('_id')) { $javaType = 'Long' } else { $javaType = 'Integer' }
        }
        elseif ($simple -in 'Long', 'long') { $javaType = 'Long' }
        elseif ($simple -in 'String', 'BigDecimal', 'Boolean', 'Double', 'Float', 'Short') { $javaType = $simple }
        else { [void]$warnings.Add("Kieu la '$simple' cua field '$fname' - giu nguyen, kiem lai tay.") }

        # Ten field: mac dinh camelCase tu ten cot; -Rename ghi de (khop bang DTO cua de)
        $name = ConvertTo-Camel $col
        if ($renameMap.ContainsKey($col))      { $name = $renameMap[$col] }
        elseif ($renameMap.ContainsKey($name)) { $name = $renameMap[$name] }

        [void]$fields.Add([pscustomobject]@{
            Name = $name; Col = $col; Type = $javaType; IsDate = $isDate; Temporal = $temporal
            Nullable = $nullable; Length = $len; IsId = $isId; Unique = $unique
            IsFk = ((-not $isId) -and $col.EndsWith('_id'))
        })
        $buf = ''
    }

    # PK len dau cho de doc, con lai giu thu tu goc
    if ($fields.Count -eq 0) {
        Write-Host "LOI: doc duoc 0 field tu $path - KHONG sinh file nao." -ForegroundColor Red
        Write-Host "     Kiem tra file entity co dung dang 'private <Kieu> <ten>;' khong." -ForegroundColor Red
        exit 1
    }
    if (-not ($fields | Where-Object { $_.IsId })) {
        Write-Host "LOI: khong thay field @Id trong $path - KHONG sinh file nao." -ForegroundColor Red
        exit 1
    }

    $ordered = New-Object System.Collections.ArrayList
    foreach ($f in $fields) { if ($f.IsId) { [void]$ordered.Add($f) } }
    foreach ($f in $fields) { if (-not $f.IsId) { [void]$ordered.Add($f) } }

    return [pscustomobject]@{ Table = $table; Fields = $ordered }
}

# ---------------------------------------------------------------------
$generated = New-Object System.Collections.ArrayList
function Out-Gen([string]$path, [string]$content) {
    [void]$generated.Add($path)
    if ($DryRun) {
        Write-Host ''
        Write-Host ("----- [DRY RUN] " + $path + " -----") -ForegroundColor Cyan
        Write-Host $content
    }
    else {
        [System.IO.File]::WriteAllText($path, $content)
        Write-Host ("  + " + $path.Substring($Root.Length + 1)) -ForegroundColor Green
    }
}

function Join-Java($list) { return (($list -join "`r`n") + "`r`n") }

# --- 1) Entity chuan hoa
function Emit-Entity($model) {
    $L = New-Object System.Collections.ArrayList
    [void]$L.Add("package fu.$SidLower.$svcLower.entity;")
    [void]$L.Add('')
    $hasDate = @($model.Fields | Where-Object { $_.IsDate }).Count -gt 0
    $hasBig  = @($model.Fields | Where-Object { $_.Type -eq 'BigDecimal' }).Count -gt 0
    $imp = @('jakarta.persistence.Column', 'jakarta.persistence.Entity', 'jakarta.persistence.GeneratedValue',
             'jakarta.persistence.GenerationType', 'jakarta.persistence.Id', 'jakarta.persistence.Table')
    if ($hasDate) { $imp += 'jakarta.persistence.Temporal'; $imp += 'jakarta.persistence.TemporalType' }
    foreach ($i in ($imp | Sort-Object)) { [void]$L.Add("import $i;") }
    [void]$L.Add('import lombok.Getter;')
    [void]$L.Add('import lombok.NoArgsConstructor;')
    [void]$L.Add('import lombok.Setter;')
    if ($hasDate -or $hasBig) {
        [void]$L.Add('')
        if ($hasBig)  { [void]$L.Add('import java.math.BigDecimal;') }
        if ($hasDate) { [void]$L.Add('import java.util.Date;') }
    }
    [void]$L.Add('')
    [void]$L.Add('@Entity')
    [void]$L.Add('@Table(name = "' + $model.Table + '")')
    [void]$L.Add('@Getter')
    [void]$L.Add('@Setter')
    [void]$L.Add('@NoArgsConstructor')
    [void]$L.Add("public class $EntityName {")
    foreach ($f in $model.Fields) {
        [void]$L.Add('')
        if ($f.IsId) {
            [void]$L.Add('    @Id')
            [void]$L.Add('    @GeneratedValue(strategy = GenerationType.IDENTITY)')
            [void]$L.Add('    @Column(name = "' + $f.Col + '")')
        }
        else {
            if ($f.IsDate) { [void]$L.Add('    @Temporal(TemporalType.' + $f.Temporal + ')') }
            $attrs = 'name = "' + $f.Col + '"'
            if (-not $f.Nullable) { $attrs += ', nullable = false' }
            if ($f.Length -gt 0 -and $f.Type -eq 'String') { $attrs += ', length = ' + $f.Length }
            if ($f.Unique) { $attrs += ', unique = true' }
            [void]$L.Add('    @Column(' + $attrs + ')')
        }
        [void]$L.Add('    private ' + $f.Type + ' ' + $f.Name + ';')
    }
    [void]$L.Add('}')
    return Join-Java $L
}

# --- 2) DTO voi validation theo bang quy doi
function Emit-DTO($model) {
    $usesNotBlank = $false; $usesNotNull = $false; $usesSize = $false; $usesPattern = $false; $usesEmail = $false
    $usesMin = $false; $usesMax = $false
    $hasDate = @($model.Fields | Where-Object { $_.IsDate }).Count -gt 0
    $hasBig  = @($model.Fields | Where-Object { $_.Type -eq 'BigDecimal' }).Count -gt 0

    $body = New-Object System.Collections.ArrayList
    foreach ($f in $model.Fields) {
        [void]$body.Add('')
        $n = $f.Name
        $rule = $null
        if ($rulesMap.ContainsKey($n)) { $rule = $rulesMap[$n] }
        if ($f.IsId) {
            [void]$null
        }
        elseif ($n -eq 'status' -and $f.Type -eq 'String' -and -not $rule) {
            $enumVals = @($StatusEnum -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
            $enumRegex = $enumVals -join '|'
            $enumList  = $enumVals -join ', '
            [void]$body.Add('    @Pattern(regexp = "' + $enumRegex + '", message = "status must be one of ' + $enumList + '",')
            [void]$body.Add('            groups = {OnCreate.class, OnUpdate.class})')
            $usesPattern = $true
        }
        else {
            $fkWriteOnly = ($isDetail -and $f.IsFk -and $DetailShape -eq 'C')
            if ($fkWriteOnly) {
                [void]$body.Add('    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)')
            }
            if (-not $f.Nullable -and -not $fkWriteOnly) {
                if ($f.Type -eq 'String') {
                    [void]$body.Add('    @NotBlank(message = "' + $n + ' is required", groups = OnCreate.class)')
                    $usesNotBlank = $true
                }
                else {
                    [void]$body.Add('    @NotNull(message = "' + $n + ' is required", groups = OnCreate.class)')
                    $usesNotNull = $true
                }
            }
            if ($f.Length -gt 0 -and $f.Type -eq 'String') {
                [void]$body.Add('    @Size(max = ' + $f.Length + ', message = "' + $n + ' must be at most ' + $f.Length + ' characters", groups = {OnCreate.class, OnUpdate.class})')
                $usesSize = $true
            }
            if ($rule -and $rule.ContainsKey('numMin')) {
                $m = "$n must be at least " + $rule['numMin']
                if ($rule.ContainsKey('msg')) { $m = [string]$rule['msg'] }
                [void]$body.Add('    @Min(value = ' + [long]$rule['numMin'] + ', message = "' + (ConvertTo-JavaString $m) + '", groups = {OnCreate.class, OnUpdate.class})')
                $usesMin = $true
            }
            if ($rule -and $rule.ContainsKey('numMax')) {
                $m = "$n must be at most " + $rule['numMax']
                if ($rule.ContainsKey('msg')) { $m = [string]$rule['msg'] }
                [void]$body.Add('    @Max(value = ' + [long]$rule['numMax'] + ', message = "' + (ConvertTo-JavaString $m) + '", groups = {OnCreate.class, OnUpdate.class})')
                $usesMax = $true
            }
            if ($rule -and $rule.ContainsKey('enum')) {
                $vals = @(([string]$rule['enum']) -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
                $rx = ConvertTo-JavaString ($vals -join '|')
                $m = "$n must be one of " + ($vals -join ', ')
                if ($rule.ContainsKey('msg')) { $m = [string]$rule['msg'] }
                [void]$body.Add('    @Pattern(regexp = "' + $rx + '", message = "' + (ConvertTo-JavaString $m) + '",')
                [void]$body.Add('            groups = {OnCreate.class, OnUpdate.class})')
                $usesPattern = $true
            }
            elseif ($rule -and $rule.ContainsKey('pattern')) {
                $m = "$n is invalid"
                if ($rule.ContainsKey('msg')) { $m = [string]$rule['msg'] }
                [void]$body.Add('    @Pattern(regexp = "' + (ConvertTo-JavaString ([string]$rule['pattern'])) + '", message = "' + (ConvertTo-JavaString $m) + '",')
                [void]$body.Add('            groups = {OnCreate.class, OnUpdate.class})')
                $usesPattern = $true
            }
            elseif ($rule -and $rule.ContainsKey('email')) {
                $m = "$n is invalid"
                if ($rule.ContainsKey('msg')) { $m = [string]$rule['msg'] }
                [void]$body.Add('    @Email(message = "' + (ConvertTo-JavaString $m) + '", groups = {OnCreate.class, OnUpdate.class})')
                $usesEmail = $true
            }
            if ($f.IsDate) {
                $vdArgs = @()
                if ($rule) {
                    if ($rule.ContainsKey('dateMin'))     { $vdArgs += 'min = "' + ([string]$rule['dateMin']).Replace('/', '-') + '"' }
                    if ($rule.ContainsKey('dateMax'))     { $vdArgs += 'max = "' + ([string]$rule['dateMax']).Replace('/', '-') + '"' }
                    if ($rule.ContainsKey('dateMaxDays')) { $vdArgs += 'maxDaysFromToday = ' + [int]$rule['dateMaxDays'] }
                    if ($rule.ContainsKey('noFuture')   -and $rule['noFuture'])   { $vdArgs += 'noFuture = true' }
                    if ($rule.ContainsKey('futureOnly') -and $rule['futureOnly']) { $vdArgs += 'futureOnly = true' }
                    if ($rule.ContainsKey('msg'))         { $vdArgs += 'message = "' + (ConvertTo-JavaString ([string]$rule['msg'])) + '"' }
                }
                $vdArgs += 'groups = {OnCreate.class, OnUpdate.class}'
                [void]$body.Add('    @ValidDate(' + ($vdArgs -join ', ') + ')')
                [void]$body.Add('    @JsonSerialize(using = DateOnlySerializer.class)')
                [void]$body.Add('    @JsonDeserialize(using = DateOnlyDeserializer.class)')
            }
        }
        [void]$body.Add('    private ' + $f.Type + ' ' + $n + ';')
    }
    if ($isDetail) {
        $mLower = $masterName.ToLower()
        [void]$body.Add('')
        if ($DetailShape -ne 'C') {
            [void]$body.Add('    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)')
        }
        [void]$body.Add("    private ${masterName}DTO $mLower;")
    }

    $L = New-Object System.Collections.ArrayList
    [void]$L.Add("package fu.$SidLower.$svcLower.dto;")
    [void]$L.Add('')
    if ($isDetail) {
        [void]$L.Add('import com.fasterxml.jackson.annotation.JsonProperty;')
    }
    if ($hasDate) {
        [void]$L.Add('import com.fasterxml.jackson.databind.annotation.JsonDeserialize;')
        [void]$L.Add('import com.fasterxml.jackson.databind.annotation.JsonSerialize;')
        [void]$L.Add("import fu.$SidLower.$svcLower.common.DateOnlyDeserializer;")
        [void]$L.Add("import fu.$SidLower.$svcLower.common.DateOnlySerializer;")
    }
    [void]$L.Add("import fu.$SidLower.$svcLower.common.OnCreate;")
    [void]$L.Add("import fu.$SidLower.$svcLower.common.OnUpdate;")
    if ($hasDate) { [void]$L.Add("import fu.$SidLower.$svcLower.common.ValidDate;") }
    if ($usesEmail)    { [void]$L.Add('import jakarta.validation.constraints.Email;') }
    if ($usesMax)      { [void]$L.Add('import jakarta.validation.constraints.Max;') }
    if ($usesMin)      { [void]$L.Add('import jakarta.validation.constraints.Min;') }
    if ($usesNotBlank) { [void]$L.Add('import jakarta.validation.constraints.NotBlank;') }
    if ($usesNotNull)  { [void]$L.Add('import jakarta.validation.constraints.NotNull;') }
    if ($usesPattern)  { [void]$L.Add('import jakarta.validation.constraints.Pattern;') }
    if ($usesSize)     { [void]$L.Add('import jakarta.validation.constraints.Size;') }
    [void]$L.Add('import lombok.Getter;')
    [void]$L.Add('import lombok.NoArgsConstructor;')
    [void]$L.Add('import lombok.Setter;')
    if ($hasDate -or $hasBig) {
        [void]$L.Add('')
        if ($hasBig)  { [void]$L.Add('import java.math.BigDecimal;') }
        if ($hasDate) { [void]$L.Add('import java.util.Date;') }
    }
    [void]$L.Add('')
    [void]$L.Add('@Getter')
    [void]$L.Add('@Setter')
    [void]$L.Add('@NoArgsConstructor')
    [void]$L.Add("public class ${EntityName}DTO {")
    foreach ($b in $body) { [void]$L.Add($b) }
    [void]$L.Add('}')
    return Join-Java $L
}

# --- 3) Mapper
function Emit-Mapper($model) {
    $E = $EntityName
    $L = New-Object System.Collections.ArrayList
    [void]$L.Add("package fu.$SidLower.$svcLower.common;")
    [void]$L.Add('')
    [void]$L.Add("import fu.$SidLower.$svcLower.dto.${E}DTO;")
    if ($isDetail) {
        if ($DetailShape -eq 'B') { [void]$L.Add("import fu.$SidLower.$svcLower.dto.${E}ResponseDTO;") }
        [void]$L.Add("import fu.$SidLower.$svcLower.dto.${masterName}DTO;")
    }
    [void]$L.Add("import fu.$SidLower.$svcLower.entity.$E;")
    [void]$L.Add('')
    [void]$L.Add("public final class ${E}Mapper {")
    [void]$L.Add('')
    [void]$L.Add("    private ${E}Mapper() {")
    [void]$L.Add('    }')
    [void]$L.Add('')
    [void]$L.Add("    public static ${E}DTO toDTO($E entity) {")
    [void]$L.Add('        if (entity == null) {')
    [void]$L.Add('            return null;')
    [void]$L.Add('        }')
    [void]$L.Add("        ${E}DTO dto = new ${E}DTO();")
    foreach ($f in $model.Fields) {
        $c = Get-Cap $f.Name
        [void]$L.Add("        dto.set$c(entity.get$c());")
    }
    [void]$L.Add('        return dto;')
    [void]$L.Add('    }')
    if ($isDetail) {
        $mLower = $masterName.ToLower()
        $mCap = Get-Cap $mLower
        [void]$L.Add('')
        [void]$L.Add("    public static ${E}DTO toDTO($E entity, ${masterName}DTO $mLower) {")
        [void]$L.Add("        ${E}DTO dto = toDTO(entity);")
        [void]$L.Add('        if (dto != null) {')
        [void]$L.Add("            dto.set$mCap($mLower);")
        [void]$L.Add('        }')
        [void]$L.Add('        return dto;')
        [void]$L.Add('    }')
    }
    if ($isDetail -and $DetailShape -eq 'B') {
        $mLower = $masterName.ToLower()
        [void]$L.Add('')
        [void]$L.Add("    public static ${E}ResponseDTO toResponseDTO($E entity, ${masterName}DTO $mLower) {")
        [void]$L.Add('        if (entity == null) {')
        [void]$L.Add('            return null;')
        [void]$L.Add('        }')
        [void]$L.Add("        ${E}ResponseDTO dto = new ${E}ResponseDTO();")
        foreach ($f in $model.Fields) {
            if ($f.IsFk -or ($f.Name -eq 'status')) { continue }
            $c = Get-Cap $f.Name
            [void]$L.Add("        dto.set$c(entity.get$c());")
        }
        [void]$L.Add("        dto.set$(Get-Cap $mLower)($mLower);")
        [void]$L.Add('        return dto;')
        [void]$L.Add('    }')
    }
    [void]$L.Add('')
    [void]$L.Add("    public static $E toEntity(${E}DTO dto) {")
    [void]$L.Add('        if (dto == null) {')
    [void]$L.Add('            return null;')
    [void]$L.Add('        }')
    [void]$L.Add("        $E entity = new $E();")
    foreach ($f in $model.Fields) {
        if ($f.IsId) { continue }
        $c = Get-Cap $f.Name
        [void]$L.Add("        entity.set$c(dto.get$c());")
    }
    [void]$L.Add('        return entity;')
    [void]$L.Add('    }')
    [void]$L.Add('')
    [void]$L.Add("    public static void applyPartialUpdate($E entity, ${E}DTO dto) {")
    foreach ($f in $model.Fields) {
        if ($f.IsId) { continue }
        $c = Get-Cap $f.Name
        [void]$L.Add("        if (dto.get$c() != null) {")
        [void]$L.Add("            entity.set$c(dto.get$c());")
        [void]$L.Add('        }')
    }
    [void]$L.Add('    }')
    [void]$L.Add('}')
    return Join-Java $L
}

# --- 4) Repository sinh tu field THAT cua entity (khong con m.owner ma)
#     -Filter "param" / "param=fieldDTO" (theo bang Query Parameters cua DE) thay cho doan tu DB.
#     -Unique fieldDTO (theo yeu cau check trung cua DE) thay cho doan tu cot UNIQUE.
function Get-FilterSpecs($model) {
    if ($filterSpecsRaw.Count -gt 0) {
        $specs = @()
        foreach ($raw in $filterSpecsRaw) {
            $kv = $raw -split '=', 2
            $param = $kv[0].Trim()
            $fname = $param
            if ($kv.Count -eq 2) { $fname = $kv[1].Trim() }
            $fld = $model.Fields | Where-Object { $_.Name -ceq $fname } | Select-Object -First 1
            if (-not $fld) {
                Write-Host "LOI: -Filter '$raw' - khong co field '$fname' tren entity." -ForegroundColor Red
                Write-Host ("     Field hien co: " + (($model.Fields | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Yellow
                Write-Host '     Param cua DE khac ten field DTO thi ghi param=field (vd directorName=director).' -ForegroundColor Yellow
                exit 1
            }
            if ($fld.Type -ne 'String') {
                Write-Host "LOI: -Filter '$raw' - field '$fname' kieu $($fld.Type), LIKE partial-match chi lam duoc voi String." -ForegroundColor Red
                Write-Host '     Param so sanh (minStar >=, ngay checkInFrom, status exact) phai them tay o service.' -ForegroundColor Yellow
                exit 1
            }
            $specs += [pscustomobject]@{ Param = $param; Field = $fld }
        }
        return $specs
    }
    $cands = @($model.Fields | Where-Object {
        (-not $_.IsId) -and (-not $_.IsFk) -and $_.Type -eq 'String' -and $_.Name -ne 'status'
    })
    $named = @($cands | Where-Object { $_.Name -eq 'name' })
    $rest = @($cands | Where-Object { $_.Name -ne 'name' })
    $picked = @(@($named + $rest) | Select-Object -First 2)
    $specs = @()
    foreach ($c in $picked) { $specs += [pscustomobject]@{ Param = $c.Name; Field = $c } }
    return $specs
}

function Get-DupField($model) {
    if ($Unique -ne '') {
        $fld = $model.Fields | Where-Object { $_.Name -ceq $Unique } | Select-Object -First 1
        if (-not $fld) {
            Write-Host "LOI: -Unique '$Unique' - khong co field ten do tren entity." -ForegroundColor Red
            Write-Host ("     Field hien co: " + (($model.Fields | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Yellow
            exit 1
        }
        return $fld
    }
    $u = $model.Fields | Where-Object { $_.Unique -and -not $_.IsId } | Select-Object -First 1
    if ($u) { return $u }
    if ($isDetail) { return $null }
    $f = @(Get-FilterSpecs $model)
    if ($f.Count -gt 0) { return $f[0].Field }
    return $null
}

function Emit-Repository($model) {
    $E = $EntityName
    $alias = $E.Substring(0, 1).ToLower()
    $pk = $model.Fields | Where-Object { $_.IsId } | Select-Object -First 1
    $dup = Get-DupField $model
    $specs = @(Get-FilterSpecs $model)

    $L = New-Object System.Collections.ArrayList
    [void]$L.Add("package fu.$SidLower.$svcLower.repository;")
    [void]$L.Add('')
    [void]$L.Add("import fu.$SidLower.$svcLower.entity.$E;")
    [void]$L.Add('import org.springframework.data.domain.Page;')
    [void]$L.Add('import org.springframework.data.domain.Pageable;')
    [void]$L.Add('import org.springframework.data.jpa.repository.JpaRepository;')
    [void]$L.Add('import org.springframework.data.jpa.repository.Query;')
    if ($specs.Count -gt 0) { [void]$L.Add('import org.springframework.data.repository.query.Param;') }
    [void]$L.Add('import org.springframework.stereotype.Repository;')
    [void]$L.Add('')
    [void]$L.Add('@Repository')
    [void]$L.Add("public interface ${E}Repository extends JpaRepository<$E, Long> {")
    if ($dup) {
        $uCap = Get-Cap $dup.Name
        $pkCap = Get-Cap $pk.Name
        [void]$L.Add('')
        [void]$L.Add("    boolean existsBy$uCap($($dup.Type) $($dup.Name));")
        [void]$L.Add('')
        [void]$L.Add("    boolean existsBy${uCap}And${pkCap}Not($($dup.Type) $($dup.Name), $($pk.Type) $($pk.Name));")
    }
    [void]$L.Add('')
    if ($specs.Count -eq 0) {
        [void]$L.Add('    @Query("SELECT ' + $alias + ' FROM ' + $E + ' ' + $alias + '")')
        [void]$L.Add("    Page<$E> search(Pageable pageable);")
    }
    else {
        [void]$L.Add('    @Query("SELECT ' + $alias + ' FROM ' + $E + ' ' + $alias + ' WHERE "')
        for ($i = 0; $i -lt $specs.Count; $i++) {
            $p = $specs[$i].Param
            $fld = $specs[$i].Field.Name
            if ($fld -eq 'status') {
                $cond = "(:$p IS NULL OR $alias.status = :$p)"
            }
            else {
                $cond = "(:$p IS NULL OR LOWER($alias.$fld) LIKE LOWER(CONCAT('%', :$p, '%')))"
            }
            if ($i -lt $specs.Count - 1) { $cond += ' AND ' }
            $tail = ''
            if ($i -eq $specs.Count - 1) { $tail = ')' }
            [void]$L.Add('            + "' + $cond + '"' + $tail)
        }
        $ps = @()
        foreach ($s in $specs) { $ps += ('@Param("' + $s.Param + '") String ' + $s.Param) }
        $ps += 'Pageable pageable'
        [void]$L.Add("    Page<$E> search(" + ($ps -join ', ') + ');')
    }
    [void]$L.Add('}')
    return Join-Java $L
}

# --- 4bis) Patch Service/ServiceImpl/Controller cho khop repository moi
function Patch-ServiceLayer($model, [string]$oldRepoText) {
    $specs = @(Get-FilterSpecs $model)
    $dup = Get-DupField $model
    $pk = $model.Fields | Where-Object { $_.IsId } | Select-Object -First 1
    $pkCap = Get-Cap $pk.Name

    $oldFilters = @()
    foreach ($pm in [regex]::Matches($oldRepoText, '@Param\("(\w+)"\)')) {
        if ($oldFilters -notcontains $pm.Groups[1].Value) { $oldFilters += $pm.Groups[1].Value }
    }
    if ($oldFilters.Count -eq 0) {
        [void]$warnings.Add('Khong doc duoc filter cu tu repository - Service/ServiceImpl/Controller PHAI ra soat tay cho khop search() moi.')
        return
    }

    $exOld = [regex]::Match($oldRepoText, 'existsBy(\w+?)And(\w+?)Not')
    $keep = [Math]::Min($specs.Count, $oldFilters.Count)

    $targets = @(
        (Join-Path $pkgDir "service\${Service}Service.java"),
        (Join-Path $pkgDir "service\impl\${Service}ServiceImpl.java"),
        (Join-Path $pkgDir "controller\${SidUpper}${Service}Controller.java")
    )
    foreach ($t in $targets) {
        if (-not (Test-Path $t)) {
            [void]$warnings.Add("Khong thay $t - bo qua patch, ra soat tay.")
            continue
        }
        $txt = [System.IO.File]::ReadAllText($t)
        $orig = $txt

        for ($i = 0; $i -lt $keep; $i++) {
            $txt = [regex]::Replace($txt, "\b$([regex]::Escape($oldFilters[$i]))\b", "__GENFILTER${i}__")
        }
        for ($i = $oldFilters.Count - 1; $i -ge $keep; $i--) {
            $f = [regex]::Escape($oldFilters[$i])
            $txt = [regex]::Replace($txt, ",\s*@RequestParam\(required = false\)\s+String\s+$f\b", '')
            $txt = [regex]::Replace($txt, ",\s*String\s+$f\b", '')
            $txt = [regex]::Replace($txt, "String\s+$f\s*,\s*", '')
            $txt = [regex]::Replace($txt, ",\s*blankToNull\($f\)", '')
            $txt = [regex]::Replace($txt, "blankToNull\($f\)\s*,\s*", '')
            $txt = [regex]::Replace($txt, "\s*$f=\{\}", '')
            $txt = [regex]::Replace($txt, ",\s*$f\b", '')
        }
        for ($i = 0; $i -lt $keep; $i++) {
            $txt = $txt.Replace("__GENFILTER${i}__", $specs[$i].Param)
        }
        if ($specs.Count -gt $oldFilters.Count) {
            $prev = $specs[$oldFilters.Count - 1].Param
            for ($i = $oldFilters.Count; $i -lt $specs.Count; $i++) {
                $p = $specs[$i].Param
                $ctrlPat = "@RequestParam\(required = false\) String $prev\)"
                if ([regex]::IsMatch($txt, $ctrlPat)) {
                    $txt = [regex]::Replace($txt, $ctrlPat,
                        "@RequestParam(required = false) String $prev,`r`n                                               @RequestParam(required = false) String $p)")
                }
                else {
                    $txt = [regex]::Replace($txt, "String $prev\)", "String $prev, String $p)")
                }
                $txt = $txt.Replace("blankToNull($prev), pageable", "blankToNull($prev), blankToNull($p), pageable")
                $txt = [regex]::Replace($txt, "(\.list\(page, size[^)]*$prev)\)", "`$1, $p)")
                $prev = $p
            }
        }

        $setNull = [regex]::Match($txt, 'entity\.set(\w+)\(null\)')
        if ($setNull.Success -and $setNull.Groups[1].Value -cne $pkCap) {
            $txt = $txt.Replace('entity.set' + $setNull.Groups[1].Value + '(null)', 'entity.set' + $pkCap + '(null)')
        }

        $fkFields = @($model.Fields | Where-Object { $_.IsFk })
        $reqm = [regex]::Match($txt, 'require\w+Exists\(dto\.get(\w+)\(\)\)')
        if ($reqm.Success) {
            if ($fkFields.Count -eq 1) {
                $fkCap = Get-Cap $fkFields[0].Name
                if ($reqm.Groups[1].Value -cne $fkCap) {
                    $txt = $txt.Replace('dto.get' + $reqm.Groups[1].Value + '()', 'dto.get' + $fkCap + '()')
                }
            }
            elseif ($fkFields.Count -eq 0) {
                [void]$warnings.Add("ServiceImpl con goi require...Exists(dto.get$($reqm.Groups[1].Value)()) nhung entity KHONG co cot FK - se khong compile. Chay lai rename-template voi `$HasCategory = `$false, hoac xoa block do tay.")
            }
            else {
                [void]$warnings.Add('Entity co nhieu FK - kiem tra tay cac require...Exists trong ServiceImpl.')
            }
        }

        if ($exOld.Success -and $txt.Contains('existsBy')) {
            if ($dup) {
                $oldU = $exOld.Groups[1].Value
                $oldPk = $exOld.Groups[2].Value
                $uCap = Get-Cap $dup.Name
                $txt = $txt.Replace("existsBy${oldU}And${oldPk}Not", "existsBy${uCap}And${pkCap}Not")
                $txt = $txt.Replace("existsBy${oldU}(", "existsBy${uCap}(")
                $txt = $txt.Replace("dto.get${oldU}()", "dto.get${uCap}()")
            }
            else {
                [void]$warnings.Add("ServiceImpl con goi existsBy... nhung entity khong co field String de check trung - SUA TAY: $t")
            }
        }

        if ($t -like '*ServiceImpl.java' -and $SizeOverMax -ne '') {
            $flag = 'false'
            if ($SizeOverMax -eq 'error') { $flag = 'true' }
            $txt = [regex]::Replace($txt, 'SIZE_OVER_MAX_IS_ERROR = (true|false)', "SIZE_OVER_MAX_IS_ERROR = $flag")
        }

        if ($t -like '*ServiceImpl.java') {
            $statusSpec = $specs | Where-Object { $_.Field.Name -eq 'status' } | Select-Object -First 1
            if ($statusSpec) {
                $p = $statusSpec.Param
                $enumVals = @($StatusEnum -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
                $listOf = 'java.util.List.of(' + (($enumVals | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ')'
                if ($txt -match 'ALLOWED_STATUS\s*=') {
                    $txt = [regex]::Replace($txt, 'ALLOWED_STATUS\s*=\s*java\.util\.List\.of\([^)]*\)', "ALLOWED_STATUS = $listOf")
                }
                else {
                    $txt = [regex]::Replace($txt, '(private static final boolean SIZE_OVER_MAX_IS_ERROR[^\r\n]*;)',
                        "`$1`r`n    private static final java.util.List<String> ALLOWED_STATUS = $listOf;")
                }
                if ($txt -notmatch 'ALLOWED_STATUS\.contains') {
                    $check = "        if ($p != null && !$p.trim().isEmpty() && !ALLOWED_STATUS.contains($p)) {`r`n            throw new ValidationException(`"Data validation failed`");`r`n        }`r`n"
                    $txt = $txt.Replace("        pageSize = Math.min(pageSize, MAX_PAGE_SIZE);`r`n",
                        "        pageSize = Math.min(pageSize, MAX_PAGE_SIZE);`r`n$check")
                }
                if ($txt -notmatch 'ALLOWED_STATUS\.contains') {
                    [void]$warnings.Add('Khong tiem duoc check enum status vao list() (ServiceImpl da sua tay?) - tu them: gia tri ngoai ALLOWED_STATUS -> throw ValidationException 400/2.')
                }
            }
        }

        if ($txt -cne $orig) {
            if ($DryRun) {
                Write-Host ('  ~ [DRY RUN] se patch ' + $t.Substring($Root.Length + 1)) -ForegroundColor Cyan
            }
            else {
                [System.IO.File]::WriteAllText($t, $txt)
                Write-Host ('  ~ patch ' + $t.Substring($Root.Length + 1)) -ForegroundColor Green
            }
        }
    }
}

# --- 5a) ResponseDTO nested (chi phia Detail)
function Emit-ResponseDTO($model) {
    $E = $EntityName
    $mLower = $masterName.ToLower()
    $incl = @($model.Fields | Where-Object { (-not $_.IsFk) -and ($_.Name -ne 'status') })
    $hasDate = @($incl | Where-Object { $_.IsDate }).Count -gt 0
    $L = New-Object System.Collections.ArrayList
    [void]$L.Add("package fu.$SidLower.$svcLower.dto;")
    [void]$L.Add('')
    if ($hasDate) {
        [void]$L.Add('import com.fasterxml.jackson.databind.annotation.JsonDeserialize;')
        [void]$L.Add('import com.fasterxml.jackson.databind.annotation.JsonSerialize;')
        [void]$L.Add("import fu.$SidLower.$svcLower.common.DateOnlyDeserializer;")
        [void]$L.Add("import fu.$SidLower.$svcLower.common.DateOnlySerializer;")
    }
    [void]$L.Add('import lombok.Getter;')
    [void]$L.Add('import lombok.NoArgsConstructor;')
    [void]$L.Add('import lombok.Setter;')
    if ($hasDate) { [void]$L.Add(''); [void]$L.Add('import java.util.Date;') }
    [void]$L.Add('')
    [void]$L.Add('@Getter')
    [void]$L.Add('@Setter')
    [void]$L.Add('@NoArgsConstructor')
    [void]$L.Add("public class ${E}ResponseDTO {")
    foreach ($f in $incl) {
        [void]$L.Add('')
        if ($f.IsDate) {
            [void]$L.Add('    @JsonSerialize(using = DateOnlySerializer.class)')
            [void]$L.Add('    @JsonDeserialize(using = DateOnlyDeserializer.class)')
        }
        [void]$L.Add('    private ' + $f.Type + ' ' + $f.Name + ';')
    }
    [void]$L.Add('')
    [void]$L.Add("    private ${masterName}DTO $mLower;")
    [void]$L.Add('}')
    return Join-Java $L
}

# --- 5b) Ban copy DTO cua Master phia Feign (chi phia Detail)
function Emit-FeignCopy() {
    $masterProj = Join-Path $Root "$SidUpper${masterName}Service"
    $masterDtoFile = Join-Path $masterProj "src\main\java\fu\$SidLower\$($masterName.ToLower())\dto\${masterName}DTO.java"
    if (-not (Test-Path $masterDtoFile)) {
        Write-Host "LOI: khong thay $masterDtoFile" -ForegroundColor Red
        Write-Host "     Chay gen-from-entity.ps1 -Service $masterName TRUOC (B3) roi moi chay phia Detail (B5)." -ForegroundColor Red
        exit 1
    }
    $mtext = [System.IO.File]::ReadAllText($masterDtoFile)
    $mfields = New-Object System.Collections.ArrayList
    foreach ($fm in [regex]::Matches($mtext, '(?m)^\s*private\s+([\w\.]+)\s+(\w+)\s*;')) {
        [void]$mfields.Add([pscustomobject]@{ Type = ($fm.Groups[1].Value -replace '^.*\.', ''); Name = $fm.Groups[2].Value })
    }
    $hasDate = @($mfields | Where-Object { $_.Type -eq 'Date' }).Count -gt 0

    $L = New-Object System.Collections.ArrayList
    [void]$L.Add("package fu.$SidLower.$svcLower.dto;")
    [void]$L.Add('')
    [void]$L.Add('import com.fasterxml.jackson.annotation.JsonIgnoreProperties;')
    if ($hasDate) {
        [void]$L.Add('import com.fasterxml.jackson.databind.annotation.JsonDeserialize;')
        [void]$L.Add('import com.fasterxml.jackson.databind.annotation.JsonSerialize;')
        [void]$L.Add("import fu.$SidLower.$svcLower.common.DateOnlyDeserializer;")
        [void]$L.Add("import fu.$SidLower.$svcLower.common.DateOnlySerializer;")
    }
    [void]$L.Add('import lombok.Getter;')
    [void]$L.Add('import lombok.NoArgsConstructor;')
    [void]$L.Add('import lombok.Setter;')
    if ($hasDate) { [void]$L.Add(''); [void]$L.Add('import java.util.Date;') }
    [void]$L.Add('')
    [void]$L.Add('@Getter')
    [void]$L.Add('@Setter')
    [void]$L.Add('@NoArgsConstructor')
    [void]$L.Add('@JsonIgnoreProperties(ignoreUnknown = true)')
    [void]$L.Add("public class ${masterName}DTO {")
    foreach ($f in $mfields) {
        [void]$L.Add('')
        if ($f.Type -eq 'Date') {
            [void]$L.Add('    @JsonSerialize(using = DateOnlySerializer.class)')
            [void]$L.Add('    @JsonDeserialize(using = DateOnlyDeserializer.class)')
        }
        [void]$L.Add('    private ' + $f.Type + ' ' + $f.Name + ';')
    }
    [void]$L.Add('}')
    return Join-Java $L
}

# --- 5c) Patch ServiceImpl/ListDTO phia Detail theo shape (A/B/C) + ten FK/PK that
function Patch-DetailShape($model) {
    $implFile = Join-Path $pkgDir "service\impl\${Service}ServiceImpl.java"
    $listFile = Join-Path $pkgDir "dto\${Service}ListDTO.java"
    $respFile = Join-Path $pkgDir "dto\${Service}ResponseDTO.java"
    $fk = @($model.Fields | Where-Object { $_.IsFk }) | Select-Object -First 1

    $mPkCap = ''
    $mDtoFile = Join-Path $pkgDir "dto\${masterName}DTO.java"
    if (Test-Path $mDtoFile) {
        $mm = [regex]::Match([System.IO.File]::ReadAllText($mDtoFile), '(?m)^\s*private\s+[\w\.]+\s+(\w+)\s*;')
        if ($mm.Success) { $mPkCap = Get-Cap $mm.Groups[1].Value }
    }

    if (Test-Path $implFile) {
        $txt = [System.IO.File]::ReadAllText($implFile)
        $orig = $txt
        if ($DetailShape -eq 'B' -and -not $txt.Contains('.toResponseDTO(')) {
            [void]$warnings.Add('ServiceImpl khong con goi toResponseDTO (truoc do da chuyen shape A/C?) - muon ve B thi sua tay list() ve toResponseDTO + ListDTO ve <X>ResponseDTO.')
        }
        if ($mPkCap -ne '') {
            $txt = [regex]::Replace($txt, "(dto\.get$masterName\(\)\.get)\w+(\(\))", "`${1}$mPkCap`$2")
        }
        if ($fk) {
            $fkCap = Get-Cap $fk.Name
            if ($fkCap -cne "${masterName}Id") {
                $txt = $txt.Replace("entity.set${masterName}Id(", "entity.set$fkCap(")
                $txt = $txt.Replace("entity.get${masterName}Id()", "entity.get$fkCap()")
                $txt = $txt.Replace("saved.get${masterName}Id()", "saved.get$fkCap()")
                $txt = $txt.Replace("dto.get${masterName}Id()", "dto.get$fkCap()")
            }
        }
        else {
            [void]$warnings.Add('Entity Detail khong co cot FK _id - ServiceImpl dang set FK se khong compile, ra soat tay.')
        }
        if ($DetailShape -ne 'B') {
            $txt = $txt.Replace('.toResponseDTO(', '.toDTO(')
            if ($DetailShape -eq 'A') {
                $txt = [regex]::Replace($txt, "\.toDTO\(entity,\s*fetch\w+OrNull\(entity\.get\w+\(\)\)\)", '.toDTO(entity)')
            }
            $txt = [regex]::Replace($txt, "\b${Service}ResponseDTO\b", "${Service}DTO")
            $seenImports = @{}
            $outLines = New-Object System.Collections.ArrayList
            foreach ($l in ($txt -split "`r`n")) {
                if ($l -match '^import ') {
                    if ($seenImports.ContainsKey($l)) { continue }
                    $seenImports[$l] = $true
                }
                [void]$outLines.Add($l)
            }
            $txt = $outLines -join "`r`n"
        }
        if ($txt -cne $orig) {
            if ($DryRun) { Write-Host ('  ~ [DRY RUN] se patch ' + $implFile.Substring($Root.Length + 1)) -ForegroundColor Cyan }
            else {
                [System.IO.File]::WriteAllText($implFile, $txt)
                Write-Host ('  ~ patch ' + $implFile.Substring($Root.Length + 1)) -ForegroundColor Green
            }
        }
    }

    if ($DetailShape -ne 'B') {
        if (Test-Path $listFile) {
            $lt = [System.IO.File]::ReadAllText($listFile)
            $lt2 = [regex]::Replace($lt, "\b${Service}ResponseDTO\b", "${Service}DTO")
            if ($lt2 -cne $lt) {
                if ($DryRun) { Write-Host ('  ~ [DRY RUN] se patch ' + $listFile.Substring($Root.Length + 1)) -ForegroundColor Cyan }
                else {
                    [System.IO.File]::WriteAllText($listFile, $lt2)
                    Write-Host ('  ~ patch ' + $listFile.Substring($Root.Length + 1)) -ForegroundColor Green
                }
            }
        }
        if (Test-Path $respFile) {
            if ($DryRun) { Write-Host ('  ~ [DRY RUN] se XOA ' + $respFile.Substring($Root.Length + 1)) -ForegroundColor Cyan }
            else {
                Remove-Item $respFile -Force
                Write-Host ('  - xoa ' + $respFile.Substring($Root.Length + 1) + " (shape $DetailShape khong dung ResponseDTO)") -ForegroundColor Green
            }
        }
    }
}

# =====================================================================
$model = Read-EntityModel $entityFile

# Guard: moi ten field/cot phai la identifier hop le - chan truoc khi sinh ra
# code khong compile duoc (vu 'position' -> '\' ngay 27/07).
$badNames = @($model.Fields | Where-Object {
    $_.Name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$' -or $_.Col -notmatch '^[A-Za-z_][A-Za-z0-9_]*$'
})
if ($badNames.Count -gt 0) {
    Write-Host 'LOI: ten field/cot doc ra khong hop le - KHONG sinh file nao:' -ForegroundColor Red
    foreach ($b in $badNames) { Write-Host ("  field '" + $b.Name + "' / cot '" + $b.Col + "'") -ForegroundColor Red }
    Write-Host 'Nguyen nhan thuong gap: cot ten trung tu khoa SQL (position, level, value...)' -ForegroundColor Yellow
    Write-Host 'bi IntelliJ quote thanh @Column(name = "\"position\"") - mo entity sua lai tay roi chay lai.' -ForegroundColor Yellow
    exit 1
}

foreach ($rk in @($rulesMap.Keys)) {
    $rf = $model.Fields | Where-Object { $_.Name -ceq $rk } | Select-Object -First 1
    if (-not $rf) {
        Write-Host "LOI: -Rules co field '$rk' khong ton tai tren entity $EntityName." -ForegroundColor Red
        Write-Host ("     Field hien co: " + (($model.Fields | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Yellow
        exit 1
    }
    $r = $rulesMap[$rk]
    if (($r.ContainsKey('pattern') -or $r.ContainsKey('enum') -or $r.ContainsKey('email')) -and $rf.Type -ne 'String') {
        Write-Host "LOI: rule pattern/enum/email cho field '$rk' nhung kieu la $($rf.Type) (phai String)." -ForegroundColor Red
        exit 1
    }
    if (($r.ContainsKey('dateMin') -or $r.ContainsKey('dateMax') -or $r.ContainsKey('dateMaxDays') -or $r.ContainsKey('noFuture') -or $r.ContainsKey('futureOnly')) -and -not $rf.IsDate) {
        Write-Host "LOI: rule date cho field '$rk' nhung field khong phai kieu ngay." -ForegroundColor Red
        exit 1
    }
    if (($r.ContainsKey('numMin') -or $r.ContainsKey('numMax')) -and $rf.Type -notin 'Integer', 'Long', 'Short', 'Double', 'Float', 'BigDecimal') {
        Write-Host "LOI: rule numMin/numMax cho field '$rk' nhung kieu la $($rf.Type) (phai kieu so)." -ForegroundColor Red
        exit 1
    }
}

$statusField = $model.Fields | Where-Object { $_.Name -eq 'status' } | Select-Object -First 1
if ($statusField) {
    [void]$warnings.Add("status dung enum '$StatusEnum' - DOI CHIEU CHECK constraint trong script SQL cua DE, khac thi chay lai voi -StatusEnum 'A,B,C'.")
}

$role = 'phia Master (khong co Feign client)'
if ($isDetail) { $role = "phia Detail (thay ${masterName}Client) | shape $DetailShape" }
Write-Host ''
Write-Host "Project : $proj" -ForegroundColor Cyan
Write-Host "Entity  : $EntityName -> table '$($model.Table)' | $role" -ForegroundColor Cyan
Write-Host ''
Write-Host 'FIELD          COT             KIEU      RANG BUOC'
Write-Host '-----          ---             ----      ---------'
foreach ($f in $model.Fields) {
    $rb = @()
    if ($f.IsId) { $rb += 'PK' }
    if (-not $f.Nullable -and -not $f.IsId) { $rb += 'NOT NULL' }
    if ($f.Length -gt 0 -and $f.Type -eq 'String') { $rb += "max $($f.Length)" }
    if ($f.Unique) { $rb += 'UNIQUE' }
    if ($f.IsFk) { $rb += 'FK' }
    Write-Host ('{0,-14} {1,-15} {2,-9} {3}' -f $f.Name, $f.Col, $f.Type, ($rb -join ', '))
}

Out-Gen $entityFile (Emit-Entity $model)
Out-Gen (Join-Path $pkgDir "dto\${EntityName}DTO.java") (Emit-DTO $model)
Out-Gen (Join-Path $pkgDir "common\${EntityName}Mapper.java") (Emit-Mapper $model)
if ($EntityName -eq $Service) {
    $repoFile = Join-Path $pkgDir "repository\${EntityName}Repository.java"
    $oldRepoText = ''
    if (Test-Path $repoFile) { $oldRepoText = [System.IO.File]::ReadAllText($repoFile) }
    Out-Gen $repoFile (Emit-Repository $model)
    Patch-ServiceLayer $model $oldRepoText

    $specsNow = @(Get-FilterSpecs $model)
    if ($filterSpecsRaw.Count -gt 0) {
        $desc = @($specsNow | ForEach-Object { if ($_.Param -cne $_.Field.Name) { "$($_.Param)->$($_.Field.Name)" } else { $_.Param } })
        Write-Host ("Filter theo -Filter cua DE: " + ($desc -join ', ')) -ForegroundColor Cyan
        Write-Host '  (ben TRAI dau = la ten query param tren URL, ben PHAI la field entity no tim)' -ForegroundColor DarkGray
    }
    if (@($specsNow | Where-Object { $_.Field.Name -eq 'status' }).Count -gt 0) {
        [void]$warnings.Add("Filter 'status': da sinh EXACT match + tiem check ALLOWED_STATUS vao list() (gia tri bay -> 400/2). DOI CHIEU message 'Data validation failed' voi bang Response Behavior cua de.")
    }
    elseif ($specsNow.Count -gt 0) {
        [void]$warnings.Add("search() tam DOAN filter theo: " + (($specsNow | ForEach-Object { $_.Param }) -join ', ') + " - doc bang Query Parameters cua DE roi chay lai voi -Filter `"param1,param2=field`" cho chac.")
    }
    else {
        [void]$warnings.Add('Entity khong co field String nao -> search() chi phan trang. Doc de xem query param la gi roi chay lai voi -Filter hoac them tay.')
    }
    $realUnique = $model.Fields | Where-Object { $_.Unique -and -not $_.IsId } | Select-Object -First 1
    $dupPick = Get-DupField $model
    if ($Unique -ne '' -and $dupPick) {
        Write-Host ("Check trung theo -Unique cua DE: " + $dupPick.Name) -ForegroundColor Cyan
    }
    elseif (-not $realUnique -and $dupPick) {
        [void]$warnings.Add("DB khong co UNIQUE -> existsBy tam dat theo '$($dupPick.Name)'. De co yeu cau check trung field khac thi chay lai voi -Unique <field>; KHONG yeu cau thi xoa block DuplicateNameException trong ServiceImpl.")
    }
    if (-not ($model.Fields | Where-Object { $_.Name -eq 'status' })) {
        [void]$warnings.Add('Entity khong co field status -> entity.setStatus(...) trong ServiceImpl se KHONG compile - doc de roi sua create/deactivate tay.')
    }
}
if ($isDetail) {
    if ($DetailShape -eq 'B') {
        Out-Gen (Join-Path $pkgDir "dto\${EntityName}ResponseDTO.java") (Emit-ResponseDTO $model)
    }
    Out-Gen (Join-Path $pkgDir "dto\${masterName}DTO.java") (Emit-FeignCopy)
    Patch-DetailShape $model
}

Write-Host ''
if ($warnings.Count -gt 0) {
    Write-Host 'CANH BAO:' -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  ! $w" -ForegroundColor Yellow }
    Write-Host ''
}
if ($DryRun) { Write-Host "DRY RUN - chua ghi file nao ($($generated.Count) file se sinh)." -ForegroundColor Yellow }
else { Write-Host "XONG. Da sinh $($generated.Count) file." -ForegroundColor Green }

$uniqueFields = @($model.Fields | Where-Object { $_.Unique } | ForEach-Object { Get-Cap $_.Name })
Write-Host ''
Write-Host 'CON LAI PHAI TU LAM (B4 - xem DOI-TEN-TUNG-BUOC.md):' -ForegroundColor Yellow
Write-Host '  1. Doi chieu bang DTO cua de: ten field khac cot -> chay lai voi -Rename "ten_cot=tenDTO"'
if ($uniqueFields.Count -gt 0) {
    Write-Host ("  2. Check trung da sinh theo cot UNIQUE = " + ($uniqueFields -join ', ') + " - doi chieu message 400/3 voi de")
}
else {
    Write-Host '  2. Khong thay cot UNIQUE - doc de xem co bat check trung khong'
}
Write-Host '  3. Query param search: dung -Filter "p1,p2=field" theo DE (TRAI=param URL, PHAI=field entity;'
Write-Host '     khong dien la script tu doan tu DB). status da duoc exact match + check enum tu dong;'
Write-Host '     param so sanh khac (minStar >=, checkInFrom ngay...) van phai them tay'
Write-Host '  4. Controller: message copy Y NGUYEN cau chu de'
Write-Host '  5. Rule ngay (format/after X/not future...): bat hang so trong common/ValidDate.java'
Write-Host '  6. Doc MOI CHECK constraint trong script SQL cua de -> phai co check tuong ung o code'
Write-Host '     (date >= getdate() -> FUTURE_ONLY; end >= start -> check o service SAU applyPartialUpdate)'
Write-Host '     De lot xuong DB la 500/0 thay vi 400/2 - handler DataIntegrity chi la luoi cuoi.'
if ($isDetail) {
    Write-Host "  7. Shape dang la $DetailShape - doi chieu bang DTO cua de:"
    Write-Host '     de co CA masterId lan DTO list nested rieng -> B (mac dinh, kieu Trial)'
    Write-Host '     de chi co object nested trong 1 DTO duy nhat -> chay lai voi -DetailShape C'
    Write-Host '     de phang het ke ca list -> chay lai voi -DetailShape A'
}
