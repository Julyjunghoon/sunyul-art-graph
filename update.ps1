# ============================================================
#  선율이 그림 그래프 - 그림 업데이트 스크립트
#  "6살에 만든 작품" 폴더의 사진을 읽어서 artworks-data.js 를
#  새로 만들어요. 이 파일을 직접 실행하지 말고,
#  같은 폴더의 "그림_업데이트.bat" 를 더블클릭하세요.
# ============================================================

$ErrorActionPreference = "Stop"

$root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$artFolder = Join-Path $root "6살에 만든 작품"
$outFile   = Join-Path $root "artworks-data.js"

if (-not (Test-Path $artFolder)) {
    Write-Host "폴더를 찾을 수 없어요: $artFolder"
    Write-Host "이 스크립트와 같은 위치에 '6살에 만든 작품' 폴더가 있어야 해요."
    exit 1
}

$exts = @(".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp")
$files = Get-ChildItem -Path $artFolder -File |
         Where-Object { $exts -contains $_.Extension.ToLower() } |
         Sort-Object Name

$items = New-Object System.Collections.Generic.List[string]

foreach ($f in $files) {
    $stem  = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)

    $title  = $stem
    $medium = "그림"
    $date   = $f.LastWriteTime.ToString("yyyy.MM.dd")

    # "20260301_집에서 인어공주.jpg" 처럼 앞이 8자리 날짜(YYYYMMDD)면
    # 그 날짜를 그림 날짜로 쓰고, 나머지를 제목으로 써요.
    if ($stem -match '^(\d{8})_(.+)$') {
        $datePart = $matches[1]
        $title    = $matches[2].Trim()
        try {
            $date = [datetime]::ParseExact($datePart, "yyyyMMdd", $null).ToString("yyyy.MM.dd")
        } catch { }
    }
    else {
        # 날짜로 시작하지 않으면 "제목_재료.jpg" 형식으로 보고 앞부분만 제목으로 써요.
        $parts = $stem -split "_", 2
        $title = $parts[0].Trim()
        if ($parts.Length -gt 1 -and $parts[1].Trim() -ne "") { $medium = $parts[1].Trim() }
        $date  = $f.LastWriteTime.ToString("yyyy.MM.dd")
    }

    # 제목 안에 밑줄이 하나 더 있으면 "제목_재료"로 나눠요. (예: 인어공주_물감)
    if ($title -match '^(.+?)_(.+)$') {
        $title  = $matches[1].Trim()
        $medium = $matches[2].Trim()
    }

    $imgPath = "6살에 만든 작품/" + $f.Name

    $escTitle  = $title  -replace '\\','\\\\' -replace '"','\"'
    $escMedium = $medium -replace '\\','\\\\' -replace '"','\"'
    $escImg    = $imgPath -replace '\\','\\\\' -replace '"','\"'

    $items.Add("  { title: `"$escTitle`", medium: `"$escMedium`", date: `"$date`", img: `"$escImg`" }")
}

$body = if ($items.Count -gt 0) { ($items -join ",`n") } else { "" }
$js = "// 이 파일은 update.ps1(그림_업데이트.bat) 실행 시 자동으로 새로 만들어져요.`n" +
      "// 직접 고치지 마세요 - 다음 업데이트 때 덮어써져요.`n" +
      "const ARTWORKS_DATA = [`n$body`n];`n"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outFile, $js, $utf8NoBom)

Write-Host ""
Write-Host "완료! 그림 $($files.Count)개를 찾았어요."
Write-Host "index.html 을 새로고침(F5)하면 바로 반영돼요."
Write-Host ""
