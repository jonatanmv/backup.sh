#!/bin/sh
#
# File:    backup.sh
# Author:  Jonatan Morales - jonatan.mv@gmail.com
# Created: 2004
# Updated: 2012-12-07
#
# Description: Backup to remote server via ssh according txt files backup.sh_include and backup.sh_exclude
#

# Init
timestamp=$(date +%Y%m%d_%H%M) # Take care not to use ":" in filenames

# Some files to email (not implemented jet)
EMAIL=

# Configuration by text files
CONFIG_FILE=/opt/backup.sh/backup.conf

if [[ -f $CONFIG_FILE ]]
then
    . $CONFIG_FILE
    echo "MODE=$MODE"
else
    echo "Configuration file ($CONFIG_FILE) not found!"
fi

# Mirrowing to remote ssh server
if [ $MODE -eq 0 -o $MODE -eq 3 ]; then
    RSYNC_OPTS="-avxz -S --delete --delete-excluded --exclude-from=$EXCLUDE --backup --backup-dir=$MIRROR_OLD --suffix=$MIRROR_OLDSUFFIX"

    echo "(conecting to ssh server... $HOST)" | tee -a $LOG
    if [ $MOUNT_CMD ]
    then
	ssh $SSH_OPTS $HOST $UMOUNT_CMD
	ssh $SSH_OPTS $HOST $MOUNT_CMD
    fi
    cat $INCLUDE | while read dir
    do
	echo | tee -a $LOG
	echo "*** $timestamp Mirrowing [$dir] ..." | tee -a $LOG
	rsync $RSYNC_OPTS  -e "ssh $SSH_OPTS" "$dir" $HOST:$MIRROR | tee -a $LOG
    done
    if [ $MOUNT_CMD ]
    then
	ssh $SSH_OPTS $HOST sudo umount $DISK
    fi
fi

# Mirrowing to external usb drive (and make it bootable)
if [ $MODE -eq 1 -o $MODE -eq 3 ]; then
    echo "Data in /Volumes/Backup may be deleted. Are you sure [Y/N] (default=N)?"
    read answer
    if test "$answer" != "Y" -a "$answer" != "y"; then
	exit 0;
    fi
    SRC=/
    DST=$USB_DISK
    OPTS="-avEx -S --delete"
    echo | tee -a $LOG
    echo "*** $timestamp Mirrowing [$SRC] to device [$DST]..." | tee -a $LOG
    if [ ! -w "$DST" ]; then
	echo "Destination $DST not writeable -  sync process to [$DST] skipped" | tee -a $LOG
	exit;
    fi
    sudo rsync $OPTS $SRC $DST | tee -a $LOG
    echo "*** $timestamp Making device [$DST] bootable..."
    sudo bless -folder "$DST"/System/Library/CoreServices | tee -a $LOG
fi

# Mirrowing Documents and specific folders to external usb drive
if [ $MODE -eq 2 -o $MODE -eq 3 ]; then
    MIRROR=/Volumes/BACKUP/
    MIRROR_OLD=$MIRROR/macbook_old/
    MIRROR_OLDSUFFIX=_rsync.$timestamp
    RSYNC_OPTS="-avxz -S --delete --delete-excluded --exclude-from=$EXCLUDE"
    echo "Backing up to external USB disk ..."
    cat $INCLUDE | while read dir
    do
	echo | tee -a $LOG
	echo "*** $timestamp Mirrowing [$dir] ..." | tee -a $LOG
	rsync $RSYNC_OPTS  "$dir" $MIRROR | tee -a $LOG
    done
fi
