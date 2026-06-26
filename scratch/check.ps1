[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

function Get-Dimensions($path) {
    if (Test-Path $path) {
        $img = [System.Drawing.Image]::FromFile($path)
        $w = $img.Width
        $h = $img.Height
        $img.Dispose()
        $frames = $w / $h
        Write-Output "$path - Size: ${w}x${h} - Frames: $frames"
    } else {
        Write-Output "File not found: $path"
    }
}

Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_1\Idle.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_1\Hurt.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_1\Dead.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_1\Shot.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_1\Jump.png"

Write-Output "--- Raider 2 ---"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_2\Idle.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_2\Hurt.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_2\Dead.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_2\Shot_1.png"
Get-Dimensions "c:\Users\readytouse\VideogiocoWW2\assets\Raider_2\Jump.png"
