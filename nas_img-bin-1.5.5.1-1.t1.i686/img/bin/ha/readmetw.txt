1. HA 是使用兩台Active and standby server所建構而成, 這兩台Server將會
    變成一個對外的 virtual server, 並且所有系統的服務將會建構在一個虛擬的IP上面，
    HA系統會使用Active and standby server上的Master RAID Volume做資料的同步。

2. 如果舊的NAS系統上有RAID data請先使用另外一台NAS將資料進行備份的動作，因為
    新建置 的Active NAS上的RAID資料會被HA功能移除。

3. 請確認 HA 的設定部分，Active and standby server設定是正確無誤的。

4. 操作步驟Setup:
  A. 開啟新的RAID volume在Active NAS上。
  B. Active NAS上啟動HA功能，並且等待重新開機 (RAID資料會被HA功能移除)。
  C. 確認RAID 狀態有顯示HA的RAID ID。
  D. 如果舊資料儲存在其他 NAS，請複製到Active NAS RAID Volume.
  E. 開啟 Standby NAS RAID volume.
  F. Standby NAS上啟動HA功能，並且等待重新開機。
  G. HA RAID狀態將會同步Active NAS資料至 Standby NAS.

額外附註：
  1. HA 系統只允許系統擁有一組RAID Volume，如果將HA功能關閉，RAID Volume將會被移除。
  2. Standby 部分功能的設定會移轉到 Active Server處理，例如 AFP, FTP, NFS, Share Folder服務。
  3. Active & Standby Server在做 Recovering 的時候，系統不要進行重新開機的動作。


