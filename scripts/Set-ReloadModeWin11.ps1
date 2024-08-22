$tsenv = new-object -comobject Microsoft.SMS.TSEnvironment
$ztilinux = $tsenv.Value("ZTILinux")
$leaveLinux = $tsenv.Value("LeaveLinux")
if (($leaveLinux -ne "true") -and ($leaveLinux -ne "false")){
	$linuxexists = test-path (join-path $env:TEMP -ChildPath "linuxexists.txt")
	if ($linuxexists -and ($ztilinux -eq "true")){
		write-output "LeaveLinux not set to 'true' or 'false'. Current value [ $LeaveLinux ]"
		$tsenv.Value('LeaveLinux') = "true"
		#Close the TS UI temporarily
		$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
		$TSProgressUI.CloseProgressDialog()
		$leaveLinux = $tsenv.Value("LeaveLinux")
		write-output "Displaying reload mode selection box because LeaveLinux not previously set to 'true' or 'false'. LeaveLinux now set to [ $leavelinux ]."
		$SecondsToWait = 60 #amount of time before the box automatically closes
		$Title = "Install Option"
		$Button = 4 #a yes/no button option (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
		$Icon = 64 #an Information icon
		$Message = "Refresh both Windows and Linux?`n`nYes = Windows and Linux are refreshed.`nNo = Only Windows is refreshed."
		$DefaultToNo = 256

		$choice = (New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon + $DefaultToNo)

		if ($choice -eq 6){ #6 equals a 'Yes'
			$tsenv.Value('LeaveLinux') = "false"
		}
		$leaveLinux = $tsenv.Value("LeaveLinux")
		write-output "Selection box choice = [ $choice ]. LeaveLinux now equals [ $leavelinux ]."
	}
	else {
		write-output "Skipping display of reload mode selection box. LeaveLinux = [ $leavelinux ]. ZTILinux = [ $ztilinux ]. LinuxExists = [ $linuxexists ]."
	}
}
else{
	write-output "Skipping display of reload mode selection box. LeaveLinux = [ $leavelinux ]."
}
	