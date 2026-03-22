# Storage, Backup & Recovery (Week 5)

This weeks objectives were:

1. **Storage Management:** Add new disks to the system without disrupting running services and configure persistent mounts.
2. **Backup Strategy:** Design and implement a robust 3-2-1 backup strategy defining retention policies and recovery objectives.
3. **Automation:** Schedule and automate backups reliably without manual intervention.
4. **Verification:** Create automated tests to ensure backups are not corrupted and can be successfully restored.
5. **Networked Storage:** Share the backup storage across the network so other machines can securely pull the data.

## Project Architecture

1. **Storage Setup (`setup_storage.sh`)**:
   * We added a secondary 5GB virtual disk (`/dev/sdb`) to our VirtualBox machine.
   * The script automatically partitions the disk using `parted` with a GPT table.
   * We formatted the partition using the **XFS** filesystem and mounted it to `/mnt/backups`.
   * Persistence is guaranteed by appending the partition's unique `UUID` to `/etc/fstab`.

2. **Automated Backups (`service_backups.sh` & `setup_admins_backups.sh`)**:
   * A full system backup (`tar.gz`) runs daily at 05:00 AM triggered by a systemd timer (`admin_backup.timer`).
   * It archives mission-critical directories (`/opt`, `/home`, `/etc`, `/usr/local`, `/root`, and `/var`).
   * **Why `/var` is included with exclusions:** We backup `/var` to preserve critical data like web server files (`/var/www`), databases (`/var/lib`), and system logs (`/var/log`). However, we explicitly use the `--exclude` flag for volatile subdirectories (`/var/tmp`, `/var/cache`, `/var/run`, `/var/lib/apt/lists`). This prevents "file changed as we read it" `tar` errors and avoids wasting storage on useless temporary data that has no value during a restore.
   * Logs are written to `/var/log/gsx_backups.log`. To prevent disk saturation, `logrotate` is configured to rotate the logs weekly, keeping a compressed 4-week history.

3. **Networked Storage (`setup_nfs_server.sh`)**:
   * Installed `nfs-kernel-server` to export the `/mnt/backups` directory to our local NAT network (`10.0.2.0/24`).
   * This allows secondary machines to access the backups securely over the network without needing direct SSH access to the main server.

4. **Automated Verification (`tests_backups.sh` & `test_nfs_client.sh`)**:
   * **Integrity Test:** The script automatically runs `tar -tzf` against the latest archive to detect corruption. It then extracts the contents into a volatile `/tmp/restore_test` directory to verify the presence of all critical folders.
   * **NFS Client Test:** A sophisticated Host script that uses `VBoxManage` to instantly clone the main VM (using Linked Clones), start it headless, install an NFS client, mount the networked storage, and list the backup archives, proving network availability.

## Design Decisions

* **XFS over EXT4**: We chose XFS for the backup drive because it is a highly scalable, high-performance journaling filesystem that excels at handling large files (like heavy `.tar.gz` archives) and parallel I/O operations.
* **Full Backups via Tar**: Since our startup is small and the infrastructure is heavily based on code (IaC), performing daily full backups is simple, fast, and guarantees the lowest possible **Recovery Time Objective (RTO)**.
* **NFS vs SMB**: We opted for NFS (Network File System) because it is the native standard for Linux-to-Linux environments. It offers better performance and simpler permission mapping compared to SMB, which is more suited for Windows mixed environments.

## Hints and Questions to Guide Your Thinking

* **If you back up every file every night, you'll have massive backups. How could you reduce storage overhead? What's the trade-off?**
  
  We could reduce storage overhead by using **Incremental or Differential backups** (using tools like `rsync` or `borg`). This way, only the modified files are saved each night. The trade-off is a longer and more complex recovery process (higher RTO), as restoring the system requires applying the last full backup plus sequentially applying all the subsequent incremental changes.

* **If you lose the main server, can you restore from backup? Have you actually tested this?**
  
  Yes, we can. We have empirically tested this via our `tests_backups.sh` script, which simulates a disaster recovery scenario by extracting the backup to an alternate location (`/tmp/restore_test`) and verifying that the internal structure (`/etc`, `/opt`, etc.) is intact and readable.

* **How long would recovery take? Is that acceptable for the startup?**
  
  With our Full Backup strategy, the recovery time (RTO) is incredibly fast—just the time it takes to extract a single `tar.gz` archive (typically a few seconds to a couple of minutes depending on the size). This is highly acceptable and exceeds the requirements for a small startup.

* **If one backup location is corrupted, do you have another copy? (This is why 3-2-1 matters.)**
  
  Yes, our setup is designed with the **3-2-1 Backup Principle** in mind:
  1. We have the **Production Data** on the main disk (`/dev/sda`).
  2. We have the **Local Backup** stored on a separate physical/virtual disk (`/dev/sdb`) mounted at `/mnt/backups`.
  3. The NFS configuration allows us to easily pull a third copy to an **Offsite/External Client** across the network.

* **How would you handle a database that's currently being written to? (You can't just copy a live database file.)**
  
  Copying a live database file directly with `tar` or `cp` can lead to corrupted or inconsistent backups because transactions might be mid-flight. To handle this, we would use a database-specific dumping tool (like `pg_dump` for PostgreSQL or `mysqldump` for MySQL) to safely export a consistent snapshot of the data to a file, and then we would back up that exported file. Alternatively, we could briefly stop the database service, take the backup, and start it again, though this implies downtime.