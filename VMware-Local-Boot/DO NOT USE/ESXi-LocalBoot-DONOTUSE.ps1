<#
.NOTES
Copyright (c) 2025 Cisco and/or its affiliates.
This software is licensed to you under the terms of the Cisco Sample
Code License, Version 1.0 (the "License"). You may obtain a copy of the
License at
               https://developer.cisco.com/docs/licenses
All use of the material herein must be in accordance with the terms of
the License. All rights not expressly granted by the License are
reserved. Unless required by applicable law or agreed to separately in
writing, software distributed under the License is distributed on an "AS
IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied.
#>
############################################################################################################
# *** This is an example script.*** It is not intended to be run in your environment without modification.
# This script exits by default to prevent damage to your existing environment. You should not run it
# unless you fully understand it and have modified it properly to work in your enviroment.
# Do not remove the "return" line from this script. Select your intended lines and run them individually or
# in small groups.
############################################################################################################

return

#Set Jumbo Frames for best effort on HX UCS before configuring VMWare side of HyperFlex. Bronse level QOS does not apply jumbo frames properly.

#List of systems and IP addresses to be assigned to each.
[array[]]$ESXi_Hosts =  @{Name='yourhost.yourdomain.local';mgmt1=10.0.0.11;iSCSI1='192.168.0.111';ISCSI2="192.168.0.211";vMotion="192.168.1.11"}

$ESXHost = $ESXi_Hosts.Name
# Common Settings
$StorageMTU = "9000"                          #Set for vswitches and port groups.
$StorageIP1 = "192.168.0.254"       #iSCSI targets on storage
$StorageIP2 = "192.168.0.253"       #iSCSI targets on storage
$syslogServer = 'udp://10.0.0.10'
$timeServer = '10.0.0.1'            #If Gateway acts as time server

$vMotionSwitchName = "vMotion"
$vMotionVmkName = "vMotion"
$vMotionVLAN = '510'
$vMotionNetMask = "255.255.255.0"             #Used for vMotion VMK interfaces
$vMotionMTU = "9000"

$iscsiVLAN = '500'
$iscsiNetMask = "255.255.255.0"             #Used for vMotion VMK interfaces


$esxHostObj = get-vmhost $ESXHost

# iSCSI / vMotion Switch Configuration
$vMotionSwitchObj = $esxHostObj | New-VirtualSwitch -Name $vMotionSwitchName -nic vmnic2,vmnic3 -Mtu $vMotionMTU
$vPortGroupName = New-VirtualPortGroup -Name $vMotionVmkName -VLanId $vMotionVLAN -VirtualSwitch $vMotionSwitchObj
$mo = New-VMHostNetworkAdapter -vmHost $ESXHost -IP $ESXi_Hosts.vMotion -SubnetMask $vMotionNetMask -VirtualSwitch $vMotionSwitchName -PortGroup $vMotionVmkName -Mtu $vMotionMTU -VMotionEnabled $True -Verbose

# If you have a seperate storage vSwitch, use the above lines as a template to create another vSwitch. Storage and vMotion are often on different adapters
# You will need to change teh -VirtualSwitch value below if you make that adjustment.

# Create Storage vSwitch
$iSCSI1PortGroup = New-VirtualPortGroup -Name "ISCSI1" -VLanId $iscsiVLAN -VirtualSwitch $vMotionSwitchObj
$iSCSI1PortGroup = New-VirtualPortGroup -Name "ISCSI2" -VLanId $iscsiVLAN -virtualSwitch $vMotionSwitchObj
$mo = New-VMHostNetworkAdapter -vmHost $ESXHost -IP $ESXi_Hosts.iSCSI1 -SubnetMask $iscsiNetMask -VirtualSwitch $vMotionSwitchName -PortGroup "ISCSI1" -Mtu $StorageMTU -Verbose
$esxHostObj | Get-VirtualPortGroup -Name ISCSI1 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused vmnic3 -MakeNicActive vmnic2
$mo = New-VMHostNetworkAdapter -vmHost $ESXHost -IP $ESXi_Hosts.iSCSI2 -SubnetMask $iscsiNetMask -VirtualSwitch $vMotionSwitchName -PortGroup "ISCSI2" -Mtu $StorageMTU -Verbose
$esxHostObj | Get-VirtualPortGroup -Name ISCSI2 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused vmnic2 -MakeNicActive vmnic3

#Enable iSCSI Adapter
Get-VMHostStorage -VMHost $ESXHost | Set-VMHostStorage -SoftwareIScsiEnabled $True

#Set ISCSI1 as an ISCSI VMK
$HBA = get-vmhosthba -vmhost $ESXHost -type IScsi | %{$_.device}

$ISCSI1_vmk = (Get-VMHostNetworkAdapter -VMHost $ESXHost -PortGroup "ISCSI1").name
$esxcli = get-esxcli -VMHost $ESXHost
$esxcli.iscsi.networkportal.add($HBA,$Null,$ISCSI1_VMk)

#Set ISCSI2 as an ISCSI VMK
$ISCSI2_vmk = (Get-VMHostNetworkAdapter -VMHost $ESXHost -PortGroup "ISCSI2").name
$esxcli.iscsi.networkportal.add($HBA,$Null,$ISCSI2_VMk)

# Enable Auto Discovery of storage.
$hbahost = get-vmhost -name $ESXHost |
        Get-VMHostHba -Type iscsi
    New-IScsiHbaTarget -IScsiHba $hbahost -Address $StorageIP1
    New-IScsiHbaTarget -IScsiHba $hbahost -Address $StorageIP2


#$esxHostObj | Get-VirtualPortGroup -Name iSCSIBootPG | Remove-VirtualPortGroup
#$esxHostObj | get-VirtualSwitch -Name "iScsiBootvSwitch" | Remove-VirtualSwitch

return

#Set Time Server to gateway
$esxHostObj | Add-VMHostNtpServer $timeServer
$esxHostObj | Get-VMHostService | ?{$_.key -eq "ntpd"} | set-vmhostService -policy On
$esxHostObj | Get-VMHostService | ?{$_.key -eq "ntpd"} | Start-VMHostService



#Configure Syslog
$esxHostObj | Set-VMHostSysLogServer -SysLogServerPort 514 -syslogServer $syslogServer
$esxHostObj | Get-VMHostFirewallException -Name syslog | Set-VMHostFirewallException -Enabled $true

# Set CML required Advanced Settings
$esxHostObj | Get-AdvancedSetting -name net.ReversePathFwd* | Set-AdvancedSetting -value 1

return
