# Diagnostic Tool for a Device

This is a diagnostic tool that can be used to help diagnose problems
with devices. It must be run as root because it needs to access
network, and TLS keys and in general secure directories.

## How to Get It

The script is available in the lmp-tools repo. To downloaded and setup:

```
wget https://raw.githubusercontent.com/foundriesio/lmp-tools/master/device-scripts/diag.sh
chmod 755 diag.sh
sudo -s
```

## How To Run It

The script can be placed in any location on a device typically in either `root/` or `fio/`.

The recommended way to execute it is:

```
# ./diag.sh | tee results.txt
```

## Results

The results will have headers that start with 3 asterisks. The current version of the script
(1.0) has the following headings:

- *** diag tool version ***
- *** os-release ***
- *** current_target *** (if registered)
- *** sota.toml *** (if registered)
- *** active networks ***
- *** Name servers ***
- *** iptable configuration ***
- *** /var/sota content ***
- *** checking [HSM | HSM+EL2GO] certs *** (if registered)
- *** requested device name *** (if registered)
- *** not registered import version *** (if not registered)
- *** Aktualizr-lite status ***
- *** fioconfig status ***
- *** Docker images ***
- *** Docker containers ***
- *** Docker usage *** (storage)
- *** Number of zero length files in /var/lib/docker ***
- *** sha256sum of /var/sota/reset-apps ***
- *** Domain access check ***
- *** domain latency *** (if names are resolved)
- *** domain access error no latency *** (if one or more did not ping)
- *** speed test *** (if argument -s | --speedtest)

