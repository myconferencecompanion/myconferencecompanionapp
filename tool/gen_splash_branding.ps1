# Regenerate splash branding wordmark in navy for the white splash background.
Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot "..\assets\images"
$out = Join-Path $root "splash_branding.png"

$w = 900; $h = 170
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear([System.Drawing.Color]::Transparent)

$navy = [System.Drawing.Color]::FromArgb(255, 18, 62, 115)
$muted = [System.Drawing.Color]::FromArgb(255, 86, 96, 87)
$navyBrush = New-Object System.Drawing.SolidBrush $navy
$mutedBrush = New-Object System.Drawing.SolidBrush $muted

$titleFont = New-Object System.Drawing.Font("Segoe UI Semibold", 40, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Segoe UI", 19, [System.Drawing.FontStyle]::Regular)

$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = [System.Drawing.StringAlignment]::Center

$g.DrawString("Conference Companion", $titleFont, $navyBrush, ($w / 2), 34, $fmt)
$g.DrawString("International Conference  -  Maiduguri 2026", $subFont, $mutedBrush, ($w / 2), 104, $fmt)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$navyBrush.Dispose(); $mutedBrush.Dispose(); $titleFont.Dispose(); $subFont.Dispose()
Write-Host "Regenerated navy splash_branding.png"
