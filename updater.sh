#!/usr/bin/env bash
set -uo pipefail

################
# YDNS-Updater #
################

# <https://github.com/Tech-no-1/YDNS-Updater/blob/c906c99efca772375d1c70fe10946a1d9b759599/updater.sh>
# 2026 | Tech-no-1

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


#################
# Configuration #
#################


# Please enter your personal configuration, specifically your YDNS credentials and hosts,
# if you want to run this script automatically using a cronjob.

# YDNS API credentials (https://ydns.io/user/api).
username=""
secret=""

# Hosts you want to update (you can update multiple hosts at once).
# ydns_hosts=(host1 host2 host*)
declare -a ydns_hosts
ydns_hosts=()

# Full path to the local ydns_lastip file. The ydns_lastip file stores some data, including the last known public IP addresses,
# locally to avoid unnecessary API calls. It is recommended to let the script create and prepare the file for you.
# If you leave this empty, a new file gets created in the directory of the script.
# The user running the script must have read/write permissions for the directory.
ydns_lastip_file=""


####################################
# ! Do not change anything below ! #
####################################


##############################
# Global constants/variables #
##############################

declare -r version="2026.05.1"

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
declare -r script_dir

declare interactive=0

p_user=$(id -un)
declare -r p_user
p_group=$(id -gn)
declare -r p_group

declare -a custom_host=()

declare last_ip4
declare last_ip6
declare -i last_host_count=0

#############
# Functions #
#############

# Usage/Help
usage () {
  printf "\n  YDNS-Updater - %s\n\n" "$version"
  printf "  Usage: %s [options]\n\n" "${BASH_SOURCE[0]}"
  printf "  Available options:\n"
  printf "%-30sYour YDNS API username (for authentication)\n" "  -u username"
  printf "%-30sYour YDNS API secret (for authentication)\n" "  -s secret"
  printf "%-30sThe YDNS host(s) you want to update. They must be separated by a comma (no spaces)\n" \
         "  -H host1,host2,host*"
  printf "%-30sFull path to the local ydns_lastip file (optional)\n" "  -l ydns_lastip filepath"
  printf "%-30sRun the script in interactive mode and follow the instructions\n" "  -i"
  printf "%-30sDisplay version\n" "  -v"
  printf "%-30sDisplay these options\n" "  -h"
  printf "\n\e[0;33m  If you want to run this script automatically using a cronjob,\n"
  printf "  please enter your personal configuration in the specified section at the top of the script.\n"
  printf "  You can override this configuration by using the input options above or the interactive mode.\e[0m\n\n"
  exit 0
}

# Display version
show_version () {
  printf "\nYDNS-Updater version: \e[0;32m%s\e[0m\n\n" "$version"
  exit 0
}

# Create ydns_lastip file
create_lastip_file () {
  touch "$ydns_lastip_file"
  chown "$p_user":"$p_group" "$ydns_lastip_file"
  chmod 640 "$ydns_lastip_file"
}

# Get ydns_lastip file properties
get_file_attr () {
f_user=$(stat --format='%U' "$ydns_lastip_file")
f_group=$(stat --format='%G' "$ydns_lastip_file")
f_perm=$(stat --format='%a' "$ydns_lastip_file")
}

# IPv4 | Update hosts
update_ip4_address () {
  local ip4_response
  local raw

  for host in "${ydns_hosts[@]}"; do
    # Call YDNS API and process response
    raw=$(curl --fail --silent --connect-timeout 5 --max-time 10 --user "$username:$secret" \
    "https://ydns.io/api/v1/update/?host=${host}&ip=${current_ip4}")
    ip4_response="${raw%% *}"

    case "$ip4_response" in
    badauth)
    	printf "\n\e[0;31mError: Authentication failed. Check your API username and secret.\e[0m\n\n"
      exit 92
      ;;

    good)
      printf " - %-30s \e[0;32m-> updated\e[0m\n" "$host"
      ;;

    nochg)
      printf " - %-30s \e[0;32m-> unchanged\e[0m\n" "$host"
      ;;

    *)
      printf " - %-30s \e[0;31m-> Error: %s\e[0m\n" "$host" "$ip4_response"
    	;;

    esac
  done
}

# IPv6 | Update hosts
update_ip6_address () {
  local ip6_response
  local raw

  for host in "${ydns_hosts[@]}"; do
    raw=$(curl --fail --silent --connect-timeout 5 --max-time 10 --user "$username:$secret" \
    "https://ydns.io/api/v1/update/?host=${host}&ip=${current_ip6}")
    ip6_response="${raw%% *}"

    case "$ip6_response" in
    badauth)
    	printf "\n\e[0;31mError: Authentication failed. Check your API username and secret.\e[0m\n\n"
      exit 92
      ;;

    good)
      printf " - %-30s \e[0;32m-> updated\e[0m\n" "$host"
      ;;

    nochg)
      printf " - %-30s \e[0;32m-> unchanged\e[0m\n" "$host"
      ;;

    *)
      printf " - %-30s \e[0;31m-> Error: %s\e[0m\n" "$host" "$ip6_response"
    	;;

    esac
  done
}

########
# Main #
########

# Check if curl is present
 command -v curl > /dev/null 2>&1
 curl_check=$?

 if [ "$curl_check" -ne 0 ]; then
   printf "\n\e[0;31mError: Curl is NOT present. Please install it, as it is required to run the script.\e[0m\n\n"
   exit 1
 fi

# User inputs
while getopts "hH:il:s:u:v" opt 2>/dev/null; do
  case $opt in
  h)
    usage
    ;;

  H)
    read -r -a custom_host <<< "${OPTARG//,/ }"
    ;;

  i)
    interactive=1
    ;;

  l)
    ydns_lastip_file=$OPTARG
    ;;

  s)
    secret=$OPTARG
    ;;

  u)
    username=$OPTARG
    ;;

  v)
    show_version
    ;;

  *)
    printf "\n\e[0;33mBad option: %s. Use -h to display options.\e[0m\n" "$opt"
    ;;
  esac
done

# Custom Host
if [ -n "${custom_host[*]}" ]; then
  ydns_hosts=("${custom_host[@]}")
fi

# Interactive mode + check if YDNS credentials, host(s) and last_ip file are specified
# username
if [ $interactive == 1 ]; then

  if [ -n "$username" ]; then
    read -r -n1 \
    -p "Do you want to use the already existing YDNS API username from the configuration/input-options (y|n)?" choice

    case $choice in
    y|Y)
    printf "\n"
    ;;

    n|N)
    printf "\n"
    username=""
    ;;

    *)
    printf "\n\e[0;33mEmpty or invalid input. Defaulting to \"no\".\e[0m\n\n"
    username=""
    ;;
    esac
  fi

  if [ -z "$username" ]; then
    read -r -s -p "Please enter your YDNS API username (inputs hidden for security): " username
    printf "\n"

    if [ -z "$username" ]; then
    printf "\n\e[0;31mError: YDNS API username is missing.\e[0m\n\n"
    exit 90
    fi
  fi

  elif [ -z "$username" ]; then
    printf "\n\e[0;31mError: YDNS API username is missing.\e[0m\n\n"
    exit 90
fi

#secret
if [ $interactive == 1 ]; then

  if [ -n "$secret" ]; then
    read -r -n1 \
    -p "Do you want to use the already existing YDNS API secret from the configuration/input-options (y|n)?" choice

    case $choice in
    y|Y)
    printf "\n"
    ;;

    n|N)
    printf "\n"
    secret=""
    ;;

    *)
    printf "\n\e[0;33mEmpty or invalid input. Defaulting to \"no\".\e[0m\n\n"
    secret=""
    ;;
    esac
  fi

  if [ -z "$secret" ]; then
    read -r -s -p "Please enter your YDNS API secret (inputs hidden for security): " secret
    printf "\n"

    if [ -z "$secret" ]; then
      printf "\n\e[0;31mError: YDNS API secret is missing.\e[0m\n\n"
      exit 90
    fi
  fi

  elif [ -z "$secret" ]; then
    printf "\n\e[0;31mError: YDNS API secret is missing.\e[0m\n\n"
    exit 90
fi

# ydns_hosts
if [ $interactive == 1 ]; then

  if [ -n "${ydns_hosts[*]}" ]; then
    read -r -n1 \
    -p "Do you want to use the already existing YDNS hosts(s) from the configuration/input-options (y|n)?" choice

    case $choice in
    y|Y)
    printf "\n"
    ;;

    n|N)
    printf "\n"
    ydns_hosts=()
    ;;

    *)
    printf "\n\e[0;33mEmpty or invalid input. Defaulting to \"no\".\e[0m\n\n"
    ydns_hosts=()
    ;;
    esac
  fi

  if [ -z "${ydns_hosts[*]}" ]; then
    read -r -a ydns_hosts -p "Please enter the YDNS host(s) you want to update. They must be separated by a space: "

    if [ -z "${ydns_hosts[*]}" ]; then
      printf "\n\e[0;31mError: No YDNS host(s) specified.\e[0m\n\n"
      exit 90
    fi
  fi

  elif [ -z "${ydns_hosts[*]}" ]; then
    printf "\n\e[0;31mError: No YDNS host(s) specified.\e[0m\n\n"
    exit 90
fi

# ydns_lastip file
if [ $interactive == 1 ]; then

  if [ -n "$ydns_lastip_file" ]; then
    read -r -n1 \
    -p "Do you want to use the already existing ydns_lastip filepath from the configuration/input-options (y|n)?" choice

    case $choice in
    y|Y)
    printf "\n"
    ;;

    n|N)
    printf "\n"
    ydns_lastip_file=""
    ;;

    *)
    printf "\n\e[0;33mEmpty or invalid input. Defaulting to \"no\".\e[0m\n"
    ydns_lastip_file=""
    ;;
    esac
  fi

  if [ -z "$ydns_lastip_file" ]; then
    printf "\n\e[0;33mInfo:\e[0m The ydns_lastip file stores some data, including the last known public IP addresses, "
    printf "locally to avoid unnecessary API calls.\nThis is optional. If you skip this step, "
    printf "the script looks for an existing ydns_lastip file in its directory and creates a new one if necessary.\n\n"

    read -r -p "Please enter the full path to the ydns_lastip file or skip by pressing enter: " ydns_lastip_file
  fi
fi

# ydns_lastip file checks and creation
# Check if ydns_lastip file exists and create a new one if necessary
if [ -z "$ydns_lastip_file" ]; then
  ydns_lastip_file="$script_dir/ydns_lastip"
fi

if [ ! -f "$ydns_lastip_file" ] && [ -f "$script_dir/ydns_lastip" ]; then
  ydns_lastip_file="$script_dir/ydns_lastip"
  printf "\n\e[0;33mWarning: Could not find a ydns_lastip file at the specified path."
  printf "However, there is one in the directory of this script. Using this one instead\e[0m\n"
fi

if [ ! -f "$ydns_lastip_file" ]; then
  printf "\n\e[0;33mCould not find a ydns_lastip file, creating a new one.\e[0m\n"

  create_lastip_file

  if [ ! -f "$ydns_lastip_file" ] && [ "$ydns_lastip_file" != "$script_dir/ydns_lastip" ]; then
    printf "\n\e[0;33mWarning: The ydns_lastip file could not be created in the specified path.\n"
    printf "Does the current user have read/write permissions for: %s?\n" "$(dirname "$ydns_lastip_file")"
    printf "Attempting to create a new ydns_lastip file in the directory of this script instead.\e[0m\n"


    ydns_lastip_file="$script_dir/ydns_lastip"
    create_lastip_file
	fi

	if [ ! -f "$ydns_lastip_file" ] && [ "$ydns_lastip_file" == "$script_dir/ydns_lastip" ]; then
		printf "\n\e[0;33mWarning: The ydns_lastip file could not be created in the directory of this script.\n"
    printf "Does the current user have read/write permissions for: %s?\e[0m\n" "$(dirname "$ydns_lastip_file")"
  fi

  if [ -f "$ydns_lastip_file" ]; then
    printf "\n\e[0;32mA new ydns_lastip file has been created at:\e[0m %s.\n" "$ydns_lastip_file"
    printf "This file stores some data, including the last known public IP addresses, locally to avoid unnecessary API calls.\n"
  fi

  # Prepare file, insert blank lines so that sed works correctly later
  printf "\n\n\n" > "$ydns_lastip_file"
fi

# Check/fix ydns_lastip file ownership and permissions
get_file_attr

if [ "$f_user" != "$p_user" ] || \
   [ "$f_group" != "$p_group" ] || \
   [ "$f_perm" != 640 ]; then
  printf "\e[0;33mWarning: The ydns_lastip file is either not owned by the user currently running this script\n"
  printf "or the file check failed. Trying to fix file ownership/permissions\e[0m\n"

  chown "$p_user":"$p_group" "$ydns_lastip_file"
  chmod 640 "$ydns_lastip_file"

  # Validate changes
  get_file_attr

  if [ "$f_user" != "$p_user" ] || \
     [ "$f_group" != "$p_group" ] || \
     [ "$f_perm" != 640 ]; then
    printf "\e[0;33mCould not fix file ownership/permissions. Does the current user have read/write permissions for: %s?\n" \
    "$(dirname "$ydns_lastip_file")"
    printf "You can try to remove the ydns_lastip file and let the script create it again.\e[0m\n"
    else
      printf "\e[0;32mSuccessfully fixed file ownership/permissions for: %s\e[0m\n" "$ydns_lastip_file"
  fi
fi

# Retrieve current public IP addresses from ipify
# IPv4
current_ip4=$(curl --fail --silent --connect-timeout 3 --max-time 5 https://api.ipify.org)

if [ -z "$current_ip4" ]; then
  declare -i ipify_retry=1
  while [ -z "$current_ip4" ] && (( ipify_retry != 4 )); do
    printf "\n\e[0;33mCould not retrieve the public IPv4 address.\e[0m\n"
    printf "\e[0;33m(%s/3) Attempting to retrieve the public IPv4 address again.\e[0m\n" "$ipify_retry"
    sleep 15
    current_ip4=$(curl --fail --silent --connect-timeout 3 --max-time 5 https://api.ipify.org)
    ((ipify_retry++))
  done

  if [ -z "$current_ip4" ]; then
    printf "\n\e[0;31mError: The public IPv4 address cannot be retrieved.\e[0m\n\n"
    exit 91
  fi
fi

# IPv6
current_ip6=$(curl --fail --silent --connect-timeout 3 --max-time 5 https://api6.ipify.org)

if [ -z "$current_ip6" ]; then
  declare -i ipify_retry=1
  while [ -z "$current_ip6" ] && (( ipify_retry != 4 )); do
    printf "\n\e[0;33mCould not retrieve the public IPv6 address.\e[0m\n"
    printf "\n\e[0;33m(%s/3) Attempting to retrieve the public IPv6 address again.\e[0m\n" "$ipify_retry"
    sleep 15
    current_ip6=$(curl --fail --silent --connect-timeout 3 --max-time 5 https://api6.ipify.org)
    ((ipify_retry++))
  done

  if [ -z "$current_ip6" ]; then
    printf "\n\e[0;31mError: The public IPv6 address cannot be retrieved.\e[0m\n\n"
    exit 91
  fi
fi

# Get locally stored data from ydns_lastip file
if [ -f "$ydns_lastip_file" ]; then
  last_ip4=$(sed -n 1p "$ydns_lastip_file")
  last_ip6=$(sed -n 2p "$ydns_lastip_file")
  last_host_count=$(sed -n 3p "$ydns_lastip_file")
fi

if [ -z "$last_ip4" ] || [ -z "$last_ip6" ] || (( last_host_count == 0 )); then
  last_ip4=""
  last_ip6=""
  last_host_count=0
  printf "\n\e[0;33mLocally stored data is missing, updating hosts.\e[0m\n"
fi

if (( last_host_count != 0 )) && (( ${#ydns_hosts[@]} != last_host_count )); then
  printf "\n\e[0;33mYDNS hosts have changed since the last run, updating hosts.\e[0m\n"
fi

# Call functions to update hosts if necessary
# IPv4
if [ "$current_ip4" != "$last_ip4" ] || (( ${#ydns_hosts[@]} != last_host_count )); then
  printf "\nIPv4 | Current public IPv4 address: %s\n" "$current_ip4"
  printf "IPv4 | Updating hosts:\n"

  update_ip4_address

  sed -i 1c\ "${current_ip4}" "$ydns_lastip_file"

  else
    printf "\nIPv4 | Current public IPv4 address: %s\n" "$current_ip4"
    printf "IPv4 | \e[0;32m-> No update required. IP address and hosts have remained unchanged since the last run.\e[0m\n"
fi

# Ipv6
if [ "$current_ip6" != "$last_ip6" ] || (( ${#ydns_hosts[@]} != last_host_count )); then
  printf "\nIPv6 | Current public IPv6 address: %s\n" "$current_ip6"
  printf "IPv6 | Updating hosts:\n"

  update_ip6_address
  printf "\n"

  sed -i 2c\ "${current_ip6}" "$ydns_lastip_file"

  else
    printf "\nIPv6 | Current public IPv6 address: %s\n" "$current_ip6"
    printf "IPv6 | \e[0;32m-> No update required. IP address and hosts have remained unchanged since the last run.\e[0m\n\n"
fi

# Update host count in ydns_lastip file and exit
sed -i 3c\ "${#ydns_hosts[@]}" "$ydns_lastip_file"
exit 0