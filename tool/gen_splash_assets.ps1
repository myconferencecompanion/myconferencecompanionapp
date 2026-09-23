Add-Type -AssemblyName System.Drawing
$root = Join-Path $PSScriptRoot '..\assets\images'
$crestPath = Join-Path $root 'nse_crest.png'
$crest = [System.Drawing.Image]::FromFile($crestPath)

function Save-Png($bmp, $path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

$logoSize = 640
$logo = New-Object System.Drawing.Bitmap $logoSize, $logoSize
$g = [System.Drawing.Graphics]::FromImage($logo)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::Transparent)
$pad = 48
$ds = $logoSize - 2 * $pad
$g.DrawImage($crest, $pad, $pad, $ds, $ds)
Save-Png $logo (Join-Path $root 'splash_logo.png')
$g.Dispose()
$logo.Dispose()

$a12 = 768
$abmp = New-Object System.Drawing.Bitmap $a12, $a12
$ag = [System.Drawing.Graphics]::FromImage($abmp)
$ag.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$ag.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$ag.Clear([System.Drawing.Color]::Transparent)
$apad = 140
$ads = $a12 - 2 * $apad
$ag.DrawImage($crest, $apad, $apad, $ads, $ads)
Save-Png $abmp (Join-Path $root 'splash_android12.png')
$ag.Dispose()
$abmp.Dispose()

$bw = 900
$bh = 160
$brand = New-Object System.Drawing.Bitmap $bw, $bh
$bg = [System.Drawing.Graphics]::FromImage($brand)
$bg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$bg.Clear([System.Drawing.Color]::Transparent)
$titleFont = New-Object System.Drawing.Font('Segoe UI', 42, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font('Segoe UI', 20, [System.Drawing.FontStyle]::Regular)
$white = [System.Drawing.Brushes]::White
$soft = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 255, 255, 255))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$bg.DrawString("Conference Companion", $titleFont, $white, (New-Object System.Drawing.RectangleF 0, 18, $bw, 70), $sf)
$bg.DrawString('International Conference - Maiduguri 2026', $subFont, $soft, (New-Object System.Drawing.RectangleF 0, 88, $bw, 50), $sf)
Save-Png $brand (Join-Path $root 'splash_branding.png')
$bg.Dispose()
$brand.Dispose()
$crest.Dispose()

Write-Host 'Splash assets created in' $root
