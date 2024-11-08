$nonUsbDisks = get-disk | where-object {$_.BusType -ne "USB"}
if ($nonUsbDisks){
    $diskinfo = foreach ($disk in $nonUsbDisks){
        $size = [math]::round($disk.size /1Gb, 3)
        $properties = [ordered]@{
            "Number" = $disk.number
            "Name" = $disk.FriendlyName
            "Model" = $disk.model
            "Serial" = $disk.serialnumber
            "Size (GB)" = $size
        }
        new-object -typename psobject -property $properties
    }
    if ($diskinfo.count -ne 1){
        $diskinfostring = $diskinfo | out-string
        $Message = "Warning: multiple disks detected. This can cause an installation failure and loss of data on Disk 0.`n`nPlease disconnect all disks except the one you intend to install the OS to and restart the installation.$diskinfostring"
        $Message = $message.trim()
        
        $Title = "CAEN Notification"
        $Button = 0 #a single OK button (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
        $Icon = 48 #an Exclamation mark icon
        $SecondsToWait = 1800 #30 minutes

        $TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
        $TSProgressUI.CloseProgressDialog()

        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null   
        (New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon)
    }
}
