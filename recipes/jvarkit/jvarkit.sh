#!/bin/bash
#
# Wraps jvarkit.jar
#
# This is adapted from picard's wrapper
#
set -eu -o pipefail

export LC_ALL=en_US.UTF-8

default_jvm_mem_opts="-Xms512m -Xmx2g"
jar_file="jvarkit.jar"

# Find original directory of bash script, resolving symlinks
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in/246128#246128
# NOTE no "realpath" on older max osx
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

JAR_DIR="$DIR"

# Use Java installed with conda to ensure correct version
if [[ -n "${JAVA_HOME}" ]]; then
    java=${JAVA_HOME}/bin/java   # point to the installed Java
else
    java=/opt/anaconda1anaconda2anaconda3/bin/java   # default old-style where anaconda installed Java
fi

### NOTE: always force the conda-installed java version
# # if JAVA_HOME is set (non-empty), use it. Otherwise keep "java"
#if [ -n "${JAVA_HOME:=}" ]; then
#	if [ -e "$JAVA_HOME/bin/java" ]; then
#		java="$JAVA_HOME/bin/java"
#	fi
#fi
###

# extract memory and system property Java arguments from the list of provided arguments
# http://java.dzone.com/articles/better-java-shell-script
jvm_mem_opts=""
jvm_prop_opts=""
pass_args=""
for arg in "$@"; do
	case $arg in
		'-D'*)
			jvm_prop_opts="$jvm_prop_opts $arg"
			;;
		'-XX'*)
			jvm_prop_opts="$jvm_prop_opts $arg"
			;;
		'-Xm'*)
			jvm_mem_opts="$jvm_mem_opts $arg"
			;;
		*)
			if [[ ${pass_args} == '' ]] #needed to avoid preceeding space on first arg e.g. ' MarkDuplicates'
				then
					pass_args="$arg"
			else
					pass_args="$pass_args \"$arg\"" #quotes later arguments to avoid problem with ()s in MarkDuplicates regex arg
			fi
			;;
	esac
done

if [ "$jvm_mem_opts" == "" ] && [ -z ${_JAVA_OPTIONS+x} ]; then
	jvm_mem_opts="$default_jvm_mem_opts"
fi

# shellcheck disable=SC2206
pass_arr=($pass_args)
if [[ ${pass_arr[0]:=} == com* ]]
then
	# shellcheck disable=SC2086
	eval set -- $jvm_mem_opts $jvm_prop_opts -cp "$JAR_DIR/$jar_file" $pass_args
else
	# shellcheck disable=SC2086
	eval set -- $jvm_mem_opts $jvm_prop_opts -jar "$JAR_DIR/$jar_file" $pass_args
fi
exec "$java" "$@"
