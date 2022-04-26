# CAEN Task Sequence Script Runner
The CAEN Task Sequence Script Runner is a platform for running PowerShell scripts stored in a GitHub repository as part of an SCCM task sequence. It is an alternative to using SCCM packages/applications stored on SCCM distribution points.

### Purpose
`Start-ScriptRunner.ps1` is intended to be run in an SCCM WinPE environment prior to the task sequence step that partitions the disk. Unlike a built in SCCM package or application, the script, json file containing child scripts, and the child scripts themselves can be downloaded to and run from the WinPE ramdisk. This is useful for systems that do not yet have a formatted disk where the download of SCCM packages or applications fails.

### Components
This repo contains three different components:
1. `Start-ScriptRunner.ps1` contains the main logic. It can download a GitHub repository, read in scripts from a json file in the repo, and run or skip each script. 
2. `Scripts.json` contains an array `entries` of child scripts to run. Each entry has a path to the script (relative to `Start-ScriptRunner`), a computer name string used to match against the name of a system to determine if the script should be run, and optional arguments for the script.
3. Individual child scripts to be run by `Start-ScriptRunner` are also included. 

### Start-ScriptRunner.ps1 Arguments
`-JsonFileName` is the path to the .json file relative to `Start-ScriptRunner.ps1`.
`-DownloadLocation` is the location the github repo should be downloaded to. It should be an empty directory.
`-GithubTokenTSVariable` (optional) is the SCCM task sequence variable that the GitHub Token is stored in for connecting to a private repo. If none is defined the download will be attempted as if it is a public repo.
`-AllowedScriptRunTime` (optional) is the maximum allowed run time, in seconds, of each individual script run by `Start-ScriptRunner.ps1`. A default value is set in `Start-ScriptRunner.ps1` if this argument is not defined.

### User Interface
`Start-ScriptRunner` updates the builtin SCCM progress bar to indicate the child script it is currently running and how many total scripts will be run. Note that each child script is responsible for closing this progress bar if and when it needs to display a message box. `Start-ScriptRunner` re-opens the progress bar after each child script.

### Scripts Output
`Start-ScriptRunner` logs to the pipeline, so when run as part of an SCCM task sequence it logs to `smsts.log`. 

Any output of the child scripts to be used later in the task sequence should be stored in task sequence variables. The ramdisk they are downloaded to is ephemeral and the hard disk is going to be formatted, so writing to a local file is not appropriate. 

### Runtime Limitations
Note that each child script can be timed out by `Start-ScriptRunner.ps1` to ensure the task sequence can always be zero touch deployed. The number of seconds before this occurs is defined in the `-AllowedScriptRunTime` argument for `Start-ScriptRunner.ps1`.