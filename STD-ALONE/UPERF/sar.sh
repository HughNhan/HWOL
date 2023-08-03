POD=$1
#OUT=$(oc exec -it $POD  -- /bin/bash -c "grep MSI /tmp/tmp*/iteration-1/sample-1/*stderrout.txt") 
#MSI=$(echo $OUT | awk -F "=" '{$1=""; print $0}')

#oc exec -it $POD  -- /bin/bash -c "ls $(readlink -e /sys/class/net/eth0)/../../msi_irqs | xargs"
LINK="$(oc exec -it $POD  -- /bin/bash -c  "readlink -e /sys/class/net/eth0" |  tr -d '\r' )"
MSI=$(oc exec -it $POD  -- /bin/bash -c  "ls $LINK/../../msi_irqs" |  tr -d '\r')
#echo MSI="${MSI}"
MSI=\"${MSI}\"
echo MSI=$MSI

exit

function one_vf {
   for i in $MSI; do
      cat /proc/irq/$i/smp_affinity_list
   done
}
CPUS=$(one_vf | tr -s '\n' ',')
echo MSI=$MSI
echo CPUS=$CPUS
echo sar -P $CPUS 1

