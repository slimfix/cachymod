# POC Extra Utilities (Deprecated)

The Piece-Of-Cake (POC) selector patch has been dropped from CachyMod to keep EEVDF closer to upstream while eliminating bitmap tracking overhead.

It has been replaced by the lightweight **`taskmod`** utility (located in the `sched-smt/` directory), which delivers comparable gaming performance via `kernel.sched_idlecore_enabled`.

## 🚀 Migration & Uninstallation

### 1. Remove Legacy POC Utilities

Run the uninstaller in this directory to remove the old `/usr/local/bin/poc*` scripts and clean up `/etc/sudoers.d/90-poc-custom`:

```bash
sudo ./uninstall-poc.sh
```

### 2. Switch to `taskmod` (Optional)

If you still want full idle-core prioritization for gaming, install the new wrapper from `../sched-smt/` and update your **Steam Launch Options**:

- **Old:** `poc-sticky %command%` or `poc-smt -d %command%`
- **New:** `taskmod -d %command%`

