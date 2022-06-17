#
# Get-BIOS-Settings-By-Model.ps1
#
# BIOS-related code written by: Jim Rennell (jrennell@umich.edu)
# Slack code written by: Greg Baker (bakegreg@umich.edu)
# Last updated: 2022-06-xx
#
# This script will query the BIOS settings of Dell and HP computers and send them to
# a slack channel.  It takes the code that Greg wrote for sending Slack messsages and
# modifies it to query and send BIOS configurations settings.
#
## 
#


###################################################################################################
#  The following section is copied from Greg Baker's Send-SlackMessage.ps1 script dated 5/10/22.  #
###################################################################################################

$ErrorActionPreference = 'SilentlyContinue'

function Read-SCCM-Variable($sccm_variable)
{
	$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
	$data =  $tsenv.Value($sccm_variable)
	return $data
}

function New-SlackMessage
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable],[String])]
    Param
    (
        [string]$Channel,
        [string]$Text,
        [string]$Username,
        [string]$IconUrl,
        [string]$IconEmoji,
        [switch]$AsUser,
        [switch]$LinkNames,
        [string]$Thread,

        [validateset('full','none')]
        [string]$Parse,

        [validateset($True, $False)]
        [bool]$UnfurlLinks,

        [validateset($True, $False)]
        [bool]$UnfurlMedia,

        [Parameter(Mandatory=$true,
                   ValueFromPipeline = $true,
                   Position=1)]
        [PSTypeName('PSSlack.MessageAttachment')]
        [System.Collections.Hashtable[]]
        $Attachments
    )
    Begin
    {
        $AllAttachments = @()
    }
    Process
    {
        foreach($Attachment in $Attachments)
        {
            $AllAttachments += $Attachment
        }
    }
    End
    {
        $body = @{}

        switch ($psboundparameters.keys) {
            'channel'     { $body.channel      = $Channel}
            'text'        { $body.text         = $text}
            'username'    { $body.username     = $username}
            'asuser'     { $body.as_user       = $AsUser}
            'iconurl'     { $body.icon_url     = $iconurl}
            'iconemoji'   { $body.icon_emoji   = $iconemoji}
            'linknames'   { $body.link_names   = 1}
            'thread'      {$body.thread_ts = $Thread}
            'Parse'       { $body.Parse        = $Parse}
            'UnfurlLinks' { $body.Unfurl_Links = $UnfurlLinks}
            'UnfurlMedia' { $body.Unfurl_Media = $UnfurlMedia}
            'iconurl'     { $body.icon_url     = $iconurl}
            'attachments' { $body.attachments   = @($AllAttachments)}
        }

        Add-ObjectDetail -InputObject $body -TypeName PSSlack.Message
    }
}
#Borrowed from https://github.com/jgigler/Powershell.Slack - thanks @jgigler et al!
function New-SlackMessageAttachment
{
    [CmdletBinding(DefaultParameterSetName='Severity')]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [PSTypeName('PSSlack.MessageAttachment')]
        [object[]]
        $ExistingAttachment,

        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]$Fallback,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Severity')]
        [ValidateSet("good",
                     "warning",
                     "danger")]
        [String]$Severity,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Color')]
        [Alias("Colour")]
        $Color,

        [String]$AuthorName,
        [String]$Pretext,
        [String]$AuthorLink,
        [String]$AuthorIcon,
        [String]$Title,
        [String]$TitleLink,
        [Parameter(Position=1)]
        [String]$Text,
        [String]$ImageURL,
        [String]$ThumbURL,
        [validatescript({
            foreach($key in $_.keys){
                if('title', 'short', 'value' -notcontains $key)
                {
                    throw "$Key is invalid, must be 'title', 'value', or 'short'"
                }
            }
            $true
        })]
        [System.Collections.Hashtable[]]$Fields,
        [System.Collections.Hashtable[]]$Actions,
        [string]$CallBackId,
        [validateset('text','pretext','fields')]
        [string[]]$MarkDownFields # https://get.slack.help/hc/en-us/articles/202288908-How-can-I-add-formatting-to-my-messages-
    )

    Begin
    {
        if(-not $Actions -and $CallBackId)
        {
            throw "The Actions parameter is required when the CallbackId parameter is used"
        }
        elseif(-not $CallBackId -and $Actions)
        {
            throw "The CallBackId parameter is required when the Actions parameter is used"
        }
        
        #consolidate the colour and severity parameters for the API.
        if($PSCmdlet.ParameterSetName -like 'Severity')
        {
            $Color = $Severity
        }

        $Attachment = @{}
        switch($PSBoundParameters.Keys)
        {
            'fallback' {$Attachment.fallback = $Fallback}
            'color' {$Attachment.color = $Color}
            'pretext'{$Attachment.pretext = $Pretext}
            'AuthorName'{$Attachment.author_name = $AuthorName}
            'AuthorLink' {$Attachment.author_link = $AuthorLink}
            'AuthorIcon' { $Attachment.author_icon = $AuthorIcon}
            'Title' { $Attachment.title = $Title}
            'TitleLink' { $Attachment.title_link = $TitleLink }
            'Text' {$Attachment.text = $Text}
            'fields' { $Attachment.fields = $Fields } #Fields are defined by the user as an Array of HashTables.
            'actions' { $Attachment.actions = $Actions } #Actions are defined by the user as an Array of HashTables.
            'CallbackId' { $Attachment.callback_id = $CallbackId }
            'ImageUrl' {$Attachment.image_url = $ImageURL}
            'ThumbUrl' {$Attachment.thumb_url = $ThumbURL}
            'MarkDownFields' {$Attachment.mrkdwn_in = @($MarkDownFields)}
        }

        Add-ObjectDetail -InputObject $Attachment -TypeName 'PSSlack.MessageAttachment' -Passthru $False
        $ReturnObject = @()
    }
    Process
    {
        foreach($a in $ExistingAttachment)
        {
            $ReturnObject += $a
        }
        
        If($ExistingAttachment)
        {
            Write-Verbose "Existing Attachemnt: $($ExistingAttachment | Convertto-Json -compress)"
        }
    }
    End {
        $ReturnObject += $Attachment
        $ReturnObject
    }
}
function Add-ObjectDetail
{
    [CmdletBinding()] 
    param(
           [Parameter( Mandatory = $true,
                       Position=0,
                       ValueFromPipeline=$true )]
           [ValidateNotNullOrEmpty()]
           [psobject[]]$InputObject,

           [Parameter( Mandatory = $false,
                       Position=1)]
           [string]$TypeName,

           [Parameter( Mandatory = $false,
                       Position=2)]    
           [System.Collections.Hashtable]$PropertyToAdd,

           [Parameter( Mandatory = $false,
                       Position=3)]
           [ValidateNotNullOrEmpty()]
           [Alias('dp')]
           [System.String[]]$DefaultProperties,

           [boolean]$Passthru = $True
    )
    
    Begin
    {
        if($PSBoundParameters.ContainsKey('DefaultProperties'))
        {
            # define a subset of properties
            $ddps = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet,$DefaultProperties
            $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]$ddps
        }
    }
    Process
    {
        foreach($Object in $InputObject)
        {
            switch ($PSBoundParameters.Keys)
            {
                'PropertyToAdd'
                {
                    foreach($Key in $PropertyToAdd.Keys)
                    {
                        #Add some noteproperties. Slightly faster than Add-Member.
                        $Object.PSObject.Properties.Add( ( New-Object System.Management.Automation.PSNoteProperty($Key, $PropertyToAdd[$Key]) ) )  
                    }
                }
                'TypeName'
                {
                    #Add specified type
                    [void]$Object.PSObject.TypeNames.Insert(0,$TypeName)
                }
                'DefaultProperties'
                {
                    # Attach default display property set
                    Add-Member -InputObject $Object -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
                }
            }
            if($Passthru)
            {
                $Object
            }
        }
    }
}
function Remove-SensitiveData {
    param (
        [parameter(ValueFromPipeline = $True)]
        $InputObject,
        $SensitiveProperties = @('Uri', 'Token'),
        $ForceVerbose = $Script:PSSlack.ForceVerbose
    )
    process {
        if($ForceVerbose) {
            return $InputObject
        }
        if($InputObject -is [hashtable] -or ($InputObject.Keys.Count -gt 0 -and $InputObject.Values.Count -gt 0)) {
            $Output = [hashtable]$($InputObject.PSObject.Copy())
            foreach($Prop in $SensitiveProperties) {
                if($InputObject.ContainsKey($Prop)) {
                    $Output[$Prop] = 'REDACTED'
                }
            }
            $Output
        }
        else {
            $InputObject | Microsoft.PowerShell.Utility\Select-Object -Property * -ExcludeProperty $SensitiveProperties
        }
    }
}
function Send-SlackMessage {
    [cmdletbinding(DefaultParameterSetName = 'SlackMessage')]
    param (

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Token = $Script:PSSlack.Token,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Uri = $Script:PSSlack.Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Proxy = $Script:PSSlack.Proxy,

        [PSTypeName('PSSlack.Message')]
        [parameter(ParameterSetName = 'SlackMessage',
                   ValueFromPipeline = $True)]
        $SlackMessage,

        $Channel,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True,
                   Position = 1)]
        $Text,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        $Username,

        [parameter(ParameterSetName = 'Param',
        ValueFromPipelineByPropertyName = $True)]
        $Thread,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        $IconUrl,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        $IconEmoji,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [switch]$AsUser,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [switch]$LinkNames,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [validateset('full','none')]
        [string]$Parse = 'none',

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [validateset($True, $False)]
        [bool]$UnfurlLinks,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [validateset($True, $False)]
        [bool]$UnfurlMedia,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [PSTypeName('PSSlack.MessageAttachment')]
        [System.Collections.Hashtable[]]$Attachments,

        [switch]$ForceVerbose = $Script:PSSlack.ForceVerbose
    )
    begin
    {
        Write-Debug "Send-SlackMessage Bound parameters: $($PSBoundParameters | Remove-SensitiveData | Out-String)`nParameterSetName $($PSCmdlet.ParameterSetName)"
        $Messages = @()
        $ProxyParam = @{}
        if($Proxy)
        {
            $ProxyParam.Proxy = $Proxy
        }
    }
    process
    {
        if($PSCmdlet.ParameterSetName -eq 'Param')
        {
            $body = @{ }

            switch ($psboundparameters.keys)
            {
                'channel'     {$body.channel = $channel }
                'text'        {$body.text     = $text}
                'thread'      {$body.thread_ts = $Thread}
                'username'    {$body.username = $username}
                'asuser'      {$body.as_user = $AsUser}
                'iconurl'     {$body.icon_url = $iconurl}
                'iconemoji'   {$body.icon_emoji   = $iconemoji}
                'linknames'   {$body.link_names = 1}
                'parse'       {$body.parse = $Parse}
                'UnfurlLinks' {$body.unfurl_links = $UnfurlLinks}
                'UnfurlMedia' {$body.unfurl_media = $UnfurlMedia}
                'attachments' {$body.attachments = $Attachments}
            }
            $Messages += $Body
        }
        else
        {
            foreach($Message in $SlackMessage)
            {
                $Messages += $SlackMessage
            }
        }
    }
    end
    {
        foreach($Message in $Messages)
        {
            if($Token -or ($Script:PSSlack.Token -and -not $Uri))
            {
                if($Message.attachments)
                {
                    $Message.attachments = ConvertTo-Json -InputObject @($Message.attachments) -Depth 6 -Compress
                }

                Write-Verbose "Send-SlackApi -Body $($Message | Format-List | Out-String)"
                $response = Send-SlackApi @ProxyParam -Method chat.postMessage -Body $Message -Token $Token -ForceVerbose:$ForceVerbose

                if ($response.ok)
                {
                    $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                    $response | Add-Member -MemberType NoteProperty -Name link -Value $link
                }

                $response
            }
            elseif($Uri -or $Script:PSSlack.Uri)
            {
                if(-not $ForceVerbose) {
                    $ProxyParam.Add('Verbose', $False)
                }
                if($ForceVerbose) {
                    $ProxyParam.Add('Verbose', $true)
                }
                $json = ConvertTo-Json -Depth 6 -Compress -InputObject $Message
                Invoke-RestMethod @ProxyParam -Method Post -Body $json -Uri $Uri
            }
            else
            {
                Throw 'No Uri or Token specified.  Specify a Uri or Token in the parameters or via Set-PSSlackConfig'
            }
        }
    }
}

function Read-SCCM-Variable($sccm_variable)
{
	$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
	$data =  $tsenv.Value($sccm_variable)
	return $data
}




###################################################################################################
# Main routine - 
###################################################################################################


$url = Read-SCCM-Variable("CAENSlackWebhookUrl")
$model = (Get-WmiObject -Class:Win32_ComputerSystem).Model
$Computer = Read-SCCM-Variable("CAENComputerName")
$Computer = $Computer.toupper()
$tsname = Read-SCCM-Variable("_SMSTSPackageName") #read in task sequence name
$product = Read-SCCM-Variable("CAEN_Product")
$version = Read-SCCM-Variable("CAEN_Version")
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
#handle unknown computer names
if (($Computer.ToLower() -like 'minwinpc*') -or !$Computer ){
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
    else{
        $Computer += " (from name service)"
    }
}
if ((Get-WmiObject -class Win32_OperatingSystem).Caption -eq 'Microsoft Windows 10 Enterprise') {  #only works correctly in full Windows OS
	$mac = Get-NetAdapter | Where-Object Status -eq "up" | Where-Object Name -NotLike "VMware*" | Select-Object -Expand MacAddress
}
else { #when in WinPE the get-netadapter function is not available
	$mac = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | Select-Object description, macaddress | Where-Object {$_.macaddress -and $_.description -notmatch "VMware*"} | Select-Object -expand macaddress
}
$mac = $mac -replace ":","-"
#$lastStep = read-sccm-variable("ErrorStepName")
#$lastStepCode = read-sccm-variable("ErrorStepCode")
$productversion = "$product $version"
if ((-not $product) -and (-not $version)){
    $productversion = "Failed before it could be determined"
}

$Manufacturer = (Get-WmiObject Win32_ComputerSystem -Namespace "root\cimv2").manufacturer
$BIOS_Version = (Get-WmiObject Win32_BIOS -Namespace "root\cimv2").SMBIOSBIOSVersion

#send slack message
$SlackProperties = [pscustomobject]@{
    "Product/Version" = "$productversion"
    "Task Sequence" = $tsname
    "Computer Model" = $model
    "MAC" = $mac
    "Computer Manufacturer" = $Manufacturer
    "BIOS Version" = $BIOS_Version
#    "Failed Step" = $laststep
#    "Return Code" = $lastStepCode
}
$SlackFields = @()
foreach ($Prop in $SlackProperties.psobject.Properties.Name){
    $SlackFields += @{
        title = $Prop
        value = $SlackProperties.$Prop
        short = $true
    }
}


# Call appropriate utility to get BIOS settings 
$Dell_BIOS_Setting_Util = ".\Manage-DellBiosSettings-WMI-Mod.ps1"
$HP_BIOS_Setting_Util = ".\BiosConfigUtility64.exe"

if($Manufacturer -eq "Dell Inc.") {
	$settingsfile = $Env:Temp + "\BIOSSettings.csv"
	$run_output = & $Dell_BIOS_Setting_Util -GetSettings -CsvPath $settingsfile
	$messagetext = get-content $settingsfile
}
elseif( ($Manufacturer -eq "Hewlett-Packard") -or ($Manufacturer -eq "HP") ) {
	$settingsfile = $Env:Temp + "\BIOSSettings.txt"
	$run_output = & $HP_BIOS_Setting_Util /get:$settingsfile
	$messagetext = get-content $settingsfile
}
else {
	$messagetext = "Computer Manufacturer not supported for querying BIOS settings"
}

# Check if settings file was found and read
if(-not $messagetext) {$messagetext = "Could not read settings file: $settingsfile`n`n$run_output"}


# Send settings file as a Slack attachment
$att = New-SlackMessageAttachment -Color "Good" -Title "BIOS Settings : $Computer" -Fields $SlackFields -fallback "$Computer" -Text "``````$messagetext``````"
new-slackmessage -Channel "#windows-bios-configuration" -Attachments $att | Send-SlackMessage -Uri $url



