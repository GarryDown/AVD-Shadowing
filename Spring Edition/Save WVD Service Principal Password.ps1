<##################################################################################################

    Script Name:   Save WVD Service Principal Password.ps1
    Written By:    Garry Down
    Version:       1.0

    Change Log: 
    -----------
    Date         Version      Changes
    ----         -------      -------
    19/06/2020     1.0        Initial Release, supporting Fall Release Only


    The script has been created to allow an administrator to create an ecrupted text file containing
    the WVD Service Principal ID Password into a text file WVDSvcPrincipal_Password.txt

    This is then used by the Shadow a User script to connect to the WVD Management Plane

    Modify Line 24 with the appropriate Service Principal ID

##################################################################################################>

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Credential = Get-Credential -UserName "<Service Principal ID Here>" -Message "Enter Service Principal Details"
$Credential.Password | ConvertFrom-SecureString | Set-Content "$ScriptPath\WVDSvcPrincipal_Password.txt"