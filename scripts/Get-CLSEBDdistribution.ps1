$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$ComputerDN = $tsenv.Value("DistinguishedName") #variable is set by get-nameandproduct.ps1
$distribution = $tsenv.Value("CAEN_DISTRIBUTION")
$TestingOU = "*OU=Testing,OU=Windows 11,OU=CAEN Lab Software Environment,OU=CAEN Managed Desktops,OU=CAEN,OU=ENGIN,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"
$UnstableOU = "*OU=Unstable,OU=Windows 11,OU=CAEN Lab Software Environment,OU=CAEN Managed Desktops,OU=CAEN,OU=ENGIN,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"
$distributions = @(`
    "Stable",`
    "Testing",`
    "Unstable"
)

if(-not($distribution -in $distributions)){
    $returnValue = "Stable" #default to stable OU
    if ($computerDN -like $TestingOU){
        $returnValue = "Testing"
    }
    elseif ($computerDN -like $UnstableOU){
        $returnValue = "Unstable"
    }
    $tsenv.Value("CAEN_DISTRIBUTION") = $returnValue
}