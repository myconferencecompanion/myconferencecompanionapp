# Regenerate splash art from the COMPLETE NSE crest (fixes cropped logo).
# Centers the full crest with generous padding; Android 12 needs the mark
# well inside the circular mask so nothing clips.
Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot "..\assets\images"
$crestPath = Join-Path $root "nse_crest.png"

if (-not (Test-Path $crestPath)) { Write-Error "Missing nse_crest.png"; exit 1 }

$crest = [System.Drawing.Image]::FromFile($crestPath)

function New-Centered([System.Drawing.Image]$src, [int]$canvas, [double]$fill) {
  $bmp = New-Object System.Drawing.Bitmap $canvas, $canvas
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.Clear([System.Drawing.Color]::Transparent)
  $target = [int]($canvas * $fill)
  $off = [int](($canvas - $target) / 2)
  $g.DrawImage($src, $off, $off, $target, $target)
  $g.Dispose()
  return $bmp
}

# Standard splash: crest fills ~62% of a 640 canvas (generous margin, uncropped).
$logo = New-Centered $crest 640 0.62
$logo.Save((Join-Path $root "splash_logo.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# Android 12: circular mask crops ~1/3 of the window, so keep mark inside ~48%.
$a12 = New-Centered $crest 960 0.46
$a12.Save((Join-Path $root "splash_android12.png"), [System.Drawing.Imaging.ImageFormat]::Png)

$logo.Dispose(); $a12.Dispose(); $crest.Dispose()
Write-Host "Regenerated splash_logo.png (640) and splash_android12.png (960) from full crest."
