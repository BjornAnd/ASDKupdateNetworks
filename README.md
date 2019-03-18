# ASDKupdateNetworks
When installing ASDK, after the first reboot into the vhd-file. the networksettings should be changed. This is what this does...

Usage:
- run the ASDK-installer. And after it hase rebooted into the "Cloudbuilder.vhdx" and _before_ running the ASDK-installer again.
- Download script. Save it to "c:\CloudDeployment\setup\
- From an elevatated PowerShell-prompt run:
       Set-Location "C:\CloudDeployment\Setup"
       .\UpdateNetworkSettingsBeforeSetup.ps1 -ExternalNetwork [yourExternalNetwork] -ExternalDomainFqdn [yourFQDN]
- This should only take a minute. 
- Continue with your normal installation and run the ASDK-installer


EXAMPLE OF HOW TO USE THE SCRIPT
Set-Location "C:\CloudDeployment\Setup"
.\UpdateNetworkSettingsBeforeSetup.ps1 -ExternalNetwork 56.56.56.0/24 -ExternalDomainFqdn "ASDK1.MyCompany.com"
 
 This will result in the ASDK beeing published on the 56.56.56.0/24 network and you will find the portal at https://portal.local.asdk1.mycompany.com
 
