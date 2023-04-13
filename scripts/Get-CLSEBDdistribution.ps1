$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$ComputerName = $tsenv.Value("CAENComputerName")

#------------------------------Connect to AD and get computer object-------------------------------------------
import-module ActiveDirectory 3>$null
$user = $tsenv.Value("CaenAdUser")
$pw = $tsenv.Value("CaenAdPw")

#the key is supposed to be integers separated by newlines but SCCM variables can't handle the newlines. Used commas instead so the data needs to converted. Writes it to disk so it can be read in in as a byte string
$tsenv.Value("CaenAdPwKey") -replace ",","`n" | out-file .\key -encoding utf8 

#build credential used to connect to AD (read only), map the drive using the AD powershell provider, set location to that drive, and get the computer object
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, ($pw | convertto-securestring -key (get-content .\key))
new-psdrive -PSProvider ActiveDirectory -Name umroot -Server "adsroot.itcs.umich.edu" -root "//RootDSE/OU=Engin,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu" -credential $credential
Set-Location umroot:
$computerObject = Get-ChildItem -recurse | Where-Object {$_.Name -eq $ComputerName}
$computerDN = $computerObject.distinguishedName 

#-------------------------------------------------------------------------------------------------------------

$TestingOU = "*OU=Testing,OU=Windows 11,OU=CAEN Lab Software Environment,OU=CAEN Managed Desktops,OU=CAEN,OU=ENGIN,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"
$UnstableOU = "*OU=Unstable,OU=Windows 11,OU=CAEN Lab Software Environment,OU=CAEN Managed Desktops,OU=CAEN,OU=ENGIN,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"

if ($computerDN -like $TestingOU){
    $returnValue = "Testing"
}
elseif ($computerDN -like $UnstableOU){
    $returnValue = "Unstable"
}
$tsenv.Value("Distribution") = $returnValue