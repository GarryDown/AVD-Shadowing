# AVD \ WVD Shadowing

Providing Remote Support, Shadowing, for a WVD Session is currently not available 'Out of the Box' in AVD

To Shadow a use you can use either Remote Assist or MSTSC, on a Client Device Remote Assist is enabled by Default but needs to be enabled in a Server OS

_**Remote Assist**_

The following command is used to run MSTSC:

msra.exe /OfferRa _'Session Host FQDN'_ _'Users UPN'_:_'Session ID'_

_**MSTSC.exe**_

The following command is used to run MSTSC:

mstsc.exe /v:_'Session Host FQDN'_ or _'IP'_ /shadow:_'Session ID'_

There are two additional, optional switches
- /noConsentPrompt
  <br>Allows you to connect to the users session without them being prompted to all the connection
  <br>_**Note:**_ If the GPO Setting **Set rules for remote control of Remote Desktop Services user sessions** is set to force the Consent Prompt then this switch has no effect
- /Control
  <br>Allows you to interact with the users session (if not set – a users session is in view mode only)

This means Support have to find out the Users UPN, which Session Host the User is connected too and their Session ID to be able to run this command

Therefore, I wrote these PowerShell scripts to automate this process
Version|Description
-------|-----------
**v1.0**|Initial version that only supported the Fall Edition, using a Service Principal ID to connect to the WVD Management Plane
**v1.1**|Updated to allow Authentication to the WVD Management Plane to be via User Account as well as Service Principal ID
**v2.0**|Updated to support both the Fall and Spring Releases of WVD
**v2.1**|Bug Fixes Applied
**v3.0**|Updated to Support the Use of Remote Assist as well as MSTSC<br>Updated to support AVD being hosted in more than one Azure Subscription<br>Support for Fall Release REMOVED
