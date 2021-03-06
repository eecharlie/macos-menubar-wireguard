#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2016-2018 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.

die() {
	echo "[-] Error: $1" >&2
	exit 1
}

PROGRAM="${0##*/}"
ARGS=( "$@" )
SELF="${BASH_SOURCE[0]}"
[[ $SELF == */* ]] || SELF="./$SELF"
SELF="$(cd "${SELF%/*}" && pwd -P)/${SELF##*/}"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[[ ${BASH_VERSINFO[0]} -ge 4 ]] || die "bash ${BASH_VERSINFO[0]} detected, when bash 4+ required"

# This is a hack, requiring this script to *not* be run as root to work correctly.
if [[ "$UID" -ne "0" ]]
then
	"$DIR/Setup"
	exec sudo -p "[?] $PROGRAM must run as root to write Wireguard config files. Please enter the password for %u to continue: " -- "$BASH" -- "$SELF" "${ARGS[@]}"
fi

type wg >/dev/null || die "Please install wireguard-tools and then try again."
type curl >/dev/null || die "Please install curl and then try again."
type jq >/dev/null || die "Please install jq and then try again."
set -e

read -p "[?] Please enter your Mullvad account number: " -r ACCOUNT

echo "[+] Contacting Mullvad API for server locations."
declare -A SERVER_ENDPOINTS
declare -A SERVER_PUBLIC_KEYS
declare -A SERVER_LOCATIONS
declare -a SERVER_CODES

RESPONSE="$(curl -LsS https://api.mullvad.net/public/relays/wireguard/v1/)" || die "Unable to connect to Mullvad API."
FIELDS="$(jq -r 'foreach .countries[] as $country (.; .; foreach $country.cities[] as $city (.; .; foreach $city.relays[] as $relay (.; .; $country.name, $city.name, $relay.hostname, $relay.public_key, $relay.ipv4_addr_in)))' <<<"$RESPONSE")" || die "Unable to parse response."
while read -r COUNTRY && read -r CITY && read -r HOSTNAME && read -r PUBKEY && read -r IPADDR; do
	CODE="${HOSTNAME%-wireguard}"
	SERVER_CODES+=( "$CODE" )
	SERVER_LOCATIONS["$CODE"]=${COUNTRY//[, ]/_}-${CITY//[, ]/_}
	SERVER_PUBLIC_KEYS["$CODE"]="$PUBKEY"
	SERVER_ENDPOINTS["$CODE"]="$IPADDR:51820"
done <<<"$FIELDS"

shopt -s nocasematch
for CODE in "${SERVER_CODES[@]}"; do
	CONFIGURATION_FILE="/etc/wireguard/${SERVER_LOCATIONS["$CODE"]}.conf"
	[[ -f $CONFIGURATION_FILE ]] || continue
	while read -r line; do
		[[ $line =~ ^PrivateKey\ *=\ *([a-zA-Z0-9+/]{43}=)\ *$ ]] && PRIVATE_KEY="${BASH_REMATCH[1]}" && break
	done < "$CONFIGURATION_FILE"
	[[ -n $PRIVATE_KEY ]] && echo "[+] Using existing private key." && break
done
shopt -u nocasematch

if [[ -z $PRIVATE_KEY ]]; then
	echo "[+] Generating new private key."
	PRIVATE_KEY="$(wg genkey)"
fi

echo "[+] Contacting Mullvad API."
RESPONSE="$(curl -sSL https://api.mullvad.net/wg/ -d account="$ACCOUNT" --data-urlencode pubkey="$(wg pubkey <<<"$PRIVATE_KEY")")" || die "Could not talk to Mullvad API."
[[ $RESPONSE =~ ^[0-9a-f:/.,]+$ ]] || die "$RESPONSE"
ADDRESS="$RESPONSE"
DNS="193.138.219.228"

echo "[+] Writing WireGuard configuration files."
for CODE in "${SERVER_CODES[@]}"; do
	CONFIGURATION_FILE="/etc/wireguard/${SERVER_LOCATIONS["$CODE"]}.conf"
	umask 077
	mkdir -p /etc/wireguard/
	rm -f "$CONFIGURATION_FILE.tmp"
	cat > "$CONFIGURATION_FILE.tmp" <<-_EOF
		[Interface]
		PrivateKey = $PRIVATE_KEY
		Address = $ADDRESS
		DNS = $DNS

		[Peer]
		PublicKey = ${SERVER_PUBLIC_KEYS["$CODE"]}
		Endpoint = ${SERVER_ENDPOINTS["$CODE"]}
		AllowedIPs = 0.0.0.0/0, ::/0
	_EOF
	mv "$CONFIGURATION_FILE.tmp" "$CONFIGURATION_FILE"
done

# Ensure file permissions allow WireGuardStatusBar to auto-populate the menu
# which requires getting a directory listing as non-privileged user
chmod o+r /etc/wireguard

echo "[+] Success. Now install/run WireGuard StatusBar and menu will auto-populate."
echo "[+] Please wait up to 60 seconds for your public key to be added to the servers."
echo "[+] You may close this window.

"
