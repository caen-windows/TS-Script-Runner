$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

$Product = $tsenv.Value("CLSEBD")
$ComputerName = $tsenv.Value("CAENComputerName")
$Model = Get-WmiObject Win32_Computersystem | foreach-object {$_.Model}

if ($tsenv.Value("ZTILinux") -eq "true"){
	$reloadMode = "Dual Boot Linux"
	$Message = "Product:                 $product `nReload mode:        $reloadMode`nComputer Name:  $ComputerName `nModel:                     $Model`n`nThis box will automatically close in two minutes." 
}
else{
	$reloadMode = "Single Boot Windows"
	$Message = "Product:                 $product `nComputer Name:  $ComputerName `nModel:                     $Model`n`nThis box will automatically close in two minutes." 
}

#Display summary of the task sequence

$SecondsToWait = 120 #amount of time before the box automatically closes
$Title = "CAEN Product Summary"
$Button = 0 #a single OK button (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
$Icon = 64 #an Information icon

$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
(New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon)