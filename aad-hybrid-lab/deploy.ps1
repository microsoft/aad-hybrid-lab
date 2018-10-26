$startTime=Get-Date
Write-Host "Beginning deployment at $starttime"

Import-Module Azure -ErrorAction SilentlyContinue

#DEPLOYMENT OPTIONS
    $vmSize                  = "Standard_A2_v2"

    # Must be unique for simultaneous/co-existing deployments
    $RGName                  = "<YOUR RESOURCE GROUP>"
    $DeployRegion            = "<SELECT AZURE REGION>"

    # "master" or "dev"
    $Branch                  = "master"

    $userName                = "<AD ADMINISTRATOR LOGIN>"
    $secpasswd               = “<AD ADMINISTRATOR PASSWORD>”

    $adDomainName            = "<2-PART AD DOMAIN NAME, LIKE CONTOSO.COM>"
    $usersArray              = @(
                                @{ "FName"= "Bob";  "LName"= "Jones";    "SAM"= "bjones" },
                                @{ "FName"= "Bill"; "LName"= "Smith";    "SAM"= "bsmith" },
                                @{ "FName"= "Mary"; "LName"= "Phillips"; "SAM"= "mphillips" },
                                @{ "FName"= "Sue";  "LName"= "Jackson";  "SAM"= "sjackson" }
                               )
    $defaultUserPassword     = "P@ssw0rd"

	# custom resolution for generated RDP connections
    $RDPWidth                = 1920
    $RDPHeight               = 1080
#END DEPLOYMENT OPTIONS

#Dot-sourced variable override (optional, comment out if not using)
. "$($env:PSH_Settings_Files)aad-hybrid-lab.ps1"

#ensure we're logged in
Get-AzureRmContext -ErrorAction Stop

#deploy
$AssetLocation           = "https://raw.githubusercontent.com/Microsoft/aad-hybrid-lab/master/aad-hybrid-lab/"

$parms=@{
    "adminPassword"               = $secpasswd;
    "adminUsername"               = $userName;
    "adDomainName"                = $ADDomainName;

    "vmSize"                      = $vmSize

    "assetLocation"               = $assetLocation;
    "virtualNetworkAddressRange"  = "10.$VNetAddrSpace2ndOctet.0.0/16";
    #The first IP deployed in the AD subnet, for the DC
    "adIP"                        = "10.$VNetAddrSpace2ndOctet.1.4";
    "adSubnetAddressRange"        = "10.$VNetAddrSpace2ndOctet.1.0/24";
    #if multiple deployments will need to route between vNets, be sure to make this distinct between them
    "usersArray"                  = $usersArray;
    "defaultUserPassword"         = "P@ssw0rd";
}

$version ++
$TemplateFile = $assetLocation + "deploy.json?x=$version"

try {
    Get-AzureRmResourceGroup -Name $RGName -ErrorAction Stop
    Write-Host "Resource group $RGName exists, updating deployment"
}
catch {
    $RG = New-AzureRmResourceGroup -Name $RGName -Location $DeployRegion -Tag @{ Shutdown = "true"; Startup = "false"}
    Write-Host "Created new resource group $RGName."
}
$deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -TemplateParameterObject $parms -TemplateFile $TemplateFile -Name "adLabDeploy$version"  -Force -Verbose

if ($deployment) {
    if (-not (Get-Command Get-IPForVM -ErrorAction SilentlyContinue)) {
        #load add-on functions to facilitate the RDP connectoid creation below
        $url="$($assetLocation)Scripts/Addons.ps1"
        $tempfile = "$env:TEMP\Addons.ps1"
        $webclient = New-Object System.Net.WebClient
        $webclient.DownloadFile($url, $tempfile)
        . $tempfile
    }

    $RDPFolder = "$env:USERPROFILE\desktop\$RGName\"
    if (!(Test-Path -Path $RDPFolder)) {
        md $RDPFolder
    }
    $ADName = $ADDomainName.Split('.')[0]
    $vms = Find-AzureRmResource -ResourceGroupNameContains $RGName | where {($_.ResourceType -like "Microsoft.Compute/virtualMachines")}
    if ($vms) {
        foreach ($vm in $vms) {
            $ip=Get-IPForVM -ResourceGroupName $RGName -VMName $vm.Name
            New-RDPConnectoid -ServerName $ip -LoginName "$($ADName)\$($userName)" -RDPName $vm.Name -OutputDirectory $RDPFolder -Width $RDPWidth -Height $RDPHeight
        }
    }

	$userList = "Local test user list:`r`n`r`n"
	$userList += ConvertTo-Json $usersArray
    $userList += "`r`n`r`nTest user password:`r`n$defaultUserPassword"

    Out-File -FilePath "$($RDPFolder)TestUsers.txt" -InputObject $userList

    start $RDPFolder
}

$endTime=Get-Date

Write-Host ""
Write-Host "Total Deployment time:"
New-TimeSpan -Start $startTime -End $endTime | Select Hours, Minutes, Seconds
