# Shadow a User within WVD

Shadowing a user within WVD is currently not built into the product

To carry out the action you need to run the following command:

mstsc.exe /v:*'VMName'* or *'IP'* /shadow:*'SessionID'*

There are two optional additional options:
- /noconsentPrompt
  Connect to the Users session without prompting them to accept the connection
  _**Note:**_ If a GPO is set to force the Consent Prompt then this switch has no effect
- /control
  Allow Control of the Users Session

You need to know the name or IP address of the Session Host the user is connect too and the Session ID of the users connection

To allow this to be automated I created a PowerShell script to assist in this process for the WVD Fall Edition, and have since updated this script to support both the WVD Fall and Spring Editions

**Disclaimer:**
These scripts are provided to you as is, with no warranty or guarantee concerning their functionality although every effort has been made to ensure that these scripts are fully functional
