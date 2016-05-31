#!/bin/sh
 
source /etc/profile
 
if [ -z $AWS_REGION ];
then
   AWS_REGION=eu-west-1
fi
 
#
# Get instance-id from metadata
#
MY_INSTANCE_ID=`wget -q -O- http://169.254.169.254/latest/meta-data/instance-id`
 
#
# Retention in days
#
RETENTION='3'
 
# Dates
datecheck_7d=`date +%Y-%m-%d --date '$RETENTION days ago'`
datecheck_s_7d=`date --date='$datecheck_7d' +%s`
datenow=`date +%Y-%m-%d-%H:%M:%S`
 
#
# Get active/in-use volume-id for current instance-id
#
VOLUME_LIST=(`ec2-describe-volumes -region $AWS_REGION --filter attachment.instance-id=$MY_INSTANCE_ID --filter status=in-use | awk '{ print $2 }'`)
 
sync
 
#
# Analyzing snapshot
#
echo ''
echo $VOLUME_LIST
echo '-----------------'
 
for volume in $(echo $VOLUME_LIST); do
   echo 'Analyzing snapshot(s) for volume: $volume'
   echo ''
 
   /usr/local/ec2/ec2-api-tools-1.7.5.1/bin/ec2-describe-snapshots -region $AWS_REGION --filter volume-id=$volume > /tmp/${volume}-snapshots
 
   num_snapshots=`cat /tmp/${volume}-snapshots | wc -l`
   echo 'Found $num_snapshots snapshot(s) for volume $volume to be analyzed'
 
   if (( $num_snapshots > 0 ));
   then
     while read line
        do
          snapshot_name=`echo $line | awk '{print $2}'`
 
          datecheck_old=`echo $line | awk '{print $5}' | awk -F 'T' '{print $1}'`
          datecheck_s_old=`date --date='$datecheck_old' +%s`
 
          # Check if snapshot is older than retention days
          if (( $datecheck_s_old <= $datecheck_s_7d ));
          then
             echo 'Deleting snapshot $snapshot_name ... older than $RETENTION days'
             /usr/local/ec2/ec2-api-tools-1.7.5.1/bin/ec2-delete-snapshot -region $AWS_REGION $snapshot_name
          else
             echo 'Snapshot $snapshot_name OK!'
          fi
 
     done < /tmp/${volume}-snapshots
   else
     echo ''
     echo '### no snapshots available for volume $volume'
   fi
    
done
 
echo '******* Ran retention check @ $(date)'
echo 'Completed'
 
exit 0
