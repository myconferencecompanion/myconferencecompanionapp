# Generates app icon PREVIEWS only — does NOT run flutter_launcher_icons.
# Output: assets/images/icon_previews/
param(
  [string]$Source = "",
  [ValidateSet("A", "C", "D")]
  [string]$Option = "A",
  [switch]$Apply
)

Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot "..\assets\images"
$previewDir = Join-Path $root "icon_previews"
New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

if ([string]::IsNullOrWhiteSpace($Source)) {
  $candidates = @(
    (Join-Path $PSScriptRoot "_nse_header_probe.png"),
    (Join-Path $root "nse_logo.png"),
    (Join-Path $root "nse_crest.png")
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { $Source = $c; break }
  }
}

if (-not (Test-Path $Source)) {
  Write-Error "No logo source found. Pass -Source path to a PNG."
  exit 1
}

$navy = [System.Drawing.Color]::FromArgb(255, 18, 62, 115) # #123E73
$gold = [System.Drawing.Color]::FromArgb(255, 201, 162, 39)

function Save-Png($bmp, $path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Extract-CrestSquare([System.Drawing.Image]$src) {
  $w = $src.Width
  $h = $src.Height
  $ratio = $w / [double]$h

  if ($ratio -gt 2.2) {
    # Wide header strip: emblem only (exclude gothic wordmark below).
    $side = [int][Math]::Min($w * 0.2, $h * 0.62)
    $x = [int](($w - $side) / 2)
    $y = [int]($h * 0.04)
  } else {
    $side = [int][Math]::Min($w, $h)
    $x = [int](($w - $side) / 2)
    $y = [int][Math]::Max(0, ($h - $side) / 2)
  }

  if ($y + $side -gt $h) { $y = [Math]::Max(0, $h - $side) }

  $rect = New-Object System.Drawing.Rectangle $x, $y, $side, $side
  return $src.Clone($rect, $src.PixelFormat)
}

function Make-TransparentBg($bmp, [int]$threshold = 28) {
  $out = New-Object System.Drawing.Bitmap $bmp.Width, $bmp.Height
  for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt $bmp.Width; $x++) {
      $c = $bmp.GetPixel($x, $y)
      if ($c.R -le $threshold -and $c.G -le $threshold -and $c.B -le $threshold) {
        $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
      } else {
        $out.SetPixel($x, $y, $c)
      }
    }
  }
  $bmp.Dispose()
  return $out
}

function Draw-CrestOnCanvas($size, $crest, $bgColor, $padRatio, $transparentBg) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  if ($transparentBg) {
    $g.Clear([System.Drawing.Color]::Transparent)
  } else {
    $g.Clear($bgColor)
  }
  $pad = [int]($size * $padRatio)
  $ds = $size - 2 * $pad
  $g.DrawImage($crest, $pad, $pad, $ds, $ds)
  $g.Dispose()
  return $bmp
}

function Draw-PhoneMock($iconPath, $label, $outPath) {
  $mockW = 360
  $mockH = 200
  $mock = New-Object System.Drawing.Bitmap $mockW, $mockH
  $g = [System.Drawing.Graphics]::FromImage($mock)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::FromArgb(255, 245, 247, 250))
  $icon = [System.Drawing.Image]::FromFile($iconPath)
  $iconSize = 96
  $ix = 24
  $iy = 52
  $g.DrawImage($icon, $ix, $iy, $iconSize, $iconSize)
  $font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
  $g.DrawString($label, $font, [System.Drawing.Brushes]::DimGray, $ix, $iy + $iconSize + 8)
  $g.DrawString("Conference Companion", $font, [System.Drawing.Brushes]::Gray, $ix + $iconSize + 20, $iy + 36)
  Save-Png $mock $outPath
  $g.Dispose(); $mock.Dispose(); $icon.Dispose()
}

Write-Host "Source:" $Source
$src = [System.Drawing.Image]::FromFile($Source)
$crest = Extract-CrestSquare $src
$crestKey = Make-TransparentBg $crest 32

$size = 1024

# A — navy full icon (recommended)
$iconA = Draw-CrestOnCanvas $size $crestKey $navy 0.14 $false
Save-Png $iconA (Join-Path $previewDir "option_a_navy_full_1024.png")

# B — adaptive foreground (transparent) — REQUIRED for Android adaptive
$fgB = Draw-CrestOnCanvas $size $crestKey $navy 0.18 $true
Save-Png $fgB (Join-Path $previewDir "option_b_foreground_1024.png")

# C — slightly more padding (safer on circular masks)
$iconC = Draw-CrestOnCanvas $size $crestKey $navy 0.18 $false
Save-Png $iconC (Join-Path $previewDir "option_c_navy_padded_1024.png")

# D — gold accent ring
$iconD = New-Object System.Drawing.Bitmap $size, $size
$gD = [System.Drawing.Graphics]::FromImage($iconD)
$gD.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gD.Clear($navy)
$ring = New-Object System.Drawing.Pen $gold, 14
$gD.DrawEllipse($ring, 80, 80, $size - 160, $size - 160)
$pad = [int]($size * 0.16)
$ds = $size - 2 * $pad
$gD.DrawImage($crestKey, $pad, $pad, $ds, $ds)
$gD.Dispose()
Save-Png $iconD (Join-Path $previewDir "option_d_gold_ring_1024.png")

# Phone mocks
Draw-PhoneMock (Join-Path $previewDir "option_a_navy_full_1024.png") "Option A (recommended)" (Join-Path $previewDir "mock_option_a.png")
Draw-PhoneMock (Join-Path $previewDir "option_c_navy_padded_1024.png") "Option C (more padding)" (Join-Path $previewDir "mock_option_c.png")
Draw-PhoneMock (Join-Path $previewDir "option_d_gold_ring_1024.png") "Option D (gold ring)" (Join-Path $previewDir "mock_option_d.png")

# Comparison sheet with CURRENT bad icon
$sheetW = 1200
$sheetH = 520
$sheet = New-Object System.Drawing.Bitmap $sheetW, $sheetH
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::White)
$titleFont = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Segoe UI", 12)
$sg.DrawString("Conference Companion - App icon previews (not applied yet)", $titleFont, [System.Drawing.Brushes]::Black, 24, 20)
$sg.DrawString("Pick A, C, or D. Option B is the Android adaptive foreground (transparent).", $subFont, [System.Drawing.Brushes]::DimGray, 24, 56)

$labels = @("CURRENT (bad)", "A navy", "B foreground", "C padded", "D gold ring")
$paths = @(
  (Join-Path $root "app_icon.png"),
  (Join-Path $previewDir "option_a_navy_full_1024.png"),
  (Join-Path $previewDir "option_b_foreground_1024.png"),
  (Join-Path $previewDir "option_c_navy_padded_1024.png"),
  (Join-Path $previewDir "option_d_gold_ring_1024.png")
)
for ($i = 0; $i -lt $labels.Length; $i++) {
  if (-not (Test-Path $paths[$i])) { continue }
  $im = [System.Drawing.Image]::FromFile($paths[$i])
  $x = 24 + $i * 230
  $sg.DrawImage($im, $x, 100, 180, 180)
  $sg.DrawString($labels[$i], $subFont, [System.Drawing.Brushes]::Black, $x, 290)
  $im.Dispose()
}

Save-Png $sheet (Join-Path $previewDir "PREVIEW_SHEET.png")
$sg.Dispose(); $sheet.Dispose()

$src.Dispose()
$crestKey.Dispose()
$iconA.Dispose(); $fgB.Dispose(); $iconC.Dispose(); $iconD.Dispose()

Write-Host ""
Write-Host "Previews written to:" $previewDir
Write-Host "Open PREVIEW_SHEET.png first - nothing applied to the app yet."
Write-Host "To apply option A after approval: .\tool\gen_app_icon_previews.ps1 -Apply -Option A"

if ($Apply) {
  $chosen = switch ($Option) {
    "C" { "option_c_navy_padded_1024.png" }
    "D" { "option_d_gold_ring_1024.png" }
    default { "option_a_navy_full_1024.png" }
  }
  $srcIcon = Join-Path $previewDir $chosen
  $srcFg = Join-Path $previewDir "option_b_foreground_1024.png"
  Copy-Item $srcIcon (Join-Path $root "app_icon.png") -Force
  Copy-Item $srcFg (Join-Path $root "app_icon_foreground.png") -Force
  Write-Host "Applied $Option to app_icon.png + app_icon_foreground.png"
  Write-Host "Run: dart run flutter_launcher_icons   (only when you want it on device)"
}
