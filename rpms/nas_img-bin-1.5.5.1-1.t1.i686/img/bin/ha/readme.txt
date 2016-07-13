1. HA keeps data updated on one Active and one Standby NAS.   All functions are run through 
    a single virtual IP address that accesses the Active NAS normally and automatically switches to 
    the Standby NAS if necessary. 
  
    The HA system synchronizes the Master RAID volume from the Active NAS on the Standby NAS 
    using \'Heartbeat\' packets. With HA, only ONE RAID volume can be created, the Master RAID.
  
2. Activating HA deletes all existing data on the NAS. Because of this, it is recommended to 
    first backup any important data before activating HA.

3. Please double-check all HA settings before activation to avoid having to reset HA in the future.

4. Step-by-step activation setup:
  A. Create a Master RAID volume on the Active NAS.
  B. Activate HA on the Active NAS and allow the system to restart(This will delete all existing data on the NAS)
  C. Confirm that the RAID volume is displayed under Storage => RAID in the UI. 
  D. If there was any previously existing data backed up onto another volume, copy that data into 
      the Active NAS\'s RAID Volume.
  E. Turn on the Standby NAS RAID volume
  F. Activate HA on the Standby NAS and allow the system to restart (This will delete all existing data on the NAS).
      This will begin Active and Passive NAS synchronization.
  G. The Active
  
Additional Notes:
  1. A NAS with HA activated can only have one RAID volume. If HA is deactivated, the RAID volume 
      will be deleted.
  2. All settings for the Standby NAS are controlled from the Active NAS, for example AFP, FTP, NFS, 
      and Shared Folder functions.
  3. After an Active NAS experiences problems and is back online, it will recover data from the Standby NAS. 
      During data recovery, DO not restart or turn off either NAS.
