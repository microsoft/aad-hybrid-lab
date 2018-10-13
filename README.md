# Azure Active Directory Hybrid Lab
## Creates an AD VM with Azure AD Connect installed
## Quick Start

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoft%2Faad-hybrid-lab%2Fmaster%2Faad-hybrid-lab%2Fdeploy.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>

## Details
* Deploys the following infrastructure:
 * Virtual Network
  * 1 subnet
  * 1 Network Security Groups
    * AD - permits AD traffic, RDP incoming to network; limits DMZ access
  * Public IP Address
  * AD VM
	* DSC installs AD
    * The Azure vNet is updated with a custom DNS entry pointing to the DC
    * Test users are created in the local AD by passing in an array. There is an array sample set as the default value in the deployment template.
    * Azure Active Directory Connect is installed and available to configure.

## Notes
* The NSG is defined for reference, but is isn't production-ready as holes are also opened for RDP, and public IPs are allocated
* One VM size is specified for all VMs

## NOTICE/WARNING
* This template is explicitly designed for a lab/classroom environment. A few compromises were made, especially with regards to credential passing to DSC and script automation, that WILL result in clear text passwords being left behind in the DSC/scriptextension package folders, Azure log folders, and system event logs on the resulting VMs. 

## Bonus
The "deploy.ps1" file above can be downloaded and run locally against this repo, and offers a few additional features:
* After the deployment completes, it will create a folder on your desktop with the name of the resource group
* It will then create an RDP connection in that folder for the DC VM.
* It will generate a text file with your test user names

 
## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
