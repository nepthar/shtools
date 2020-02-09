# This doesn't work right now
# Programming language definitions
# Match	header comment


# TODO: Use the spookly skeletons in new/
# Require date_stamp, NAME, EMAIL
# Optional: payload
new()
{
	if [[ -z $1 ]]; then
		echo "Need filename"
		return 1
	fi

	if [[ -f "$1" ]]; then
		echo "$1 already exists"
		return 1
	fi

	local payload="" # "$(pbpaste)"
	local date_stamp="$(date +'%d %B %Y')"

	filename="${1##*/}"
	case "$filename" in

		__init__.py)
			touch $1
			;;

		*.py)
			cat > $1 <<-EOF
			#!/usr/bin/env python
			# $filename | $date_stamp
			# $NAME <$EMAIL>
			$payload
			EOF
			chmod +x $1
			;;

		*.sh)
			cat > $1 <<-EOF
			#!/usr/bin/env bash
			# $filename | $date_stamp
			# $NAME <$EMAIL>
			$payload
			EOF
			chmod +x $1
			;;

		*.c | *.cpp)
			cat > $1 <<-EOF
			/* $filename | $date_stamp
			 * $NAME <$EMAIL>
			 */
			$payload
			EOF
			;;

		*.h | *.hpp)
			cat > $1 <<-EOF
			#pragma once
			/* $filename | $date_stamp
			 * $NAME <$EMAIL>
			 */
			$payload
			EOF
			;;

		*.pig)
			cat > $1 <<-EOF
			-- $filename | $date_stamp
			-- $NAME <$EMAIL>
			$payload
			EOF
			;;

		*.scala)
			cat > $1 <<-EOF
			package com.twitter....

			import ...

			$payload
			EOF
			;;

		*)
			touch $1
			;;
	esac

	open -t $1
}