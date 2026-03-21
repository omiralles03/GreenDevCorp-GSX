# Infrastructure Setup and Automation (Week 1)

This weeks objectives were:

1. Remote Access: enable remote access via SSH for administration.
2. Privilege Escalation: structure admin users privileges and disable root access.
3. Version Control: use Git to track system configuration.
4. Automation: write shell scripts that set up the administrative environment, securing safety and repetability.
5. Documentation: display the decisions we made and why.

## Project Architecture

1.  **Virtualization Layer (`setup_vbox.sh`)**: 
    * Automates VM creation, hardware provisioning, and unattended Debian installation.
    * Sets up a **NAT Port Forwarding** (default port `2222`) to allow SSH access from the host.
    * Mounts a **Shared Folder** (`gsx_share`) which acts as a **Bootstrap Volume** for configuration scripts.

2.  **Configuration Layer (`run_setup_system.sh`)**:
    * Utilizes VirtualBox CLI **Guest Control** to execute commands inside the VM without requiring a manual login.
    * **User administration**: Creates administrative accounts (`admin1`, `admin2`) and assigns sudo privileges.
    * **SSH Key Injection**: Iterates through `keys/*.pub`, mapping public keys to users based on filename prefixes (e.g., `admin1_laptop.pub` -> `admin1`).
    * **Hardening**: Disables password authentication and root login via `ssh_setup.sh`.
    * **Guest Control** is only used for the bootstrap, during the VMs lifecycle all operations are performed via SSH (reason why only `setup_vbox.sh` and `run_setup_system` use VBoxManage).

## Design Decisions

1. **SSH**:
    * We ensure SSH connections are safer with the following rules:
        * **PasswordAuthentication** `no`
        * **PubkeyAuthentication** `yes`
        * **PermitRootLogin** `no`
    * This allows to track properly who performed and action with elevated privileges, and without password-based authentication we ensure only users with a private key can attempt the login.

2. **Privileges**:
    * We leaned to a per-user directory structure in `/opt/user-admin/{scripts, backups, configs}`.
    * This allows us to set the directory's ownership to sudo users and keep an organized structure.

3. **VBOX**:
    * We decided to automate the VM creation, although it was not mandatory, for three reasons:
        1. **Idempotency**: we can recreate the enviroment at any given time with just a few minutes. If we mess up a configuration or a script during testing we can just revert to initial state with snapshots, but when we need to operate on a different machine, this saves us a lot of time by just running a script.
        2. **Consistency**: we ensure both members will always work on the same hardware profiles on any machine.
        3. **Learning**: we simulate and learn how a more real DevOps approach would look like and apply the Infrastructure as Code philosophy.

4. **Root Locking**:
    * We lock the root account during the setup.
    * This prevents unauthenticated console logins againts attackers.
    * We ensure no untracked changes are made via the root account.

5. **Key Naming**:
    * We enforced a `username_device.pub` naming convention in the `/keys` folder.
    * This allows us to have an organized folder to know who has access to the VM and maintain multiple devices for a single user.
    * Our script automatically parses the target user with this syntax.

6. **Logs**:
    * Each script has logging functions to allow a more precise feedback on what is going on during the execution:
    ``` bash
    log() { echo -e "${B}[$(date +%T)]${NC} $1\n"; }
    error() { echo -e "${R}[ERROR]${NC} $1\n"; exit 1; }
    info() { echo -e "${B}[INFO]${NC} $1\n"; }
    success() { echo -e "${G}[SUCCESS]${NC} $1\n"; }
    warning() { echo -e "${Y}[WARNING]${NC} $1\n"; }

    # Wrapper for VBoxManage
    vrun() {
        local out
        if ! out=$(VBoxManage "$@" 2>&1); then
            echo -e "${R}[VBOX ERROR]${NC} ${out#*error: }"
            exit 1
        fi
        echo "$out" | grep -v "0%...10%" || true # Hide progress clutter
    }
    ```
    * The messages take a text as an argument and prints them with the desired format.
    * With this we can alter the behaviour depending on the action.
    * e.g `error` exits with 1. `log` could redirect message with a date to a log file.
    * `vrun` acts as a wrapper for VBoxManage commands to intercept any errors and keep them clean for CI/CD readability.


### Prerequisites
* VirtualBox 7.x installed.
* A Debian `netinst` ISO located in the path specified in `.env`.
* SSH public keys placed in the `/keys` directory following the naming convention `username_device.pub`.

### Deployment
1. Copy `scripts/env` to `scripts/.env` and fill in your local paths.
2. Run the main script if deploying for first time:
   ```bash
   chmod +x scripts/*.sh
   ./scripts/setup_vbox.sh
   ```
3. Run the desired script for any other config if VM is already setup:
   ```bash
   chmod +x scripts/*.sh
   ./scripts/DESIRED_SCRIPT.sh
   ```
## Hints and Questions to Guide Your Thinking

* **What are the security implications of using passwords vs. keys for SSH?**

   SSH keys are impossible to decrypt by burte force compared to regular passwords, and so, enabling `PasswordAuthentication` allows us to harden the security. With the naming convention for the keys we can also identify who and which deviced was used to establish the connection.
  
* **If you have to reinstall the system, can your scripts restore the entire configuration? If not, what’s
missing?**

   With our `setup_vbox.sh` and `run_setup_system.sh` we are able to replicate the work environment in just a few minutes on any machine. The only thing that is left are backups and user generated files.

* **How would you prevent both team members from accidentally running the same setup script at the
same time?**

   We would probably use a lock file that would verify if the file exist and stop the installation processes for the new process that would have invoked it.

* **What information should be in Git, and what should only live on the server (why)?**

   On Git we would have anything code-related like scripts, config files, documents... In the server, only secret keys or passwords and local files like logs, backups or user generated files that are not part of the core architecture of the server.
