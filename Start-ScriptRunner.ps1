Param(
    [Parameter(Mandatory=$True)][string]$RepositoryZipFileUrl,
    [Parameter(Mandatory=$True)][string]$JsonFileName,
    [Parameter(Mandatory=$True)][string]$DownloadLocation, #should be an empty directory
    [string]$GithubTokenTSVariable,
    [int]$AllowedScriptRunTime = 900 #seconds
)

#Connect to task sequence environment and task sequence progress UI
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI

#Populate variables to be used in the Task Sequence UI (all default from the task sequence environment)
$OrgName = $tsenv.value("_SMSTSOrgName")
$PackageName = $tsenv.value("_SMSTSPackageName")
$Title = $tsenv.value("_SMSTSCustomProgressDialogMessage")
$CurrentAction = $tsenv.value("_SMSTSCurrentActionName")
$CurrentStep = [Convert]::ToUInt32($tsenv.Value("_SMSTSNextInstructionPointer"))
$TotalSteps = [Convert]::ToUInt32($tsenv.Value("_SMSTSInstructionTableSize"))

#verify downloadlocationroot exists
if (-not(test-path $DownloadLocation)){
    new-item $DownloadLocation -ItemType Directory -Confirm:$false
}

#download zip file, expand, and clean up zip file
write-output "Downloading GitHub repo from [ $RepositoryZipFileUrl ]"
$zipFile = join-path -path $DownloadLocation -ChildPath zip.zip
new-item $zipFile -ItemType File -Force
if ($GithubTokenTSVariable){ #for private repos
    $Token = $tsenv.Value("CAENGithubToken")
    Invoke-RestMethod -Uri $RepositoryZipFileUrl -method Get -Headers @{"Authorization" = "Bearer $Token"} -OutFile $ZipFile
}
else { #for public repos
    Invoke-RestMethod -Uri $RepositoryZipFileUrl -OutFile $ZipFile
}
Expand-Archive -path $zipFile -DestinationPath $DownloadLocation -Force
Remove-item -path $zipFile -Force
$DownloadLocation = (get-childitem $DownloadLocation).FullName
write-output "GitHub repo downloaded to [ $DownloadLocation ]"

#read in scripts to process from the json file and run them
$jsonFilePath = join-path -path $DownloadLocation -ChildPath $JsonFileName
write-output "Reading in script json file [ $jsonFilePath ]"
$json = Get-Content -Raw -Path $jsonFilePath | ConvertFrom-Json
write-output "Json script version: [ $($json.jsonversion) ]"
$entryCount = 0 #for keeping track of current step for TS the progress UI
write-output "There are [ $($json.entries.count) ] scripts to run in the json file"
foreach ($entry in $json.entries){
    $entryCount += 1
    $TSProgressUI.ShowActionProgress(` #custom TS step UI progress bar
        $OrgName,`
        $PackageName,`
        $Title,`
        $CurrentAction,`
        $CurrentStep,`
        $TotalSteps,`
        "Script [ $entryCount / $($json.entries.count) ] : $($entry.script.split("\")[-1]) ",`
        $entryCount,`
        $json.entries.count
    )

    $computerName = $tsenv.Value("CAENComputerName") #exists inside the foreach in case the value is changed by a script that is run
    $filepath = join-path $DownloadLocation -ChildPath $entry.script
    if ($entry.argumentList){
        $filepath = $filepath + " $($entry.argumentlist)"
    }
    write-output "Processing script [ $($entry.script) ]"
    write-output "Arguments [ $($entry.argumentList) ]"
    write-output "Computer Name [ $computerName ]"
    write-output "Name string to match against [ $($entry.ComputerNameString) ]"

    if (($entry.ComputerNameString -eq "All") -or ($computerName -like $entry.ComputerNameString)){
        write-output "Running [ powershell.exe -executionpolicy bypass -file $($filepath) ]."
        $processid = (start-process -nonewwindow -passthru -filepath "powershell.exe" -argumentList "-executionpolicy bypass -file $filepath").Id
        $starttime = get-date
        do{
            start-sleep -seconds 2
            $currenttime = get-date
            if (($currenttime - $starttime).totalseconds -gt $AllowedScriptRunTime){
                write-output "Script runtime of [ $AllowedScriptRunTime ] exceeded. Force closing it now."
                Get-Process -Id $processid | Select-Object -Property Id | ForEach-Object -Process { Stop-Process -Id $_.Id -Force }
            }
        } while ((get-process -Id $processid -ErrorAction Ignore) -and (($currenttime - $starttime).totalseconds -le $AllowedScriptRunTime))
        write-output "[$($entry.script)] completed."
    }
    else{
        write-output "Skipping [ $($entry.script) ]"
    }
}
write-output "All scripts from [ $jsonFileName ] have been processed. Exiting."