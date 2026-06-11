# USBBackup.ps1 - Admin tələb etmir

$BackupRoot = "C:\USB_Backup"
$LogFile = "$BackupRoot\USB_Backup_Log.txt"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$Timestamp] $Message" -Encoding UTF8
}

if (-not (Test-Path $BackupRoot)) { New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null }

Write-Log "Skript başladı. USB gözlənilir..."

$KnownDrives = @(Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)

while ($true) {
    $CurrentDrives = @(Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)
    $NewDrives = $CurrentDrives | Where-Object { $_ -notin $KnownDrives }

    foreach ($Drive in $NewDrives) {
        $DriveID = $Drive.TrimEnd('\')
        $Volume = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$DriveID'"

        if ($Volume.DriveType -eq 2) {
            Write-Log "USB aşkar edildi: $Drive"
            Start-Sleep -Seconds 3

            $Label = if ($Volume.VolumeName) { $Volume.VolumeName } else { "USB" }
            $BackupFolder = "$BackupRoot\${Label}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null

            Write-Log "Backup başlayır: $Drive -> $BackupFolder"
            robocopy "$Drive" "$BackupFolder" /E /COPY:DAT /R:1 /W:3 /MT:4 /NP /LOG+:$LogFile
            Write-Log "Backup bitdi (Robocopy kod: $LASTEXITCODE)"
        }
    }

    $KnownDrives = $CurrentDrives
    Start-Sleep -Seconds 5
}