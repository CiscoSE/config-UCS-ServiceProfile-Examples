<#
.NOTES
Copyright (c) 2020 Cisco and/or its affiliates.
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
# Unless you fully understand it and have modified it properly to work in your enviroment. 
# Do not remove the "return" line from this script. Select your intended lines and run them individually or 
# in small groups.
############################################################################################################
return

#Connect to UCS to to configure.

Import-Module Cisco.UCSManager
connect-ucs $ucsMgmtIP
############################################################################################################
# Note
# Change below IP addressing before using this script.
############################################################################################################
$ucsMgmtIP="IP-of-UCS"
$ucsNTP = "ntp-ip-address"

#These names are for VLANS.
$ManagementVLANName = "ESXiMgmt-1000"
$vMotionVLANName    = "vMotion-1001"
$StorageVLANName    = "Storage-1002"
#$LegacyStorageVLANName = "LegStorage-1003"

############# MAC Address Pool Variables #############

$mgmtMacPoolName = "Mgmt"
$vMotionMacPoolName = "vMotion"
$StorageMacPoolName = "Storage"
$vmMacPoolName = "VM"

############## Assign names for VNIC Templates ###########

$vicMgmtAName = "eth0-Mgmt-A"
$VicMgmtBName = "eth1-Mgmt-B"

$vicVMotionAName = "eth2-vMotion-A"
$VicVMotionBName = "eth3-vMotion-B"

$vicStorageAName = "eth4-Storage-A"
$VicStorageBName = "eth5-Storage-B"

$vicVMAName = "eth6-VM-A"
$VicVMBName = "eth7-VM-B"

$iscsiVnicAName = "iSCSI-A"
$iscsiVnicBName = "iSCSI-B"

#The site name is used to seperate configurations in UCS. We are assuming one site per cluster.
$SiteName = "ESX-C1-TEST" 

#Create Site Name.
add-UcsOrg -Name $SiteName

############################################################################################################
# Critical Note
# Do not duplicate MAC addresses in your L2 space. The below MAC pools are provided only as an example
############################################################################################################

############# Management MAC Pools ################

#Create MAC Address Pools (Management A)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$mgmtMacPolName}-A" -Name "${$mgmtMacPolName}-A" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1A:00:01" -To "00:25:B5:1A:00:40"
Complete-UcsTransaction

#Create MAC Address Pools (Management B)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$mgmtMacPolName}-B" -Name "${$mgmtMacPolName}-B" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1B:00:01" -To "00:25:B5:1B:00:40"
Complete-UcsTransaction

############# vMotion MAC Pools ################

#Create MAC Address Pools (vMotion A)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$vMotionMacPoolName}-A" -Name "${$vMotionMacPoolName}-A" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1A:01:01" -To "00:25:B5:1A:01:40"
Complete-UcsTransaction

#Create MAC Address Pools (vMotion B)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$vMotionMacPoolName}-B" -Name "${$vMotionMacPoolName}-B" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1B:01:01" -To "00:25:B5:1B:01:40"
Complete-UcsTransaction

############# Storage MAC Pools ################

#Create MAC Address Pools (vMotion A)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$StorageMacPoolName}-A" -Name "${$StorageMacPoolName}-A" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1A:02:01" -To "00:25:B5:1A:02:40"
Complete-UcsTransaction

#Create MAC Address Pools (vMotion B)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$StorageMacPoolName}-B" -Name "${$StorageMacPoolName}-B" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1B:02:01" -To "00:25:B5:1B:02:40"
Complete-UcsTransaction

############# VM MAC Pools ################

#Create MAC Address Pools (VM A)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$vmMacPoolName}-A" -Name "${$vmMacPoolName}-A" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1A:03:31" -To "00:25:B5:1A:03:40"
Complete-UcsTransaction

#Create MAC Address Pools (VM B)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr "${$vmMacPoolName}-B" -Name "${$vmMacPoolName}-B" -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From "00:25:B5:1B:03:31" -To "00:25:B5:1B:03:40"
Complete-UcsTransaction


#Create UUIDs for Servers
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsUuidSuffixPool -AssignmentOrder sequential -Descr "" -Name $SiteName -PolicyOwner "local" -Prefix "derived"
$mo_1 = $mo | Add-UcsUuidSuffixBlock -From "101A-000000000001" -To "101A-000000000040"
Complete-UcsTransaction

##########################################################################################################################################################################################
#   Create VNIC Templates
##########################################################################################################################################################################################

##################### Management Interface Templates #####################
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicMgmtAName -PeerRedundancyTemplName $VicMgmtBName -RedundancyPairType primary -IdentPoolName "Mgmt-A" -Mtu 1500 -PolicyOwner "local" -StatsPolicyName "default" -SwitchId "A" -TemplType 'updating-template'
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "no" -Name $ManagementVLANName
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicMgmtBName -PeerRedundancyTemplName $VicMgmtAName -RedundancyPairType secondary -IdentPoolName "Mgmt-B" -Mtu 1500 -PolicyOwner "local" -StatsPolicyName "default" -SwitchId "B" -TemplType 'updating-template'
Complete-UcsTransaction

##################### vMotion Interface Templates #####################

Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicVMotionAName -PeerRedundancyTemplName $VicVMotionBName -RedundancyPairType primary -IdentPoolName "vMotion-A" -Mtu 9000 -PolicyOwner "local" -StatsPolicyName "default" -SwitchId "A" -TemplType 'updating-template'
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "yes" -Name $vMotionVLANName
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicVMotionBName -PeerRedundancyTemplName $VicVMotionAName -RedundancyPairType secondary -IdentPoolName "vMotion-B" -Mtu 9000 -PolicyOwner "local" -StatsPolicyName "default" -SwitchId "B" -TemplType 'updating-template'
Complete-UcsTransaction

##################### Storage Interface Templates #####################

Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicStorageAName -PeerRedundancyTemplName $VicStorageBName -RedundancyPairType primary -IdentPoolName "Storage-A" -Mtu 9000 -PolicyOwner "local" -QosPolicyName "" -StatsPolicyName "default" -SwitchId "A" -TemplType 'updating-template'
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "yes" -Name $StorageVLANName
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "no"  -Name $LegacyStorageVLANName
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicStorageBName -PeerRedundancyTemplName $VicStorageAName -RedundancyPairType secondary -IdentPoolName "Storage-B" -Mtu 9000 -PolicyOwner "local" -QosPolicyName "" -StatsPolicyName "default" -SwitchId "B" -TemplType 'updating-template'
Complete-UcsTransaction

##################### VM Interface Templates #####################

Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicVMAName -PeerRedundancyTemplName $VicVMBName -RedundancyPairType primary -IdentPoolName "VM-A" -Mtu 1500 -PolicyOwner "local" -StatsPolicyName "default" -SwitchId "A" -TemplType 'updating-template'
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "no" -Name 'Server-VM-Data-Network'
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicVMBName -PeerRedundancyTemplName $VicVMAName -RedundancyPairType secondary -IdentPoolName "VM-B" -Mtu 1500 -PolicyOwner "local" -StatsPolicyName "default" -SwitchId "B" -TemplType 'updating-template'
Complete-UcsTransaction

##########################################################################################################################################################################################
#   Base Policies
##########################################################################################################################################################################################

#Require User Acknowledgement for changes.
Get-UcsOrg -Name $SiteName  | Add-UcsMaintenancePolicy -Descr "" -Name "UserAck" -PolicyOwner "local" -SchedName "" -UptimeDisr "user-ack" -TriggerConfig on-next-boot -SoftShutdownTimer 120

#BIOS Settings
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsBiosPolicy -Descr "" -Name $SiteName -PolicyOwner "local" -RebootOnUpdate "no"
$mo_1 = $mo | Set-UcsBiosVfAltitude -VpAltitude "platform-default"
$mo_2 = $mo | Set-UcsBiosVfCPUPerformance -VpCPUPerformance enterprise
$mo_5 = $mo | Set-UcsBiosVfDRAMClockThrottling -VpDRAMClockThrottling performance
$mo_6 = $mo | Set-UcsBiosVfDirectCacheAccess -VpDirectCacheAccess enabled
$mo_8 = $mo | Set-UcsBiosEnhancedIntelSpeedStep -VpEnhancedIntelSpeedStepTech enabled
$mo_9 = $mo | Set-UcsBiosExecuteDisabledBit -VpExecuteDisableBit "enabled"
$mo_10 = $mo | Set-UcsBiosVfFrequencyFloorOverride -VpFrequencyFloorOverride enabled
$mo_12 = $mo | Set-UcsBiosHyperThreading -VpIntelHyperThreadingTech "enabled"
$mo_13 = $mo | Set-UcsBiosTurboBoost -VpIntelTurboBoostTech enabled
$mo_14 = $mo | Set-UcsBiosIntelDirectedIO -VpIntelVTForDirectedIO enabled
$mo_15 = $mo | Set-UcsBiosVfIntelVirtualizationTechnology -VpIntelVirtualizationTechnology "enabled"
$mo_18 = $mo | Set-UcsBiosLvDdrMode -VpLvDDRMode performance-mode
$mo_24 = $mo | Set-UcsBiosVfProcessorCState -VpProcessorCState disabled
$mo_25 = $mo | Set-UcsBiosVfProcessorC1E -VpProcessorC1E disabled
$mo_26 = $mo | Set-UcsBiosVfProcessorC3Report -VpProcessorC3Report disabled
$mo_27 = $mo | Set-UcsBiosVfProcessorC6Report -VpProcessorC6Report disabled
$mo_28 = $mo | Set-UcsBiosVfProcessorC7Report -VpProcessorC7Report disabled
$mo_29 = $mo | Set-UcsBiosVfProcessorEnergyConfiguration -VpEnergyPerformance performance -VpPowerTechnology performance
$mo_34 = $mo | Set-UcsBiosVfSelectMemoryRASConfiguration -VpSelectMemoryRASConfiguration maximum-performance
Complete-UcsTransaction -force

#Create Policy to set encryption on KVM connections
Get-UcsOrg -Name $SiteName | Add-UcsComputeKvmMgmtPolicy -Descr "" -Name "Encrypted" -PolicyOwner "local" -VmediaEncryption "enable"

$identityPoolA = "ACI-Storage-A"
$identityPoolB = "ACI-Storage-B"

# Create Identity Pools for iSCSI Boot
Start-UcsTransaction
$mo = Get-UcsOrg -Level root | Get-UcsOrg -Name $siteName -LimitScope | Add-UcsIpPool -AssignmentOrder "sequential" -Name $identityPoolA
$mo_1 = $mo | Add-UcsIpPoolBlock -DefGw "172.16.43.1" -From "172.16.43.141" -To "172.16.43.150"
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root | Get-UcsOrg -Name $siteName -LimitScope | Add-UcsIpPool -AssignmentOrder "sequential" -Name $identityPoolB
$mo_1 = $mo | Add-UcsIpPoolBlock -DefGw "172.16.43.1" -From "172.16.43.241" -To "172.16.43.250"
Complete-UcsTransaction

##########################################################################################################################################################################################
#   Service Profile
##########################################################################################################################################################################################

#Create Service Profile Template
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName -LimitScope | Add-UcsServiceProfile -BootPolicyName "" -HostFwPolicyName "default" -IdentPoolName $siteName -KvmMgmtPolicyName "Encrypted" -MaintPolicyName "UserAck" -BiosProfileName $SiteName -Name $SiteName -Type "updating-template"
$mo_2 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $vicMgmtAName     -NwTemplName $vicMgmtAName    -Order "1" -SwitchId "A"
$mo_3 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $VicMgmtBName     -NwTemplName $VicMgmtBName    -Order "2" -SwitchId "B"
$mo_4 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $vicVMotionAName  -NwTemplName $vicVMotionAName -Order "3" -SwitchId "A"
$mo_5 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $vicVMotionBName  -NwTemplName $VicVMotionBName -Order "4" -SwitchId "B"
$mo_6 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $vicStorageAName  -NwTemplName $vicStorageAName -Order "5" -SwitchId "A"
$mo_7 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $VicStorageBName  -NwTemplName $VicStorageBName -Order "6" -SwitchId "B"
$mo_8 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $vicVMAName       -NwTemplName $vicVMAName      -Order "7" -SwitchId "A"
$mo_9 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $vicVMBName       -NwTemplName $VicVMBName      -Order "8" -SwitchId "B"
# Create the iSCSI Adapters
$mo_10 = $mo | Add-UcsVnicIScsiNode -ModifyPresent -InitiatorName "" -InitiatorPolicyName "" -IqnIdentPoolName "FED-ESX-C1"
$mo_11 = $mo | Add-UcsVnicIScsi -Name $iscsiVnicAName -VnicName $vicStorageAName
$mo_11_1 = $mo_11 | Add-UcsVnicVlan -ModifyPresent -Name "" -VlanName "ACI-Storage-2043"
$mo_12 = $mo | Add-UcsVnicIScsi -Name $iscsiVnicBName -VnicName $VicStorageBName
$mo_12_1 = $mo_12 | Add-UcsVnicVlan -ModifyPresent -Name "" -VlanName "ACI-Storage-2043"
#Configure iSCSI Adapter A in the Template

# Use this object for the 
$mo_13 = $mo | Add-UcsVnicIScsiBootParams -ModifyPresent

$mo_13_1 = $mo_13 | Add-UcsVnicIScsiBootVnic -ModifyPresent -Name $iscsiVnicAName
$mo_13_1_1 = $mo_13_1 | Add-UcsVnicIScsiStaticTargetIf -IpAddress "172.16.43.11" -name "iqn.2010-06.com.purestorage:flasharray.12ffdf9f66d021ad" -Priority 1
$mo_13_1_1_1 = $mo_13_1_1 | Add-UcsVnicLun -ModifyPresent -Bootable no -id 1
$mo_13_2 = $mo_13_1 |Add-UcsVnicIPv4If -name ""
$mo_13_2_1 = $mo_13_2 | Add-UcsManagedObject -ClassId VnicIPv4PooledIscsiAddr -PropertyMap @{IdentPoolName=$identityPoolA; }

#Configure iSCSI Adapter B in the Template
$mo_14 = $mo_13 | Add-UcsVnicIScsiBootVnic -ModifyPresent -Name $iscsiVnicBName
$mo_14_1 = $mo_14 | Add-UcsVnicIScsiStaticTargetIf -IpAddress "172.16.43.12" -name "iqn.2010-06.com.purestorage:flasharray.12ffdf9f66d021ad" -Priority 1
$mo_14_1_1 = $mo_14_1 | Add-UcsVnicLun -ModifyPresent -Bootable no -id 1
$mo_14_2 = $mo_14 |Add-UcsVnicIPv4If -name ""
$mo_14_2_1 = $mo_14_2 | Add-UcsManagedObject -ClassId VnicIPv4PooledIscsiAddr -PropertyMap @{IdentPoolName=$identityPoolB; }

#Create Boot Definition

$mo_15 = $mo | Add-UcsBootDefinition -ModifyPresent -AdvBootOrderApplicable "no" -BootMode uefi -Descr "" -EnforceVnicName "yes" -PolicyOwner "local" -RebootOnUpdate "no"
$mo_15_1 = $mo_15 | Add-UcsLsbootIScsi -order 1
$mo_15_1_1 = $mo_15_1 | Add-UcsLsbootIScsiImagePath -ISCSIVnicName $iscsiVnicAName -IpAddrType "none" -Type "primary" -VnicName ""
$mo_15_1_1 = $mo_15_1 | Add-UcsLsbootIScsiImagePath -ISCSIVnicName $iscsiVnicBName -IpAddrType "none" -Type "secondary" -VnicName ""
$mo_15_2 = $mo_15 | Add-UcsLsbootVirtualMedia -Access read-only -LunId 0 -order 2

#$mo_11 = $mo | Add-UcsFabricVCon -ModifyPresent -Fabric "NONE" -Id "1" -InstType "manual" -Placement "physical" -Select "all" -Share "shared" -Transport "ethernet","fc"
#$mo_12 = $mo | Add-UcsFabricVCon -ModifyPresent -Fabric "NONE" -Id "2" -InstType "manual" -Placement "physical" -Select "all" -Share "shared" -Transport "ethernet","fc"
#$mo_13 = $mo | Add-UcsFabricVCon -ModifyPresent -Fabric "NONE" -Id "3" -InstType "manual" -Placement "physical" -Select "all" -Share "shared" -Transport "ethernet","fc"
#$mo_14 = $mo | Add-UcsFabricVCon -ModifyPresent -Fabric "NONE" -Id "4" -InstType "manual" -Placement "physical" -Select "all" -Share "shared" -Transport "ethernet","fc"
$mo_16 = $mo | Set-UcsServerPower -State "admin-up"
Complete-UcsTransaction

##########################################################################################################################################################################################
#   Create Server 1
##########################################################################################################################################################################################

#Create a service profile
$mo = Get-UcsOrg -Name $SiteName | Get-UcsServiceProfile -Name $siteName -LimitScope | Add-UcsServiceProfileFromTemplate -NewName @("FED-ESX-C1-N1") -DestinationOrg $SiteName
$mo_1 = Get-UcsOrg -Name $SiteName | Get-UcsServiceProfile -Name $siteName -LimitScope | Add-UcsServiceProfileFromTemplate -NewName @("FED-ESX-C1-N2") -DestinationOrg $SiteName
$mo_2 = Get-UcsOrg -Name $SiteName | Get-UcsServiceProfile -Name $siteName -LimitScope | Add-UcsServiceProfileFromTemplate -NewName @("FED-ESX-C1-N3") -DestinationOrg $SiteName
$mo_3 = Get-UcsOrg -Name $SiteName | Get-UcsServiceProfile -Name $siteName -LimitScope | Add-UcsServiceProfileFromTemplate -NewName @("FED-ESX-C1-N4") -DestinationOrg $SiteName

#Associate Servers
$mo | Add-UcsLsBinding -ModifyPresent  -PnDn "sys/chassis-1/blade-3" -RestrictMigration "no"
$mo_1 | Add-UcsLsBinding -ModifyPresent  -PnDn "sys/chassis-3/blade-3" -RestrictMigration "no"
$mo_2 | Add-UcsLsBinding -ModifyPresent  -PnDn "sys/chassis-3/blade-6" -RestrictMigration "no"
$mo_3 | Add-UcsLsBinding -ModifyPresent  -PnDn "sys/chassis-3/blade-5" -RestrictMigration "no"
