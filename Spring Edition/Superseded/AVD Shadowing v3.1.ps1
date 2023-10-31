<##################################################################################################

    Script Name:   AVD Shadowing.ps1
    Written By:    Garry Down
    Version:       3.1

    Change Log: 
    -----------
    Date         Version      Changes
    ----         -------      -------
    19/06/2020     1.0        Initial Release, supporting Fall Release Only
    26/06/2020     1.1        Updated to allow prompt for Authentication if no Service Principal ID
                              Password TXT File Found
    06/07/2020     2.0        Updated to allow the Shadowing of both Fall or Spring Release Users
    09/07/2020     2.1        Corrected an issue remunerating Active Spring Release Users
    29/04/2022     3.0        Support for the Fall Release REMOVED
                              Support for AVD being deployed to more than one Azure Subscriptions
    30/10/2023     3.1        Corrected Error is only a Single Subscription is required
    
    The script has been created to allow an administrator to select a user via a PowerShell GUI and shadow that user

    
    Script works with ONLY with the Spring Releases of AVD


    Requirements:
    -------------
    The Azure AZ PowerShell Modules need to be installed, specific Modules required are:

        Az.Accounts
        Az.DesktopVirtualization
    

    Variables:
    ----------
        Azure Tenant ID in which the Host Pools reside (Line 78)
        
            AzureTenantId

        The Azure Subscriptions within the Azure Tenant that Host AVD Environments (Line 81)
            
            AVDSubscriptions
            
            Note: This is an array so multiple Resource Groups can be added, seperated by a coma ','
            Examples: 
                @('My Only Subscription')
                @('Subscription One','Subscription Two','Subscription Three')


    The Script Actions are:
    -----------------------
        Import the required PowerShell Modules

        If the Device running the Shadowing Script has Remote Assistance installed th

        Login into Azure and connect to the configured Azure Tenant ID

        Via the PowerShell GUI:

            If more than One Azure Subscription has been configured Provide a Drop Down Box so the Administrator

            Gather a List of the Host Pools within the Subscription and to populate the Host Pool list

            The required Host Pool is selected

            Populate the User List with all ACTIVE Users connected to the Host Pool

            Select the User to be shadowed

            Enable Remote Control if required

            Shadow the User

##################################################################################################>

## Variables \ Arrays
# Azure Tenant ID
$AzureTenantId                   = "<Azure AzureTenantId Here>"

# Subscriptions Hosting AVD Environments
$AVDSubscriptions                = @('<AVD Subscriptions Here>')


## Import Required PowerShell Modules
cls
Write-Host 
Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Importing PowerShell Modules"
$Modules = @('Az')
Foreach ($Module in $Modules) {
    if((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Importing Module" $Module -ForegroundColor DarkYellow
        Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
        }
    Else {
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   PowerShell Module " -NoNewline -ForegroundColor DarkYellow ; Write-Host "'$Module'" -NoNewline -ForegroundColor DarkCyan ; Write-Host " already imported" -ForegroundColor DarkYellow
        }
    }


## Validate Variables
# AzureTenantId
If (!($AzureTenantId -match("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"))) {
    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " ERROR: " -NoNewline -ForegroundColor Red ; Write-Host "Azure Tenant Id is not a valid GUID"
    Break
}

# Subscriptions
If ($AVDSubscriptions -eq '<AVD Subscriptions Here>') {
    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " ERROR: " -NoNewline -ForegroundColor Red ; Write-Host "AVD Subscription Variable not updated"
    Break
}

If ($AVDSubscriptions.Count -eq 0) {
    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " ERROR: " -NoNewline -ForegroundColor Red ; Write-Host "AVD Subscriptions Variable is empty"
    Break
}

$WindowPadSubs                   = 0
If ($AVDSubscriptions.Count -gt 1) {
    $WindowPadSubs               = 90
}


## Check to see if Remote Assistance is installed
$UseMSTSC                        = $false
$WindowPadMSTSC                  = 0
If (!(Test-Path -Path 'C:\Windows\System32\msra.exe')) {
    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Remote Assistance not Enabled, Switching the Remote Desktop Shadowing"
    $UseMSTSC                    = $true
    $WindowPadMSTSC              = 50
}


## Log into Azure
Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Log into Azure"
Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Prompting for Log In Credentials for Azure Tenant ID " -ForegroundColor DarkYellow -NoNewline ; Write-Host $AzureTenantId -ForegroundColor DarkCyan
$HideOutput                      = Get-AzContext -ListAvailable | Disconnect-AzAccount
$HideOutput                      = Connect-AzAccount -Tenant $AzureTenantId -WarningAction SilentlyContinue


## Launch Shadow Selector Windows
Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Launching Shadow Selector Screen"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$ShadowUser                      = New-Object system.Windows.Forms.Form
$ShadowUser.ClientSize           = New-Object System.Drawing.Size(700,(270 + $WindowPadSubs + $WindowPadMSTSC))
$ShadowUser.text                 = "User Shadow Selector"
$ShadowUser.TopMost              = $false

$Subscriptions_Label             = New-Object system.windows.forms.label
$Subscriptions_Label.text        = "Select the Azure Subscription the user is connected too"
$Subscriptions_Label.autosize    = $true
$Subscriptions_Label.enabled     = $false
$Subscriptions_Label.location    = New-Object System.Drawing.Point(30,10)
$Subscriptions_Label.Font        = 'Microsoft Sans Serif,12'

If ($AVDSubscriptions.Count -gt 1) {
    $Subscriptions               = New-Object system.Windows.Forms.ComboBox
    $Subscriptions.text          = ""
    $Subscriptions.BackColor     = "#c2c2c2"
    $Subscriptions.width         = 640
    $Subscriptions.height        = 25
    $Subscriptions.location      = New-Object System.Drawing.Point(30,45)
    $Subscriptions.Font          = 'Microsoft Sans Serif,14'

    Foreach ($Subs in $AVDSubscriptions) {
        $Subscriptions.Items.Add($Subs) | Out-Null
        }
    }
Else {
    $Subscriptions               = New-Object system.Windows.Forms.ComboBox
    $Subscriptions.text          = $AVDSubscriptions
    $Subscriptions.BackColor     = "#c2c2c2"
    $Subscriptions.width         = 640
    $Subscriptions.height        = 25
    $Subscriptions.location      = New-Object System.Drawing.Point(30,45)
    $Subscriptions.Font          = 'Microsoft Sans Serif,14'
    }
    
$HostPool_Label                  = New-Object system.windows.forms.label
$HostPool_Label.text             = "Select the Host Pool the user is connected too"
$HostPool_Label.autosize         = $true
$HostPool_Label.enabled          = $false
$HostPool_Label.location         = New-Object System.Drawing.Point(30,(10 + $WindowPadSubs))
$HostPool_Label.Font             = 'Microsoft Sans Serif,12'

$HostPool                        = New-Object system.Windows.Forms.ComboBox
$HostPool.text                   = "Please Select Subscription to Populate"
$HostPool.BackColor              = "#c2c2c2"
$HostPool.width                  = 640
$HostPool.height                 = 30
$HostPool.location               = New-Object System.Drawing.Point(30,(45 + $WindowPadSubs))
$HostPool.Font                   = 'Microsoft Sans Serif,14'
$HostPool.enabled                = $false

$UserSession_Label               = New-Object system.windows.forms.label
$UserSession_Label.text          = "Select User to be Shadowed"
$UserSession_Label.autosize      = $true
$UserSession_Label.enabled       = $false
$UserSession_Label.location      = New-Object System.Drawing.Point(30,(100 + $WindowPadSubs))
$UserSession_Label.Font          = 'Microsoft Sans Serif,12'

$UserSession                     = New-Object system.Windows.Forms.ComboBox
$UserSession.text                = "Please Select Host Pool to Populate"
$UserSession.width               = 640
$UserSession.height              = 30
$UserSession.location            = New-Object System.Drawing.Point(30,(135 + $WindowPadSubs))
$UserSession.Font                = 'Microsoft Sans Serif,14'
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
$TakeControl.location            = New-Object System.Drawing.Point(30,(195 + $WindowPadSubs))
$TakeControl.Font                = 'Microsoft Sans Serif,12'

$Shadow                          = New-Object system.Windows.Forms.Button
$Shadow.BackColor                = "#f8e71c"
$Shadow.text                     = "Shadow User"
$Shadow.width                    = 500
$Shadow.height                   = 50
$Shadow.enabled                  = $false
$Shadow.location                 = New-Object System.Drawing.Point(100,(195 + $WindowPadSubs + $WindowPadMSTSC))
$Shadow.Font                     = 'Microsoft Sans Serif,14'
$Shadow.ForeColor                = "#0000ff"

$ShadowUser.controls.Clear()
$ShadowUser.controls.AddRange(@($HostPool_Label,$HostPool,$UserSession_Label,$UserSession,$Shadow))
If ($AVDSubscriptions.Count -gt 1) {
    $ShadowUser.controls.AddRange(@($Subscriptions_Label,$Subscriptions))
    }
If ($UseMSTSC -eq $true) {
    $ShadowUser.controls.AddRange(@($TakeControl))
    }

If ($AVDSubscriptions.Count -gt 1) {
    $Subscriptions.Add_SelectedValueChanged({ Gather_HostPools })
    }
Else {
    $Subscriptions.text          = $AVDSubscriptions
    $HostPool.text               = ""
    Gather_HostPools
    }

$HostPool.Add_SelectedValueChanged({ HostPoolSelected })

$UserSession.Add_SelectedValueChanged({ $Shadow.enabled = $true })

$Shadow.Add_Click({ ShadowUserSession })


## Functions
Function Gather_HostPools {

    Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Gathering a list of Host Pools in the Subscription " -ForegroundColor DarkYellow -NoNewLine ; Write-Host $Subscriptions.Text -ForegroundColor DarkCyan

    $HostPool.text               = "Gathering a list of Host Pools in the Subscription - Please Wait"
    $HostPool.Enabled            = $false

    Select-AzSubscription -Subscription $Subscriptions.Text -WarningAction SilentlyContinue | Out-Null

    $SubscriptionInfo            = Get-AzSubscription -SubscriptionName $Subscriptions.Text -WarningAction SilentlyContinue
    $HostPools                   = Get-AzWvdHostPool -SubscriptionId $SubscriptionInfo.Id -WarningAction SilentlyContinue

    $HostPool.Items.Clear()
    Foreach ($HP in $HostPools) {
        $HostPool.Items.Add($HP.Name) | Out-Null
        }

    $HostPool.text               = "Please Select the Host Pool required"
    $HostPool.Enabled            = $true

    }


Function HostPoolSelected {

    Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Gathering a list of Users Connected to " -ForegroundColor DarkYellow -NoNewLine ; Write-Host $HostPool.Text -ForegroundColor DarkCyan

    $SubscriptionInfo            = Get-AzSubscription -SubscriptionName $Subscriptions.Text -WarningAction SilentlyContinue
    $HostPoolInfo                = Get-AzWvdHostPool -SubscriptionId $SubscriptionInfo.Id | Where {$_.Name -eq $HostPool.Text}

    $UserSession.Items.Clear()
    $UserSessionHost.Items.Clear()
    $UserSessionID.Items.Clear()

    $ActiveUsers                 = Get-AzWvdUserSession -HostPoolName $HostPool.Text -ResourceGroupName $HostPoolInfo.id.Split('/')[4] -ErrorAction SilentlyContinue -Filter "SessionState eq 'active'"

    If ($ActiveUsers.Count -eq 0) {
        $UserSession.text        = "No Active Users logged into Selected Host Pool"
        $UserSession.Enabled     = $false
        }
    Else {
        $UserSession.BackColor   = "white"
        $UserSession.text        = "Please Select the User to be Shadowed"
        $UserSession.Enabled     = $true
        }

    Foreach ($ActiveUser in $ActiveUsers) {
        $UserSession.Items.Add($ActiveUser.ActiveDirectoryUserName)
        $UserSessionHost.Items.Add($ActiveUser.Name.Split('/')[1])
        $UserSessionID.Items.Add($ActiveUser.Name.Split('/')[2])
        }

    }


Function ShadowUserSession {

    $UserUPN                     = $UserSession.Text
    $AVDSessionHost              = $UserSessionHost.Items.Item($UserSession.SelectedIndex)
    $AVDSessionID                = $UserSessionID.Items.Item($UserSession.SelectedIndex)

    If ($TakeControl.Checked -eq $True) {
        $AllowControl            = "Yes"
        }
    Else {
        $AllowControl            = "No"
        }

    $ShadowUser.Dispose()

    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Shadowing User " -NoNewline
    Write-Host $UserUPN -ForegroundColor Cyan -NoNewline ; Write-Host ", Connected to " -NoNewline
    Write-Host $AVDSessionHost -ForegroundColor Green -NoNewline ; Write-Host " on Session ID " -NoNewline
    Write-Host $AVDSessionID -ForegroundColor Gray -NoNewline

    If ($UseMSTSC -eq $true) {
        If ($AllowControl -eq "Yes") {
            Write-Host " with Remote Control " -NoNewline ; Write-Host "Enabled" -ForegroundColor Green
            Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$AVDSessionHost /shadow:$AVDSessionID /control"
            }
            Else {
            Write-Host " with Remote Control " -NoNewline ; Write-Host "Disabled" -ForegroundColor Red
            Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$AVDSessionHost /shadow:$AVDSessionID"
            }
        }
    Else {
        Start-Process -FilePath "msra.exe" -ArgumentList "/OfferRa $($AVDSessionHost) $($UserUPN):$($AVDSessionID)"
        }
    }

[void]$ShadowUser.ShowDialog()