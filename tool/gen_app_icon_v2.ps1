# App icon previews v2 - crisp typography + simplified mark (no blurry crest upscale).
param(
  [ValidateSet("E", "F")]
  [string]$Option = "E",
  [switch]$Apply
)

Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot "..\assets\images"
$previewDir = Join-Path $root "icon_previews"
New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

$navy = [System.Drawing.Color]::FromArgb(255, 18, 62, 115)
$navyDeep = [System.Drawing.Color]::FromArgb(255, 8, 40, 78)
$gold = [System.Drawing.Color]::FromArgb(255, 201, 162, 39)
$green = [System.Drawing.Color]::FromArgb(255, 26, 122, 62)
$red = [System.Drawing.Color]::FromArgb(255, 196, 48, 48)

function Save-Png($bmp, $path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Fill-NavyGradient($g, $size) {
  $rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $navy, $navyDeep, 135
  $g.FillRectangle($brush, 0, 0, $size, $size)
  $brush.Dispose()
}

function Draw-CenteredText($g, $text, $font, $brush, $y, $size) {
  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment = [System.Drawing.StringAlignment]::Center
  $sf.LineAlignment = [System.Drawing.StringAlignment]::Near
  $h = $size - $y
  $rect = New-Object System.Drawing.RectangleF(0, $y, $size, $h)
  $g.DrawString($text, $font, $brush, $rect, $sf)
}

function New-TypographyIcon([int]$size, [bool]$withBackground) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  if ($withBackground) { Fill-NavyGradient $g $size } else { $g.Clear([System.Drawing.Color]::Transparent) }

  $pad = [int]($size * 0.12)
  $penW = [Math]::Max(3.0, $size * 0.012)
  $goldPen = New-Object System.Drawing.Pen($gold, $penW)
  $lineY = [int]($size * 0.18)
  $g.DrawLine($goldPen, $pad, $lineY, $size - $pad, $lineY)

  $fontNse = New-Object System.Drawing.Font("Segoe UI", [int]($size * 0.24), [System.Drawing.FontStyle]::Bold)
  $fontYear = New-Object System.Drawing.Font("Segoe UI", [int]($size * 0.11), [System.Drawing.FontStyle]::Bold)
  $fontSub = New-Object System.Drawing.Font("Segoe UI", [int]($size * 0.045), [System.Drawing.FontStyle]::Regular)

  Draw-CenteredText $g "NSE" $fontNse ([System.Drawing.Brushes]::White) ([int]($size * 0.28)) $size
  Draw-CenteredText $g "'26" $fontYear (New-Object System.Drawing.SolidBrush($gold)) ([int]($size * 0.56)) $size
  $soft = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210, 255, 255, 255))
  Draw-CenteredText $g "INTERNATIONAL CONFERENCE" $fontSub $soft ([int]($size * 0.70)) $size

  $goldPen.Dispose(); $fontNse.Dispose(); $fontYear.Dispose(); $fontSub.Dispose(); $soft.Dispose(); $g.Dispose()
  return $bmp
}

function New-SimplifiedMarkIcon([int]$size, [bool]$withBackground) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

  if ($withBackground) { Fill-NavyGradient $g $size } else { $g.Clear([System.Drawing.Color]::Transparent) }

  $cx = $size / 2.0
  $cy = $size * 0.46
  $r = $size * 0.30
  $penW = [Math]::Max(5.0, $size * 0.018)
  $goldPen = New-Object System.Drawing.Pen($gold, $penW)
  $g.DrawEllipse($goldPen, $cx - $r, $cy - $r, 2 * $r, 2 * $r)

  $toothLen = $size * 0.05
  for ($i = 0; $i -lt 8; $i++) {
    $angle = [Math]::PI * 2 * $i / 8
    $x1 = $cx + ($r + $toothLen * 0.2) * [Math]::Cos($angle)
    $y1 = $cy + ($r + $toothLen * 0.2) * [Math]::Sin($angle)
    $x2 = $cx + ($r + $toothLen) * [Math]::Cos($angle)
    $y2 = $cy + ($r + $toothLen) * [Math]::Sin($angle)
    $g.DrawLine($goldPen, $x1, $y1, $x2, $y2)
  }

  $inner = $r * 0.62
  $g.FillEllipse([System.Drawing.Brushes]::White, $cx - $inner, $cy - $inner, 2 * $inner, 2 * $inner)

  $barW = $size * 0.035
  $barH = $inner * 0.9
  $gap = $inner * 0.55
  $redBrush = New-Object System.Drawing.SolidBrush($red)
  $g.FillRectangle($redBrush, $cx - $gap - $barW, $cy - $barH / 2, $barW, $barH)
  $g.FillRectangle($redBrush, $cx + $gap, $cy - $barH / 2, $barW, $barH)
  $g.FillRectangle($redBrush, $cx - $gap, $cy - $barW / 2, 2 * $gap + $barW, $barW)

  $greenBrush = New-Object System.Drawing.SolidBrush($green)
  $arcRect = New-Object System.Drawing.Rectangle ([int]($cx - $inner)), ([int]($cy)), ([int](2 * $inner)), ([int]($inner))
  $g.FillPie($greenBrush, $arcRect, 0, 180)

  $font = New-Object System.Drawing.Font("Segoe UI", [int]($size * 0.065), [System.Drawing.FontStyle]::Bold)
  Draw-CenteredText $g "NSE" $font ([System.Drawing.Brushes]::White) ([int]($cy + $inner * 0.18)) $size

  $goldPen.Dispose(); $redBrush.Dispose(); $greenBrush.Dispose(); $font.Dispose(); $g.Dispose()
  return $bmp
}

$size = 1024
$iconE = New-TypographyIcon $size $true
$fgE = New-TypographyIcon $size $false
$iconF = New-SimplifiedMarkIcon $size $true
$fgF = New-SimplifiedMarkIcon $size $false
Save-Png $iconE (Join-Path $previewDir "option_e_typography_1024.png")
Save-Png $fgE (Join-Path $previewDir "option_e_foreground_1024.png")
Save-Png $iconF (Join-Path $previewDir "option_f_mark_1024.png")
Save-Png $fgF (Join-Path $previewDir "option_f_foreground_1024.png")

$sheetW = 1100; $sheetH = 560
$sheet = New-Object System.Drawing.Bitmap $sheetW, $sheetH
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::White)
$titleFont = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Segoe UI", 12)
$sg.DrawString("Conference Companion - NEW icon previews (v2)", $titleFont, [System.Drawing.Brushes]::Black, 24, 18)
$sg.DrawString("A/C/D failed: crest source is only 100px tall. E = crisp type. F = simplified mark.", $subFont, [System.Drawing.Brushes]::DimGray, 24, 54)

$labels = @("OLD crest upscale", "NEW E typography", "NEW F mark", "CURRENT device")
$paths = @(
  (Join-Path $previewDir "option_a_navy_full_1024.png"),
  (Join-Path $previewDir "option_e_typography_1024.png"),
  (Join-Path $previewDir "option_f_mark_1024.png"),
  (Join-Path $root "app_icon.png")
)
for ($i = 0; $i -lt $labels.Length; $i++) {
  if (-not (Test-Path $paths[$i])) { continue }
  $im = [System.Drawing.Image]::FromFile($paths[$i])
  $x = 24 + $i * 265
  $sg.DrawImage($im, $x, 100, 200, 200)
  $sg.DrawString($labels[$i], $subFont, [System.Drawing.Brushes]::Black, $x, 315)
  $im.Dispose()
}
Save-Png $sheet (Join-Path $previewDir "PREVIEW_SHEET_v2.png")
$sg.Dispose(); $sheet.Dispose()
$iconE.Dispose(); $fgE.Dispose(); $iconF.Dispose(); $fgF.Dispose()

Write-Host "Open:" (Join-Path $previewDir "PREVIEW_SHEET_v2.png")

if ($Apply) {
  $chosen = if ($Option -eq "F") { "option_f_mark_1024.png" } else { "option_e_typography_1024.png" }
  $chosenFg = if ($Option -eq "F") { "option_f_foreground_1024.png" } else { "option_e_foreground_1024.png" }
  Copy-Item (Join-Path $previewDir $chosen) (Join-Path $root "app_icon.png") -Force
  Copy-Item (Join-Path $previewDir $chosenFg) (Join-Path $root "app_icon_foreground.png") -Force
  Write-Host "Applied $Option. Run: dart run flutter_launcher_icons"
}
