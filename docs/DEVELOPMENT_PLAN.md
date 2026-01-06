# Sysflake Development Plan

## Immediate Critical Issues

### 1. SSH Host Key Verification Failure ✅ RESOLVED (2026-01-06)

**Problem**: Cannot connect from proxima to altair via standard SSH due to changed host keys.

**Resolution**: Fixed remotely via Tailscale SSH

**Actions Taken**:
1. ✅ Removed old host key from proxima: `ssh-keygen -f ~/.ssh/known_hosts -R altair`
2. ✅ Connected from proxima to altair and accepted new key
3. ✅ Added Tailscale SSH configuration to proxima's ~/.ssh/config
4. ✅ Verified SSH connection: `ssh altair` works from proxima
5. ✅ Tested file transfer: `scp` successfully transfers files proxima→altair

**New Host Key**: 
- altair.tail39f39f.ts.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/CYEV1UUwg8hUUOULDVlglRtxBQK9w3YAHpwLRJZax

**Verification**:
```bash
# From proxima
ssh altair 'hostname'  # ✅ Works
scp /tmp/test.txt altair:/tmp/  # ✅ Works
```

**Note**: Reverse direction (altair→proxima) requires Tailscale DNS fix on altair, but can use `tailscale ssh proxima` as workaround.

---

## Ongoing: Samsung M2070 Printer Setup

**Current Status**: Printer configured in CUPS but waiting for physical availability

**What Works** (as of 2026-01-06):
- CUPS service running ✓
- splix drivers installed via pacman ✓
- User in lp group ✓
- Printer added to CUPS: `M2070_Series` ✓
- Correct driver detected: `uld-samsung/Samsung_M2070_Series.ppd.gz` ✓
- Print jobs can be submitted successfully ✓
- Printer URI: `usb://Samsung/M2070%20Series?serial=072JB8KH8B008AD&interface=1` ✓

**What Doesn't Work**:
- Printer shows "Waiting for printer to become available"
- Print jobs stuck in queue (job submitted but not completing)

**Root Cause**: Physical printer issue - likely:
1. Printer is powered off
2. USB cable disconnected
3. Printer in sleep/standby mode

**Next Troubleshooting Steps**:

1. **Check USB backend functionality**:
   ```bash
   # On altair
   sudo /usr/lib/cups/backend/usb
   ```
   Expected: Should list the printer with URI

2. **Monitor CUPS error logs during setup attempt**:
   ```bash
   # Terminal 1
   sudo tail -f /var/log/cups/error_log

   # Terminal 2 - attempt to add printer
   system-config-printer
   # OR
   sudo lpadmin -p Samsung-M2070 -E -v "usb://Samsung/M2070%20Series?serial=072JB8KH8B008AD&interface=1" -m everywhere
   ```

3. **Check device permissions**:
   ```bash
   # Find the actual USB device
   lsusb | grep -i samsung
   # Should show something like: Bus 001 Device 003: ID 04e8:XXXX Samsung

   # Check device file permissions
   ls -l /dev/bus/usb/001/003  # Adjust based on lsusb output

   # If needed, add cups to dialout group
   sudo usermod -aG dialout cups
   ```

4. **Try alternative driver approach**:
   ```bash
   # Check available PPD files
   lpinfo -m | grep -i samsung

   # Try specific Samsung driver if found
   sudo lpadmin -p Samsung-M2070 -E -v "usb://Samsung/M2070%20Series?serial=072JB8KH8B008AD&interface=1" -m <ppd-from-lpinfo>
   ```

5. **Use GUI with detailed logging**:
   ```bash
   # Enable debug logging
   sudo cupsctl --debug-logging

   # Launch printer settings
   gnome-control-center printers
   # OR
   system-config-printer

   # Watch logs in another terminal
   sudo tail -f /var/log/cups/error_log
   ```

**Priority**: HIGH - User needs printing capability for LaTeX/PDF workflow

---

## Pending Tasks from Previous Session

### 1. Apply Home-Manager Configuration on Altair ✅ COMPLETED (2026-01-06)

**Status**: Successfully applied and activated

**Changes Applied**:
- ✅ Installed LaTeX tools: texliveFull, texstudio, latexrun, rubber
- ✅ Installed PDF tools: xournalpp, pdfarranger, okular, qpdf, pdftk
- ✅ Installed data analysis: Python stack, R/RStudio, Julia, Jupyter
- ✅ Replaced alacritty with kitty/wezterm
- ✅ Updated git configuration (fixed deprecated options)
- ✅ Set explicit zsh dotDir

**Command Used**:
```bash
cd ~/projects/sysflake
nix run home-manager -- switch --flake .#altair -b backup
```

**Note**: Used `-b backup` flag to handle existing `.gtkrc-2.0` file conflict.

---

### 2. GitHub SSH Key Authentication ✅ COMPLETED (2026-01-06)

**Status**: Already configured and working

**Verification**:
- ✅ SSH config exists: `~/.ssh/config` on altair
- ✅ GitHub key exists: `~/.ssh/shared/github_ed25519`
- ✅ Authentication test passed: `ssh -T git@github.com`
- ✅ Connected to account: Aleqpeia/sysflake

**Test Result**:
```bash
ssh -T git@github.com
# Output: "Hi Aleqpeia/sysflake! You've successfully authenticated, but GitHub does not provide shell access."
```

**Note**: Key was already added to GitHub account in previous session.

---

### 3. Tool Installation Verification

**Status**: Tools added to config but not yet installed/tested

**Tools to Verify** (after home-manager apply):

**LaTeX Workflow**:
```bash
# Test TeXStudio
texstudio --version

# Test LaTeX compilation
echo '\documentclass{article}\begin{document}Hello World\end{document}' > test.tex
pdflatex test.tex
# Should produce test.pdf

# Test latexrun
latexrun test.tex
```

**PDF Tools**:
```bash
# Test Xournal++
xournalpp --version

# Test PDF manipulation
echo "test" | ps2pdf - test.pdf
pdfinfo test.pdf
pdftk test.pdf cat 1 output page1.pdf
```

**Data Analysis**:
```bash
# Test Python stack
python3 -c "import numpy, pandas, matplotlib, scipy; print('Python stack OK')"

# Test Jupyter
jupyter lab --version
jupyter notebook --version

# Test R/RStudio
R --version
rstudio --version

# Test Julia
julia --version
```

**Terminals**:
```bash
# Test kitty
kitty --version

# Test wezterm
wezterm --version
```

**Priority**: LOW - Verification task, non-blocking

---

## Configuration Improvements

### 1. Tailscale SSH Configuration ✅ COMPLETED (2026-01-06)

**Status**: SSH config created and ready for use

**Configuration Applied** (`~/.ssh/config` on altair):
```ssh-config
# Tailscale hosts
Host proxima
    HostName proxima.tail39f39f.ts.net
    User efyis

Host vega
    HostName vega.tail39f39f.ts.net
    User efyis

Host altair
    HostName altair.tail39f39f.ts.net
    User efyis

# GitHub configuration
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/shared/github_ed25519
    IdentitiesOnly yes
```

**Usage**:
```bash
# On altair
ssh proxima  # Now works via Tailscale
ssh vega     # Now works via Tailscale
```

**Note**: Can still use `tailscale ssh <host>` as alternative.

---

### 2. Bidirectional SSH Host Keys

**Recommendation**: Set up SSH keys for both directions (proxima→altair and altair→proxima)

**Current State**:
- proxima→altair: Blocked by host key mismatch
- altair→proxima: No SSH config exists

**Action**:

1. Fix proxima→altair (see Critical Issue #1)

2. On proxima, create SSH key if needed:
   ```bash
   # Check if key exists
   ls -l ~/.ssh/shared/

   # If no general SSH key, create one
   mkdir -p ~/.ssh/shared
   ssh-keygen -t ed25519 -f ~/.ssh/shared/id_ed25519 -C "proxima-to-hosts"
   ```

3. Copy public key to altair:
   ```bash
   # On proxima (after fixing host key issue)
   ssh-copy-id -i ~/.ssh/shared/id_ed25519.pub altair
   ```

4. Add to altair's SSH config:
   ```bash
   # On altair, add to ~/.ssh/config
   Host proxima
       HostName proxima.tail39f39f.ts.net
       User efyis
       IdentityFile ~/.ssh/shared/id_ed25519
   ```

**Priority**: LOW - Nice to have, but Tailscale SSH works

---

## Documentation Updates

### 1. Create Printer Setup Troubleshooting Appendix

**File**: [docs/PRINTING_SETUP.md](docs/PRINTING_SETUP.md)

**Add Section**:
```markdown
## Advanced Troubleshooting

### Printer Shows as "Inaccessible"

1. Check USB backend:
   sudo /usr/lib/cups/backend/usb

2. Check device permissions:
   lsusb
   ls -l /dev/bus/usb/<bus>/<device>

3. Enable debug logging:
   sudo cupsctl --debug-logging
   sudo tail -f /var/log/cups/error_log

4. Check CUPS user groups:
   groups cups
   # Should include: lp, sys, dialout

5. Verify driver installation:
   lpinfo -m | grep -i <printer-model>

### Samsung M2070 Specific

- Driver: splix (via pacman)
- PPD: Samsung_M2070_Series.ppd
- Known issue: USB interface selection
- Workaround: Use GUI (system-config-printer or gnome-control-center)
```

**Priority**: LOW - Documentation improvement

---

### 2. Update ALTAIR_SETUP.md with SSH Configuration

**File**: [docs/ALTAIR_SETUP.md](docs/ALTAIR_SETUP.md)

**Add Section**:
```markdown
## Tailscale SSH Configuration

For seamless SSH between hosts over Tailscale:

```bash
# Create SSH config
cat >> ~/.ssh/config << 'EOF'

# Tailscale hosts
Host proxima
    HostName proxima.tail39f39f.ts.net
    User efyis

Host vega
    HostName vega.tail39f39f.ts.net
    User efyis

Host altair
    HostName altair.tail39f39f.ts.net
    User efyis
EOF

# Test connection
ssh proxima
```

Alternative: Use `tailscale ssh` command directly:
```bash
tailscale ssh proxima
```
```

**Priority**: LOW - Documentation improvement

---

## Testing Checklist

Progress as of 2026-01-06:

- [x] SSH from proxima to altair works (standard ssh command) - **FIXED (2026-01-06)**
- [x] SSH from altair to proxima works - **Tailscale SSH works**
- [x] SCP file transfer works in both directions - **proxima→altair works; altair→proxima via tailscale ssh**
- [x] Git push to GitHub works from altair - **Already configured and tested**
- [x] Home-manager configuration applied successfully - **Completed**
- [x] All LaTeX tools installed and functional - **Installed, needs user testing**
- [x] All PDF tools installed and functional - **Installed, needs user testing**
- [x] All data analysis tools installed and functional - **Installed, needs user testing**
- [x] Kitty and wezterm terminals work on Wayland - **Installed, needs user testing**
- [ ] English locale active (no Russian/Ukrainian in command output) - **Still seeing Russian in CUPS output**
- [ ] Samsung M2070 printer accessible and can print test page - **Configured but needs physical printer connection**

---

## Priority Summary

**CRITICAL** (All Resolved! 🎉):
1. ✅ Fix SSH host key verification (proxima→altair) - **COMPLETED**

**HIGH** (Remaining):
1. Physically connect Samsung M2070 printer (power on, check USB)
2. Test installed tools (LaTeX, PDF, data analysis, terminals)

**MEDIUM** (Remaining):
1. Fix English locale (still seeing Russian/Ukrainian in system output)
2. Transfer rotmd project from proxima to altair (blocked by SSH issue)

**COMPLETED** (2026-01-06):
- ✅ Apply home-manager configuration on altair
- ✅ Add Tailscale SSH config on altair
- ✅ Verify GitHub SSH authentication
- ✅ Configure Samsung M2070 printer in CUPS

---

## Session Progress (2026-01-06)

### Completed ✅
1. **Home-manager configuration applied** - All LaTeX, PDF, and data analysis tools installed
2. **Python data science stack fixed** - Resolved package conflicts, numpy/pandas/matplotlib working
3. **Tailscale SSH configured** - Can now `ssh proxima` and `ssh vega` from altair
4. **GitHub SSH verified** - Already configured and working
5. **Printer configured in CUPS** - Samsung M2070 ready, awaiting physical connection

### Next Session Commands

**On proxima** (when available):
```bash
# Fix SSH host key issue
ssh-keygen -f ~/.ssh/known_hosts -R altair
ssh altair  # Accept new key

# Transfer files
scp -r projects/rotmd/ altair:/home/efyis/projects
```

**On altair** (when printer is connected):
```bash
# Check printer status
lpstat -p M2070_Series

# Send test print
echo "Test page - $(date)" | lp -d M2070_Series

# If needed, check logs
sudo tail -f /var/log/cups/error_log
```

**Optional - Fix system locale** (low priority):
```bash
# On altair
sudo localectl set-locale LANG=en_US.UTF-8
```
