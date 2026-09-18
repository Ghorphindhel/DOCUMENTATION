# Fichier de sortie
$OutputFile = "C:\temp\$env:COMPUTERNAME-connections.csv"

# Création du répertoire si nécessaire
if (!(Test-Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp" | Out-Null
}

Write-Host "Analyse des connexions réseau de $env:COMPUTERNAME..." -ForegroundColor Cyan

# Equivalent moderne de netstat pour les connexions TCP
$Connections = Get-NetTCPConnection -ErrorAction SilentlyContinue |
    Where-Object {
        $_.RemoteAddress -notin @(
            "0.0.0.0",
            "::",
            "::1",
            "127.0.0.1"
        )
    }

$Results = foreach ($Connection in $Connections) {

    $RemoteIP = $Connection.RemoteAddress
    $RemoteName = "Non resolu"

    # Résolution DNS inverse
    try {
        $RemoteName = [System.Net.Dns]::GetHostEntry($RemoteIP).HostName
    }
    catch {
        # Pas d'enregistrement DNS inverse disponible
    }

    # Recherche du processus correspondant au PID
    try {
        $Process = Get-Process -Id $Connection.OwningProcess -ErrorAction Stop
        $ProcessName = $Process.ProcessName
    }
    catch {
        $ProcessName = "Inconnu"
    }

    [PSCustomObject]@{
        PC            = $env:COMPUTERNAME
        LocalIP       = $Connection.LocalAddress
        LocalPort     = $Connection.LocalPort
        RemoteIP      = $RemoteIP
        RemotePort    = $Connection.RemotePort
        RemoteServer  = $RemoteName
        State         = $Connection.State
        PID           = $Connection.OwningProcess
        Process       = $ProcessName
    }
}

# Affichage à l'écran
$Results |
    Sort-Object RemoteIP, RemotePort |
    Format-Table RemoteIP, RemotePort, RemoteServer, State, PID, Process -AutoSize

# Export CSV
$Results |
    Sort-Object RemoteIP, RemotePort |
    Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

Write-Host ""
Write-Host "Rapport enregistré dans : $OutputFile" -ForegroundColor Green