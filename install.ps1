# pasta da steam
$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath

if (-not $steamPath) {
    $steamPath = (Get-ItemProperty -Path "HKLM:\Software\Valve\Steam" -ErrorAction SilentlyContinue).InstallPath
}

if (-not $steamPath) {
    Write-Error "C ta com a steam instalada?."
    exit 1
}

Write-Host "A steam ta em $steamPath"

# pastas a mimir
$foldersToDelete = @(
    "bin",
    "clientui",
    "package",
    "public",
    "resource",
    "steam"
)

# deletador
foreach ($folder in $foldersToDelete) {
    $fullPath = Join-Path -Path $steamPath -ChildPath $folder
    if (Test-Path $fullPath) {
        Write-Host "Deleting folder: $fullPath"
        Remove-Item -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Pasta nao encontrada: $fullPath"
    }
}
# dlls a mimir
Write-Host "Apagando dlls velhas"
Get-ChildItem -Path $steamPath -Filter "*.dll" -File | ForEach-Object {
    Write-Host "Deleting DLL: $($_.FullName)"
    Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
}
$steamExe = Join-Path -Path $steamPath -ChildPath "steam.exe"

if (-not (Test-Path $steamExe)) {
    Write-Error "steam.exe not found at: $steamExe"
    exit 1
}

Write-Host "Abrindo a steam com o downgrade configurado..."
$steamArgs = '-forcesteamupdate -forcepackagedownload -overridepackageurl http://web.archive.org/web/20260430114655if_/media.steampowered.com/client -exitsteam -clearbeta'
$process = Start-Process -FilePath $steamExe -ArgumentList $steamArgs -PassThru

Write-Host "Esperando a steam terminar..."
$process.WaitForExit()
Write-Host "Steam terminou."

# cria o trancador
$steamCfgPath = Join-Path -Path $steamPath -ChildPath "steam.cfg"
Write-Host "Trancando updates: $steamCfgPath"

$cfgContent = @"
BootStrapperForceSelfUpdate=disable
BootStrapperInhibitAll=enable
"@

Set-Content -Path $steamCfgPath -Value $cfgContent -Encoding ASCII
Write-Host "steam.cfg trancador criado."

# baixa o careca
$dllDownloads = @(
    @{
        Url      = "https://placeholder.example.com/first.dll"
        FileName = "dwmapi.dll"
    },
    @{
        Url      = "https://placeholder.example.com/second.dll"
        FileName = "baldtools.dll"
    }
)

foreach ($dll in $dllDownloads) {
    $destinationPath = Join-Path -Path $steamPath -ChildPath $dll.FileName
    Write-Host "baixando $($dll.FileName) de $($dll.Url)..."
    try {
        Invoke-WebRequest -Uri $dll.Url -OutFile $destinationPath -ErrorAction Stop
        Write-Host "baixado com sucesso: $destinationPath"
    } catch {
        Write-Warning "deu ruim com o $($dll.FileName): $_"
    }
}

Write-Host "tudo pronto."
