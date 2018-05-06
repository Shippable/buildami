$ErrorActionPreference = "Stop"

$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$SHIPPABLE_RELEASE_VERSION = "master"
$EXEC_IMAGE = "drydock/w16reqproc:master"
$REQKICK_DIR = "$env:USERPROFILE/Shippable/reqKick"
$NODE_SCRIPTS_LOCATION = "$env:USERPROFILE/node"
$NODE_SHIPCTL_LOCATION = "$NODE_SCRIPTS_LOCATION/shipctl"
$INIT_SCRIPT_NAME = "Docker_17.06.ps1"
$NODE_SCRIPTS_DOWNLOAD_LOCATION = "$env:TEMP/node.zip"
$NODE_DOWNLOAD_URL = "http://shippable-artifacts.s3.amazonaws.com/node/master/node-master.zip"
$REQKICK_DOWNLOAD_URL = "http://shippable-artifacts.s3.amazonaws.com/reqKick/master/reqKick-master.zip"
$SHIPPABLE_FIREWALL_RULE_NAME = "shippable-docker"

#Write-Output "|___Set username and password"
wmic useraccount where "name='$env:WINRM_USERNAME'" set PasswordExpires=FALSE

Write-Output "|___Configure UAC to allow privilege elevation in remote shells"
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

#Write-Output "|___Configure and restart the WinRM Service; Enable the required firewall exception"
#Stop-Service -Name WinRM
#Set-Service -Name WinRM -StartupType Automatic
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any
#Start-Service -Name WinRM

Write-Output "|___downloading node scripts zip package"
Invoke-RestMethod "$NODE_DOWNLOAD_URL" -OutFile $NODE_SCRIPTS_DOWNLOAD_LOCATION

Write-Output "|___creating node scripts dir"
mkdir -p $NODE_SCRIPTS_LOCATION

Write-Output "|___extracting node scripts"
Expand-Archive $NODE_SCRIPTS_DOWNLOAD_LOCATION -DestinationPath $NODE_SCRIPTS_LOCATION

Write-Output "|___Initializing node"
& "$NODE_SCRIPTS_LOCATION/initScripts/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/$INIT_SCRIPT_NAME"
