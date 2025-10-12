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

# Hosts you want to update (you can update multiple hosts at once).
# YDNS_HOST=(Host1 Host2 Host*), use ("Host1" "Host2" "Host*") if you want to prevent word splitting/globbing
YDNS_HOST=()

# Full path to your local YDNS_LASTIP file. This file stores the last known public IP addresses to avoid
# unnecessary API calls.
# If the file does not exist at the specified path, a new one will be created. If left blank, a new file will be
# created in the current working directory.
# !! When using cronjob, it is strongly recommended to set a custom path because the working directory
# is read-only and therefore automatic file creation will fail.
YDNS_LASTIP_FILE=""


####################################
# ! Do not change anything below ! #
####################################


YDNS_UPD_VERSION="2025.10.1"

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
  echo "  -h                          Display usage options"
  echo "  -H HOST1,HOST2,HOST*        Your YDNS hosts to be updated separated by commas (no spaces!)"
  echo "                              Use (\"Host1\",\"Host2\",\"Host*\") if you want to prevent globbing"
  echo "  -u USERNAME                 Your YDNS API username (for authentication)"
  echo "  -s SECRET                   Your YDNS API secret (for authentication)"
  echo "  -l YDNS_LASTIP FILE PATH    Full path to your local YDNS_LASTIP file (optional)"
  echo "  -v                          Display version"
  echo ""
  echo "  !! If you want to use this script in conjunction with a cronjob to run it automatically,"
  echo "  !! please enter your personal YDNS data in the specified section at the top of the script"
  echo ""
  exit 0
}

# Update IP addresses
# Function to update the IPv4 address
update_ip4_address () {
  retip4=""

  for host in "${YDNS_HOST[@]}"; do
    retip4=$(curl --fail --silent --user "$USERNAME:$SECRET" https://ydns.io/api/v1/update/?host="${host}"\&ip="${current_ip4}")
	  done

# API response
  echo "$retip4" | sed -E 's/^([^[:space:]]+).*/\1/'
}

# Function to update the IPv6 address
update_ip6_address () {
  retip6=""

  for host in "${YDNS_HOST[@]}"; do
    retip6=$(curl --fail --silent --user "$USERNAME:$SECRET" https://ydns.io/api/v1/update/?host="${host}"\&ip="${current_ip6}")
    done

  echo "$retip6" | sed -E 's/^([^[:space:]]+).*/\1/'
}

# Display version
show_version () {
  echo ""
  echo "YDNS Updater version: $YDNS_UPD_VERSION"
  echo ""
  exit 0
}

custom_host=()

# User inputs
while getopts "hH:l:s:u:v" opt 2>/dev/null; do
  case $opt in
  h)
    usage
    ;;

  H)
    IFS=,
    custom_host=($OPTARG)
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

  *)
    echo "Invalid option used. Use -h to display usage options."
    ;;
  esac
  done

# Custom Host
if [ -n "${custom_host[*]}" ]; then
  YDNS_HOST=("${custom_host[@]}")
fi

# Check if YDNS credentials and host(s) are specified
if [ -z "$USERNAME" ]; then
  echo ""
  echo "Error: YDNS API username missing."
  exit 90
fi

if [ -z "$SECRET" ]; then
  echo ""
  echo "Error: YDNS API secret missing."
  exit 90
fi

if [ -z "${YDNS_HOST[*]}" ]; then
  echo ""
  echo "Error: No YDNS host(s) specified."
  exit 90
fi

# Check if YDNS_LASTIP file exists and create a new one if necessary
if [ -z "$YDNS_LASTIP_FILE" ]; then
  YDNS_LASTIP_FILE="$(pwd)/YDNS_LASTIP"
fi

if [ -f "$(pwd)/YDNS_LASTIP" ] && [ ! -f "$YDNS_LASTIP_FILE" ]; then
  YDNS_LASTIP_FILE="$(pwd)/YDNS_LASTIP"
fi

if [ ! -f "$YDNS_LASTIP_FILE" ]; then
  echo ""
  echo "The YDNS_LASTIP file does not exist. Creating a new one."

	touch "$YDNS_LASTIP_FILE"

		if [ ! -f "$YDNS_LASTIP_FILE" ] && [ "$YDNS_LASTIP_FILE" != "$(pwd)/YDNS_LASTIP" ]; then
		  echo ""
		  echo "Warning: The YDNS_LASTIP file could not be created in the specified path. Check file path and permissions."
		  echo "Attempting to create a new YDNS_LASTIP file in the current working directory instead."

		  YDNS_LASTIP_FILE="$(pwd)/YDNS_LASTIP"
		  touch "$YDNS_LASTIP_FILE"
		fi

		if [ ! -f "$YDNS_LASTIP_FILE" ] && [ "$YDNS_LASTIP_FILE" == "$(pwd)/YDNS_LASTIP" ]; then
		  echo ""
		  echo "Warning: The YDNS_LASTIP file could not be created in the current working directory. Check permissions."
    fi

    if [ -f "$YDNS_LASTIP_FILE" ]; then
    echo ""
    echo "A new YDNS_LASTIP file has been created - $YDNS_LASTIP_FILE."
    echo "This file stores the last known public IP addresses locally to avoid unnecessary API calls."
    fi

    # Prepare file, insert blank lines so that sed works correctly later
    { echo "";echo "";echo ""; } >> "$YDNS_LASTIP_FILE"
fi

# Retrieve current public IP addresses from ipify
# IPv4
current_ip4=$(curl --fail --silent https://api.ipify.org)

if [ -z "$current_ip4" ]; then
  declare -i ipify_retry=1
  while [ -z "$current_ip4" ] && [ $ipify_retry -ne 4 ]; do
    echo ""
    echo "($ipify_retry/3) Attempting to retrieve the public IPv4 address. Please wait..."
    sleep 15
    current_ip4=$(curl --fail --silent https://api.ipify.org)
    ((ipify_retry++))
    done

  if [ -z "$current_ip4" ]; then
    echo ""
    echo "Error: The public IPv4 address cannot be retrieved."
    echo ""
    exit 91
  fi
fi

# IPv6
current_ip6=$(curl --fail --silent https://api6.ipify.org)

if [ -z "$current_ip6" ]; then
  ipify_retry=1
  while [ -z "$current_ip6" ] && [ $ipify_retry -ne 4 ]; do
    echo ""
    echo "($ipify_retry/3) Attempting to retrieve the public IPv6 address. Please wait..."
    sleep 15
    current_ip6=$(curl --fail --silent https://api6.ipify.org)
    ((ipify_retry++))
    done

  if [ -z "$current_ip6" ]; then
    echo ""
    echo "Error: The public IPv6 address cannot be retrieved."
    echo ""
    exit 91
  fi
fi

# Get locally stored data
last_ip4=""
last_ip6=""
declare -i last_host_count=0

if [ -f "$YDNS_LASTIP_FILE" ]; then
  last_ip4=$(sed -n '1p' "$YDNS_LASTIP_FILE")
  last_ip6=$(sed -n '2p' "$YDNS_LASTIP_FILE")
  last_host_count=$(sed -n '3p' "$YDNS_LASTIP_FILE")
fi

if [ -z "$last_ip4" ] || [ -z "$last_ip6" ] || [ "$last_host_count" -eq 0 ]; then
  last_ip4=""
  last_ip6=""
  last_host_count=0
  echo ""
  echo "Locally stored data is missing. Fallback to YDNS API call."
fi

if [ "$last_host_count" -ne 0 ] && [ "${#YDNS_HOST[@]}" != "$last_host_count" ]; then
  echo ""
  echo "YDNS API call due to changes in the YDNS hosts to be updated."
fi

# Call function to update host IP addresses if necessary and/or output results.
# IPv4
if [ "$current_ip4" != "$last_ip4" ] || [ "${#YDNS_HOST[@]}" != "$last_host_count" ]; then

  retip4=$(update_ip4_address)

  case "$retip4" in

  badauth)
    echo ""
    echo "IPv4 | Public IP address: $current_ip4."
	  echo "IPv4 | Host update failed for:"
	  for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
	  echo ""
	  echo "IPv4 | Authentication failed. Check your API username and secret."
	  echo ""
    ;;

  good)
    echo ""
    echo "IPv4 | Public IP address: $current_ip4."
    echo "IPv4 | Host update successful for:"
	  for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
    echo ""
    echo "IPv4 | New IP address: $current_ip4."
    echo ""

    sed -i "1c\\$current_ip4" "$YDNS_LASTIP_FILE"
    ;;

  nochg)
    echo ""
    echo "IPv4 | Public IP address: $current_ip4."
    echo "IPv4 | YDNS API detected no change for:"
    for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
    echo ""
    echo "IPv4 | IP address unchanged, no update necessary."
    echo ""

    sed -i "1c\\$current_ip4" "$YDNS_LASTIP_FILE"
    ;;

  *)
    echo ""
    echo "IPv4 | Public IP address: $current_ip4."
    echo "IPv4 | Host update failed for:"
    for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
    echo ""
    echo "IPv4 | Error: $retip4."
    echo ""
	  ;;

	esac

  else
    echo ""
    echo "IPv4 | Public IP address: $current_ip4."
    echo "IPv4 | IP address unchanged, no update necessary."
fi

# Ipv6
if [ "$current_ip6" != "$last_ip6" ]  || [ "${#YDNS_HOST[@]}" != "$last_host_count" ]; then

  retip6=$(update_ip6_address)

  case "$retip6" in

  badauth)
    echo ""
    echo "IPv6 | Public IP address: $current_ip6."
    echo "IPv6 | Host update failed for:"
	  for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
    echo ""
    echo "IPv6 | Authentication failed. Check your API username and secret."
    echo ""

    exit 92
    ;;

  good)
    echo ""
    echo "IPv6 | Public IP address: $current_ip6."
    echo "IPv6 | Host update successful for:"
	  for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
    echo ""
    echo "IPv6 | New IP address: $current_ip6."
    echo ""

    sed -i "2c\\$current_ip6" "$YDNS_LASTIP_FILE"
    sed -i "3c\\${#YDNS_HOST[@]}" "$YDNS_LASTIP_FILE"
    exit 0
    ;;

  nochg)
    echo ""
    echo "IPv6 | Public IP address: $current_ip6."
    echo "IPv6 | YDNS API detected no change for:"
	  for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
    echo ""
    echo "IPv6 | IP address unchanged, no update necessary."
    echo ""

    sed -i "2c\\$current_ip6" "$YDNS_LASTIP_FILE"
    sed -i "3c\\${#YDNS_HOST[@]}" "$YDNS_LASTIP_FILE"
    exit 0
    ;;

  *)
    echo ""
    echo "IPv6 | Public IP address: $current_ip6."
    echo "IPv6 | Host update failed for:"
	  for host in "${YDNS_HOST[@]}"; do
	    echo "- $host"
	    done
    echo ""
    echo "IPv6 | Error: $retip6."
    echo ""

    exit 93
    ;;

	esac

  else
    echo ""
    echo "IPv6 | Public IP address: $current_ip6."
    echo "IPv6 | IP address unchanged, no update necessary."
    echo ""

    sed -i "3c\\${#YDNS_HOST[@]}" "$YDNS_LASTIP_FILE"
    exit 0
fi

