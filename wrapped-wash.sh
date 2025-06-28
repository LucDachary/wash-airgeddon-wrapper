#!/usr/bin/env bash
#
# Wrap the 'wash' binary and look for default PINs in the airgeddon 'known_pins' database.

[[ $UID != 0 ]] && exec sudo -E "$(readlink -f "$0")" "$@"

BIN="$(which wash)"
AIRGEDDON_DB_FILEPATH="/usr/share/airgeddon/known_pins.db"

if [[ ! -s "$AIRGEDDON_DB_FILEPATH" ]]; then
	printf "Cannot find Airgeddon default PINs database. "
	printf "I looked for file \"$AIRGEDDON_DB_FILEPATH\".\n"
	printf "I won't enhance the wash output.\n"
else
	source "$AIRGEDDON_DB_FILEPATH"
fi

i_line=0
LINE_LENGTH=80 # Measured empirically
DEFAULT_PINS_HEADER="Default PINs"

while read LINE
do
	if (( $i_line == 0 )); then
		# Pad the line up to LINE_LENGTH, with spaces
		printf -v PADDING '%*s' $(($LINE_LENGTH - ${#LINE})) ' '
		printf "%s%s" "$LINE" "$PADDING"

		# Print the additional column name.
		printf "$DEFAULT_PINS_HEADER\n"

	elif (( $i_line == 1 )); then
		# Augment the dashed line, the length of our new header
		printf -v DASHES '%*s' ${#DEFAULT_PINS_HEADER} '-'
		DASHES=${DASHES// /-}
		printf "%s%s\n" "$LINE" $DASHES

	else
		# All these lines discovered WiFis with WPS.

		# Pad the line up to LINE_LENGTH, with spaces
		printf -v PADDING '%*s' $(($LINE_LENGTH - ${#LINE})) ' '
		printf "%s%s" "$LINE" "$PADDING"

		# Read the database for this BSSID
		BSSID_START=${LINE:0:8}
		BSSID_START=${BSSID_START//:/}
		DEFAULT_PINS=${PINDB[$BSSID_START]}

		if [[ -z "$DEFAULT_PINS" ]]; then
			printf "%s\n" "-"
		else
			printf "$DEFAULT_PINS\n"
		fi
	fi

	i_line=$((i_line + 1))
done < <("$BIN" "$@")

# Future improvment ideas:
# * add coloring before printing. A basic style, like gray, for all the things added,
# 	and an improved color, like yellow, for default PINs found.
# * some providers have MANY default PINs. In this case show the number instead of the list, not
#   to break the layout.
