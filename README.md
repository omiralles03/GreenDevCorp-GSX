# GreenDevCorp: Foundational Server Administration
Sysadmin project for Systems and Network Management subject.

Tracks the lifecycle of an enterprise server maintainment and deployment, focusing on **Automation, Scalability, Security, and Monitoring**.

> [!SUCCESS]  
> **Status: Stable / Production Ready** > This project has successfully completed all 6 weeks of development and infrastructure deployment.

---

## Project Overview

The project focuses on **Infrastructure as Code (IaC)** principles and professional collaboration to build a robust Debian server from scratch. It is divided into 6 progressive milestones:

* **Week 1 (Infrastructure & Access):** Automated VirtualBox provisioning (`VBoxManage`), unattended Debian installation, SSH hardening (key-based auth, disabled root), and idempotent bootstrap scripts.
* **Week 2 (Services & Observability):** Implementation of reliable `systemd` services and timers for Nginx and backups. Centralized logging and diagnostic tools via `journalctl`.
* **Week 3 (Resource Control):** Development of a custom CLI monitoring tool in **Go** reading directly from `/proc`. Implementation of `cgroups` to prevent Out-Of-Memory (OOM) crashes via custom limits.
* **Week 4 (Access Control):** Dynamic user and group provisioning. Advanced Unix permissions combining **SGID** and **Sticky Bits** for shared directories. PAM-based resource limits (`limits.conf`) and shell environment personalization.
* **Week 5 (Storage & Network):** Physical volume partitioning (`fdisk`/`parted`), XFS filesystem mounting via `fstab`. Automated `tar` backups with `logrotate`, and networked storage sharing via **NFS**. Automated restore and integrity tests.
* **Week 6 (Handoff & Ops):** Comprehensive documentation, operations runbook, architecture diagrams, and disaster recovery planning.

---

## Tech Stack & Specs

* **Environment:** Linux (Debian)
* **Virtualization:** VirtualBox CLI
* **Custom Tooling:** Go (Standalone CLI binary)
* **Scripting:** Bash (Idempotent, safe execution)
* **Version Control:** Git (Feature Branch Workflow)

---

## Repository Structure

* `cmd/monitor/`: Go source code for the custom system monitoring tool.
* `configs/`: Drop-in configurations for `systemd`, `logrotate`, and `nginx`.
* `docs/`: Weekly documentation, architecture, and runbooks.
* `keys/`: Public SSH keys for automated authorized_keys injection.
* `scripts/`: Core infrastructure scripts.
  * `bootstrap/`: VM creation, OS installation, and initial setup.
  * `services/`: Automated installation of services (NFS, limits, users, backups).
  * `tests/`: Automated verification scripts for security, limits, and backup integrity.
  * `core/`: Environment variables and shared messaging functions.

---

## Workflow

We follow a professional **Feature Branch Workflow** to ensure code quality and system stability:

1. **`main`**: Production-ready state.
2. **`dev`**: Integration branch for new features.
3. **`feat/topic`**: Isolated branches for specific task development.

*For more details, see our [Workflow Documentation](./WORKFLOW.md).*