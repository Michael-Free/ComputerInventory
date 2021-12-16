<#

#>
Function GetLaptop($Computer) {
 $isLaptop = $false
 if(Get-WmiObject -Class win32_systemenclosure -ComputerName $computer |
    Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 `
    -or $_.chassistypes -eq 14})
   { $isLaptop = $true }
 if(Get-WmiObject -Class win32_battery -ComputerName $computer)
   { $isLaptop = $true }
 $isLaptop
}
function PollComputers($Computer) {
  Write-Host "Polling $Computer for information..."
  $Manufacturers = Get-WmiObject win32_SystemEnclosure -computername $Computer -erroraction silentlycontinue | Select-Object -ExpandProperty Manufacturer -First 1
  $ComputerModel = get-wmiobject win32_computersystem -Computername $computer | select-object -ExpandProperty Model -First 1
  $SerialNumbers = Get-WmiObject win32_SystemEnclosure -computername $Computer -erroraction silentlycontinue | Select-Object -ExpandProperty SerialNumber -first 1
  $CPUModel = Get-WmiObject -Class Win32_Processor -ComputerName $Computer -erroraction SilentlyContinue | Select-Object -ExpandProperty Name -First 1
  $RAMSize = (Get-WMIObject -class Win32_PhysicalMemory -ComputerName $Computer -ErrorAction SilentlyContinue | Measure-Object -Property capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
  $StorageType = invoke-command -ComputerName $Computer -ScriptBlock {Get-PhysicalDisk | Select-object -ExpandProperty MediaType -First 1}
  $StorageSize = invoke-command -ComputerName $Computer -ScriptBlock {(Get-PhysicalDisk | measure-object -property Size -Sum | % {[Math]::Round(($_.sum / 1GB),2)})}
  $IsLaptop = if (GetLaptop($Computer)){"Laptop"}else{"Desktop"}
  $MouseCount = invoke-command -ComputerName $Computer -ScriptBlock {(get-pnpdevice | where-object {$_.Status -eq "OK" -and $_.Class -eq "Mouse"} | measure-object).Count}
  $TrueMouseCount = if ($IsLaptop -eq "Laptop"){$MouseCount - 1}else{$MouseCount}
  $KeyboardCount = invoke-command -ComputerName $Computer -ScriptBlock {(get-pnpdevice | where-object {$_.Status -eq "OK" -and $_.Class -eq "Keyboard"} | measure-object).Count}
  $TrueKeyboardCount = if ($IsLaptop -eq "Laptop"){$KeyboardCount - 1}else{$KeyboardCount}
  $MonitorCount = invoke-command -ComputerName $Computer -ScriptBlock {(get-pnpdevice | where-object {$_.Status -eq "OK" -and $_.Class -eq "Monitor"} | measure-object).Count}
  $TrueMonitorCount = if ($IsLaptop -eq "Laptop"){$MonitorCount - 1}else{$MonitorCount}
  Add-Content $inventoryreport "$Computer,$Manufacturers,$ComputerModel,$SerialNumbers,$CPUModel,$RAMSize,$StorageType,$StorageSize,$IsLaptop,$TrueMouseCount,$TrueKeyboardCount,$TrueMonitorCount"
}
function ForceManagement($Computer) {
  Write-Host "Trying to force management of $Computer"
  # If we can't find any information about the system - let's try to enforce windows remote management with this tool.
  Start-Process -Filepath "$PsScriptRoot\PsExec.exe" -Argumentlist "\\$computer -h -d winrm.cmd quickconfig -q"      
  # Wait for a bit
  Start-Sleep -Seconds 10 
  # Try to Force a group policy update
  ## haven't put this in yet
  # Wait for a bit
  Start-Sleep -Seconds 10 
  # Let's try to bypass execution policy - and try to bypass admin privs to update firewall settings
  Start-Process -Filepath "$PsScriptRoot\PsExec.exe" -Argumentlist "\\$computer -h -d powershell.exe -executionpolicy bypass 'if((([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match \`"S-1-5-32-544\`")) { Enable-NetFirewallRule -Name \`"WMI-WINMGMT-In-TCP\`", \`"WMI-RPCSS-In-TCP\`"} else {\`$registryPath = \`"HKCU:\Environment\`"; \`$Name = \`"windir\`"; \`$Value = \`"powershell -ep bypass -w h \`$PSCommandPath;\`#\`"; Set-ItemProperty -Path \`$registryPath -Name \`$name -Value \`$Value; Start-Sleep -Seconds 5; schtasks /run /tn \Microsoft\Windows\DiskCleanup\SilentCleanup /I | Out-Null; Start-Sleep -Seconds 5; Remove-ItemProperty -Path \`$registryPath -Name \`$name}'"
  # Wait for a bit
  Start-Sleep -Seconds 10  
}
$inventoryreport='C:\Users\MFree\Desktop\InventoryReport.csv' #New-TemporaryFile
$monitorinventory='c:\Users\MFree\Desktop\MonitorInventory.csv'
Add-Content $inventoryreport "Hostname,Manufacturer,Model,ServiceTag,CPU,RAM,DriveType,DriveSize,FormFactor,MouseCount,KeyboardCount,MonitorCount"
Add-Content $monitorinventory "Manufacturer,Model,SerialNumber,Hostname"
$DomainComputers = get-adcomputer -filter * | sort-object -property Name | ForEach-Object {$_.Name}
Foreach ($Computer in $DomainComputers) {
  $online = Test-Connection -ComputerName $Computer -erroraction silentlycontinue
  if ($online) {
    Get-WmiObject -query "SELECT * FROM Win32_OperatingSystem" -ComputerName $Computer -erroraction silentlycontinue | out-null
    if ($?) {
      PollComputers($Computer)
      get-monitor -computername $computer -erroraction silentlycontinue | convertto-csv -notypeinformation | select-object -skip 1 | Out-File $monitorinventory -Append -encoding utf8
    } else {
      ForceManagement($Computer)
      Get-WmiObject -query "SELECT * FROM Win32_OperatingSystem" -ComputerName $Computer -erroraction silentlycontinue | out-null
      if ($?){
        Write-Host "Attempting to retry polling $Computer..."
        PollComputers($Computer)
        get-monitor -computername $computer -erroraction silentlycontinue | convertto-csv -notypeinformation | select-object -skip 1 | Out-File $monitorinventory -Append -encoding utf8
      } else {
        Write-Host "Failed to get info for $computer. Moving on..."
        Add-Content $inventoryreport "$Computer, CONNECTIONERROR"
      }
    }
  } Else {
    Write-Host "$Computer is offline. Moving on..."
    Add-Content $inventoryreport "$Computer, OFFLINE"
  }
}