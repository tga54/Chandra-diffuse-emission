evtname="20327 20328 20329 20330 20331 20332 20962 20963 20967 21067 21098 21126 21724 21874" 
dir=/home/chaomingli/Downloads/pwn
for i in {0..6}
do 
for obsid in $evtname
do
cd $dir/$obsid/repro
time_evt=$(dmkeypar evt2_clean.fits EXPOSURE echo+) 
time_bkg=$(dmkeypar blanksky.fits EXPOSURE echo+)
count_evt=$(dmstat "evt2_clean.fits[energy=9500:12000][cols energy]" | grep "good" | awk '{print $2}')
count_bkg=$(dmstat "blanksky.fits[energy=9500:12000][cols energy]" | grep "good" | awk '{print $2}')
areascal=$(awk -v c1=$count_bkg -v t1=$time_bkg -v c2=$count_evt -v t2=$time_evt 'BEGIN{print (c1/t1)/(c2/t2)}')
echo $obsid $areascal >> $dir/spec_blanksky/pwn1/r${i}/areascal.txt
cd $dir/spec_blanksky/pwn1/r${i}
fparkey $areascal ${obsid}_bkg.pi AREASCAL add=yes
backscal=$(dmkeypar ${obsid}.pi BACKSCAL echo+)
area=$(awk -v backs=$backscal 'BEGIN{print backs*8192^2*0.492^2/3600}')
echo ${obsid}.pi $area >> backscal.txt
done

#group the spec1
cd $dir/spec_blanksky/pwn1/r${i}
for obsid in $evtname
do
ftgrouppha infile=${obsid}.pi outfile=${obsid}.grp grouptype=min groupscale=20 clobber=yes
done
done

########### lbg 
#cd ${dir}/spec_newgain/lbg
#for obsid in $evtname
#do
#cd $dir/$obsid/repro
#time_evt=$(dmkeypar evt2_clean_3sigma_ccsrc.fits EXPOSURE echo+) 
#time_bkg=$(dmkeypar bgstow_proj_newgain.fits EXPOSURE echo+)
#count_evt=$(dmstat "evt2_clean_3sigma_ccsrc.fits[energy=9500:12000][cols energy][sky=region($dir/spec_newgain/for_scale.reg)]" | grep "good" | awk '{print $2}')
#count_bkg=$(dmstat "bgstow_proj_newgain.fits[energy=9500:12000][cols energy][sky=region($dir/spec_newgain/for_scale.reg)]" | grep "good" | awk '{print $2}')
#areascal=$(awk -v c1=$count_bkg -v t1=$time_bkg -v c2=$count_evt -v t2=$time_evt 'BEGIN{print (c1/t1)/(c2/t2)}')
#echo $obsid $areascal >> $dir/spec_newgain/lbg/areascal.txt
#cd $dir/spec_newgain/lbg
#fparkey $areascal ${obsid}_bkg.pi AREASCAL add=yes
#backscal=$(dmkeypar ${obsid}.pi BACKSCAL echo+)
#area=$(awk -v backs=$backscal 'BEGIN{print backs*8192^2*0.492^2/3600}')
#echo ${obsid}.pi $area >> backscal.txt
#done
#cd $dir/spec_newgain/lbg
#for obsid in $evtname
#do
#ftgrouppha infile=${obsid}.pi outfile=${obsid}.grp grouptype=min groupscale=20 clobber=yes
#done
