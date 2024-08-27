$mac = get-ciminstance win32_networkadapter | where {$_.AdapterTypeId -eq 0 -and $_.NetConnectionStatus -eq 2} | select -expandproperty MACAddress
$smbiosguid = get-wmiobject Win32_ComputerSystemProduct  | Select-Object -ExpandProperty UUID

#Display summary of the task sequence
$Message = "The Windows 10 EBD is now available by request only. Please contact caen@umich.edu with the computer name, MAC address, and SMBIOS GUID of the system, as well as the reason Windows 10 is required. `n`nIn October 2025 Windows 10 reaches end of support from Microsoft. All Windows 10 EBD systems will need to be decommissioned or reloaded with Windows 11 by then.`n`nYour system information:`nMAC Address: [ $mac ]`nSMBIOS GUID: [ $smbiosguid ]" 
#$Message = "The Windows 10 EBD is now available by request only."
$Title = "CAEN Notification"
$Button = 0 #a single OK button (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
$Icon = 64 #an Information icon
$SecondsToWait = 10800 #3 hours

$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
(New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon)