# Shadow a User

The script has been created to allow an administrator to select a user via a PowerShell GUI
and shadow that user

**Note:** This script now ONLY works with both the AVD Spring Release

### Requirements

The Azure **'AZ'** PowerShell Modules need to be installed, specific Modules required are:

        Az.Accounts
        Az.DesktopVirtualization

### Variables:

_**Note:**_ Both Fall and Spring Releases can be set to True simultaneously

Are Spring Release Host Pools to be included
- SpringReleaseEnabled: True or False

Are Fall Release Host Pools to be included
- FallReleaseEnabled: True or False

Subscription ID the Spring Release Host Pools are located
- SpringSubscriptionId

Resource Groups the Spring Release Host Pools are located in, Within Subscription ID specified
- SpringResourceGroups
  This is an array so multiple Resource Groups can be added, seperated by a coma ','
  
Tenant Name of the Fall Release Host Pools
- FallTenantName
  
WVD Service Principal ID (If WVD Service Principal ID is to be used)
- svcPrincipalID

Azure Tenant ID (If WVD Service Principal ID is to be used)
- AzureTenantID

### The Script Actions are:
- If the Spring Release Features are enabled check the Azure **'Az.DesktopVirtualization'** PowerShell module is installed, if it is not installed then disable the Spring Release Features
- If the Fall Release Features are enabled check the **'Microsoft.RDInfra.RDPowerShell'** PowerShell Module is installed, if it is not installed then disable the Fall Release Features
- If neither Spring or Fall Features are enabled then **Quit**
- Import the required PowerShell Module(s)
- If the Spring Release Features are enabled:
  - Login into Azure and connect to the configured Subscription ID
  - Gather a List of Host Pools within the configured Subscription ID / Resource Groups specified
- If the Fall Release Features are enabled:
  - Connect to the WVD Management Plane
  - Gather a List of Host Pools within the WVD Tenant Name specified
- Via the PowerShell GUI:
  - Select the Host Pool the user is connected too
  - Populate the User List with all ACTIVE Users connected to the Host Pool
  - Select the User to be shadowed
  - Enable Remote Control if required
  - Shadow the User

If a Service Principal ID is to be used to connect to the WVD Management Plane then each User that needs to run this script needs to take a copy of both scripts and run them from within their personal area, the encryption of the Service Principal Password links the txt file to that user, therefore this can't be spared across multiple users

_**Note:**_ Lines that require updating for each customer in the Shadow a User Script:
- **Line 124:** Azure Subscription ID
- **Line 125:** Resource Group(s)
- **Line 130:** WVD Tenant Name
- **Line 241:** Service Principal ID
- **Line 242:** Azure Tenant ID

_**Note:**_ Lines that require updating for each customer in the Save WVD Service Principal Password Script:
- **Line 24:** Service Principal ID
