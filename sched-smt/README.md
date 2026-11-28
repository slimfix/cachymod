# Scheduler SMT Control (`taskmod`)

This directory contains a lightweight wrapper utility designed to toggle CachyMod's **Prefer Idle Core** (`kernel.sched_idlecore_enabled`) and **Relax Asymmetric Active Balance** (`kernel.sched_relax_asym_enabled`) scheduler features, as well as optionally pin workloads to specific CPU lists (`-c`).

- **`taskmod -e`** *(Default)*: Prefers SMT sibling scheduling / mainline EEVDF behavior (`kernel.sched_idlecore_enabled = 0`) for high multi-threaded throughput and power efficiency.
- **`taskmod -d`**: Disables SMT sibling preference on wakeup and asymmetric active load balancing (`kernel.sched_idlecore_enabled = 1`), prioritizing completely idle physical cores to eliminate hyper-threading contention and boost gaming frame rates.
- **`taskmod -r` / `--relax-asym`**: Skips cross-core and cross-CCD asymmetric active load balancing (`kernel.sched_relax_asym_enabled = 1`) for all tasks (including unpinned workloads), preventing stop-machine migration spikes while preserving primary SMT sibling preference. Use `-n` / `--no-relax-asym` to restore default behavior (`0`).
- **`taskmod -c <cpu-list>`**: Expands comma-separated CPUs, ranges (`start-end`), and strides (`start-end:step`), exporting `WINE_CPU_TOPOLOGY` in exact specified order and wrapping execution with `taskset -c`.

## 🚀 Installation & Uninstallation

### Install

Run the installation script to copy `taskmod` to `/usr/local/bin/` and configure passwordless `sudo` access for toggling `kernel.sched_idlecore_enabled` and `kernel.sched_relax_asym_enabled` via `/etc/sudoers.d/90-taskmod`:

```bash
sudo ./install.sh
```

### Uninstall

To remove `/usr/local/bin/taskmod` and `/etc/sudoers.d/90-taskmod`:

```bash
sudo ./uninstall.sh
```

## 📖 Usage Examples

### Manual Toggling & Topology Preview

- **View current status:** `taskmod`
- **Prefer SMT siblings (default):** `taskmod -e` or `taskmod --enable`
- **Prefer full idle physical cores:** `taskmod -d` or `taskmod --disable`
- **Relax cross-core asymmetric active balance:** `taskmod -r` or `taskmod --relax-asym`
- **Restore default asymmetric active balance:** `taskmod -n` or `taskmod --no-relax-asym`
- **Preview expanded `WINE_CPU_TOPOLOGY`:**
  ```bash
  taskmod -c 0-5,24-29,12-17:2
  # Output: WINE_CPU_TOPOLOGY=15:0,1,2,3,4,5,24,25,26,27,28,29,12,14,16
  ```

### 🎮 Steam Launch Options (Gaming)

Apply scheduler tuning dynamically on a per-game basis without leaving it enabled globally on the desktop. Right-click a game in Steam ➔ **Properties** ➔ **Launch Options**:

```text
# Recommended starting point (all CPUs, unpinned — eliminates mid-frame asym pulls)
taskmod -r %command%

# High-core-count CPUs (12–24+ cores) or extra protection against SMT contention
taskmod -d -r %command%
# or bundled:
taskmod -dr %command%
```

To restrict a game to specific CCDs on multi-CCD processors (preserving primary-first core ordering for Wine/Proton and applying `taskset -c` for native Linux binaries—where `0290` automatically protects pinned threads without needing `-r`):

```text
# 3 CCDs on a 24C/48T Threadripper (CCDs 0, 2, 3; leaving CCD 1 for OS/drivers)
taskmod -d -c 0-5,24-29,12-17,36-41,18-23,42-47 %command%

# 2 CCDs with default SMT mode (-e)
taskmod -c 0-5,24-29,12-17,36-41 %command%
```

`taskmod` automatically applies the requested setting(s) when the game launches and restores your previous system state the moment the game exits. If you boot into a kernel without these sysctl knobs, it still applies `WINE_CPU_TOPOLOGY` and `taskset -c` and runs the game normally.

### 🧮 Server & Compute Workloads

For latency-sensitive or heavy simulation jobs that benefit from uncontended physical cores or primary-sibling pinning:

```bash
taskmod -d ./my-simulation-job
taskmod -c 0-23 ./my-simulation-job
```

