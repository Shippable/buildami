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

Function __process_msg([string] $msg) {
  echo "|___ $msg"
}

__process_msg "Set username and password"
net user {{%WINRM_USERNAME%}} {{%WINRM_PASSWORD%}}
wmic useraccount where "name='{{%WINRM_USERNAME%}}'" set PasswordExpires=FALSE

__process_msg "First, make sure WinRM can't be connected to"
winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

__process_msg "Create a new WinRM listener and configure"
winrm create winrm/config/listener?Address=*+Transport=HTTP
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

__process_msg "Configure UAC to allow privilege elevation in remote shells"
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

__process_msg "Configure and restart the WinRM Service; Enable the required firewall exception"
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any
Start-Service -Name WinRM

__process_msg "downloading node scripts zip package"
Invoke-RestMethod "$NODE_DOWNLOAD_URL" -OutFile $NODE_SCRIPTS_DOWNLOAD_LOCATION

__process_msg "creating node scripts dir"
mkdir -p $NODE_SCRIPTS_LOCATION

__process_msg "extracting node scripts"
Expand-Archive $NODE_SCRIPTS_DOWNLOAD_LOCATION -DestinationPath $NODE_SCRIPTS_LOCATION

__process_msg "Initializing node"
& "$NODE_SCRIPTS_LOCATION/initScripts/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/$INIT_SCRIPT_NAME"
