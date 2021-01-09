<#
.NOTES
Copyright (c) 2021 Cisco and/or its affiliates.
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
############################################################################################################
# Note
# Change below IP addressing before using this script.
############################################################################################################
$ucsMgmtIP="Your IP or FQDN for UCS Manager"
connect-ucs $ucsMgmtIP

############################################################################################################
# Variables we need throughout this script
############################################################################################################

#Create hash tables for any VLANs that you want to create and associate later with hosts / servers
#We always want two variables in hashtables we create for vlans. Name and ID.
[hashtable]$ManagementVLAN = @{Name="1050"; ID='1050'}

#The site name is used to seperate configurations in UCS. I prefer all systems in a site to be configured identically to avoid confusion.
$SiteName = "Linux" 

#Range of Managmenet MAC Addresses
[hashtable]$MgmtMacPool = @{Description='MAC Addresses for Linux Management'; Name='Linux-Mgmt'; From='00:25:B5:AA:00:01'; To='00:25:B5:AA:00:ff'}

#UUID Pool Properties
[hashtable]$LinuxUUIDPool = @{Description='UUID Pool for Linux Servers'; Name=$SiteName; From='1800-000000000001'; To='1800-0000000000FF'}

# Assign names for VNIC Templates
$vicMgmtName = "eth0-Mgmt"

#Create VLAN for Mgmt Networking on Fabric Interconnect
Get-UcsLanCloud | Add-UcsVlan -CompressionType "included" -DefaultNet "no" -Id $ManagementVLAN['ID'] -McastPolicyName "" -Name $ManagementVLAN['Name'] -PolicyOwner "local" -PubNwName "" -Sharing "none"

#Create Site Name.
add-UcsOrg -Name $SiteName


############################################################################################################
# Create Pools
#
# Critical Note
# In most cases, you need to validate that the pools we are about to create will not be duplicated with 
# existing systems. You can cause pretty severe outages if you duplicate pools between different systems
############################################################################################################

############## Management MAC Pools ################

#Create MAC Address Pools (K8S Managment)
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsMacPool -AssignmentOrder "sequential" -Descr $MgmtMacPool['Description'] -Name $MgmtMacPool['Name'] -PolicyOwner "local"
$mo_1 = $mo | Add-UcsMacMemberBlock -From $MgmtMacPool['From'] -To $MgmtMacPool['To']
Complete-UcsTransaction

#Create UUIDs for Servers
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName | Add-UcsUuidSuffixPool -AssignmentOrder sequential -Descr $LinuxUUIDPool['Description'] -Name $LinuxUUIDPool['Name'] -PolicyOwner "local" -Prefix "derived"
$mo_1 = $mo | Add-UcsUuidSuffixBlock -From $LinuxUUIDPool['From'] -To $LinuxUUIDPool['To']
Complete-UcsTransaction


##########################################################################################################################################################################################
#   Create VNIC Templates
##########################################################################################################################################################################################

##################### Management Interface Templates #####################
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName  | Add-UcsVnicTemplate -Name $vicMgmtName -RedundancyPairType none -IdentPoolName $MgmtMacPool['Name'] -Mtu 1500 -PolicyOwner "local" -StatsPolicyName "default" -SwitchId "A-B" -TemplType 'updating-template'
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "yes" -Name $ManagementVLAN['Name']
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

#VMedia Profile
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName -LimitScope | Add-UcsVmediaPolicy -ModifyPresent  -Descr "" -Name "Ubuntu20.04" -PolicyOwner "local" -RetryOnMountFail "yes"
$mo_1 = $mo | Add-UcsVmediaMountEntry -ModifyPresent -AuthOption "none" -DeviceType "cdd" -ImageFileName "ubuntu-20.04-live-server-amd64.iso" -ImageNameVariable "none" -ImagePath "/" -MappingName "Ubuntu" -MountProtocol "http" -Password "" -RemapOnEject "no" -RemoteIpAddress "172.16.12.10" -RemotePort 80 -XtraProperty @{Writable="no"; }
Complete-UcsTransaction

#Local Disk Mirrored Policy
Get-UcsOrg -Name $SiteName  | Add-UcsLocalDiskConfigPolicy -Descr "" -FlexFlashRAIDReportingState "disable" -FlexFlashState "disable" -Mode "raid-mirrored" -Name "Raid1Mirrored" -PolicyOwner "local" -ProtectConfig "yes"

##########################################################################################################################################################################################
#   Service Profile
##########################################################################################################################################################################################

#Create Service Profile Template
Start-UcsTransaction
$mo = Get-UcsOrg -Name $SiteName -LimitScope | Add-UcsServiceProfile -LocalDiskPolicyName 'Raid1Mirrored' -BootPolicyName '' -HostFwPolicyName "default" -IdentPoolName $siteName -KvmMgmtPolicyName "Encrypted" -MaintPolicyName "UserAck" -BiosProfileName $SiteName -Name $SiteName -Type "updating-template" -VmediaPolicyName "Ubuntu20.04"
$mo_2 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -AdminVcon "1" -Name $vicMgmtName     -NwTemplName $vicMgmtName    -Order "1"

#Create Boot Definition
$mo_15 = $mo | Add-UcsBootDefinition -ModifyPresent -AdvBootOrderApplicable "no" -BootMode uefi -Descr "" -EnforceVnicName "yes" -PolicyOwner "local" -RebootOnUpdate "no"
$mo_15_2 = $mo_15 | Add-UcsLsbootVirtualMedia -Access read-only -LunId 0 -order 1
$mo_15_3 = $mo_15 | Add-UcslsbootStorage -Order 3 | 
    Add-UcsLsbootLocalStorage | 
        Add-UcsLsbootLocalHddImage -Order 2

$mo_16 = $mo | Set-UcsServerPower -State "admin-up"
Complete-UcsTransaction -force

##########################################################################################################################################################################################
#   Create Servers
##########################################################################################################################################################################################

#Create a service profile
$mo =   Get-UcsOrg -Name $SiteName | Get-UcsServiceProfile -Name $siteName -LimitScope | Add-UcsServiceProfileFromTemplate -NewName @("NSO-K8S-C1-N1") -DestinationOrg $SiteName
$mo_1 = Get-UcsOrg -Name $SiteName | Get-UcsServiceProfile -Name $siteName -LimitScope | Add-UcsServiceProfileFromTemplate -NewName @("NSO-K8S-C1-N2") -DestinationOrg $SiteName
$mo_2 = Get-UcsOrg -Name $SiteName | Get-UcsServiceProfile -Name $siteName -LimitScope | Add-UcsServiceProfileFromTemplate -NewName @("NSO-K8S-C1-N3") -DestinationOrg $SiteName


#Associate Servers
$mo   | Add-UcsLsBinding -ModifyPresent  -PnDn "sys/chassis-1/blade-4" -RestrictMigration "no"
$mo_1 | Add-UcsLsBinding -ModifyPresent  -PnDn "sys/chassis-1/blade-5" -RestrictMigration "no"
$mo_2 | Add-UcsLsBinding -ModifyPresent  -PnDn "sys/chassis-1/blade-6" -RestrictMigration "no"

