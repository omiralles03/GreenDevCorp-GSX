# GreenDevCorp: Foundational Server Administration
Sysadmin project for Systems and Network Management subject.

Tracks the lifecycle of an enterprise server maintainment and deployment, focusing on **Automation, Scalability, and Monitoring**.

> [!NOTE]  
> Currently in development.

---

## Project Overview

The project focuses on **Infrastructure as Code (IaC)** principles and professional collaboration:

* **Automated Server Configuration:** Focus on Linux system administration via CLI.
* **Custom Monitoring Tooling:** Development of a system monitor in **Go** to track server processes (CPU, Memory, Disk, ...).
* **Security & Hardening:** Implementation of best practices in user management and system permissions.
* **Collaborative DevOps Workflow:** Using a strict **Feature Branch Workflow** to manage concurrent development across the team.

---

## Specs

* **Environment:** Linux (Debian)
* **Custom Tooling:** Go
* **Version Control:** Git
* **Monitoring:** Standalone CLI binary

---

## Workflow

We follow a professional **Feature Branch Workflow** to ensure code quality and system stability:

1. **`main`**: Production-ready state.
2. **`dev`**: Integration branch for new features.
3. **`feat/topic`**: Isolated branches for specific task development.

*For more details, see our [Workflow Documentation](./WORKFLOW.md).*

