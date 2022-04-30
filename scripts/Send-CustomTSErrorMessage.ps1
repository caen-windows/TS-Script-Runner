$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSEnv = new-object -comobject Microsoft.SMS.TSEnvironment

$OrgName = $tsenv.value("_SMSTSOrgName")
$PackageName = $tsenv.value("_SMSTSPackageName")
$Title = $tsenv.value("_SMSTSCustomProgressDialogMessage")

$model = (Get-WmiObject -Class:Win32_ComputerSystem).Model
$errorStep = $tsenv.value("ErrorStepName")
$errorStepCode = $tsenv.value("ErrorStepCode")
$timeout = 86400
$Computer = $tsenv.value("CAENComputerName")
if (($Computer -like "*minint*") -or (-not($Computer))){
    $scriptpath = $MyInvocation.MyCommand.Path
    $dir = Split-Path $scriptpath
    set-location $dir
    $ip = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | Where-object { $_.ipaddress} | Where-object { ($_.Description -notlike "*VMware*") } | Select-object -Expand ipaddress 
    $ip = $ip -split '`n'
    $ip = $ip[0]
    $Computer = .\nslookup.exe $ip | Select-String -pattern "engin.umich.edu"
    $Computer = $Computer -split ' '
    $Computer = ($Computer[-1] -replace ".engin.umich.edu","").toupper() 
    if (-not($Computer)){
        $Computer = "Not detected. Please send CAEN the intended computer name."
    }
    else{
        $Computer +=  " (pulled from name service)"
    }
}
if ((Get-WmiObject -class Win32_OperatingSystem).Caption -eq 'Microsoft Windows 10 Enterprise') {  #only works correctly in full Windows OS
	$mac = Get-NetAdapter | Where-Object Status -eq "up" | Where-Object Name -NotLike "VMware*" | Select-Object -Expand MacAddress
}
else { #when in WinPE the get-netadapter function is not available
    $mac = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | Select-Object description, macaddress | Where-Object {$_.macaddress -and $_.description -notmatch "VMware*"} | Select-Object -expand macaddress
}
$TSProgressUI.CloseProgressDialog()
if ($errorStep -like "*Detect Disk*"){
 $TSProgressUI.ShowErrorDialog(`
        $PackageName,`
        $PackageName,`
        $ErrorStep,`
        "No disk detected to install the CLSEBD on. If a disk is installed a driver is likely missing. Put the driver on a usb drive, boot into the CLSEBD installer, and use drvload to load it before starting the task sequence next time. Please include the computer model [ $model ] if you open a ticket with CAEN.",`
        $errorStepCode,`
        $timeout,`
        1,`
        $errorstep
    )
}
else{
    $TSProgressUI.ShowErrorDialog(`
        $PackageName,`
        $PackageName,`
        $ErrorStep,`
        "Please send the following information to CAEN for troubleshooting: Computer Name : [ $Computer ]   Model : [ $model ]   MAC : [ $mac ]   Error Step : [ $errorstep ]   Return Code : [ $errorStepCode ]",`
        $errorStepCode,`
        $timeout,`
        1,`
        $errorstep
    )
}
