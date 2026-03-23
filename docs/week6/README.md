# Documentation & Handoff (Week 6)

This document serves as the final handoff manual for the GreenDevCorp startup infrastructure. It contains the operational runbook, system architecture rationale, disaster recovery timelines, and personal reflections.

---

## 1. System Architecture & Design

### 1.1 Architecture Diagram
Below is a high-level overview of our system components and how they interact between the Host machine and the Debian Guest VM.

```text
+-----------------------------------------------------------------+
|                         Host Machine                            |
|  +--------------------+                 +--------------------+  |
|  |  Git Repository    |                 |  NFS Backup Pool   |  |
|  |  (Scripts & Docs)  |                 |  (Host/Network)    |  |
|  +---------+----------+                 +---------+----------+  |
|            |                                      ^             |
|            | (VBoxManage / SSH / GuestControl)    | (NFS)       |
|            v                                      |             |
|  +-------------------------------------------------------+      |
|  |                  Debian VM (Guest)                    |      |
|  |                                                       |      |
|  |  +----------------+  +----------------+  +---------+  |      |
|  |  |  Nginx Service |  | Dev/Admin Users|  | limitd  |  |      |
|  |  |  (Web Server)  |  | (PAM & SGID)   |  | (OOM)   |  |      |
|  |  +----------------+  +----------------+  +---------+  |      |
|  |                                                       |      |
|  |  +----------------+  +----------------+  +---------+  |      |
|  |  | Systemd Timers |  |   Go Monitor   |  | XFS VDI |  |      |
|  |  | (Auto Backups) |  |   (CLI Tool)   |  | Storage |  |      |
|  |  +-------+--------+  +----------------+  +----+----+  |      |
|  |          |                                    |       |      |
|  +----------|------------------------------------|-------+      |
|             +------------------------------------+              |
+-----------------------------------------------------------------+
```

### 1.2 Design Rationale (Why did we make these choices?)
Our infrastructure follows a strict **Infrastructure as Code (IaC)** philosophy. Every choice was made prioritizing automation, system resilience, and least privilege:
* **Bash & VBoxManage over Manual Setup:** We chose to automate the entire VM lifecycle using VirtualBox CLI and idempotent Bash scripts. The rationale is disaster recovery: if the VM breaks entirely, we can reconstruct the exact same server state in minutes without manual intervention.
* **Go for System Monitoring:** Instead of relying on heavy third-party agents, we chose Go. It allowed us to compile a single, fast, static CLI binary that safely reads `/proc` directly, teaching us how the kernel actually exposes metrics.
* **SGID & Sticky Bits over POSIX ACLs:** We opted for standard Unix permissions (combining SGID and the Sticky Bit) for the team's shared folders. The rationale was to keep the permission model predictable and standard without adding the overhead of complex Access Control Lists.
* **Systemd Drop-ins (`.d` directories):** Instead of modifying default package configuration files directly (like Nginx), we used `systemd` drop-in configurations. This ensures our custom restart logic survives future package upgrades.

### 1.3 Trade-offs & Reflections

**What would we do differently?**
* **Configuration Management:** We would transition from pure Bash scripts to a Configuration Management tool like **Ansible**. Enforcing idempotency in Bash (using `sed` and `grep` to check if a line already exists) became overly complex. Ansible handles state natively.
* **Backup Strategy:** We implemented a daily full `tar` backup. While simple and guaranteeing the lowest recovery time, it is highly inefficient for storage. If we started over, we would implement an incremental/deduplicated backup system using tools like `rsync` or `BorgBackup`.

**What would we keep the same?**
* **Headless VirtualBox Orchestration:** Being able to provision, clone, and configure environments completely headless via `VBoxManage` and `guestcontrol` proved incredibly reliable. It allowed us to test features safely without touching the production state.
* **PAM for Resource Limits:** Using `limits.conf` to restrict the development team's processes and memory usage was highly effective. We would definitely keep this exact model to prevent any single user from exhausting server resources and triggering the OOM killer unexpectedly.

### 1.4 Future Planning: Scaling to 100 People
To scale this infrastructure from 4 to 100 employees, the current architecture would need to evolve:
1. **User Management:** Local `useradd` scripts would be replaced by a centralized directory service (e.g., OpenLDAP or Active Directory).
2. **Storage & Backups:** Local NFS and VDI disks would migrate to scalable Cloud Object Storage (e.g., AWS S3) with automated lifecycle policies.
3. **Monitoring:** The custom Go CLI tool would be upgraded to a daemon agent exporting metrics to a centralized Prometheus & Grafana stack.

---

## 2. Operations Runbook

This section details how to perform routine administrative tasks, troubleshoot common issues, and escalate critical failures using the custom tooling we developed.

### 2.1 Common Tasks ("How do I...?")

**How do I create a new server?**
To use our centralized configuration script that builds the virtual machine from scratch, configure the `.env` file to specify the paths and parameters you wish to use. 
Navigate to:
```bash
cd /greendevcorp-gsx/scripts/bootstrap 
```
And execute:
```bash
./setup_vbox.sh
```

**How do I add a new developer to the team?**
Use our dynamic provisioning script. It automatically finds the next available ID and provisions the user in the `greendevcorp` group:
```bash
sudo /opt/admin/scripts/services/add_users_group.sh dev 1 greendevcorp
```

**How do I handle a team member leaving?**
When a developer leaves the company, we must immediately secure the system, retain their work for auditing purposes, and finally remove their access:

1. **Lock and expire the account** to prevent new logins via password or SSH keys:
   ```bash
   sudo usermod -L -e $(date +%F) devX
   ```
2. **Terminate any active sessions** or background processes belonging to the user:
   ```bash
   sudo pkill -KILL -u devX
   ```
3. **Create an audit backup** of their home directory and store it safely in the backup drive:
   ```bash
   sudo tar -czvf /mnt/backups/audit_archive_devX_$(date +%F).tar.gz /home/devX
   ```
4. **Remove the user and their home directory** safely once the backup is verified:
   ```bash
   sudo userdel -r devX
   ```

**How do I check if services are running correctly?**
Use our observability diagnostic script, which aggregates `systemctl` status and the latest `journalctl` error logs:
```bash
sudo /opt/admin/scripts/services/check_logs.sh <service_name>
```

**How do I diagnose a slow system?**
Run our custom Go monitoring tool to identify processes consuming excessive CPU or Memory:
```bash
/usr/local/bin/monitor --top --cpu
```
Once the PID is identified, you can inspect its tree with:
```bash
/usr/local/bin/monitor --tree --m <PID>
```
or kill it if necessary.

**How do I restore from a backup?**
1. Locate the latest backup:
   ```bash
   ls -t /mnt/backups/server_backup_*.tar.gz | head -n 1
   ```
2. Test the integrity using our script: 
   ```bash
   sudo /opt/admin/scripts/tests/tests_backups.sh
   ```
3. To perform a full restore, extract the archive from the root directory (Caution: this overwrites current data):
   ```bash
   sudo tar -xzf /mnt/backups/server_backup_DATE.tar.gz -C /
   ```

### 2.2 Troubleshooting Guide

* **Problem:** A developer gets a "Permission Denied" error when trying to edit a file in `/home/greendevcorp/shared`.
  * **Diagnosis:** The file might not have inherited the proper group, or the Sticky Bit is preventing modification.
  * **Resolution:** Verify the user is part of the `greendevcorp` group using `id <username>`. Ensure the directory permissions are `3770` (`stat /home/greendevcorp/shared`). If the user is trying to delete a file owned by someone else, remind them that the Sticky Bit prevents this by design.

* **Problem:** Nginx is not serving the website.
  * **Diagnosis:** The service might have crashed or the configuration is invalid.
  * **Resolution:** First, check the logs specifically for Nginx using `sudo /opt/admin/scripts/services/check_logs.sh nginx`. If it's a syntax error in the config, fix it and manually trigger the restart: `sudo systemctl restart nginx`. Note that our drop-in configuration (`restart.conf`) should automatically attempt to restart it after 5 seconds on failure.

* **Problem:** A specific background job keeps disappearing or crashing without notice.
  * **Diagnosis:** The process might be hitting the hard resource limits defined in PAM or `cgroups` and being terminated by the OOM Killer.
  * **Resolution:** Check the system logs for OOM killer activity (`journalctl -k | grep -i oom`). Check the user's hard limits by switching to their account and running `ulimit -H -a`. If the limits are too strict for a legitimate workload, escalate to modify `/etc/security/limits.d/greendevcorp.conf`.

### 2.3 Escalation Procedures

**When to call for help:**
Routine operations (user creation, log checking, service restarts) should be handled by the junior SysAdmin on duty. However, you must escalate to the **Senior Infrastructure Team** immediately if you encounter:
1. Physical or virtual hardware corruption (e.g., VDI disk failure).
2. A security breach or unauthorized root access attempt.
3. A critical service failure (e.g., Kernel Panic) that persists after a reboot and cannot be resolved using the Troubleshooting Guide.
4. Total loss of the main database without a verifiable backup.

**Action Plan while waiting for response:**
If a critical system failure occurs that completely takes down the production server, do not attempt to patch a broken OS manually for hours. The SysAdmin on duty should power off the corrupted VM and spin up a clean clone using the `./scripts/bootstrap/setup_vbox.sh` and `./scripts/bootstrap/run_setup_system.sh` scripts to restore services immediately from the latest NAS backup.

---

## 3. Verified Backup and Recovery Timeline

We have simulated a complete disaster recovery scenario. Below is the tested timeline (RTO - Recovery Time Objective):

1. **Hardware Provisioning (T+0:00):** Run `setup_vbox.sh` to spin up a new Debian VM. *(Time: ~20 minutes)*
2. **System Bootstrap (T+20:00):** Run `run_setup_system.sh` to inject configurations and recreate users. *(Time: ~5 minutes)*
3. **Storage Mount (T+25:00):** Attach the backup VDI disk and mount it to `/mnt/backups`. *(Time: ~1 minute)*
4. **Data Restoration (T+27:00):** Extract the `tar.gz` archive over the `/opt`, `/etc`, and `/home` directories. *(Time: ~2 minutes)*

**Total Estimated RTO:** ~30 Minutes. 
This rapid recovery is made possible entirely by our Infrastructure as Code (IaC) implementation.

---

## 4. Personal Reflections

### Reflection by RAFA
The most complex challenge of this project was achieving the comprehensive and orchestrated automation of the entire infrastructure, designing a workflow where a couple of scripts are capable of provisioning the machine, injecting configurations, and starting services in a fully unattended manner. Despite this initial difficulty, if I had to start over, I would keep exactly the same approach. I am very proud of the result because we have managed to build a robust, modular architecture that has proven to be highly reliable during recovery tests. 

This entire process has profoundly changed my understanding of system administration. I now realize that this discipline goes far beyond simply installing programs or typing commands: it requires designing with a constant focus on security, resilience through automated backup strategies, and strict resource control using tools like PAM limits and cgroups. As a natural next step after building this entire infrastructure based on pure Bash, I would love to delve deeper into enterprise-level orchestration tools, to learn how to apply this exact same "Infrastructure as Code" philosophy to hundreds of servers simultaneously in the cloud.

### Reflection by OUPMAN
* **Most challenging aspect:**
* **What I would do differently:** 
* **How my understanding changed:** 
* **What I want to learn more about:**