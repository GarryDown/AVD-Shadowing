# Shadow a User
The script has been created to allow an administrator to select a user via a PowerShell GUI
and shadow that user

**Note:** This script is for WVD Fall Edition <u>ONLY</u>

Script connects to the WVD Environment using a Service Principal ID (Details Hard Coded)
The Service Principal Password is encrypted in the text file **WVDSvcPrincipal_Password.txt**
located in the same folder as this script
This encrypted text file is created by running the **'Save WVD Service Principal Password'**
script provided with this script

The WVD Tenant Name is a Variable within the Script

The Script Actions are:

- Install the Microsoft.RDInfra.RDPowerShell if not already installed (Admin Rights required)
- Connect to the WVD Management Platform using the Service Principal ID
- Via the PowerShell GUI:
  - Select the Host Pool the user is connected too
  - Populate the User List with all ACTIVE Users connected to the Host Pool
  - Select the User to be shadowed
  - Enable Remote Control if required
  - Shadow the User
  
Each User needs to take a copy of both scripts and run them from within their personal area, the encryption of the Service Principal
Password links the txt file to that user, therefore this can't be spared across multiple users

_**Note:**_ Lines that require updating for each customer in the Shadow a User Script:
- **Line 48:** WVD Tenant Name
- **Line 84:** Service Principal ID
- **Line 85:** Azure Tenant ID

_**Note:**_ Lines that require updating for each customer in the Save WVD Service Principal Password Script:
- **Line 24:** Service Principal ID
