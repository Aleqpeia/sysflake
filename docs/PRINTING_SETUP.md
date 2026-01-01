# CUPS Printing Setup on EndevourOS (altair)

## Overview

Your altair configuration now includes:
- CUPS (Common Unix Printing System)
- system-config-printer (GUI for printer management)
- Samba support for Windows/network printer sharing

## Initial Setup

### 1. Enable CUPS Service

On EndevourOS (non-NixOS), you need to enable the CUPS service through systemd:

```bash
# Enable and start CUPS
sudo systemctl enable cups.service
sudo systemctl start cups.service

# Check status
sudo systemctl status cups
```

### 2. Install System Packages

Since you're on EndevourOS (Arch-based), install CUPS system packages:

```bash
# Install CUPS and drivers
sudo pacman -S cups cups-pdf

# Common printer drivers
sudo pacman -S \
  hplip \              # HP printers
  gutenprint \         # Wide driver support
  foomatic-db \        # Driver database
  foomatic-db-engine \ # Driver engine
  foomatic-db-nonfree  # Additional drivers

# For network/Samba printing
sudo pacman -S samba
```

### 3. Add Your User to lp Group

```bash
sudo usermod -aG lp $USER
# Log out and back in for group changes to take effect
```

## Printer Configuration

### Using GUI (Recommended)

1. Run the printer configuration tool (now available via Nix):
```bash
system-config-printer
```

2. Click "Add" to add a new printer
3. Select your printer from the detected devices
4. Follow the wizard to complete setup

### Using Web Interface

1. Open browser to: http://localhost:631
2. Navigate to "Administration" → "Add Printer"
3. Authenticate with your user credentials
4. Select and configure your printer

### Using Command Line

```bash
# List available printers
lpstat -p -d

# Print a test page
lp -d <printer-name> /usr/share/cups/data/testprint

# Set default printer
lpoptions -d <printer-name>
```

## Network Printing with Samba

### Enable Samba Printing

Edit `/etc/samba/smb.conf`:

```ini
[global]
   printing = cups
   printcap name = cups
   load printers = yes
   cups options = raw

[printers]
   comment = All Printers
   path = /var/spool/samba
   browseable = no
   guest ok = yes
   writable = no
   printable = yes
   create mode = 0700
```

Enable Samba:
```bash
sudo systemctl enable smb.service
sudo systemctl start smb.service
```

### Connect to Windows Shared Printer

Using system-config-printer:
1. Add → Network Printer → Windows Printer via SAMBA
2. Enter: `smb://workgroup/computer/printer`
3. Provide credentials if required

## Testing

### Test Local Printing

```bash
# Print a test file
echo "Test print from altair" | lp

# Print a PDF
lp document.pdf

# Print with options
lp -o sides=two-sided-long-edge document.pdf
```

### Test Network Printer

```bash
# List network printers
lpstat -a

# Print to specific network printer
lp -d network-printer document.pdf
```

## Troubleshooting

### Printer Not Detected

```bash
# Restart CUPS
sudo systemctl restart cups

# Check for errors
journalctl -u cups -f

# Check USB connection (for USB printers)
lsusb | grep -i printer
```

### Permission Issues

```bash
# Verify group membership
groups | grep lp

# Fix permissions
sudo chmod 666 /var/run/cups/cups.sock
```

### Driver Issues

```bash
# List available drivers
lpinfo -m | grep -i <printer-model>

# Check installed drivers
ls /usr/share/cups/model/
```

## Useful Commands

```bash
# List print queue
lpq

# Cancel print job
cancel <job-id>

# Cancel all jobs
cancel -a

# Printer status
lpstat -p

# Default printer
lpstat -d

# Print options for a printer
lpoptions -p <printer-name> -l
```

## PDF Printing (Virtual Printer)

The `cups-pdf` package creates a virtual printer that outputs to PDF:

- Prints save to: `~/PDF/`
- Printer name: `cups-pdf`
- Usage: `lp -d cups-pdf document.txt`

## Integration with Applications

### LaTeX/TeXStudio

TeXStudio (included in your config) will automatically detect CUPS printers.
Configure in: Options → Configure TeXStudio → Commands → External PDF Viewer

### RStudio

RStudio will use system print dialog. Print plots with:
```r
# Save plot as PDF
pdf("plot.pdf")
plot(x, y)
dev.off()

# Then print the PDF
system("lp plot.pdf")
```

### Jupyter

Print notebooks:
```bash
# Convert to PDF
jupyter nbconvert --to pdf notebook.ipynb

# Print
lp notebook.pdf
```

## Maintenance

### Check CUPS Logs

```bash
# Error log
sudo tail -f /var/log/cups/error_log

# Access log
sudo tail -f /var/log/cups/access_log
```

### Clear Print Queue

```bash
# Cancel all jobs
cancel -a

# Restart CUPS
sudo systemctl restart cups
```

## Security Notes

1. CUPS web interface is available only on localhost by default
2. For remote management, edit `/etc/cups/cupsd.conf`
3. Be cautious exposing CUPS to network
4. Use firewall rules for Samba printing:
   ```bash
   sudo ufw allow Samba
   ```

## Additional Resources

- CUPS documentation: https://www.cups.org/doc/
- ArchWiki CUPS: https://wiki.archlinux.org/title/CUPS
- Samba printing: https://wiki.archlinux.org/title/Samba#Printer_sharing
