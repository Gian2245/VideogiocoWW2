[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$files = @("blocco3.png", "blocco4.png", "blocco5.png")
foreach ($f in $files) {
    $img = [System.Drawing.Bitmap]::FromFile("c:\Users\User\VideogiocoWW2\assets\blocchi\$f")
    $width = $img.Width
    $height = $img.Height
    $min_y = $height
    $max_y = 0
    $min_x = $width
    $max_x = 0
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $color = $img.GetPixel($x, $y)
            if ($color.A -gt 0) {
                if ($y -lt $min_y) { $min_y = $y }
                if ($y -gt $max_y) { $max_y = $y }
                if ($x -lt $min_x) { $min_x = $x }
                if ($x -gt $max_x) { $max_x = $x }
            }
        }
    }
    Write-Host "Crate $f"
    Write-Host "Width:" $width "Height:" $height
    Write-Host "Min X:" $min_x "Max X:" $max_x
    Write-Host "Min Y:" $min_y "Max Y:" $max_y
}
