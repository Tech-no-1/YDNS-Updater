# YDNS Updater Script


Updates your YDNS hosts. It is highly recommended to use this script with a cronjob to run it automatically.


## What's new?

- Support for current YDNS API
- Support for IPv4 and IPv6 addresses 
- Uses the Ipify API to retrieve public IP addresses
- Revision of the usage options, output and YDNS_LASTIP file
- Code cleanup, updates and fixes


## Installation:

1. Place the script where you want it and make it executable (chmod +x updater.sh)

2. Edit the script to include your YDNS API credentials, host(s), and the path to the local YDNS_LASTIP file (mandatory for cronjob only)

3. Run the script: 	- Manually via the command line. Show options: -h
			- Via cronjob for automatic execution (recommended)


## License:

The code is licensed under the GNU Public License, version 3.