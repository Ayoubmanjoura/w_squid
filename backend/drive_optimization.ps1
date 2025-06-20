$drives = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.MediaType -ne $null }

foreach ($drive in $drives) {

}

try {
    $physicalDisks = Get-PhysicalDisk
} catch {
    Write-Host "Get-PhysicalDisk not available. Cannot detect SSD/HDD properly."
    exit
}

foreach ($pd in $physicalDisks) {
    $friendlyName = $pd.FriendlyName
    $mediaType = $pd.MediaType 

    $diskNumber = $pd.DeviceId
    $volumes = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\\\.\\PHYSICALDRIVE$diskNumber'} WHERE AssocClass = Win32_DiskDriveToDiskPartition" | 
        ForEach-Object {
            Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($_.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
        }

    foreach ($vol in $volumes) {
        $driveLetter = $vol.DeviceID.TrimEnd(":")  
        if ($mediaType -eq "SSD") {
            Write-Host "Drive $driveLetter is on SSD ($friendlyName). Optimizing..."
            Optimize-Volume -DriveLetter $driveLetter -ReTrim -Verbose
        } elseif ($mediaType -eq "HDD") {
            Write-Host "Drive $driveLetter is on HDD ($friendlyName). Defragmenting and optimizing..."
            Optimize-Volume -DriveLetter $driveLetter -Defrag -Verbose
        } else {
            Write-Host "Drive $driveLetter has unknown media type ($mediaType). Skipping."
        }
    }
}
