#!/bin/sh

# Author: Pali Rohár
# License: GPLv3+
# Description: Show state of CSSU packages in apt repositories and on gitorious

GIT_PACKAGES=`(wget -q https://gitorious.org/community-ssu/ -O - | sed -n 's/git clone .*\.git //p'; wget -q https://gitorious.org/community-ssu/ -O - | sed -n 's/.*"><strong>//p' | sed 's/<\/strong>.*//') | sort -u`
for git_package in $GIT_PACKAGES; do
	package=`echo $git_package | tr .+- ___`
	eval GIT_$package="`wget -q https://gitorious.org/community-ssu/$git_package/blobs/raw/master/debian/changelog --max-redirect 0 -O - | head -1 | sed 's/^.*(\(.*\)).*$/\1/'`"
	eval GITSTABLE_$package="`wget -q https://gitorious.org/community-ssu/$git_package/blobs/raw/stable/debian/changelog --max-redirect 0 -O - | head -1 | sed 's/^.*(\(.*\)).*$/\1/'`"
done

wget -q http://maemo.merlin1991.at/cssu/community-devel/dists/fremantle/free/source/Sources.gz -O - | gunzip | (

package=
while read key value; do
	if [ "$key" = "Package:" ]; then
		package=`echo $value | tr .+- ___`
	elif [ -z "$key" ]; then
		package=""
	elif [ "$key" = "Version:" ]; then
		if [ -n "$package" ]; then
			eval old="\${DEVEL_$package}"
			if [ -z "$old" ] || dpkg --compare-versions "$old" "<" "$value"; then
				eval DEVEL_$package="$value"
			fi
		fi
		package=""
	fi
done

wget -q http://repository.maemo.org/community-testing/dists/fremantle/free/source/Sources.gz -O - | gunzip | (

package=
while read key value; do
	if [ "$key" = "Package:" ]; then
		package=`echo $value | tr .+- ___`
	elif [ -z "$key" ]; then
		package=""
	elif [ "$key" = "Version:" ]; then
		if [ -n "$package" ]; then
			eval old="\${TESTING_$package}"
			if [ -z "$old" ] || dpkg --compare-versions "$old" "<" "$value"; then
				eval TESTING_$package="$value"
			fi
		fi
		package=""
	fi
done

wget -q http://repository.maemo.org/community/dists/fremantle/free/source/Sources.gz -O - | gunzip | (

package=
while read key value; do
	if [ "$key" = "Package:" ]; then
		package=`echo $value | tr .+- ___`
	elif [ -z "$key" ]; then
		package=""
	elif [ "$key" = "Version:" ]; then
		if [ -n "$package" ]; then
			eval old="\${STABLE_$package}"
			if [ -z "$old" ] || dpkg --compare-versions "$old" "<" "$value"; then
				eval STABLE_$package="$value"
			fi
		fi
		package=""
	fi
done

printf "%-40s %-35s %-35s %-35s %-35s %-35s\n" "package" "git" "devel" "testing" "git-stable" "stable"
for git_package in $GIT_PACKAGES; do
	package=`echo $git_package | tr .+- ___`
	eval git_version="\${GIT_$package}"
	eval devel_version="\${DEVEL_$package}"
	eval testing_version="\${TESTING_$package}"
	eval gitstable_version="\${GITSTABLE_$package}"
	eval stable_version="\${STABLE_$package}"
	printf "%-40s %-35s %-35s %-35s %-35s %-35s\n" "$git_package" "$git_version" "$devel_version" "$testing_version" "$gitstable_version" "$stable_version"
done

)

)

)
