# Shadow a User

The script has been created to allow an administrator to select a user via a PowerShell GUI
and shadow that user

_**Note:**_ This script now ONLY works with the AVD Spring Release

### Requirements

The Azure **'AZ'** PowerShell Modules need to be installed, specific Modules required are:

        Az.Accounts
        Az.DesktopVirtualization

### Variables:

Azure Tenant ID in which the Host Pools reside (Line 78)
        
- AzureTenantId

The Azure Subscriptions within the Azure Tenant that Host AVD Environments (Line 81)
            
- AVDSubscriptions
            
  - _**Note:**_ This is an array so multiple Resource Groups can be added, seperated by a coma ','
  - Examples: 
    - @('My Only Subscription')
    - @('Subscription One','Subscription Two','Subscription Three')


### The Script Actions are:
- Import the required PowerShell Modules
- If the Device running the Shadowing Script has Remote Assistance installed th
- Login into Azure and connect to the configured Azure Tenant ID
- Via the PowerShell GUI:
  - If more than One Azure Subscription has been configured Provide a Drop Down Box so the Administrator
  - Gather a List of the Host Pools within the Subscription and to populate the Host Pool list
  - The required Host Pool is selected
  - Populate the User List with all ACTIVE Users connected to the Host Pool
  - Select the User to be shadowed
  - Enable Remote Control if required
  - Shadow the User


_**Note:**_ Lines that require updating for each customer in the AVD Shadowing Script:
- **Line 78:** Azure Tenant ID
- **Line 91:** Azure Subscriptions(s)
