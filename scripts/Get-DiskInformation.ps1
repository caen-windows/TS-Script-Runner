$nonUsbDisks = get-disk | where-object {$_.BusType -ne "USB"} | sort-object number
if ($nonUsbDisks){
    $diskinfo = foreach ($disk in $nonUsbDisks){
        $size = [math]::round($disk.size /1Gb, 3)
        $properties = [ordered]@{
            "Number" = $disk.number
            "Model" = $disk.model
            "Bus Type" = $disk.bustype
            "Serial" = $disk.serialnumber
            "Size (GB)" = $size
        }
        new-object -typename psobject -property $properties
    }
    if ($nonUsbDisks.count -gt 1){
        $diskinfostring = $diskinfo | out-string
        $Message = "Warning: multiple disks detected. This can cause an installation failure and loss of data on Disk 0.`n`nCAEN recommends disconnecting all disks except the one you intend to install the OS on and restarting the installation.$diskinfostring`n`nClick 'Cancel' to restart or 'OK' to continue anyway."
        $Message = $message.trim()
        
        $Title = "CAEN Notification"
        $Button = 1 #a single OK button (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
        $Icon = 48 #an Exclamation mark icon
        $SecondsToWait = 1800 #30 minutes

        $TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
        $TSProgressUI.CloseProgressDialog()

        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null   
        $output = (New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon)
        if (-not($output -eq 1 -or $output -eq -1)){
            restart-computer -force
        }
    }
}
