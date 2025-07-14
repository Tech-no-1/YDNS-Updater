#!/usr/bin/env bash
#
# YDNS updater script
#
# <https://github.com/Tech-no-1/YDNS-Updater/blob/c906c99efca772375d1c70fe10946a1d9b759599/updater.sh>
# 2025 | Tech-no-1
#
# Fork from: <https://github.com/ydns/bash-updater/blob/master/updater.sh>
# Copyright (C) 2013-2017 TFMT UG (haftungsbeschränkt) <support@ydns.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


########################################
# Please input your personal YDNS data #
########################################


# YDNS API Credentials (https://ydns.io/user/api).
USERNAME=""
SECRET=""

# List of hosts you want to update (you can update multiple hosts at once)
# For a better readability/overview, it's recommended to create a list as follows:
# YDNS_HOST="Host1
# Host2
# Host3"
YDNS_HOST=""

# Full path to your local YDNS_LASTIP file containing the last known public IP addresses of your system (optional)
# If left blank, a YDNS_LASTIP file will be created in the current directory
YDNS_LASTIP_FILE=""


####################################
# ! Do not change anything below ! #
####################################


YDNS_UPD_VERSION="2025.7.1"

# Check if curl is present
command -v curl > /dev/null 2>&1
curl_check=$?

if [ "$curl_check" -ne 0 ]; then
	echo ""
	echo "Error: Curl is NOT present. Please install it, as it is required to run the script."
    	exit 1
fi

# Usage/Help
usage () {
	echo ""
	echo "  YDNS Updater - $YDNS_UPD_VERSION"
	echo ""
	echo "  Usage: $0 [options]"
	echo ""
	echo "  Available options are:"
	echo ""
	echo "  -h                   Display usage options"
	echo "  -H HOST              Your YDNS host(s) to update"
	echo "  -u USERNAME          Your YDNS API username (for authentication)"
	echo "  -s SECRET            Your YDNS API secret (for authentication)"
	echo "  -l LAST_IP           Full path to your local YDNS_LASTIP file (optional)"
	echo "  -v                   Display version"
	echo "  -V                   Enable verbose output"
	echo ""
	exit 0
}

## Update IP addresses
## Function to update the IPv4 address
update_ip4_address () {
	retip4=

	for host in $YDNS_HOST; do
		retip4=$(curl --connect-timeout 5 --max-time 10 -u "$USERNAME:$SECRET" -s https://ydns.io/api/v1/update/?host="${host}"\&ip="${current_ip4}")
	done

# API response
	echo "$retip4" | sed -E 's/^([^[:space:]]+).*/\1/'
}

## Function to update the IPv6 address
update_ip6_address () {
        retip6=

  	for host in $YDNS_HOST; do
		retip6=$(curl --connect-timeout 5 --max-time 10 -u "$USERNAME:$SECRET" -s https://ydns.io/api/v1/update/?host="${host}"\&ip="${current_ip6}")
  	done

  	echo "$retip6" | sed -E 's/^([^[:space:]]+).*/\1/'
}

## Display version
show_version () {
	echo ""
	echo "YDNS Updater version: $YDNS_UPD_VERSION"
	exit 0
}

verbose=0
custom_host=""

# User input
while getopts "hH:l:s:u:vV" opt 2>/dev/null; do
	case $opt in
		h)
			usage
			;;

		H)
			custom_host=$OPTARG
			;;

		l)
			YDNS_LASTIP_FILE=$OPTARG
			;;
	
		s)
			SECRET=$OPTARG
			;;

		u)
			USERNAME=$OPTARG
			;;

		v)
			show_version
			;;

		V)
			verbose=1
			;;

	  	*)
	    		echo "Invalid option used"
			;;
	esac
done

# Custom Host
if [ -n "$custom_host" ]; then
	YDNS_HOST=$custom_host
fi

# Check if YDNS credentials and host(s) are specified
if [ -z "$USERNAME" ]; then
	echo ""
	echo "Error: YDNS API username missing"
    	exit 90
fi

if [ -z "$SECRET" ]; then
	echo ""
    	echo "Error: YDNS API secret missing"
    	exit 90
fi

if [ -z "$YDNS_HOST" ]; then
	echo ""
    	echo "Error: No YDNS host(s) specified"
    	exit 90
fi

# Search for YDNS_LASTIP_FILE in the current directory if no custom file path is specified.
# Create a new file if necessary
if [ -z "$YDNS_LASTIP_FILE" ]; then
	YDNS_LASTIP_FILE="$(pwd)/YDNS_LASTIP"

	if [ ! -e "$YDNS_LASTIP_FILE" ]; then
		touch "$YDNS_LASTIP_FILE"
		echo ""
		echo "Info: A new YDNS_LASTIP file has been created in the current directory."
      		echo "This file contains the last known public IP addresses of your system."
    fi
fi

## Retrieve current public IP addresses from ipify
## IPv4
if [ -z "$current_ip4" ]; then
	current_ip4=$(curl --connect-timeout 5 --max-time 15 --retry-all-errors --retry-max-time 10 -s https://api.ipify.org)

		if [ -z "$current_ip4" ]; then
		echo ""
	  	echo "Error: Unable to retrieve the current public IPv4 address. API request failed or timed out"
          	exit 91
  fi
	echo ""
  	echo "Current public IPv4 address: $current_ip4"
fi

##IPv6
if [ -z "$current_ip6" ]; then
  	current_ip6=$(curl --connect-timeout 5 --max-time 15 --retry-all-errors --retry-max-time 10 -s https://api6.ipify.org)

		if [ -z "$current_ip6" ]; then
		echo ""
	  	echo "Error: Unable to retrieve the current public IPv6 address. API request failed or timed out"
    		exit 91
  fi
	echo "Current public IPv6 address: $current_ip6"
fi

# Get last known IP addresses that where stored locally
if [ -f "$YDNS_LASTIP_FILE" ]; then
	last_ip4=$(sed -n '1p' "$YDNS_LASTIP_FILE")
        last_ip6=$(sed -n '2p' "$YDNS_LASTIP_FILE")
else
        last_ip4=""
        last_ip6=""
fi

## Compare the last known public IP addresses with the retrieved current ones.
## Call function to update host IP addresses if necessary and/or output results.
if [ "$current_ip4" != "$last_ip4" ]; then

	retip4=$(update_ip4_address)

	case "$retip4" in

	badauth)
	echo ""
	echo "IPv4 | YDNS host update failed for:"
	echo "$YDNS_HOST"
	echo ""
	echo "Authentication failed. Check your API username and secret."
    	echo ""
    	;;

    	good)
    	echo ""
    	echo "IPv4 | YDNS host update successful for:"
	echo "$YDNS_HOST"
    	echo ""
    	echo "New IPv4 address: $current_ip4"
    	echo ""

    	echo "$current_ip4" > "$YDNS_LASTIP_FILE"
    	;;

	nochg)
    	echo ""
    	echo "IPv4 | YDNS API replied: No change for:"
	echo "$YDNS_HOST"
    	echo ""
    	echo "-> IPv4 address unchanged"
    	echo ""

    	echo "$current_ip4" > "$YDNS_LASTIP_FILE"
    	;;

	*)
    	echo ""
    	echo "IPv4 | YDNS host update failed for:"
	echo "$YDNS_HOST"
    	echo ""
    	echo "Error: $retip4"
    	echo ""   	
	;;

	esac

    	else

	echo ""
	echo "Not updating YDNS host(s):"
	echo "$YDNS_HOST"
    	echo ""
    	echo "-> IPv4 address unchanged"
    	echo ""
fi

if [ "$current_ip6" != "$last_ip6" ]; then

	retip6=$(update_ip6_address)

	case "$retip6" in

	badauth)
	echo "IPv6 | YDNS host update failed for:"
	echo "$YDNS_HOST"
    	echo ""
    	echo "Authentication failed. Check your API username and secret."
    	echo ""

    	exit 92
    	;;

	good)
    	echo "IPv6 | YDNS host update successful for:"
	echo "$YDNS_HOST"
    	echo ""
    	echo "New IPv6 address: $current_ip6"
    	echo ""

    	echo "$current_ip6" >> "$YDNS_LASTIP_FILE"
    	exit 0
    	;;

	nochg)
    	echo "IPv6 | YDNS API replied: No change for:"
	echo "$YDNS_HOST"
    	echo ""
    	echo "-> IPv6 address unchanged"
    	echo ""

    	echo "$current_ip6" >> "$YDNS_LASTIP_FILE"
    	exit 0
    	;;

	*)
    	echo "IPv6 | YDNS host update failed for:"
	echo "$YDNS_HOST"
    	echo ""
    	echo "Error: $retip6"
    	echo ""

	exit 93
    	;;

	esac

    	else

    	echo "Not updating YDNS host(s):"
	echo "$YDNS_HOST"
    	echo ""
    	echo "-> IPv6 address unchanged"
    	echo ""
    	exit 0
fi