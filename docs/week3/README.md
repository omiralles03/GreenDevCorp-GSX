# Process Management & Resource Control (Week 3)

This weeks objectives were:

1. Process Inspection: How do you discover what’s running on a system? Where do you look, and
what tools are available?
2. Resource Usage: How do you identify which processes consume CPU, memory, or I/O? What’s
normal, and what’s concerning?
3. Process Control: How do you influence process behavior (pause, resume, kill, change priority)
without rebooting?
4. Resource Limits: How do you prevent one runaway process from taking down the entire system?
5. Service Resilience: How can your service (from Week 2) signal gracefully and handle resource
constraints?

## Project Architecture

1. **Monitoring Tool**:
   * We developed an CLI Tool in Go that reads directly from the `/proc` folder to get the system metrics.
   * `main.go`: manages the arguments (flag parsing).
   * `process.go`: implements the logic for reading and calculating the CPU and Memory from `/proc/[pid]/stat` and `/proc/[pid]/status`.
   * `tree.go`: builds the Process Tree using a map recursively.
   * `display.go`: small logic for formatting information on display.

2. **Resource Limiting**:
   * We created a service (`limitd`) that executes an intensive CPU task (`yes`).
   * We apply limits with systemd configuration that invokes cgroups to limit the CPU and Memory usage before the OOM Killer takes place.

3. **Workload**:
   * A simple script that redirects `yes` to `/dev/null` and waits for a signal on an infinite loop to catch the different signals and see their behaviour.

## Design Decisions

* **Language Choice**: we decided Go was a fast and simple language to compile static binaries for CLI tool development.
* **Direct `/proc` reading**: instead of using `ps` or `top`, we decided to read directly from the kernel files, which allowed us to learn more in depth how Linux stores this information and how those tools use it.
* **OOM Killer Testing**: we decided to generate an exponencial usage of CPU to demonstrate and validate our `limitd` service.


## Hints and Questions to Guide Your Thinking

* **How is killing a process with `SIGTERM` different from `SIGKILL` ? When would you use each?**

  `SIGTERM` is a greacefull signal that can be caught by the process and it terminates it while saving it's state.
  `SIGKILL` is an immediate Kernel order that is not gracefull and can not be caught nor ignored and it terminates immediatelly the process without caring about it's state.

* **If your service receives a signal, how should it respond? Should it save state before exiting?**

  It traps the signal and uses a cleanup function to kill all subprocesses childs before exiting, which avoids leaving Zombie Processes.

* **How do you verify that a resource limit is actually working? (Can you create a test that would fail
without the limit?)**

  With our `test_limitd.sh` we force an OOM Kill and we can see with `systemctl status` that the service goes from `active` to `failed` by oom-kill when reaching the `60MB` limit.

* **If a developer’s job is using 90% CPU, is that a problem? How do you decide?**

  Depends on the metric. If the 90% of CPU is relative to all cores it may not be a problem, but if it is relative to the whole CPU usage then it becomes a problem.
  If the `loadavg` was higher than the total CPU cores, then the new processes would be waiting for that process to end, which would slow down the server by a lot.
  To avoid this we would limit the CPU usage for a developer, so if they exceeded it, instead of forcefully killing it and potentially lose the developers work, it would keep working but way slower.
