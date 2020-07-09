<##################################################################################################

    Script Name:   Shadow a User.ps1
    Written By:    Garry Down
    Version:       2.1

    Change Log: 
    -----------
    Date         Version      Changes
    ----         -------      -------
    19/06/2020     1.0        Initial Release, supporting Fall Release Only
    26/06/2020     1.1        Updated to allow prompt for Authentication if no Service Principal ID
                              Password TXT File Found
    06/07/2020     2.0        Updated to allow the Shadowing of both Fall or Spring Release Users
    09/07/2020     2.1        Corrected an issue remunerating Active Spring Release Users

    The script has been created to allow an administrator to select a user via a PowerShell GUI
    and shadow that user

    Script works with both the Fall and Spring Releases of WVD


    Requirements:
    -------------
    For the Spring Release feature to be available the PowerShell Module 'Az.DesktopVirtualization'
    needs to be installed, this is one of the Azure PowerShell 'Az' Modules, in v4.3.0 and above
    
    For the Fall Release feature to be available the PowerShell Module 'Microsoft.RDInfra.RDPowerShell'
    needs to be installed

    Credentials to Authenticate to Azure if the Spring Release Features are enabled

	Credentials to Authenticate to the WVD Management Plane if the Fall Release Features are enabled
	or a Service Principal ID (Details Hard Coded)


    Spring Release:
    ---------------
    Script connects to the Azure Subscripton ID that hosts the WVD Host Pools, if a valid connection
    to the Subscription ID is already available then this is used otherwise the user is promtped to
    Authenticate to Azure

    The Azure Subscripton ID is a Variable within the Script


    Fall Release:
    -------------
    Script connects to the WVD Environment using a Service Principal ID (Details Hard Coded) or 
    Prompts for login. If a Service Principal ID is to be used the Service Principal Password needs
    to be encrypted in the text file called 'WVDSvcPrincipal_Password.txt' located in the same 
    folder as this script

    This encrypted text file is created by running the 'Save WVD Service Principal Password'
    script provided with this script

    If No Password file is found then the user is prompted to Authenticate to the WVD Management Plane

    The WVD Tenant Name is a Variable within the Script


    Variables:
    ----------
        Are Spring Release Host Pools to be included
    
            SpringReleaseEnabled: True or False

        Are Fall Release Host Pools to be included
        
            FallReleaseEnabled: True or False

        Note: Both can be set to True

        Subscription ID the Spring Release Host Pools are located
        
            SpringSubscriptionId

        Resource Groups the Spring Release Host Pools are located in, Within Subscription ID specified
            
            SpringResourceGroups
            This is an array so multiple Resource Groups can be added, seperated by a coma ','

        Tenant Name of the Fall Release Host Pools
            
            FallTenantName

        WVD Service Principal ID (If WVD Service Principal ID is to be used)

            svcPrincipalID

        Azure Tenant ID (If WVD Service Principal ID is to be used)

            AzureTenantID


    The Script Actions are:
    -----------------------
        If the Spring Release Features are enabled check the Azure 'Az.DesktopVirtualization' PowerShell
        module is installed, if it is not installed then disable the Spring Release Features

        If the Fall Release Features are enabled check the 'Microsoft.RDInfra.RDPowerShell' PowerShell Module
        is installed, if it is not installed then disable the Fall Release Features

        If neither Spring or Fall Features are enabled then quit

        Import the required PowerShell Modules

        If the Spring Release Features are enabled

            Login into Azure and connect to the configured Subscription ID
            Gather a List of Host Pools within the configured Subscription ID / Resource Groups specified

        If the Fall Release Features are enabled

            Connect to the WVD Management Plane
            Gather a List of Host Pools within the WVD Tenant Name specified

        Via the PowerShell GUI:

            Select the Host Pool the user is connected too

            Populate the User List with all ACTIVE Users connected to the Host Pool

            Select the User to be shadowed

            Enable Remote Control if required

            Shadow the User

##################################################################################################>

## Variables \ Arrays
# WVD Environment
$SpringReleaseEnabled            = $true                                  # Are Spring Release Host Pools to be included?
$SpringSubscriptionId            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # Subscription ID Host Pools are located
$SpringResourceGroups            = @("<RG Name Here>","<RG Name Here>")   # Resource Groups the Host Pools are located in, Within Subscription ID
                                                                          # Multiple RG's can be added, seperated by a coma ','

$FallReleaseEnabled              = $true                                  # Are Fall Release Host Pools to be included?
$FallTenantName                  = "<WVD Tenant NAme Here>"               # Tenant Name of the Fall Release Host Pools

# PowerShell Modules
$Modules                         = @()


cls
Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Checking Available PowerShell Modules"
If ($SpringReleaseEnabled -eq $true) {
    $AzCmdlet                    = Get-InstalledModule -Name Az.DesktopVirtualization -ErrorAction SilentlyContinue
    If ($AzCmdlet -ne $null) {
        # PowerShell Module found
        $Modules                 += "Az"
        }
    Else {
        # PowerShell not Module found, disable Spring Release
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Disabling " -ForeGroundColor Red -NoNewline
        Write-Host "Spring Release Features, PowerShell Module " -NoNewline -ForegroundColor DarkYellow ; Write-Host "'Az.DesktopVirtualization'" -NoNewline -ForegroundColor DarkCyan ; Write-Host " not installed" -ForegroundColor DarkYellow
        $SpringReleaseEnabled    = $false
        }
    }
If ($FallReleaseEnabled -eq $true) {
    $WVDCmdlet                   = Get-InstalledModule -Name Microsoft.RDInfra.RDPowerShell -ErrorAction SilentlyContinue
    If ($WVDCmdlet -ne $null) {
        $Modules                 += "Microsoft.RDInfra.RDPowerShell"
        }
    Else {
        # PowerShell not Module found, disable Fall Release
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Disabling " -ForeGroundColor Red -NoNewline
        Write-Host "Fall Release Features, PowerShell Module " -NoNewline -ForegroundColor DarkYellow ; Write-Host "'Microsoft.RDInfra.RDPowerShell'" -NoNewline -ForegroundColor DarkCyan ; Write-Host " not installed" -ForegroundColor DarkYellow
        $FallReleaseEnabled     = $false
        }
    }


If ($Modules.Count -eq 0) {
    Write-Host 
    Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Error:" -ForeGroundColor Red -NoNewline 
    Write-Host " At Least one of the Requiured PowerShell Modules needs to be installed on this Device" -ForegroundColor DarkYellow
    Write-Host "                 Please See Requirements listed within the Script" -ForegroundColor DarkYellow
    Break
    }

Write-Host 
Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Importing PowerShell Modules"
Foreach ($Module in $Modules) {
    if((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Importing Module" $Module -ForegroundColor DarkYellow
        Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
        }
    Else {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   PowerShell Module " -NoNewline -ForegroundColor DarkYellow ; Write-Host "'$Module'" -NoNewline -ForegroundColor DarkCyan ; Write-Host " already imported" -ForegroundColor DarkYellow
        }
    }


If ($SpringReleaseEnabled -eq $true) {
    # Log into Azure
    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Log into Azure"

    # Check if the user running this script is already logged into Azure and connected to the correct Subscription, if not prompt for authentication
    $AzLoginNeeded = $true
    Try {
        $AzLogin = Get-AzContext
        If ($AzLogin) {
            $AzLoginNeeded       = ([string]::IsNullOrEmpty($AzLogin.Account))
            If ($AzLogin.Subscription.Id -ne $SpringSubscriptionId) {
                $AzLoginNeeded   = $true
                }
            }
        }
    Catch {
        If ($_ -like"*Login-AzAccount to Login*") {
            $AzLoginNeeded       = $true
            }
        Else {
            Throw
            }
        }

    If ($AzLoginNeeded) {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Prompting for Log In Credentials for Azure Subscription ID " -ForegroundColor DarkYellow -NoNewline ; Write-Host $SpringSubscriptionId -ForegroundColor DarkCyan
        $HideOutput              = Get-AzContext -ListAvailable | Disconnect-AzAccount
        $HideOutput              = Connect-AzAccount
        }
    Else {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   User already Authenticated to Azure Subscription ID " -ForegroundColor DarkYellow -NoNewline ; Write-Host $SpringSubscriptionId -ForegroundColor DarkCyan
        }
    $HideOutput                  = Set-AzContext -SubscriptionId $SpringSubscriptionId

    Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Gathering a list of Available Host Pools" -ForegroundColor DarkYellow
    $SpringHostPools             = ""
    $SpringHostPools             = Get-AzWvdHostPool -SubscriptionId $SpringSubscriptionId

    }

If ($FallReleaseEnabled -eq $true) {
    # Log onto WVD Management Plain
    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Connecting the WVD Platform"

    $ScriptPath                  = Split-Path -Parent $MyInvocation.MyCommand.Definition
    If (Test-Path "$ScriptPath\WVDSvcPrincipal_Password.txt") {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Logging in as Service Principal" -ForegroundColor DarkYellow
        $svcPrincipalID          = "<Service Principal ID Here>"
        $AzureTenantID           = "<Azure Tenant ID Here>"

        $svcPrincipalIDPWD       = Get-Content "$ScriptPath\WVDSvcPrincipal_Password.txt" | ConvertTo-SecureString

        $creds                   = New-Object System.Management.Automation.PSCredential($svcPrincipalID, ($svcPrincipalIDPWD))
        $HideOutput              = Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $creds -ServicePrincipal -AadTenantId $AzureTenantID
        }
    Else {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Prompting for Log In Details" -ForegroundColor DarkYellow
        $HideOutput              = Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
        }

    Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Gathering a list of Available Host Pools" -ForegroundColor DarkYellow
    $FallHostPools               = ""
    $FallHostPools               = Get-RdsHostPool -TenantName $FallTenantName

    }


Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Launching Shadow Selector Screen"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$ShadowUser                      = New-Object system.Windows.Forms.Form
$ShadowUser.ClientSize           = '700,350'
If ($Modules.Count -eq 2) {
    $ShadowUser.text             = "User Shadow Selector - Fall & Spring Release"
    }
ElseIf ($SpringReleaseEnabled -eq $true) {
    $ShadowUser.text             = "User Shadow Selector - Spring Release"
    }
Else {
    $ShadowUser.text             = "User Shadow Selector - Fall Release"
    }
$ShadowUser.TopMost              = $false

$HostPool                        = New-Object system.Windows.Forms.ComboBox
$HostPool.text                   = "Select the Host Pool the User is connected too"
$HostPool.BackColor              = "#c2c2c2"
$HostPool.width                  = 640
$HostPool.height                 = 30
$HostPool.location               = New-Object System.Drawing.Point(30,30)
$HostPool.Font                   = 'Microsoft Sans Serif,18'

If ($SpringReleaseEnabled -eq $true) {
    If ($SpringHostPools.Count -eq 0) {
        $HostPool.Items.Add("No Spring Release Host Pools Found") | Out-Null
        $SpringReleaseEnabled    = $false
        }
    Else {
        Foreach ($HostPoolName in $SpringHostPools) {
            $HostPool.Items.Add($HostPoolName.Name) | Out-Null
            }
        }
    }

If ($FallReleaseEnabled -eq $true) {
    If ($FallHostPools.Count -eq 0) {
        $HostPool.Items.Add("No Fall Release Host Pools Found") | Out-Null
        $FallReleaseEnabled      = $false
        }
    Else {
        Foreach ($HostPoolName in $FallHostPools) {
            $HostPool.Items.Add($HostPoolName.HostPoolName) | Out-Null
            }
        }
    }

$UserSession                     = New-Object system.Windows.Forms.ComboBox
$UserSession.text                = "Please Select Host Pool to Populate"
$UserSession.width               = 640
$UserSession.height              = 30
$UserSession.location            = New-Object System.Drawing.Point(30,100)
$UserSession.Font                = 'Microsoft Sans Serif,18'
$UserSession.enabled             = $false

#Hidden Value to calculate Session Host the User is connected too
$UserSessionHost                 = New-Object system.Windows.Forms.ComboBox
$UserSessionHost.enabled         = $false
$UserSessionHost.Visible         = $false

#Hidden Value to calculate the Session ID of the Users Session
$UserSessionID                   = New-Object system.Windows.Forms.ComboBox
$UserSessionID.enabled           = $false
$UserSessionID.Visible           = $false

$TakeControl                     = New-Object system.Windows.Forms.CheckBox
$TakeControl.text                = " Allow Remote Control of the Users Session"
$TakeControl.width               = 600
$TakeControl.height              = 30
$TakeControl.location            = New-Object System.Drawing.Point(30,170)
$TakeControl.Font                = 'Microsoft Sans Serif,14'

$ErrorMsg                        = New-Object system.Windows.Forms.Button
$ErrorMsg.BackColor              = "#db1a1a"
$ErrorMsg.width                  = 600
$ErrorMsg.height                 = 50
$ErrorMsg.enabled                = $false
$ErrorMsg.location               = New-Object System.Drawing.Point(50,210)
$ErrorMsg.Font                   = 'Microsoft Sans Serif,12'
$ErrorMsg.Visible                = $false

$Shadow                          = New-Object system.Windows.Forms.Button
$Shadow.BackColor                = "#f8e71c"
$Shadow.text                     = "Shadow User"
$Shadow.width                    = 500
$Shadow.height                   = 50
$Shadow.enabled                  = $true
$Shadow.location                 = New-Object System.Drawing.Point(100,280)
$Shadow.Font                     = 'Microsoft Sans Serif,14'
$Shadow.ForeColor                = "#0000ff"

$ShadowUser.controls.AddRange(@($HostPool,$UserSession,$TakeControl,$ErrorMsg,$Shadow))

$HostPool.Add_SelectedValueChanged({ HostPoolSelected })

$Shadow.Add_Click({

    $ValidRunChecksResult = RunChecks
    If ($ValidRunChecksResult -eq "No Host Pool Selected") {
        $ErrorMsg.text = "No Host Pool Selected"
        $ErrorMsg.Visible        = $true
        $ErrorMsg.enabled        = $true
        }
    ElseIf ($ValidRunChecksResult -eq "No User Selected") {
        $ErrorMsg.text = "No User Selected"
        $ErrorMsg.Visible        = $true
        $ErrorMsg.enabled        = $true
        }
    ElseIf ($ValidRunChecksResult -eq "Invalid Host Pool Selected") {
        $ErrorMsg.text           = "Invalid Host Pool Selected"
        $ErrorMsg.Visible        = $true
        $ErrorMsg.enabled        = $true
        }
    Else {
        ShadowUserSession
        }
    })


Function HostPoolSelected {

    If ($HostPool.Text -eq "No Spring Release Host Pools Found" -or $HostPool.Text -eq "No Fall Release Host Pools Found") {
        $ErrorMsg.text           = "Invalid Host Pool Selected"
        $ErrorMsg.Visible        = $true
        $ErrorMsg.enabled        = $true
        Return
        }
    Else {
        $ErrorMsg.Visible        = $false
        $ErrorMsg.enabled        = $false
        }

    Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Gathering a list of Users Connected to " -ForegroundColor DarkYellow -NoNewLine ; Write-Host $HostPool.Text -ForegroundColor DarkCyan

    $UserSession.Items.Clear()
    $UserSessionHost.Items.Clear()
    $UserSessionID.Items.Clear()

    Foreach ($SpringHostPool in $SpringHostPools) {
        If ($SpringHostPool.Name -eq $HostPool.Text) {
            Foreach ($SpringResourceGroup in $SpringResourceGroups) {
                $SpringActiveUsers = Get-AzWvdUserSession -HostPoolName $HostPool.Text -ResourceGroupName $SpringResourceGroup -ErrorAction SilentlyContinue -Filter "SessionState eq 'active'"
                If ($springActiveUsers.Count -ne 0) {
                    # Host Pool found, break out of For Loop otherwise checking other RG's may blank the Active User List
                    Break
                    }
                }
            }
        }

    Foreach ($FallHostPool in $FallHostPools) {
        If ($FallHostPool.HostPoolName -eq $HostPool.Text) {
            $FallActiveUsers     = Get-RdsUserSession -TenantName $FallTenantName -HostPoolName $HostPool.Text | where { $_.SessionState -eq "active"}
            }
        }

    If ($FallActiveUsers.Count -eq 0 -and $SpringActiveUsers.Count -eq 0) {
        $UserSession.text        = "No Active Users logged into Selected Host Pool"
        $UserSession.Enabled     = $false
        }
    Else {
        $UserSession.BackColor   = "white"
        $UserSession.text        = "Please Select the User to be Shadowed"
        $UserSession.Enabled     = $true
        }

    Foreach ($ActiveUser in $FallActiveUsers) {
        $UserSession.Items.Add($ActiveUser.UserPrincipalName)
        $UserSessionHost.Items.Add($ActiveUser.SessionHostName)
        $UserSessionID.Items.Add($ActiveUser.SessionId)
        }

    Foreach ($ActiveUser in $SpringActiveUsers) {
        $UserSession.Items.Add($ActiveUser.ActiveDirectoryUserName)
        $UserSessionHost.Items.Add($ActiveUser.Name.Split('/')[1])
        $UserSessionID.Items.Add($ActiveUser.Name.Split('/')[2])
        }

    }


Function RunChecks {

    If ($HostPool.Text -eq "Select the Host Pool the User is connected too") {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Error: " -ForeGroundColor Red -NoNewline 
        Write-Host "No Host Pool Selected" -ForegroundColor DarkYellow
        $ValidRunChecksResult    = "No Host Pool Selected"
        Return $ValidRunChecksResult
        }
    If ($HostPool.Text -eq "No Spring Release Host Pools Found" -or $HostPool.Text -eq "No Fall Release Host Pools Found") {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Error: " -ForeGroundColor Red -NoNewline 
        Write-Host "Invalid Host Pool Selected" -ForegroundColor DarkYellow
        $ValidRunChecksResult    = "Invalid Host Pool Selected"
        $ErrorMsg.Visible        = $true
        $ErrorMsg.enabled        = $true
        Return $ValidRunChecksResult
        }
    If ($UserSession.text -eq "Please Select the User to be Shadowed" -or $UserSession.text -eq "No Active Users logged into Selected Host Pool") {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Error: " -ForeGroundColor Red -NoNewline 
        Write-Host "No User Selected" -ForegroundColor DarkYellow
        $ValidRunChecksResult    = "No User Selected"
        Return $ValidRunChecksResult
        }

    }


Function ShadowUserSession {

    $UserUPN                     = $UserSession.Text
    $WVDSessionHost              = $UserSessionHost.Items.Item($UserSession.SelectedIndex)
    $WVDSessionID                = $UserSessionID.Items.Item($UserSession.SelectedIndex)

    If ($TakeControl.Checked -eq $True) {
        $AllowControl            = "Yes"
        }
    Else {
        $AllowControl            = "No"
        }

    $ShadowUser.Dispose()

    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Shadowing User " -NoNewline
    Write-Host $UserUPN -ForegroundColor Cyan -NoNewline ; Write-Host ", Connected to " -NoNewline
    Write-Host $WVDSessionHost -ForegroundColor Green -NoNewline ; Write-Host " on Session ID " -NoNewline
    Write-Host $WVDSessionID -ForegroundColor Gray -NoNewline
    If ($AllowControl -eq "Yes") {
        Write-Host " with Remote Control " -NoNewline ; Write-Host "Enabled" -ForegroundColor Green
        Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$WVDSessionHost /shadow:$WVDSessionID /control"
        }
    Else {
        Write-Host " with Remote Control " -NoNewline ; Write-Host "Disabled" -ForegroundColor Red
        Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$WVDSessionHost /shadow:$WVDSessionID"
        }
    }

[void]$ShadowUser.ShowDialog()
