# Generates the Conference Companion launcher icon: gold "CC" monogram on the
# NSE navy, with a subtle gold ring. Outputs:
#   assets/images/app_icon.png             (1024x1024 full icon)
#   assets/images/app_icon_foreground.png  (1024x1024 adaptive foreground)
# Run: powershell -ExecutionPolicy Bypass -File tool/gen_cc_icon.ps1
# (Uses if/else, not ternaries - Windows PowerShell 5.1 has no ? operator.)
Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot "..\assets\images"
$size = 1024

$navy = [System.Drawing.Color]::FromArgb(255, 18, 62, 115)
$navyDark = [System.Drawing.Color]::FromArgb(255, 12, 42, 79)
$gold = [System.Drawing.Color]::FromArgb(255, 255, 160, 0)
$cream = [System.Drawing.Color]::FromArgb(255, 251, 247, 239)

function New-Icon([bool]$adaptive) {
  $bmp = New-Object System.Drawing.Bitmap $script:size, $script:size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  if ($adaptive) {
    # Adaptive foreground must be transparent outside the safe zone.
    $g.Clear([System.Drawing.Color]::Transparent)
    $top = 140; $bottom = 280
  } else {
    # Full icon: navy base with a darker diagonal gradient.
    $rect = New-Object System.Drawing.Rectangle 0, 0, $script:size, $script:size
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $script:navy, $script:navyDark, 55
    $g.FillRectangle($bg, 0, 0, $script:size, $script:size)
    $bg.Dispose()
    $top = 110; $bottom = 220

    # Gold ring.
    $ringPen = New-Object System.Drawing.Pen $script:gold, 18
    $g.DrawEllipse($ringPen, 92, 92, $script:size - 184, $script:size - 184)
    $ringPen.Dispose()
  }

  # CC monogram.
  $font = New-Object System.Drawing.Font("Segoe UI Black", 380, [System.Drawing.FontStyle]::Bold)
  $brush = New-Object System.Drawing.SolidBrush $script:gold
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rect = New-Object System.Drawing.RectangleF 0, $top, $script:size, ($script:size - $bottom)
  $g.DrawString("CC", $font, $brush, $rect, $fmt)
  $brush.Dispose()
  $font.Dispose()
  $fmt.Dispose()

  # Small cream companion dot.
  if (-not $adaptive) {
    $dot = New-Object System.Drawing.SolidBrush $script:cream
    $cx = $script:size / 2
    $g.FillEllipse($dot, ($cx - 26), ($script:size - 210), 52, 52)
    $dot.Dispose()
  }

  $g.Dispose()
  return $bmp
}

$full = New-Icon $false
$full.Save((Join-Path $root "app_icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$full.Dispose()

$fg = New-Icon $true
$fg.Save((Join-Path $root "app_icon_foreground.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$fg.Dispose()

Write-Host "Conference Companion icons written to $root"
