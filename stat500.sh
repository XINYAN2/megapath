SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`
touch empty
set -x

for i in `cut -f1 allall.txt`; 
do 
	if [ -f /dev/shm/$i/m.nt.done ] && [ -f /dev/shm/$i/c.report ] && [ -f /dev/shm/$i/bn.lsam.id ]; then
		echo "$i ";
		# id=`grep $i allall.txt | cut -f2`;
		# mp=`cut -f1,6 /dev/shm/$i/m.nt.ra.lsam.id | sed 's/[0-9\.]*,//g' | ${SCRIPT_PATH}/cc/masonAccuracy empty ${SCRIPT_PATH}/db/tax/nodes.dmp ${SCRIPT_PATH}/db/tax/names.dmp - /dev/shm/$i/500_1.fq $id | grep Genus | cut -d" " -f4,5,6`
		# bn=`cut -f1,6 /dev/shm/$i/bn.lsam.id | sed 's/[0-9\.]*,//g' | ${SCRIPT_PATH}/cc/masonAccuracy empty ${SCRIPT_PATH}/db/tax/nodes.dmp ${SCRIPT_PATH}/db/tax/names.dmp - /dev/shm/$i/500_1.fq $id| grep Genus | cut -d" " -f4,5,6`
		# cf=`cut -f1,3 /dev/shm/$i/c.out | ${SCRIPT_PATH}/cc/masonAccuracy empty ${SCRIPT_PATH}/db/tax/nodes.dmp ${SCRIPT_PATH}/db/tax/names.dmp - /dev/shm/$i/500_1.fq $id| grep Genus | cut -d" " -f4,5,6`
		# echo "$mp $bn $cf"
	fi
done

rm empty