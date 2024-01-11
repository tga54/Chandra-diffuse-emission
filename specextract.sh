evtname="20327 20328 20329 20330 20331 20332 20962 20963 20967 21067 21098 21126 21724 21874"
dir=/home/chaomingli/Downloads/pwn
for i in {0..6}
do
  mkdir r${i}
  for obsid in ${evtname}
  do
    punlearn specextract
    pset specextract infile="${dir}/${obsid}/repro/evt2_clean.fits[sky=region(${dir}/spec_blanksky/pwn1/spec${i}.reg)]"
    pset specextract outroot=r${i}/${obsid}
    pset specextract bkgfile="${dir}/${obsid}/repro/blanksky.fits[sky=region(${dir}/spec_blanksky/pwn1/spec${i}.reg)]"
    pset specextract bkgresp=no
    pset specextract grouptype=NONE
    pset specextract binspec=NONE
    specextract mode=h
  done
done

