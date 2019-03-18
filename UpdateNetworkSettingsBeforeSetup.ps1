    [CmdletBinding()]

    Param
    (
     [Parameter(Mandatory=$true)]
     [String]
     $ExternalNetwork,
     [Parameter(Mandatory=$true)]
     [String]
     $ExternalDomainFqdn
    )


function Test-IpAndSubnetInput
{
    [CmdletBinding()] 
    param(
        [Parameter(ValueFromPipeline=$True, Mandatory=$true)]
        [String]
        $Address
    )

    $ErrorActionPreference = 'Stop'

    $splitAddress = $Address.Split('/')
    $ipAddress = $splitAddress[0]
    $prefix = $splitAddress[1]

    if(-not $prefix)
    {
        throw ("Invalid Subnet")
    }
    if ($prefix -ne 24)
    {
        throw ("24 bit subnet required")
    }

    $ipAddress | Test-IpInput
}

function Test-IpInput
{
    [CmdletBinding()] 
    param(
        [Parameter(ValueFromPipeline=$True, Mandatory=$true)]
        [String]
        $Address
    )

    $ErrorActionPreference = 'Stop'

    try
    {
        $ipAddress = [IPAddress]$Address
    }
    catch
    {
        throw ("Invalid IP Address")
    }

    # Validate IP Address
    if(-not ($Address -match $ipAddress))
    {
        throw ("Invalid IP Address")
    }
}

$DeploymentScriptPath = "$env:SystemDrive\CloudDeployment\Setup\DeploySingleNode.ps1"
if (!(Test-Path $DeploymentScriptPath))
    {
    . C:\CloudDeployment\Setup\BootstrapAzureStackDeployment.ps1
    }
#OLD $configfile = 'C:\CloudDeployment\Configuration\OneNodeCustomerConfigTemplate.xml'
$parameterfile = 'C:\CloudDeployment\Configuration\Parameters\OneNodeDeploymentParameters.xml'

$ExternalNetwork | Test-IpAndSubnetInput
$index = $ExternalNetwork.LastIndexOf('.')
$prefix = $ExternalNetwork.Substring(0,$index)

$testip = Get-NetIPAddress | Where-Object {$_.IPAddress -like "$prefix.*"}
if ($testip )
    {
        throw ("External Subnet must be different from server network")
    }

#OLD [xml]$configxml=Get-Content($configfile)
[xml]$parameterxml=Get-Content($parameterfile)

# SET NETWORKS INFO
#MGMT
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-VMDC1_DefaultGateway}]"]/@Value').Value = "$prefix.1"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-VMDC1_PhysicalSubnet}]"]/@Value').Value = "$prefix.0/25"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-VMDC1_StartAddress}]"]/@Value').Value = "$prefix.97"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-VMDC1_EndAddress}]"]/@Value').Value = "$prefix.126"

#Transit
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-Transit_DefaultGateway}]"]/@Value').Value = "$prefix.1"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-Transit_PhysicalSubnet}]"]/@Value').Value = "$prefix.0/25"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-Transit_StartAddress}]"]/@Value').Value = "$prefix.17"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-Transit_EndAddress}]"]/@Value').Value = "$prefix.30"
#HNV
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-HNV_DefaultGateway}]"]/@Value').Value = "$prefix.1"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-HNV_PhysicalSubnet}]"]/@Value').Value = "$prefix.0/28"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-HNV_StartAddress}]"]/@Value').Value = "$prefix.1"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-HNV_EndAddress}]"]/@Value').Value = "$prefix.14"
#Off Stamp
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-OffStampInfra_DefaultGateway}]"]/@Value').Value = "$prefix.1"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-OffStampInfra_PhysicalSubnet}]"]/@Value').Value = "$prefix.0/25"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-OffStampInfra_StartAddress}]"]/@Value').Value = "$prefix.49"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{s-cluster-OffStampInfra_EndAddress}]"]/@Value').Value = "$prefix.62"
#External
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{External_DefaultGateway}]"]/@Value').Value = "$prefix.192"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{External_PhysicalSubnet}]"]/@Value').Value = "$prefix.192/26"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{External_StartAddress}]"]/@Value').Value = "$prefix.193"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{External_EndAddress}]"]/@Value').Value = "$prefix.254"

$parameterxml.SelectsingleNode('//Parameter[@Reference="[{MuxPeerRouterIPv4Address}]"]/@Value').Value = "$prefix.1"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{MuxIPv4Address}]"]/@Value').Value = "$prefix.96"


# SET Static One Node IPs
#
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{SLB-HNV-IpAddress}]"]/@Value').Value = "$prefix.96"
########################
# New from ASDK 1901
# this is still a test to see if it works.. Not ready for final yet.
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{HostRouter-PrefixLength}]"]/@Value').Value = "25"
$parameterxml.SelectsingleNode('//Parameter[@Reference="[{HostRouter-IpAddress}]"]/@Value').Value = "$prefix.1"
##### End of new for 1901
########################

# SET SUBNET RANGES
# Management subnet
$parameterxml.SelectSingleNode('//Parameter[@Name="Management Subnet"]/@Value').Value="$prefix.0/25"
$parameterxml.SelectSingleNode('//Parameter[@Name="Management Subnet"]/@SkipCount').Value='96'
$parameterxml.SelectSingleNode('//Parameter[@Name="Management Subnet"]/@AllocatableIps').Value='30'
#Transit subnet
$parameterxml.SelectSingleNode('//Parameter[@Name="Transit Subnet"]/@Value').Value="$prefix.0/25"
$parameterxml.SelectSingleNode('//Parameter[@Name="Transit Subnet"]/@SkipCount').Value='16'
$parameterxml.SelectSingleNode('//Parameter[@Name="Transit Subnet"]/@AllocatableIps').Value='14'
#HNV subnet
$parameterxml.SelectSingleNode('//Parameter[@Name="HNV Subnet"]/@Value').Value="$prefix.0/28"
$parameterxml.SelectSingleNode('//Parameter[@Name="HNV Subnet"]/@SkipCount').Value='1'
$parameterxml.SelectSingleNode('//Parameter[@Name="HNV Subnet"]/@AllocatableIps').Value='14'
#OffStampInfra subnet
$parameterxml.SelectSingleNode('//Parameter[@Name="OffStampInfra Subnet"]/@Value').Value="$prefix.0/25"
$parameterxml.SelectSingleNode('//Parameter[@Name="OffStampInfra Subnet"]/@SkipCount').Value='48'
$parameterxml.SelectSingleNode('//Parameter[@Name="OffStampInfra Subnet"]/@AllocatableIps').Value='14'
#External Subnet
$parameterxml.SelectSingleNode('//Parameter[@Name="External Subnet"]/@Value').Value="$prefix.192/26"
$parameterxml.SelectSingleNode('//Parameter[@Name="External Subnet"]/@SkipCount').Value='0'
$parameterxml.SelectSingleNode('//Parameter[@Name="External Subnet"]/@AllocatableIps').Value='62'
 

$parameterxml.Save($parameterfile)
write-host "Configuration_OneNoteCustomerConfigTemplate - Updates has been saved"

$vpnfile="C:\CloudDeployment\Configuration\Roles\Infrastructure\POC\OneNodeRole.xml"
[xml]$vpnxml = Get-Content($vpnfile)
$vpnxml.SelectSingleNode('//StaticIPPool/@StartIPv4Address').Value="$Prefix.65"
$vpnxml.SelectSingleNode('//StaticIPPool/@EndIPv4Address').Value="$Prefix.94"
$vpnxml.Save($vpnfile)
write-host "Configuration_Roles_Ifrasrtucture_POC_OneNodeRole.xml - Updates has been saved"

$InstallDeploySingleNodefile = "C:\CloudDeployment\Setup\DeploySingleNode.ps1"
if (!([String]::IsNullOrEmpty($ExternalDomainFqdn)))
    {
    (Get-Content $InstallDeploySingleNodefile).Replace('"azurestack.external"','"'+$ExternalDomainFqdn+'"') | Set-Content $InstallDeploySingleNodefile
    write-host "Setup_DeploySingleNode.ps1 - Updates has been saved"
    }


$InstallCommonDeploySingleNodeCommonfile = "C:\CloudDeployment\Setup\Common\DeploySingleNodeCommon.ps1"
if (!([String]::IsNullOrEmpty($ExternalDomainFqdn)))
    {
    (Get-Content $InstallCommonDeploySingleNodeCommonfile).Replace('"azurestack.external"','"'+$ExternalDomainFqdn+'"') | Set-Content $InstallCommonDeploySingleNodeCommonfile
    write-host "Setup_Common_DeploySingleNodeCommon.ps1 - Updates has been saved"
    }