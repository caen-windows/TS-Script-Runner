function IsFileLocked([string]$filePath){
    Rename-Item $filePath $filePath -ErrorVariable errs -ErrorAction SilentlyContinue
    return ($errs.Count -ne 0)
}

#Set powershell directory to script location
$scriptPath = Split-Path $MyInvocation.mycommand.path
Set-Location $scriptPath

function Read-SCCM-Variable($sccm_variable) 
{
	$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
	$data =  $tsenv.Value($sccm_variable)
	return $data
}
$tsname = Read-SCCM-Variable("_SMSTSPackageName") #read in task sequence name
$errorstep = Read-SCCM-Variable("ErrorStepName")
$model = get-ciminstance -ClassName win32_computersystem | select-object -expandproperty model
$mac = get-ciminstance win32_networkadapter | where-object {$_.AdapterTypeId -eq 0 -and $_.NetConnectionStatus -eq 2} | select-object -expandproperty MACAddress
$Computer = Read-SCCM-Variable("CAENComputerName")
if (($Computer.ToLower() -like 'minwinpc*') -or !$Computer ){
	if (($Computer.ToLower() -like 'minwinpc*') -or !$Computer ){
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
            $Computer = "Not entered into task sequence or name service."
        }
        else {
            $Computer += " (from name service)"
        }
    }
}

$from = "CAEN CLSE Deployment Tracking <CLSE-Deployment-NoReply@umich.edu>"
$UMODGroup = "CAEN CLSE Deployment Tracking <CAEN-CLSE-Deployment-Tracking@umich.edu>"
$body = "Task Sequence failed`n`nComputer Name : [ $Computer ]`nModel : [ $model ]`nMAC : [ $mac ]`n`nTask Sequence : [ $tsname ]`nError Step : [ $errorStep ]`n`nPlease see attached logs for details"


$Subject = "$Computer FAILED $tsname" 

#$smstsattachment = Get-ChildItem C:\Temp | Where-Object {$_.Name -match "smsts-"}
$smtpServer = "mx1.a.mail.umich.edu"
$body = $body -join "`n"


$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$message = new-object System.Net.Mail.MailMessage
$message.From = $from
$message.To.Add($UMODGroup)
$message.Subject = $Subject

#find attachments and deal with locked files
try {
    $logpath = Read-SCCM-Variable "_smstslogpath"
    $filepath = join-path -path $logpath -childpath "smsts*.log"
    $driverfilepath = join-path -path $logpath -childpath "*driverload.log"
    $loglist = get-childitem $filepath, $driverfilepath
    if ($loglist){
        New-Item (join-path -path $logpath -childpath "unlocked") -type directory
        foreach ($element in $loglist) {
            $outfile = $unlockedfolder + $element.name
            get-content $element | out-file (join-path -path (join-path -path $logpath -childpath "unlocked") -childpath $element.name)
        }
        $loglist = get-childitem (join-path -path $logpath -childpath "unlocked")
        $loglist | ForEach-Object {$message.Attachments.Add($_.fullname)}
    }
}

catch {
    $body += "`nUnable to attach logs"
}
    

$message.body = $body
$smtp.Send($message)