$ErrorActionPreference = "Stop"

$NODE_ARCHITECTURE = "$env:ARCHITECTURE"
$NODE_OPERATING_SYSTEM = "$env:OS"
$INIT_SCRIPT_NAME = "Docker_$env:DOCKER_VER.ps1"
$NODE_DOWNLOAD_URL = "$env:NODE_DOWNLOAD_URL"

$NODE_SCRIPTS_TMP_LOC = "$env:TEMP/node.zip"
$NODE_SCRIPTS_LOCATION = "$env:USERPROFILE/node"
$NODE_SHIPCTL_LOCATION = "$NODE_SCRIPTS_LOCATION/shipctl"
$SHIPPABLE_FIREWALL_RULE_NAME = "shippable-docker"

$INSTALL_DOCKER_ONLY = $TRUE

Write-Output "|___Set username and password"
wmic useraccount where "name='$env:WINRM_USERNAME'" set PasswordExpires=FALSE

Write-Output "|___Configure UAC to allow privilege elevation in remote shells"
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

Write-Output "|___Configure and restart the WinRM Service; Enable the required firewall exception"
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any

Write-Output "|___downloading node scripts zip package"
Invoke-RestMethod "$NODE_DOWNLOAD_URL" -OutFile $NODE_SCRIPTS_TMP_LOC

Write-Output "|___creating node scripts dir"
mkdir -p $NODE_SCRIPTS_LOCATION

Write-Output "|___extracting node scripts"
Expand-Archive $NODE_SCRIPTS_TMP_LOC -DestinationPath $NODE_SCRIPTS_LOCATION

Write-Output "|___Initializing node"
& "$NODE_SCRIPTS_LOCATION/initScripts/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/$INIT_SCRIPT_NAME"
