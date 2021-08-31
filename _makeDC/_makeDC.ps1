<#
  .SYNOPSIS
  automatic creation domain controller

  .DESCRIPTION
  creates the first domain controller in a new active directory structure

  .PARAMETER configfile
  Configuration file with the parameters to set the static ip address of the host and create the new domain

  .INPUTS
  None. You cannot pipe objects to _makeDC.ps1

  .OUTPUTS
  None. You get no return of _makeDC.ps1

  .EXAMPLE
  PS> Get-Content ".\configDC1.xml"
  <config>
    <ipaddress>10.0.0.2</ipaddress>
    <subnetmask>24</subnetmask>
    <gateway>10.0.0.1</gateway>
    <domainname>CONTOSO.COM</domainname>
    <netbios>CONTOSO</netbios>
    <domainmode>7</domainmode>
    <smAdmPwd>SECRETPASSWORD</smAdmPwd>
  </config>
  PS> .\_makeDC.xml -configfile ".\configDC1.xml"
  
  .FUNCTIONALITY
  Automatic creation of primary domain controller

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/nettcpip

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/servermanager/install-windowsfeature

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/addsdeployment/install-addsforest
#>
[cmdletbinding()]
param(
  [System.IO.file]$configfile
)

#import configfile
[xml]$config = Get-Content -Path "$configfile"

#validate config
#TODO

#set netipaddress

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

# disable DHCP for network adapter
Set-NetIPInterface -InterfaceAlias "$netadapter" -AddressFamily IPv4 -DHCP Disabled -PassThru
 
# set ip, subnet and gateway
New-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "$netadapter" -IPAddress $($config.config.ipaddress) -PrefixLength $($config.config.subnetmask) -DefaultGateway $($config.config.gateway)
 
# set dns to server
Set-DnsClientServerAddress -InterfaceAlias "$netadapter" -ServerAddresses $($config.config.ipaddress)
 
# disable ipv6
#Disable-NetAdapterBinding -Name "$netadapter" -ComponentID ms_tcpip6

# install roles and features
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature

# configure adds
Install-ADDSForest -DomainName $($config.config.domainname) -DomainNetBiosName $($config.config.netbios) -DomainMode $($config.config.domainmode) -ForestMode $($config.config.domainmode) -SkipPreChecks -InstallDns:$true -SafeModeAdministratorPassword $(ConvertTo-SecureString $($config.config.smAdmPwd) -AsPlaintext -Force) -Force

