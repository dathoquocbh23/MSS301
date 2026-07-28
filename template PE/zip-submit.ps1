# =====================================================================
#  zip-submit.ps1 - Don dep + zip 3 project de nop EOS (BUOC 5)
#    powershell -ExecutionPolicy Bypass -File .\zip-submit.ps1
#  Lam gi:
#    1. Kiem tra application.properties (password/username/db/port) - canh bao neu le
#    2. Xoa target/ + .idea/ + *.iml trong tung project
#    3. Zip TUNG PROJECT FOLDER (giai nen ra la thay folder project o root zip)
#    4. -Bundle: goi 3 zip vao 1 zip tong (khi EOS chi cho nop 1 file)
#  Zip xong TU GIAI NEN THU ra cho khac, mo IntelliJ chay lai duoc roi hay nop!
#  File ASCII thuan cho PowerShell 5.1.
# =====================================================================
param(
    [string]$Root = "e:\fpt_university\Semester8\MSS301\PE\EXAM",
    [string]$ExpectedPassword = "sa",
    [switch]$Bundle
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Root)) { Write-Host "LOI: khong thay $Root" -ForegroundColor Red; exit 1 }

$projects = Get-ChildItem $Root -Directory | Where-Object { $_.Name -match '^SE193114\w+$' }
if ($projects.Count -eq 0) { Write-Host "LOI: khong thay project SE193114* nao trong $Root" -ForegroundColor Red; exit 1 }

# 1) Kiem tra properties truoc khi nop (muc 3 Grading Policies: sai = 0 diem)
$warn = 0
foreach ($p in $projects) {
    Get-ChildItem $p.FullName -Recurse -Filter application.properties | Where-Object { $_.FullName -notmatch '\\target\\' } | ForEach-Object {
        $t = [System.IO.File]::ReadAllText($_.FullName)
        if ($t -match 'spring\.datasource\.password=(.+)') {
            $pw = $Matches[1].Trim()
            if ($pw -cne $ExpectedPassword) {
                Write-Host "CANH BAO: $($p.Name) password='$pw' (de yeu cau '$ExpectedPassword')" -ForegroundColor Red
                $script:warn++
            }
        }
        if ($t -match 'ddl-auto=(update|create|create-drop)') {
            Write-Host "CANH BAO: $($p.Name) ddl-auto dang '$($Matches[1])' - nen la none" -ForegroundColor Red
            $script:warn++
        }
    }
}
if ($warn -gt 0) {
    Write-Host ""
    Write-Host "SUA CAC CANH BAO TREN roi chay lai. (Muon zip bat chap thi sua script)" -ForegroundColor Red
    exit 1
}

# 2) Don rac
foreach ($p in $projects) {
    Get-ChildItem $p.FullName -Recurse -Directory | Where-Object { $_.Name -in 'target', '.idea' } |
        Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    Get-ChildItem $p.FullName -Recurse -Filter *.iml | Remove-Item -Force -ErrorAction SilentlyContinue
}

# 3) Zip tung project folder
$submitDir = Join-Path $Root 'submit'
if (Test-Path $submitDir) { Remove-Item $submitDir -Recurse -Force }
New-Item -ItemType Directory -Force $submitDir | Out-Null
$zips = @()
foreach ($p in $projects) {
    $zip = Join-Path $submitDir "$($p.Name).zip"
    Compress-Archive -Path $p.FullName -DestinationPath $zip -Force
    $zips += $zip
    Write-Host ("  + " + $zip) -ForegroundColor Green
}

# 4) Goi 1 zip tong neu can
if ($Bundle) {
    $big = Join-Path $submitDir 'SE193114_ALL.zip'
    Compress-Archive -Path $zips -DestinationPath $big -Force
    Write-Host ("  + " + $big + "  (nop file nay neu EOS chi cho 1 file)") -ForegroundColor Green
}

Write-Host ""
Write-Host "XONG. File nop nam trong: $submitDir" -ForegroundColor Green
Write-Host "TRUOC KHI NOP: giai nen thu 1 zip ra cho khac -> mo IntelliJ -> Maven reload -> chay duoc moi nop!" -ForegroundColor Yellow
