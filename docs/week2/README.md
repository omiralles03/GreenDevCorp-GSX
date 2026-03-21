# Services, Observability & Automation (Week 2)

This weeks objectives were:

1. **Service Management:** How do modern Linux systems ensure services run reliably? What hap-
pens if a service crashes?
2. **Observability:** When a service fails, how do you diagnose what went wrong? Where are logs
stored, and how do you query them?
3. **Automatic Tasks:** How do you run backup and maintenance tasks automatically without manual
intervention?
4. **Custom Services:** Can you create your own services that integrate with the system’s service
management?
5. **Log Management:** How do you prevent logs from consuming all disk space?
   
## Project Architecture

1. **Nginx:**
  * `restart.conf`: a **Drop-In** file for the nginx service, in where if the service fails, it will automatically restart with a delay of 5 seconds.

2. **Systemd:**
  * `admin_backup.service`: a service unit of type `oneshot` that executes once the `service_backups.sh` script.
  * `admin_backup.timer`: it is configured to run daily at 05:00 AM. With the `Persistent=true`, even if the VM is powered off, the backup will run immediatelly when it powers on.

3. **Observability:**
  * `check_logs.sh`: a script that diagnoses a service (specified by parameter) using `systemctl status` and `journalctl`, with the usage of proper flags to filter the critical information for quick diagnostics.  

## Design Decisions

1. **Drop-In vs Overwriting**: we decided to use the `nginx.service.d` folder to store our Drop-In file because if any APT update where to happen, it would not get automatically overwritten as oposed to manually write our configuration on it's default file. 
2. **Journald Integration**: instead of multiple log files, we redirect the `StandardOutput` and `StandardError` to **journal** on the `admin_backup.service`, which allows us to update the backup logic wihtout having to reconfigure the service config again.

## Hints and Questions to Guide Your Thinking

* **What should happen if Nginx crashes at 3 AM? Who finds out, and how?**

  With our `restar.conf`, systemdd will be able to catch the failure and restart the server within 5 seconds, so the sysadmin does not have to be present at 3 AM, and is still able to check what happened next morning with `systemctl`.
    
* **How do you test that a service will actually restart automatically? (You can’t just wait for it to fail!)**

  We can forcefully terminate the Nginx process by identifying it's PID and kill it. With `systemctl` we can then check it's status and see that the service is running again but with a different PID.

* **If backups are failing silently, how would you know? What metrics matter?**

  By using `journalctl` we could see an error if the backup script failed with a code different than 0. With `systemctl list-timers` we can see when was the last execution of the backup and if it coincides with the LAST column at 5 AM.
   
* **How would you explain a service failure to the startup’s team using only the logs?**

  We would tell them to run our `check_logs.sh` and check for the output of the `journalctl -u <service> -p err`, which displays only the last error messages from that service.
