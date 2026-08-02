# =====================================================================
#  clone-field.ps1 - THEM MOT FIELD MOI bang cach nhan ban 1 field da co
#  Y tuong: field "description" da nam dung 7 cho (entity/DTO/mapper/service...).
#  Script tim moi khoi lenh nhac toi no, copy them 1 ban, doi ten thanh field moi.
#  Vi du: de co them cot "note" kieu chuoi
#    powershell -ExecutionPolicy Bypass -File .\clone-field.ps1 -From description -To note -DryRun
#  Sau do MO ENTITY sua lai kieu du lieu / length / annotation cho dung de.
#  File ASCII thuan cho PowerShell 5.1.
# =====================================================================
param(
    [string]$Root = "e:\fpt_university\Semester8\MSS301\PE\EXAM",
    [Parameter(Mandatory = $true)][string]$From,     # field mau da co: description
    [Parameter(Mandatory = $true)][string]$To,       # field moi: note
    [string]$Column = "",                            # ten cot SQL cua field moi; rong = dung $To
    [switch]$DryRun
)

if (-not (Test-Path $Root)) { Write-Host "LOI: khong thay $Root" -ForegroundColor Red; exit 1 }

$FromP = $From.Substring(0, 1).ToUpper() + $From.Substring(1)
$ToP = $To.Substring(0, 1).ToUpper() + $To.Substring(1)
if ([string]::IsNullOrEmpty($Column)) { $Column = $To }

function Convert-Text([string]$t) {
    $s = $t
    $s = [regex]::Replace($s, "get$FromP(?![A-Za-z0-9_])", "get$ToP")
    $s = [regex]::Replace($s, "set$FromP(?![A-Za-z0-9_])", "set$ToP")
    $s = [regex]::Replace($s, "is$FromP(?![A-Za-z0-9_])",  "is$ToP")
    $s = [regex]::Replace($s, "\b$From\b", $To)
    $s = [regex]::Replace($s, "\b$FromP\b", $ToP)
    $s = [regex]::Replace($s, '(@Column\(name\s*=\s*")' + [regex]::Escape($To) + '(")', '${1}' + $Column + '${2}')
    return $s
}

# Mot "khoi" = dong khop + cac dong annotation/comment ngay tren no
# + phan than {...} neu dong do mo ngoac (vd: if (dto.getX() != null) { ... }).
function Get-Blocks($lines, [string]$token) {
    $raw = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch $token) { continue }
        $s = $i
        while ($s -gt 0) {
            $prev = $lines[$s - 1].Trim()
            if ($prev.StartsWith('@') -or $prev.StartsWith('//') -or $prev.StartsWith('*') -or $prev.StartsWith('/*')) { $s-- }
            else { break }
        }
        $e = $i
        $depth = 0
        for ($k = $s; $k -le $e; $k++) {
            $depth += ([regex]::Matches($lines[$k], '\{')).Count - ([regex]::Matches($lines[$k], '\}')).Count
        }
        while ($depth -gt 0 -and $e -lt $lines.Count - 1) {
            $e++
            $depth += ([regex]::Matches($lines[$e], '\{')).Count - ([regex]::Matches($lines[$e], '\}')).Count
        }
        $raw.Add([pscustomobject]@{ S = $s; E = $e }) | Out-Null
    }
    # gop cac khoi chong nhau (dong @Size va dong private la 2 match cua cung 1 field;
    # dong entity.setX() nam trong khoi if (dto.getX() != null)).
    # $raw da sap xep san theo S vi vong for chay tu tren xuong.
    $merged = New-Object System.Collections.ArrayList
    for ($r = 0; $r -lt $raw.Count; $r++) {
        $cur = $raw[$r]
        if ($merged.Count -gt 0) {
            $last = $merged[$merged.Count - 1]
            if ($cur.S -le $last.E) {
                if ($cur.E -gt $last.E) { $last.E = $cur.E }
                continue
            }
        }
        $merged.Add([pscustomobject]@{ S = $cur.S; E = $cur.E }) | Out-Null
    }
    return , $merged     # dau phay: chan PowerShell trai phang mang long
}

$token = "(?:\b$From\b|\b$FromP\b|get$FromP|set$FromP|is$FromP)"
$touched = 0

Get-ChildItem $Root -Recurse -File -Filter *.java |
    Where-Object { $_.Name -ne 'OpenApiConfig.java' } |
    ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName)
        if ($text -notmatch $token) { return }
        $lines = @($text -split "`r?`n")
        $ranges = Get-Blocks $lines $token
        if ($ranges.Count -eq 0) { return }

        # chen tu duoi len de chi so khong bi lech
        $out = New-Object System.Collections.ArrayList
        $out.AddRange($lines) | Out-Null
        for ($r = $ranges.Count - 1; $r -ge 0; $r--) {
            $s = $ranges[$r].S; $e = $ranges[$r].E
            $block = @($lines[$s..$e])
            $clone = @()
            foreach ($ln in $block) { $clone += (Convert-Text $ln) }
            # field trong entity/DTO cach nhau bang dong trong -> chen them 1 dong trong
            if ($block[-1].Trim() -match '^private .*;$') { $clone = @('') + $clone }
            $out.InsertRange($e + 1, [string[]]$clone)
        }

        $touched++
        Write-Host ""
        Write-Host $_.FullName.Substring($Root.Length + 1) -ForegroundColor Cyan
        for ($r = 0; $r -lt $ranges.Count; $r++) {
            foreach ($ln in @($lines[$ranges[$r].S..$ranges[$r].E])) {
                Write-Host ("  + " + (Convert-Text $ln).Trim()) -ForegroundColor Green
            }
        }
        if (-not $DryRun) { [System.IO.File]::WriteAllText($_.FullName, ($out -join "`r`n")) }
    }

Write-Host ""
if ($DryRun) { Write-Host "DRY RUN - chua ghi gi. $touched file se them field." -ForegroundColor Yellow }
else         { Write-Host "XONG. Da them field '$To' vao $touched file." -ForegroundColor Green }
Write-Host "PHAI SUA TAY SAU KHI CHAY:" -ForegroundColor Yellow
Write-Host "  1. Entity: kieu du lieu + length + nullable cua field moi theo SCRIPT SQL de"
Write-Host "  2. DTO: annotation validation + message dung cau chu de (dang copy tu field mau)"
Write-Host "  3. Neu field moi la ngay: them @Temporal(TemporalType.DATE) + @JsonFormat"
Write-Host "  4. Field moi co trong bang DTO cua de khong - khong co thi xoa khoi DTO, giu o entity"
