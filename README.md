# YDNS Updater

Updates your YDNS hosts.

## What's new?

- Support for the current YDNS API.
- Support for IPv4 and IPv6 addresses.
- Addition of a new interactive mode intended for one-off use cases.
- Usage of the Ipify API to retrieve your public IP addresses.
- Feedback for each host individually during the update process.
- Revision of the usage options, improvements to output formatting and colors for better readability.
- Improvement and expansion of the ydns_lastip file, including file checks and auto creation logic.
- Restructuring, refactoring and other improvements.


## Installation:

1. Place the script where you want it and make it executable (chmod +x updater.sh).
2. Edit the script to enter your personal configuration (credentials, hosts) in the specified section at the top of the script (only necessary for cronjob).
3. Run the script:
- Manually via the command line. Show options with -h.
- In interactive mode (option -i).
- Using a cronjob for automatic execution (recommended)


## License:
The code is licensed under the GNU Public License, version 3.
