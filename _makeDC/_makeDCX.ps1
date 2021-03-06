<#
  .SYNOPSIS
  automatic creation additional domain controller

  .DESCRIPTION
  creates additional domain controller(s) in an existing active directory structure

  .PARAMETER configfile
  Configuration file with the parameters to set the static ip address of the host and join an existing domain

  .INPUTS
  None. You cannot pipe objects to _makeDC.ps1

  .OUTPUTS
  None. You get no return of _makeDC.ps1

  .EXAMPLE
  PS> Get-Content ".\configDCX.xml"
  <config>
    <ipaddress>10.0.0.3</ipaddress>
    <subnetmask>24</subnetmask>
    <gateway>10.0.0.1</gateway>
    <domainname>CONTOSO.COM</domainname>
    <smAdmPwd>SECRETPASSWORD</smAdmPwd>
  </config>
  PS> .\_makeDCX.xml -configfile ".\configDCX.xml"
  
  .FUNCTIONALITY
  Automatic creation of additional domain controller

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/nettcpip

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/servermanager/install-windowsfeature

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/addsdeployment/install-addsdomaincontroller
#>
[cmdletbinding()]
param(
  [System.IO.fileinfo]$configfile
)
#requires -RunAsAdministrator

$Message = "Starting"
Write-Output -InputObject $Message

#convert relative path to absolute path for configfile
#TODO

$Message = "Importing configuration file: '"+$configfile+"'"
Write-Output -InputObject $Message
[xml]$config = Get-Content -Path "$configfile"

$Message = "Validate configuration file"
Write-Output -InputObject $Message
#TODO

$Message = "Check network adapter"
Write-Output -InputObject $Message
# get network adapter / including case netadapter>1
if ($((Get-NetAdapter | Measure-Object).Count) -lt 1){
  throw "No network adapter found"
}
elseif ($((Get-NetAdapter | Measure-Object).Count) -gt 1){
  $netadapter = Read-Host -prompt "Please specifiy the name of the network adapter to use"
  if (-not(Get-NetAdapter -Name $netadapter)){
    throw "No network adapter found with name '$netadapter'"
  }
}else{
  $netadapter = (Get-NetAdapter).Name
}
$Message = "Network-Adapter is: '"+$netadapter+"'"
Write-Output -InputObject $Message

$Message = "Disable DHCP for network adapter"
Write-Output -InputObject $Message
[void]$(Set-NetIPInterface -InterfaceAlias "$netadapter" -AddressFamily IPv4 -DHCP Disabled -PassThru)
 
$Message = "Set ip, subnet and gateway"
Write-Output -InputObject $Message
[void]$(New-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "$netadapter" -IPAddress $($config.config.ipaddress) -PrefixLength $($config.config.subnetmask) -DefaultGateway $($config.config.gateway))
 
$Message = "Set DNS to server"
Write-Output -InputObject $Message
[void]$(Set-DnsClientServerAddress -InterfaceAlias "$netadapter" -ServerAddresses $($config.config.dnsserver),$($config.config.ipaddress))
 
#$Message = "Disable ipv6"
#Write-Output -InputObject $Message
#[void]$(Disable-NetAdapterBinding -Name "$netadapter" -ComponentID ms_tcpip6)

$Message = "Install roles and features"
Write-Output -InputObject $Message
$rfresult = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature

if (($rfresult.Success -eq $true)-and($rfresult.Restart -eq 'No')){
  $Message = "Configure ADDS"
  Write-Output -InputObject $Message
  [void]$(Install-ADDSDomainController -Credential (Get-Credential "$($config.config.domainname)\Administrator") -DomainName $($config.config.domainName) -SkipPreChecks -NoGlobalCatalog:$true -CriticalReplicationOnly:$false -InstallDns:$true -SiteName "Default-First-Site-Name" -SafeModeAdministratorPassword $(ConvertTo-SecureString $($config.config.smAdmPwd) -AsPlaintext -Force) -Force)

  $Message = "Done"
  Write-Output -InputObject $Message
}
else
{
  $Message = "Error installing roles and features"
  Write-Output -InputObject $Message
}