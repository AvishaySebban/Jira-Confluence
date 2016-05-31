#!/bin/bash
  
#source /etc/profile
  
if [ -z $AWS_REGION ];
then
   AWS_REGION=eu-west-1
fi
  
#
# Get instance-id from metadata
#
MY_INSTANCE_ID=`wget -q -O- http://169.254.169.254/latest/meta-data/instance-id`
  
#
# Get active/in-use volume-id for current instance-id
#
VOLUME_LIST=(`ec2-describe-volumes -region $AWS_REGION --filter attachment.instance-id=$MY_INSTANCE_ID  --filter status=in-use | awk '{ print $2 }'`)
sync
  
#
# Create snapshot
#
echo "Create EBS Volume Snapshot - Process started at $(date +%m-%d-%Y-%T)"
echo ''
echo $VOLUME_LIST
echo '-----------------'
  
DATE=$(date +'%Y%m%d_%H%M')
  
for volume in $(echo $VOLUME_LIST); do
   DESC='Confluecne_Automated_Snapshot_'$DATE
   echo 'Creating snapshot for volume: $volume with description: $DESC'
   echo ''
  
   ec2-create-snapshot -region $AWS_REGION -d $DESC $volume
  
   echo ''
  
   # Describe the snapshot just created
   #ec2-describe-snapshots -region $AWS_REGION --filter tag-value=$DESC
  
done
  
echo "******* Ran backup @ $(date)"
echo 'Completed'
  
exit 0
