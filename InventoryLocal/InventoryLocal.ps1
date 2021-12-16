Function GetLaptop {
    $isLaptop = $false
    if(Get-WmiObject -Class win32_systemenclosure |
       Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 `
       -or $_.chassistypes -eq 14})
      { $isLaptop = $true }
    if(Get-WmiObject -Class win32_battery)
      { $isLaptop = $true }
    $isLaptop
}
$hostname = hostname
$Manufacturers = Get-WmiObject win32_SystemEnclosure -erroraction silentlycontinue | Select-Object -ExpandProperty Manufacturer -First 1
$ComputerModel = get-wmiobject win32_computersystem | select-object -ExpandProperty Model -First 1
$SerialNumbers = Get-WmiObject win32_SystemEnclosure -erroraction silentlycontinue | Select-Object -ExpandProperty SerialNumber -first 1
$CPUModel = Get-WmiObject -Class Win32_Processor -erroraction SilentlyContinue | Select-Object -ExpandProperty Name -First 1
$RAMSize = (Get-WMIObject -class Win32_PhysicalMemory -ErrorAction SilentlyContinue | Measure-Object -Property capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
$StorageType = Get-PhysicalDisk | Select-object -ExpandProperty MediaType -First 1
$StorageSize = (Get-PhysicalDisk | measure-object -property Size -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
$IsLaptop = if (GetLaptop){"Laptop"}else{"Desktop"}
$MouseCount = (get-pnpdevice | where-object {$_.Status -eq "OK" -and $_.Class -eq "Mouse"} | measure-object).Count
$TrueMouseCount = if ($IsLaptop -eq "Laptop"){$MouseCount - 1}else{$MouseCount}
$KeyboardCount = (get-pnpdevice | where-object {$_.Status -eq "OK" -and $_.Class -eq "Keyboard"} | measure-object).Count
$TrueKeyboardCount = if ($IsLaptop -eq "Laptop"){$KeyboardCount - 1}else{$KeyboardCount}
$MonitorCount = (get-pnpdevice | where-object {$_.Status -eq "OK" -and $_.Class -eq "Monitor"} | measure-object).Count
$TrueMonitorCount = if ($IsLaptop -eq "Laptop"){$MonitorCount - 1}else{$MonitorCount}
write-host "$hostname,$Manufacturers,$ComputerModel,$SerialNumbers,$CPUModel,$RAMSize,$StorageType,$StorageSize,$IsLaptop,$TrueMouseCount,$TrueKeyboardCount,$TrueMonitorCount,,,,"
