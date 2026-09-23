# User crest: black -> transparent, centered on navy. Preview only unless -Apply.
param([switch]$Apply)

Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot "..\assets\images"
$previewDir = Join-Path $root "icon_previews"
$source = Join-Path $root "nse_crest_source.png"
New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

if (-not (Test-Path $source)) {
  Write-Error "Missing nse_crest_source.png"
  exit 1
}

$navy = [System.Drawing.Color]::FromArgb(255, 18, 62, 115)
$navyDeep = [System.Drawing.Color]::FromArgb(255, 8, 40, 78)

function Save-Png($bmp, $path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Remove-BlackBackground([System.Drawing.Bitmap]$src, [int]$threshold = 40) {
  $out = New-Object System.Drawing.Bitmap $src.Width, $src.Height
  for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
      $c = $src.GetPixel($x, $y)
      if ($c.R -le $threshold -and $c.G -le $threshold -and $c.B -le $threshold) {
        $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
      } else {
        $out.SetPixel($x, $y, $c)
      }
    }
  }
  return $out
}

function Compose-Icon([System.Drawing.Image]$crest, [int]$size, [double]$padRatio, [bool]$transparentBg) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  if ($transparentBg) {
    $g.Clear([System.Drawing.Color]::Transparent)
  } else {
    $rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $navy, $navyDeep, 135
    $g.FillRectangle($brush, 0, 0, $size, $size)
    $brush.Dispose()
  }

  $pad = [int]($size * $padRatio)
  $ds = $size - 2 * $pad
  $g.DrawImage($crest, $pad, $pad, $ds, $ds)
  $g.Dispose()
  return $bmp
}

$raw = [System.Drawing.Bitmap]::FromFile($source)
$crest = Remove-BlackBackground $raw 42
$raw.Dispose()

$size = 1024

# Standard fit (recommended)
$icon = Compose-Icon $crest $size 0.11 $false
$fg = Compose-Icon $crest $size 0.14 $true

# Slightly more padding for circular Android masks
$iconPadded = Compose-Icon $crest $size 0.14 $false

Save-Png $icon (Join-Path $previewDir "user_logo_navy_1024.png")
Save-Png $fg (Join-Path $previewDir "user_logo_foreground_1024.png")
Save-Png $iconPadded (Join-Path $previewDir "user_logo_navy_padded_1024.png")
Save-Png $crest (Join-Path $previewDir "user_logo_transparent_crest.png")

# Phone mock
$mock = New-Object System.Drawing.Bitmap 360, 200
$mg = [System.Drawing.Graphics]::FromImage($mock)
$mg.Clear([System.Drawing.Color]::FromArgb(255, 245, 247, 250))
$im = [System.Drawing.Image]::FromFile((Join-Path $previewDir "user_logo_navy_1024.png"))
$mg.DrawImage($im, 24, 52, 96, 96)
$font = New-Object System.Drawing.Font("Segoe UI", 11)
$mg.DrawString("Your crest on navy", $font, [System.Drawing.Brushes]::DimGray, 24, 154)
$mg.DrawString("Conference Companion", $font, [System.Drawing.Brushes]::Gray, 140, 88)
Save-Png $mock (Join-Path $previewDir "mock_user_logo.png")
$mg.Dispose(); $mock.Dispose(); $im.Dispose(); $font.Dispose()

# Sheet
$sheet = New-Object System.Drawing.Bitmap 900, 480
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::White)
$t = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$s = New-Object System.Drawing.Font("Segoe UI", 11)
$sg.DrawString("Your NSE crest - preview (NOT applied yet)", $t, [System.Drawing.Brushes]::Black, 20, 16)
$sg.DrawString("Black removed, centered on navy #123E73. Say apply when happy.", $s, [System.Drawing.Brushes]::DimGray, 20, 48)

$labels = @("Original", "Navy icon", "More padding", "Transparent crest")
$paths = @($source, (Join-Path $previewDir "user_logo_navy_1024.png"), (Join-Path $previewDir "user_logo_navy_padded_1024.png"), (Join-Path $previewDir "user_logo_transparent_crest.png"))
for ($i = 0; $i -lt 4; $i++) {
  $im2 = [System.Drawing.Image]::FromFile($paths[$i])
  $sg.DrawImage($im2, 20 + $i * 215, 90, 180, 180)
  $sg.DrawString($labels[$i], $s, [System.Drawing.Brushes]::Black, 20 + $i * 215, 280)
  $im2.Dispose()
}
Save-Png $sheet (Join-Path $previewDir "PREVIEW_USER_LOGO.png")
$sg.Dispose(); $sheet.Dispose()

$icon.Dispose(); $fg.Dispose(); $iconPadded.Dispose(); $crest.Dispose()

Write-Host "Preview:" (Join-Path $previewDir "PREVIEW_USER_LOGO.png")

if ($Apply) {
  Copy-Item (Join-Path $previewDir "user_logo_navy_1024.png") (Join-Path $root "app_icon.png") -Force
  Copy-Item (Join-Path $previewDir "user_logo_foreground_1024.png") (Join-Path $root "app_icon_foreground.png") -Force
  Copy-Item $source (Join-Path $root "nse_crest.png") -Force
  Write-Host "Applied. Run: dart run flutter_launcher_icons"
}
