#!/bin/bash
#set -vx
BASEDIR=`dirname $0`
pushd $BASEDIR 2>/dev/null
BASEDIR=$(pwd)
popd 2>/dev/null

WORKDIR=${1:-`pwd`}
pushd "$WORKDIR" >/dev/null
WORKDIR=`pwd`"/"
popd >/dev/null

if [ "${WORKDIR}" == "${BASEDIR}" ]
then
	WORKDIR="${WORKDIR}/flashdump/"
fi

PATH=$BASEDIR/bin:$PATH

BINDIR="${BASEDIR}/bin"
LOGFILE="${BASEDIR}/log"
PLUGINS="${BASEDIR}/plugins"
PATH="${BINDIR}":$PATH

export BASEDIR WORKDIR BINDIR LOGFILE PATH  PLUGINS

trap "rm -f $tempfile" 0 1 2 5 15

declare MENUITEM
declare FUNCTION

rm "${LOGFILE}"
touch "${LOGFILE}"
chmod +x "${BINDIR}/"*

for file in `ls -1 "${PLUGINS}"/[0-9][0-9]\.*\.sh`
do
	chmod +x $file
	source $file
done

echo Check that your tablet is in the firmware flash mode and connected to computer
read a

cd ${WORKDIR}

PARAMFILE="parameter"
parameter_Parse

sz=${#SECTION[@]}
for (( n=0; n<${#SECTION[@]}; n++ ))
do
	sname=${SECTION[$n]}
	ssize=${SSIZE[$n]}
	sstart=${SSTART[$n]}
	if [ ${sname} == "user" ]
	then
		continue
	fi
	cmd=`printf "rkflashtool29 w 0x%08x 0x%08x " ${sstart} ${ssize}`
	case $sname in
		"boot" | "kernel" | "misc" | "recovery" | "system" )
			if [ -e Image/${sname}.img ]
			then
				echo "Flashing ${sname} ($cmd)"
				${SUDO} $cmd > Image/${sname}.img 2>>${LOGFILE}
			fi
			;;
		"backup" )
			if [ -e ${sname}.img ]
			then
				echo "Flashing ${sname} ($cmd)"
				${SUDO} $cmd > ${sname}.img 2>>${LOGFILE}
			fi
			;;
		"cache" | "kpanic" | "userdata" | "user" )
			;;
	esac
done

