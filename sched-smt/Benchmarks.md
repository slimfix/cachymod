# CachyMod Scheduler Benchmarks (`0270`–`0290` Trio)

This document compares stock **CachyOS 7.3.6** against **CachyMod 7.3.6** with the three-patch scheduler series applied:

- **`0270-deprioritize-smt-itmt`**: Applies a `-42` ITMT/CPPC priority offset to secondary SMT siblings so physical cores are saturated first while preserving intra-CCD L3 cache locality on multi-CCD processors.
- **`0280-prefer-idle-core`**: Adds `kernel.sched_idlecore_enabled` (`0` by default; toggled via `taskmod -d` / `taskmod -e`) to keep wakeups on cache-hot idle physical cores and require idle cores during asymmetric active balancing.
- **`0290-relax-asym-active-balance`**: Automatically skips cross-core and cross-CCD `asym_active_balance()` migrations for tasks with restricted CPU affinity (`taskset`, `WINE_CPU_TOPOLOGY`, etc.) and adds `kernel.sched_relax_asym_enabled` (`0` by default; toggled via `taskmod -r` / `--relax-asym`) to extend this relaxation to unpinned workloads on both SMT and non-SMT configurations.

---

## 1. Parallel Compute (`algorithm3.pl` Prime Sieve)

Workload: [`algorithm3.pl`](https://github.com/marioroy/mce-sandbox) parallel prime sieve.

### Multi-CCD: AMD Ryzen Threadripper 9960X (24C/48T, 4 CCDs)

Command: `algorithm3.pl 1e12 --threads=20`

| Mode | CachyOS (Default) | CachyMod (Patched) | Delta |
| :--- | :---: | :---: | :---: |
| **Unpinned** | 15.133s | **13.107s** | **-2.026s (-13.4%)** |
| **Pinned primary (`taskset -c 0-23`)** | 17.323s *(+2.19s regression)* | **12.567s** | **-4.756s (-27.5%)** |
| **Idle-core mode (`taskmod -d`)** | — | **12.421s** | — |
| **1:1 per-core bound (`--procbind`)** | 12.391s | **12.357s** | **-0.034s (-0.3%)** |

### Single-CCD: AMD Ryzen 7 9800X3D (8C/16T, 1 CCD)

Command: `algorithm3.pl 5e11 --threads=5`

| Mode | CachyOS (Default) | CachyMod (Patched) | Delta |
| :--- | :---: | :---: | :---: |
| **Unpinned** | 27.354s | **27.014s** | **-0.340s (-1.2%)** |
| **Pinned primary (`taskset -c 0-7`)** | 27.000s | **26.467s** | **-0.533s (-2.0%)** |
| **Idle-core mode (`taskmod -d`)** | — | **26.422s** | — |
| **1:1 per-core bound (`--procbind`)** | 26.345s | **26.326s** | **-0.019s (-0.1%)** |

---

## 2. Unpinned Gaming Benchmarks (Threadripper 9960X, 4 CCDs)

Test system: **AMD Ryzen Threadripper 9960X (24C/48T, 4 CCDs)** + **AMD Radeon AI PRO R9700 (RADV GFX1201)**, running completely unpinned across all 48 logical CPUs (`nr_cpus_allowed == 48`).

- **`taskmod -e`**: `idlecore=0, relax_asym=0` (default)
- **`taskmod -d`**: `idlecore=1, relax_asym=0`
- **`taskmod -r`**: `idlecore=0, relax_asym=1`
- **`taskmod -d -r`** *(or `taskmod -dr`)*: `idlecore=1, relax_asym=1`

### Summary Across Unpinned Titles (`taskmod -d -r`)

Without manual CPU masks, `taskmod -d -r` eliminates cross-CCD `asym_active_balance()` preemption spikes across all 4 CCDs—allowing multi-CCD-friendly game engines to scale across all 24 physical cores with zero manual topology configuration. *(Barrier-heavy engines like REDengine 4 in Cyberpunk 2077 still benefit most from 2-CCD pinning; see Section 3.)*

| Game (Unpinned, 4 CCDs) | Metric | Stock `cachyos` *(Pinned)* | CachyMod (`taskmod -d -r` Unpinned) | Gain |
| :--- | :--- | :---: | :---: | :---: |
| ***Shadow of the Tomb Raider*** *(Native)* | **Avg / Min FPS** | 374 / 241 *(Unpinned)* | **433 / 314** | **+15.8% Avg / +30.3% Min** |
| ***Horizon Zero Dawn Remastered*** *(Wine)* | **Avg / Min / GPU FPS** | 376 / 182 / 451 *(3 CCDs)* | **417 / 212 / 514** | **+10.9% Avg / +16.5% Min** |
| ***Forza Horizon 6*** *(Wine)* | **CPU Sim Avg / 1% / Stutters** | 277.5 / 205.1 / 15 *(2 CCDs)* | **335.8 / 234.5 / 12** | **+21.0% Avg / +14.3% 1% Low** |

---

## 3. Pinned Multi-CCD Gaming Benchmarks (Threadripper 9960X)

For engines with tightly coupled barrier synchronization across worker threads (such as REDengine 4 in *Cyberpunk 2077*), confining threads to 2 or 3 CCDs via `taskmod -c` keeps synchronization inside fewer L3 caches. `0290` automatically skips non-SMT `asym_active_balance()` for the pinned game threads (`nr_cpus_allowed < 48`), while `0270` prioritizes primary physical cores over SMT siblings inside each assigned CCD.

### Topology Masks Used

- **3 CCDs (36 threads — CCDs 0, 2, 3; leaving CCD 1 free for OS/drivers):**
  ```bash
  taskmod -d -c 0-5,24-29,12-17,36-41,18-23,42-47 %command%
  ```

- **2 CCDs (24 threads — CCDs 0, 2; leaving CCDs 1 & 3 free for OS/drivers):**
  ```bash
  taskmod -d -c 0-5,24-29,12-17,36-41 %command%
  ```

### Summary Across Pinned Titles

| Game & Topology | Metric | `cachyos` | `-e` | `-d` | `-d -r` | Best Gain vs. `cachyos` |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| ***Shadow of the Tomb Raider*** *(Native, 3 CCDs)* | **Avg / Min FPS** | 362 / 220 | 427 / 307 | **432 / 318** | 427 / 305 | **+19.3% Avg / +44.5% Min** |
| ***Horizon Zero Dawn Remastered*** *(Wine, 3 CCDs)* | **Avg / 1% Low** | 376 / 127 | **413 / 142** | 411 / 138 | 408 / 135 | **+9.8% Avg / +11.8% 1% Low** |
| ***Forza Horizon 6*** *(Wine, 2 CCDs)* | **CPU Sim Avg / 1% / Stutters** | 277.5 / 205.1 / 15 | 297.4 / 221.9 / 14 | **302.3** / 221.2 / 18 | 302.1 / **222.8 / 12** | **+9.4% Avg / +8.6% 1% Low** |
| ***Cyberpunk 2077*** *(Wine, 2 CCDs)* | **Avg / Min FPS** | 403.30 / 330.20 | 417.41 / 346.31 | **423.70 / 356.79** | 414.88 / 345.66 | **+5.1% Avg / +8.1% Min** |

