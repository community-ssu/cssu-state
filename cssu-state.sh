#!/bin/sh

# Author: Pali Rohár
# License: GPLv3+
# Description: Show state of CSSU packages in apt repositories and on github

dpkg_cmp() {

	if [ -n "$1" -a -n "$2" ] && dpkg --compare-versions "$1" "<<" "$2"; then
		return 0
	else
		return 1
	fi

}

GIT_PACKAGES=`wget --no-check-certificate -q 'https://api.github.com/orgs/community-ssu/repos?per_page=100&page=1' -O - | sed -n 's/^\s*"name": "\([^ ]*\)",$/\1/p' | grep -v '^Other$'; wget --no-check-certificate -q 'https://api.github.com/orgs/community-ssu/repos?per_page=100&page=2' -O - | sed -n 's/^\s*"name": "\([^ ]*\)",$/\1/p' | grep -v '^Other$'`
PACKAGES=
for git_package in $GIT_PACKAGES; do
	line=`wget --no-check-certificate -q https://raw.githubusercontent.com/community-ssu/$git_package/master/debian/changelog -O - | head -1 | sed -n 's/^\([^\ ]*\) (\(.*\)).*$/\1 \2/p'`
	package=`echo $line | cut -f1 -d' '`
	if [ -z "$package" ]; then
		package=$git_package
	fi
	PACKAGES="$PACKAGES $package"
	package=`echo $package | tr .+- ___`
	eval GIT_$package="`echo $line | cut -f2 -d' '`"
	eval GITSTABLE_$package="`wget --no-check-certificate -q https://raw.githubusercontent.com/community-ssu/$git_package/stable/debian/changelog -O - | head -1 | sed -n 's/^.*(\(.*\)).*$/\1/p'`"
	eval GITTHUMB_$package="`wget --no-check-certificate -q https://raw.githubusercontent.com/community-ssu/$git_package/thumb-testing/debian/changelog -O - | head -1 | sed -n 's/^.*(\(.*\)).*$/\1/p'`"
done

PACKAGES=`echo $PACKAGES | tr ' ' '\n' | sort -u`

wget --no-check-certificate -q http://maemo.merlin1991.at/cssu/community-devel/dists/fremantle/free/source/Sources.gz -O - | gunzip | (

package=
while read key value; do
	if [ "$key" = "Package:" ]; then
		package=`echo $value | tr .+- ___`
	elif [ -z "$key" ]; then
		package=""
	elif [ "$key" = "Version:" ]; then
		if [ -n "$package" ]; then
			eval old="\${DEVEL_$package}"
			if [ -z "$old" ] || dpkg_cmp "$old" "$value"; then
				eval DEVEL_$package="$value"
			fi
		fi
		package=""
	fi
done

wget --no-check-certificate -q http://maemo.merlin1991.at/cssu/community-thumb/dists/fremantle/free/source/Sources.gz -O - | gunzip | (

package=
while read key value; do
	if [ "$key" = "Package:" ]; then
		package=`echo $value | tr .+- ___`
	elif [ -z "$key" ]; then
		package=""
	elif [ "$key" = "Version:" ]; then
		if [ -n "$package" ]; then
			eval old="\${THUMB_$package}"
			if [ -z "$old" ] || dpkg_cmp "$old" "$value"; then
				eval THUMB_$package="$value"
			fi
		fi
		package=""
	fi
done

wget --no-check-certificate -q http://repository.maemo.org/community-testing/dists/fremantle/free/source/Sources.gz -O - | gunzip | (

package=
while read key value; do
	if [ "$key" = "Package:" ]; then
		package=`echo $value | tr .+- ___`
	elif [ -z "$key" ]; then
		package=""
	elif [ "$key" = "Version:" ]; then
		if [ -n "$package" ]; then
			eval old="\${TESTING_$package}"
			if [ -z "$old" ] || dpkg_cmp "$old" "$value"; then
				eval TESTING_$package="$value"
			fi
		fi
		package=""
	fi
done

wget --no-check-certificate -q http://repository.maemo.org/community/dists/fremantle/free/source/Sources.gz -O - | gunzip | (

package=
while read key value; do
	if [ "$key" = "Package:" ]; then
		package=`echo $value | tr .+- ___`
	elif [ -z "$key" ]; then
		package=""
	elif [ "$key" = "Version:" ]; then
		if [ -n "$package" ]; then
			eval old="\${STABLE_$package}"
			if [ -z "$old" ] || dpkg_cmp "$old" "$value"; then
				eval STABLE_$package="$value"
			fi
		fi
		package=""
	fi
done

NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)

if test -n "$1"; then
	printf "%-40s %-35s %-35s %-35s %-35s %-35s\n" "package" "git" "devel" "testing" "git-thumb" "thumb"
else
	printf "%-40s %-35s %-35s %-35s %-35s %-35s\n" "package" "git" "devel" "testing" "git-stable" "stable"
fi
for git_package in $PACKAGES; do
	if [ -z "$git_package" ]; then continue; fi
	package=`echo $git_package | tr .+- ___`
	eval git_version="\${GIT_$package}"
	eval devel_version="\${DEVEL_$package}"
	eval testing_version="\${TESTING_$package}"
	eval gitstable_version="\${GITSTABLE_$package}"
	eval stable_version="\${STABLE_$package}"
	eval gitthumb_version="\${GITTHUMB_$package}"
	eval thumb_version="\${THUMB_$package}"
	printf "%-40s " "$git_package"
	if dpkg_cmp "$git_version" "$devel_version" || dpkg_cmp "$git_version" "$testing_version" || dpkg_cmp "$git_version" "$gitstable_version"; then
		printf "${YELLOW}%-35s${NORMAL} " "$git_version"
	else
		printf "%-35s " "$git_version"
	fi
	if dpkg_cmp "$devel_version" "$git_version"; then
		printf "${YELLOW}%-35s${NORMAL} " "$devel_version"
	else
		printf "%-35s " "$devel_version"
	fi
	if dpkg_cmp "$testing_version" "$git_version" || dpkg_cmp "$testing_version" "$devel_version"; then
		printf "${YELLOW}%-35s${NORMAL} " "$testing_version"
	else
		printf "%-35s " "$testing_version"
	fi
	if test -n "$1"; then
		if dpkg_cmp "$gitthumb_version" "$git_version" || dpkg_cmp "$gitthumb_version" "$devel_version" || dpkg_cmp "$gitthumb_version" "$testing_version" || dpkg_cmp "$gitthumb_version" "$thumb_version"; then
			printf "${YELLOW}%-35s${NORMAL} " "$gitthumb_version"
		else
			printf "%-35s " "$gitthumb_version"
		fi
		if dpkg_cmp "$thumb_version" "$gitthumb_version"; then
			printf "${YELLOW}%-35s${NORMAL}\n" "$thumb_version"
		else
			printf "%-35s\n" "$thumb_version"
		fi
	else
		if dpkg_cmp "$gitstable_version" "$git_version" || dpkg_cmp "$gitstable_version" "$stable_version"; then
			printf "${YELLOW}%-35s${NORMAL} " "$gitstable_version"
		else
			printf "%-35s " "$gitstable_version"
		fi
		if dpkg_cmp "$stable_version" "$gitstable_version"; then
			printf "${YELLOW}%-35s${NORMAL}\n" "$stable_version"
		else
			printf "%-35s\n" "$stable_version"
		fi
	fi
done

)

)

)

)
