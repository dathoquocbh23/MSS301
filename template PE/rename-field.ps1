# =====================================================================
#  rename-field.ps1 - Doi ten MOT field cua entity tren CA 3 PROJECT
#  Vi du:  de bat doi "description" thanh "note", cot SQL van la description
#    powershell -ExecutionPolicy Bypass -File .\rename-field.ps1 -Old description -New note -Column description
#  Neu cot SQL cung doi thanh note thi bo -Column (mac dinh lay ten moi).
#  Luon chay thu truoc bang -DryRun de xem no dinh sua nhung dong nao.
#  File ASCII thuan cho PowerShell 5.1.
# =====================================================================
param(
    [string]$Root = "e:\fpt_university\Semester8\MSS301\PE\EXAM",
    [Parameter(Mandatory = $true)][string]$Old,      # ten field cu, viet thuong dau: description
    [Parameter(Mandatory = $true)][string]$New,      # ten field moi, viet thuong dau: note
    [string]$Column = "",                            # ten COT SQL sau khi doi; rong = dung $New
    [switch]$DryRun
)

if (-not (Test-Path $Root)) { Write-Host "LOI: khong thay $Root" -ForegroundColor Red; exit 1 }

$OldP = $Old.Substring(0, 1).ToUpper() + $Old.Substring(1)   # Description
$NewP = $New.Substring(0, 1).ToUpper() + $New.Substring(1)   # Note
if ([string]::IsNullOrEmpty($Column)) { $Column = $New }

function Convert-Text([string]$t) {
    $s = $t
    # 1) getter/setter Lombok sinh ra (getDescription -> getNote)
    $s = [regex]::Replace($s, "get$OldP(?![A-Za-z0-9_])", "get$NewP")
    $s = [regex]::Replace($s, "set$OldP(?![A-Za-z0-9_])", "set$NewP")
    $s = [regex]::Replace($s, "is$OldP(?![A-Za-z0-9_])",  "is$NewP")
    # 2) ten field, ten trong @Query JPQL, message validation, @Column(name=...)
    $s = [regex]::Replace($s, "\b$Old\b", $New)
    $s = [regex]::Replace($s, "\b$OldP\b", $NewP)
    # 3) tra ten COT ve dung yeu cau (buoc 2 vua doi no theo ten field)
    $s = [regex]::Replace($s, '(@Column\(name\s*=\s*")' + [regex]::Escape($New) + '(")', '${1}' + $Column + '${2}')
    return $s
}

$touched = 0
Get-ChildItem $Root -Recurse -File -Filter *.java |
    Where-Object { $_.Name -ne 'OpenApiConfig.java' } |     # .description() cua springdoc - dung dung
    ForEach-Object {
        $orig = [System.IO.File]::ReadAllText($_.FullName)
        $done = Convert-Text $orig            # KHONG dat ten $new - trung tham so $New (PS khong phan biet hoa thuong)
        if ($done -cne $orig) {
            $touched++
            Write-Host ""
            Write-Host $_.FullName.Substring($Root.Length + 1) -ForegroundColor Cyan
            $a = @($orig -split "`r?`n")
            $b = @($done -split "`r?`n")
            for ($i = 0; $i -lt $a.Count; $i++) {
                if ($a[$i] -cne $b[$i]) {
                    Write-Host ("  - " + $a[$i].Trim()) -ForegroundColor DarkRed
                    Write-Host ("  + " + $b[$i].Trim()) -ForegroundColor Green
                }
            }
            if (-not $DryRun) { [System.IO.File]::WriteAllText($_.FullName, $done) }
        }
    }

Write-Host ""
if ($DryRun) { Write-Host "DRY RUN - chua ghi gi. $touched file se doi." -ForegroundColor Yellow }
else         { Write-Host "XONG. Da sua $touched file." -ForegroundColor Green }
Write-Host "Nho ra lai bang tay:" -ForegroundColor Yellow
Write-Host "  1. @Column(name=...) co dung ten cot trong SCRIPT SQL cua de khong"
Write-Host "  2. Message validation phai copy Y NGUYEN cau chu de (script doi may moc theo ten field)"
Write-Host "  3. Native query / ten cot trong file .sql: script KHONG dung toi"
