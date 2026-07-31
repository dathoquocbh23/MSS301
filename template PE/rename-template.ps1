# =====================================================================
#  rename-template.ps1 - Doi template Master/Detail/Category/Gateway thanh bai thi
#  Cach dung: sua cac bien duoi theo BANG BUOC 0 trong DOI-TEN-TUNG-BUOC.md roi
#    powershell -ExecutionPolicy Bypass -File .\rename-template.ps1
#  Template goc KHONG bi dung - moi thu copy sang $Dest.
#  LUU Y: file nay co tinh ASCII thuan (khong dau) de PowerShell 5.1
#  doc dung du may thiet lap bang ma nao.
# =====================================================================

$Src        = $PSScriptRoot                                        # folder "template PE" (tu nhan)
$Dest       = "e:\fpt_university\Semester8\MSS301\PE\EXAM"     # folder bai lam moi
$MasterNew  = "Room"        # ten thay cho Master  (Viet Hoa Dau, dung chinh ta de)
$DetailNew  = "Reservation"       # ten thay cho Detail  (Viet Hoa Dau)
$CategoryNew = "Category"     # ten entity phu theo de (chi co nghia khi $HasCategory = $true)
$GatewayNew = "HotelGateway"   # ten project gateway theo de (phan SAU MSSV)

# De KHONG co entity phu (kieu PE1 Department/Employee) -> dat $false:
# script tu XOA 7 file Category*, go route gateway, cat cac dong CATEGORY trong ServiceImpl.
$HasCategory = $false

# So nhieu trong URL (/api/...). De trong = tu dong lay ten thuong + "s".
# BAT BUOC dien tay khi so nhieu bat quy tac: hotel-types, categories, companies
$MasterPlural   = ""
$DetailPlural   = ""
$CategoryPlural = "categories"

# Ten BANG trong DB - chi dien khi KHAC so nhieu o tren (doi chieu script SQL cua de).
# Vi du Mock01: URL /api/hotel-types nhung bang ten "HotelType" -> dien "HotelType".
# De trong = lay so nhieu. (Ten bang co dau gach noi la INVALID SQL -> phai dien o day.)
$MasterTable   = ""
$DetailTable   = ""
$CategoryTable = ""

# ---------------------------------------------------------------------
# CAU HINH application.properties - CHEP TU BANG "Configuration" CUA DE.
# MUC 3 Grading Policies: sai bang nay = 0 DIEM CA BAI. Script ghi cho ca 2 service
# nen khong con canh "doi password ben Master, quen ben Detail" (loi that ngay 27/07).
$DbName       = "MSS301_2026_PE"
$DbUser       = "sa"
$DbPass       = "sa"
$DbUrl        = "jdbc:sqlserver://localhost:1433;databaseName=$DbName;encrypt=false;"
$DdlAuto      = "none"
$PortMaster   = 8081
$PortDetail   = 8082
$PortGateway  = 8080

# ---------------------------------------------------------------------
function ConvertTo-CamelName([string]$s) { return $s.Substring(0, 1).ToLower() + $s.Substring(1) }
function ConvertTo-SnakeName([string]$s) { return ([regex]::Replace($s, '(?<=[a-z0-9])([A-Z])', '_$1')).ToLower() }

$masterLower   = $MasterNew.ToLower()
$detailLower   = $DetailNew.ToLower()
$categoryLower = $CategoryNew.ToLower()
# Dang camelCase cho ten bien/field ghep (masterId -> hotelTypeId, khong phai hoteltypeId)
$masterCamel   = ConvertTo-CamelName $MasterNew
$detailCamel   = ConvertTo-CamelName $DetailNew
$categoryCamel = ConvertTo-CamelName $CategoryNew
# Dang snake_case cho ten COT (category_id -> hotel_type_id)
$masterSnake   = ConvertTo-SnakeName $MasterNew
$detailSnake   = ConvertTo-SnakeName $DetailNew
$categorySnake = ConvertTo-SnakeName $CategoryNew
if (-not $MasterPlural)   { $MasterPlural   = $masterLower + "s" }
if (-not $DetailPlural)   { $DetailPlural   = $detailLower + "s" }
if (-not $CategoryPlural) { $CategoryPlural = $categoryLower + "s" }
if (-not $MasterTable)    { $MasterTable    = $MasterPlural }
if (-not $DetailTable)    { $DetailTable    = $DetailPlural }
if (-not $CategoryTable)  { $CategoryTable  = $CategoryPlural }

if (Test-Path $Dest) {
    Write-Host "LOI: $Dest da ton tai - xoa hoac doi ten truoc de khong ghi de nham." -ForegroundColor Red
    exit 1
}

# 1) Copy (bo target/)
New-Item -ItemType Directory -Force $Dest | Out-Null
foreach ($item in 'SE193114MasterService','SE193114DetailService','SE193114Gateway','sql') {
    Copy-Item -Recurse -Force (Join-Path $Src $item) (Join-Path $Dest $item)
}
Get-ChildItem $Dest -Recurse -Directory -Filter target | Remove-Item -Recurse -Force -Confirm:$false

# 1b) De khong co entity phu -> don sach code Category TRUOC khi doi ten
if (-not $HasCategory) {
    $mroot = Join-Path $Dest 'SE193114MasterService\src\main\java\fu\se193114\master'
    foreach ($f in 'entity\Category.java', 'dto\CategoryDTO.java', 'repository\CategoryRepository.java',
                   'service\CategoryService.java', 'service\impl\CategoryServiceImpl.java',
                   'controller\SE193114CategoryController.java', 'common\CategoryMapper.java') {
        $p = Join-Path $mroot $f
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    # cat code Category trong MasterServiceImpl (source khong co comment/marker nao)
    $svcFile = Join-Path $mroot 'service\impl\MasterServiceImpl.java'
    $lines = [System.IO.File]::ReadAllLines($svcFile)
    $out = New-Object System.Collections.ArrayList
    $inMethod = $false
    $depth = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $ln = $lines[$i]
        if ($inMethod) {
            $depth += ([regex]::Matches($ln, '\{')).Count - ([regex]::Matches($ln, '\}')).Count
            if ($depth -le 0) { $inMethod = $false }
            continue
        }
        if ($ln -match 'private void requireCategoryExists') {
            $inMethod = $true
            $depth = ([regex]::Matches($ln, '\{')).Count - ([regex]::Matches($ln, '\}')).Count
            # nuot luon dong trong ngay truoc method
            if ($out.Count -gt 0 -and $out[$out.Count - 1].Trim() -eq '') { $out.RemoveAt($out.Count - 1) }
            continue
        }
        if ($ln -match 'CategoryRepository') { continue }
        if ($ln -match 'annotation\.Autowired') { continue }
        if ($ln.Trim() -eq '@Autowired') { continue }
        if ($ln -match 'requireCategoryExists') { continue }
        [void]$out.Add($ln)
    }
    # don cac cap dong trong lien nhau phat sinh sau khi cat
    $clean = New-Object System.Collections.ArrayList
    $prevBlank = $false
    foreach ($ln in $out) {
        $blank = ($ln.Trim() -eq '')
        if ($blank -and $prevBlank) { continue }
        [void]$clean.Add($ln)
        $prevBlank = $blank
    }
    [System.IO.File]::WriteAllText($svcFile, (($clean -join "`r`n") + "`r`n"))
    # go route category + comment lien quan khoi gateway
    $gw = Join-Path $Dest 'SE193114Gateway\src\main\resources\application.properties'
    $glines = [System.IO.File]::ReadAllLines($gw) | Where-Object { $_ -notmatch 'routes\[4\]' -and $_ -notmatch '(?i)categor' }
    [System.IO.File]::WriteAllLines($gw, [string[]]$glines)
}

# 2) Doi ten THU MUC - sau nhat truoc de khong hong path cha
Get-ChildItem $Dest -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
    $n = $_.Name
    if ($n -ceq 'SE193114Gateway') { $n = "SE193114$GatewayNew" }
    $n = $n.Replace('Master', $MasterNew)
    $n = $n.Replace('master', $masterLower)
    $n = $n.Replace('Detail', $DetailNew)
    $n = $n.Replace('detail', $detailLower)
    $n = $n.Replace('Category', $CategoryNew)
    $n = $n.Replace('category', $categoryLower)
    if ($n -cne $_.Name) { Rename-Item $_.FullName $n }
}

# 3) Doi ten FILE
Get-ChildItem $Dest -Recurse -File | ForEach-Object {
    $n = $_.Name
    $n = $n.Replace('Se193114Gateway', "Se193114$GatewayNew")
    $n = $n.Replace('Master', $MasterNew)
    $n = $n.Replace('master', $masterLower)
    $n = $n.Replace('Detail', $DetailNew)
    $n = $n.Replace('detail', $detailLower)
    $n = $n.Replace('Category', $CategoryNew)
    $n = $n.Replace('category', $categoryLower)
    if ($n -cne $_.Name) { Rename-Item $_.FullName $n }
}

# 4) Thay NOI DUNG (case-sensitive). THU TU QUAN TRONG: so nhieu truoc, roi Hoa, roi thuong.
#    WriteAllText mac dinh UTF-8 khong BOM - an toan cho javac.
$exts = '.java', '.xml', '.properties', '.sql', '.md'
Get-ChildItem $Dest -Recurse -File | Where-Object { $exts -contains $_.Extension } | ForEach-Object {
    $t = [System.IO.File]::ReadAllText($_.FullName)
    $new = $t
    $new = $new.Replace('SE193114Gateway', "SE193114$GatewayNew")
    $new = $new.Replace('Se193114Gateway', "Se193114$GatewayNew")
    $new = $new.Replace('masters',    $MasterPlural)
    $new = $new.Replace('details',    $DetailPlural)
    $new = $new.Replace('categories', $CategoryPlural)
    # ten COT: master_id -> hotel_id, category_id -> hotel_type_id
    $new = $new.Replace('master_',   $masterSnake + '_')
    $new = $new.Replace('detail_',   $detailSnake + '_')
    $new = $new.Replace('category_', $categorySnake + '_')
    # ten BIEN ghep: masterId -> hotelId, categoryId -> hotelTypeId (KHONG phai hoteltypeId)
    $new = [regex]::Replace($new, 'master(?=[A-Z])',   $masterCamel)
    $new = [regex]::Replace($new, 'detail(?=[A-Z])',   $detailCamel)
    $new = [regex]::Replace($new, 'category(?=[A-Z])', $categoryCamel)
    $new = $new.Replace('Master', $MasterNew)
    $new = $new.Replace('master', $masterLower)
    $new = $new.Replace('Detail', $DetailNew)
    $new = $new.Replace('detail', $detailLower)
    $new = $new.Replace('Category', $CategoryNew)
    $new = $new.Replace('category', $categoryLower)
    if ($new -cne $t) { [System.IO.File]::WriteAllText($_.FullName, $new) }
}

# 4b) Ten BANG khac so nhieu URL -> sua lai @Table (va ten bang trong sql mau)
$tableFix = @{ $MasterPlural = $MasterTable; $DetailPlural = $DetailTable; $CategoryPlural = $CategoryTable }
Get-ChildItem $Dest -Recurse -File | Where-Object { $_.Extension -in '.java', '.sql' } | ForEach-Object {
    $t = [System.IO.File]::ReadAllText($_.FullName)
    $new = $t
    foreach ($k in $tableFix.Keys) {
        if ($tableFix[$k] -cne $k) {
            $new = $new.Replace('@Table(name = "' + $k + '")', '@Table(name = "' + $tableFix[$k] + '")')
            if ($_.Extension -eq '.sql') { $new = [regex]::Replace($new, '(?<![\w-])' + [regex]::Escape($k) + '(?![\w-])', $tableFix[$k]) }
        }
    }
    if ($new -cne $t) { [System.IO.File]::WriteAllText($_.FullName, $new) }
}

# 4c) Ghi application.properties theo bang Configuration cua de (muc 0 diem)
function Set-Prop([string]$file, [string]$key, [string]$value) {
    if (-not (Test-Path $file)) { return }
    $lines = [System.IO.File]::ReadAllLines($file)
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ('^\s*' + [regex]::Escape($key) + '\s*=')) {
            $lines[$i] = "$key=$value"
            $found = $true
        }
    }
    if (-not $found) { $lines += "$key=$value" }
    [System.IO.File]::WriteAllLines($file, [string[]]$lines)
}

$propMaster = Join-Path $Dest "SE193114${MasterNew}Service\src\main\resources\application.properties"
$propDetail = Join-Path $Dest "SE193114${DetailNew}Service\src\main\resources\application.properties"
$propGw     = Join-Path $Dest "SE193114$GatewayNew\src\main\resources\application.properties"

foreach ($pair in @(@{ f = $propMaster; p = $PortMaster }, @{ f = $propDetail; p = $PortDetail })) {
    Set-Prop $pair.f 'spring.datasource.url'          $DbUrl
    Set-Prop $pair.f 'spring.datasource.username'     $DbUser
    Set-Prop $pair.f 'spring.datasource.password'     $DbPass
    Set-Prop $pair.f 'spring.jpa.hibernate.ddl-auto'  $DdlAuto
    Set-Prop $pair.f 'server.port'                    $pair.p
}
Set-Prop $propGw 'server.port' $PortGateway

# 5) Bao cao + nhac viec script KHONG lam duoc
Write-Host ""
Write-Host "XONG. Bai lam o: $Dest" -ForegroundColor Green
Write-Host "  SE193114${MasterNew}Service (8081) | SE193114${DetailNew}Service (8082) | SE193114$GatewayNew (8080)"
if ($HasCategory) { Write-Host "  URL: /api/$MasterPlural  /api/$DetailPlural  /api/$CategoryPlural" }
else { Write-Host "  URL: /api/$MasterPlural  /api/$DetailPlural  (da don sach code Category)" }
Write-Host ""
Write-Host "CON LAI PHAI TU LAM (xem DOI-TEN-TUNG-BUOC.md, Buoc 3):" -ForegroundColor Yellow
Write-Host "  1. @Table/@Column doi chieu SCRIPT SQL cua DE (khong theo doc)"
Write-Host "  2. Field DTO + validation theo bang DTO + bang Database cua DE"
Write-Host "     (dung gen-from-entity.ps1 / rename-field.ps1 / clone-field.ps1)"
Write-Host "  3. Message + HTTP code + status copy Y NGUYEN cau chu de"
if ($HasCategory) { Write-Host "  4. Entity phu ${CategoryNew}: doi chieu bang cua de + route /api/$CategoryPlural da co san" }
else { Write-Host "  4. (Khong co entity phu - da xoa; MasterDTO van con field categoryId, gen-from-entity se tu bo khi DB khong co cot do)" }
Write-Host "  5. Rule ngay (format/after X/not future...) - bat hang so trong common/ValidDate.java"
Write-Host "  6. MOI CHECK constraint trong SQL de -> check tuong ung o code (khong thi 500/0 thay vi ma validation)"
Write-Host ""
Write-Host "DA GHI HO application.properties (doi chieu lai bang Configuration cua de!):" -ForegroundColor Cyan
Write-Host "     db=$DbName  user=$DbUser  pass=$DbPass  ddl-auto=$DdlAuto"
Write-Host "     port: $PortMaster / $PortDetail / $PortGateway"
Write-Host ""
Write-Host "BUOC TIEP THEO BAT BUOC - BANG MA HTTP:" -ForegroundColor Yellow
Write-Host "  Mo gen-all.ps1, dien \$HttpValidation/\$HttpDuplicate/\$HttpNotFound/\$HttpBusiness"
Write-Host "  theo cot 'HTTP Code' trong bang Response Behavior cua DE, roi chay:"
Write-Host "     powershell -ExecutionPolicy Bypass -File .\gen-all.ps1 -HttpOnly"
Write-Host "  Template mac dinh 400 cho tat ca (kieu de Trial/PE1). De SU26 PE1 dung 406/226/404/400"
Write-Host "  -> khong doi la sai HTTP code o GAN NHU MOI dong cua moi bang." -ForegroundColor Yellow
