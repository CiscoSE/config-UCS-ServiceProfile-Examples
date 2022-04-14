<#
.NOTES
Copyright (c) 2022 Cisco and/or its affiliates.
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
# This is an example script. It is not intended to be run in your environment without modification.
# This script exits by default to prevent damage to your existing environment. You should not run it
# unless you fully understand it and have modified it properly to work in your enviroment. 
# Do not remove the "return" line from this script. Select your intended lines and run them individually or 
# in small groups.
############################################################################################################
return

#Set Jumbo Frames for best effort on HX UCS before configuring VMWare side of HyperFlex.

$ESXHost = '1.1.1.11'

# ISCSI Settings (Common)
$StorageMTU =            "9000"                    #Set for vswitches and port groups.
$iSCSI_Mask =            "255.255.255.0"
$iSCSI_LocalSwitchName = "ISCSI"

#ISCSI Targets on the storage you are attaching to
$iSCSITargetStorageIP1 = "1.1.2.250"           #iSCSI targets on storage
$iSCSITargetStorageIP2 = "1.1.2.251"           #iSCSI targets on storage


# First VMK Adapter for ISCSI
$iSCSI1_vmKernalName =   "ISCSI1"
$storageVmkIP1 =         '1.1.2.11'

# Second VMK Adpater for ISCSI
$iSCSI2_vmKernalName =   "ISCSI2"
$storageVmkIP2 =         '1.1.2.111'

#VMotion Configuration
$vMotionNetMask =        "255.255.255.0"
$vMotionMTU =            "9000"
$vMotionVMKIP =          "1.1.3.11"
$vMotionSwitchName =     "vMotion"

#SysLog Server
$syslogServer =          'udp://1.1.3.150'

#Get ESXi Host Object
$esxHostObj = get-vmhost $ESXHost


#Enable Software iSCSI Adapter
Get-VMHostStorage -VMHost $ESXHost | Set-VMHostStorage -SoftwareIScsiEnabled $True

# Create Storage vSwitch
$StorageSwitchObj = $esxHostObj | New-VirtualSwitch -name $iSCSI_LocalSwitchName -nic vmnic5,vmnic6 -mtu $StorageMTU

#Create VMK1 (First ISCSI Storage Adapter
$mo = New-VMHostNetworkAdapter -vmHost $ESXHost -IP $storageVmkIP1 -SubnetMask $iSCSI_Mask -VirtualSwitch $iSCSI_LocalSwitchName -PortGroup $iSCSI1_vmKernalName -Mtu $StorageMTU -Verbose
#Set teaming Configuration
Get-VirtualPortGroup -VMHost $esxHostObj -Name $iSCSI1_vmKernalName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic5 -MakeNicUnused vmnic6

#Create VMK2 (Second ISCSI Storage Adapater)
$mo = New-VMHostNetworkAdapter -vmHost $ESXHost -IP $storageVmkIP2 -SubnetMask $iSCSI_Mask -VirtualSwitch $iSCSI_LocalSwitchName -PortGroup $iSCSI2_vmKernalName  -Mtu $StorageMTU -Verbose
#Set teaming Configuration
Get-VirtualPortGroup -VMHost $esxHostObj -Name $iSCSI2_vmKernalName | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic6 -MakeNicUnused vmnic5


$HBA = get-vmhosthba -vmhost $ESXHost -type IScsi | %{$_.device}
$esxcli = get-esxcli -VMHost $ESXHost -v2

#Add ISCSI1 VMK to ISCSI Configuration
$ISCSI1_vmk = (Get-VMHostNetworkAdapter -VMHost $ESXHost -PortGroup $iSCSI1_vmKernalName).name
$iscsi1_associate_args=$esxcli.iscsi.networkportal.add.CreateArgs()
$iscsi1_associate_args.nic = $ISCSI1_vmk
$iscsi1_associate_args.adapter = $HBA
$esxcli.iscsi.networkportal.add.Invoke($iscsi1_associate_args)

#Add ISCSI2 VMK to ISCSI Configuration
$ISCSI2_vmk = (Get-VMHostNetworkAdapter -VMHost $ESXHost -PortGroup $iSCSI2_vmKernalName).name
$iscsi2_associate_args=$esxcli.iscsi.networkportal.add.CreateArgs()
$iscsi2_associate_args.nic = $ISCSI2_vmk
$iscsi2_associate_args.adapter = $HBA
$esxcli.iscsi.networkportal.add.Invoke($iscsi2_associate_args)

#Scan ISCSI Storage for accessible volumes. 
$hbahost = get-vmhost -name $ESXHost |
        Get-VMHostHba -Type iscsi
    New-IScsiHbaTarget -IScsiHba $hbahost -Address $iSCSITargetStorageIP1
    New-IScsiHbaTarget -IScsiHba $hbahost -Address $iSCSITargetStorageIP2

$esxHostObj | Get-VMHostStorage -RescanAllHba -RescanVmfs

# vMotion Switch Configuration
$vMotionSwitchObj = $esxHostObj | New-VirtualSwitch -Name $vMotionSwitchName -nic vmnic2,vmnic3 -Mtu $vMotionMTU
$mo = New-VMHostNetworkAdapter -vmHost $ESXHost -IP $vMotionVMKIP -SubnetMask $vMotionNetMask -VirtualSwitch $vMotionSwitchName -PortGroup "vMotion" -Mtu $vMotionMTU -Verbose 
$esxHostObj |  Get-VMHostNetworkAdapter -VMKernel -Name vmk0 | Set-VMHostNetworkAdapter -VMotionEnabled:$true -confirm:$false

#Configure Syslog
$esxHostObj | Set-VMHostSysLogServer -SysLogServerPort 514 -syslogServer $syslogServer
$esxHostObj | Get-VMHostFirewallException -Name syslog | Set-VMHostFirewallException -Enabled $true



