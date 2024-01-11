#!/bin/sh

#  data_preparation.sh
#  
#
#  Created by Chaoming Li on 2021/5/3.
#  
##############################
##1. source evts
evtname="20327 20328 20329 20330 20331 20332 20962 20963 20967 21067 21098 21126 21724 21874"
bin_size=2
path=/home/chaomingli/Downloads/pwn
ccdid="0 1 2 3"
cd ${path}
##find & download & reprocess data
##  find_chandra_obsid 20327
##for obsid in ${evtname}
##do
##download_chandra_obsid ${obsid}
##done
##or you can: download_chandra_obsid 20327,20328,...,21874
#for obsid in ${evtname}
#do
#punlearn chandra_repro
#pset chandra_repro indir=${obsid}
#pset chandra_repro outdir=
#pset chandra_repro check_vf_pha=yes
#pset chandra_repro clobber+
#chandra_repro mode=h
#done
#for obsid in ${evtname}
#do 
#cd ${path}/${obsid}/repro
#punlearn dmcopy
#dmcopy "acisf${obsid}_repro_evt2.fits[ccd_id=0,1,2,3]" acisi_${obsid}.fits clobber+
#done
###
##merge observations 
#cd ${path}
#punlearn merge_obs
#pset merge_obs infile=*/repro/acisi_*.fits
#pset merge_obs outroot=merge_bin2/
#pset merge_obs bands=broad
#pset merge_obs binsize=${bin_size}
#pset merge_obs psfecf=0.9
#pset merge_obs psfmerge=expmap
#pset merge_obs clobber+
#merge_obs mode=h
##detect point sources
#cd ${path}/merge_bin2
#punlearn wavdetect
#pset wavdetect infile=broad_thresh.img
#pset wavdetect outfile=src.fits
#pset wavdetect scellfile=src.scell
#pset wavdetect imagefile=src.image
#pset wavdetect defnbkgfile=src.nbkg
#pset wavdetect regfile=src.reg
#pset wavdetect ellsigma=5
#pset wavdetect scales='2 4' 
#pset wavdetect psffile=broad_thresh.psfmap
#pset wavdetect clobber+
#wavdetect mode=h

#ds9 broad_thresh.img -smooth -region src.reg &
#接下来手动将region改为ciao/wcs格式，在探测的点源前加上负号，用于在之后的分析中去除点源

####################################
#remove background flares by filtering lightcurves
#for obsid in $evtname
#do
#
#cd ${path}/${obsid}/repro
#punlearn dmcopy
#dmcopy "acisi_${obsid}.fits[energy=2300:7300]" evt2_lc.fits clobber+
#punlearn dmextract
#dmextract "evt2_lc.fits[exclude sky=region(${path}/src319.reg)][bin time=::50]" lc.fits opt=ltc1 clobber+
#punlearn deflare
#deflare lc.fits outfile=lc.gti method="sigma" nsigma=3 save=deflare_3sigma_ccsrc.png
#punlearn dmcopy
#dmcopy "acisi_${obsid}.fits[@lc.gti]" evt2_clean.fits clobber+
#dmkeypar acisf${obsid}_repro_evt2.fits EXPOSURE echo+
#dmkeypar evt2_clean.fits EXPOSURE echo+
#done
########################
#merge clean events
#punlearn merge_obs
#pset merge_obs infile=2*/repro/evt2_clean.fits
#pset merge_obs outroot=merge_bin2_c/
#pset merge_obs bands=broad
#pset merge_obs binsize=${bin_size}
#pset merge_obs psfecf=0.9
#pset merge_obs psfmerge=expmap
#pset merge_obs clobber+
#merge_obs mode=h
#########################################
##2. background evts(blank-sky)
#creat background fits
#for obsid in $evtname
#do
# cd ${path}/${obsid}/repro
# punlearn blanksky
# blanksky evtfile="evt2_clean.fits" outfile=blanksky.fits clobber+
#done
#rescale background file
#exposure time
#for obsid in $evtname
#do
#cd ${path}/${obsid}/repro
#time_evt=$(dmkeypar evt2_clean.fits EXPOSURE echo+)
#time_bkg=$(dmkeypar blanksky.fits EXPOSURE echo+)
##count number in 9.5-12keV
#count_evt=$(dmstat "evt2_clean.fits[energy=9500:12000][cols energy]" | grep "good" | awk '{print $2}')
#count_bkg=$(dmstat "blanksky.fits[energy=9500:12000][cols energy]" | grep "good" | awk '{print $2}')
##rescale background
#areascal=$(awk -v c1=$count_bkg -v t1=$time_bkg -v c2=$count_evt -v t2=$time_evt 'BEGIN{print (c1/t1)/(c2/t2)}')
#norm=$(awk -v norm=$areascal 'BEGIN{print 1./norm}')
#echo areascal
#echo ${norm}
##creat scaled background image
#produce counts image and exposure map
#punlearn fluximage
#fluximage evt2_clean.fits fluxed binsize=${bin_size} bands=broad clobber+
#find the region covered by an image in sky coordinates
#punlearn get_sky_limits
#get_sky_limits fluxed_broad_thresh.expmap
#dmf=$(pget get_sky_limits dmfilter)
#dmcopy "blanksky.fits[energy=500:7000][bin $dmf]" ${obsid}_blanksky.img clobber+
#dmimgcalc ${obsid}_blanksky.img none ${obsid}_blank_norm.img op="imgout=img1*${norm}*${time_evt}/${time_bkg}" clobber+
#done
#
#######################################
#4. Produce stowed background image
#Using acis_bkgrnd_lookup
#tmp3=2009-09-21 #using this one if not find bgstow
###produce clean event list for each sigle CCD for background subtract individoully.
#for obsid in ${evtname}
#do
#cd ${path}/${obsid}/repro
#for id in ${ccdid}
#do
#punlearn dmcopy
#dmcopy "evt2_clean.fits[ccd_id=${id}]" evt2_I${id}.fits clobber+
#cp -f $CALDB/data/chandra/acis/bkgrnd/acis${id}D${tmp3}bgstow* bgstow_I${id}.fits
###Matching calibration to the event data
#dmkeypar evt2_clean.fits GAINFILE echo+ > match_cal.txt
#dmkeypar bgstow_I0.fits GAINFILE echo+ >> match_cal.txt                                        
#
##Filter to get the VFAINT background
#punlearn dmcopy
#dmcopy "bgstow_I${id}.fits[status=0]" bgstow_VF_I${id}.fits clobber+
##match gain file
#punlearn acis_process_events
#pset acis_process_events infile=bgstow_VF_I${id}.fits
#pset acis_process_events outfile=bgstow_VF_I${id}_newgain.fits
#pset acis_process_events acaofffile=NONE
#pset acis_process_events stop="none"
#pset acis_process_events doevtgrade=no
#pset acis_process_events apply_cti=yes
#pset acis_process_events apply_tgain=no
#pset acis_process_events calculate_pi=yes
#pset acis_process_events pix_adj=NONE
#pset acis_process_events gainfile=$CALDB/data/chandra/acis/det_gain/acisD2000-01-29gain_ctiN0008.fits 
#pset acis_process_events eventdef="{s:ccd_id,s:node_id,i:expno,s:chip,s:tdet,f:det,f:sky,s:phas,l:pha,l:pha_ro,f:energy,l:pi,s:fltgrade,s:grade,x:status}"
#pset acis_process_events clobber+
#acis_process_events mode=h
#
##Reproject the background data
#punlearn reproject_events
#reproject_events bgstow_VF_I${id}_newgain.fits bgstow_proj_I${id}_newgain.fits evt2_I${id}.fits aspect=*_asol1.fits random=0 clobber+
#done
##punlearn dmmerge
#dmmerge "bgstow_proj_I0_newgain.fits,bgstow_proj_I1_newgain.fits,bgstow_proj_I2_newgain.fits,bgstow_proj_I3_newgain.fits" bgstow_proj_newgain.fits clobber+ 
#done

#######################################
##3. merge observations & plot real pwn image

#cd ${path}
#punlearn merge_obs
#merge_obs "*/repro/evt2_clean.fits" merge_clean/ bands=broad bin=${bin_size} psfecf=0.393 psfmerge=exptime
#prepare scaled bkg image and reproject image
#for obsid in $evtname
#do
#  cp ${path}/${obsid}/repro/${obsid}_blank_norm.img ${path}/merge_bin2_c/
#  cd ${path}/merge_bin2_c
#  reproject_image infile="${obsid}_blank_norm.img" matchfile=broad_thresh.expmap outfile=${obsid}_blank_norm_repro.img clobber+
#  
#done

#将多次观测rescale后的背景累加起来
#cd ${path}/merge_bin2_c
#punlearn dmimgcalc
#pset dmimgcalc infile="20327_blank_norm_repro.img,20328_blank_norm_repro.img,20329_blank_norm_repro.img,20330_blank_norm_repro.img,20331_blank_norm_repro.img,20332_blank_norm_repro.img,20962_blank_norm_repro.img,20963_blank_norm_repro.img,20967_blank_norm_repro.img,21067_blank_norm_repro.img,21098_blank_norm_repro.img,21126_blank_norm_repro.img,21724_blank_norm_repro.img,21874_blank_norm_repro.img"
#pset dmimgcalc infile2=none
#pset dmimgcalc outfile=blank_norm.img
#pset dmimgcalc op="imgout=(img1+img2+img3+img4+img5+img6+img7+img8+img9+img10+img11+img12+img13+img14)"
#pset dmimgcalc clobber+
#dmimgcalc mode=h
##exclude point sources and fill the holes
#cp ${path}/src319.reg ${path}/merge_bin2_c/
#punlearn dmmakereg
#dmmakereg "region(src319.reg)" sources.fits wcsfile=broad_thresh.img clobber+
##
#mkdir sources
#punlearn roi
#pset roi infile=sources.fits
#pset roi outsrcfile=sources/src%d.fits
#pset roi bkgfactor=0.5
#roi mode=h
#
#splitroi "sources/src*.fits" exclude
#
#dmmakereg "region(exclude.bg.reg)" exclude.bg.fits
#
#punlearn dmfilth
#pset dmfilth infile=broad_thresh.img
#pset dmfilth outfile=diffuse.img
#pset dmfilth method=POISSON
#pset dmfilth srclist=@exclude.src.reg
#pset dmfilth bkglist=@exclude.bg.reg
#pset dmfilth randseed=0
#dmfilth mode=h
#plot real pwn image: 用diffuse.img减去所有次观测rescale后的背景，除以expmap
#dmimgcalc diffuse.img blank_norm.img subed.img sub clobber+
#dmimgcalc subed.img broad_thresh.expmap real_pwn.img div clobber+
#ds9 real_pwn.img -smooth &
##radial profile
#未做曝光修正的radial profile用于误差估计

#punlearn dmextract
#pset dmextract infile="subed.img[bin sky=@ul_10_20.reg]"
#pset dmextract outfile=ul_c_10_20.fits
#pset dmextract bkg="subed.img[bin sky=@bg.reg]"
#pset dmextract exp=broad_thresh.expmap
#pset dmextract bkgexp=broad_thresh.expmap
#pset dmextract opt=generic
#pset dmextract clobber+
#dmextract mode=h
##曝光修正的流量随半径变化
#punlearn dmextract
#pset dmextract infile="real_pwn.img[bin sky=@ul_10_20.reg]"
#pset dmextract outfile=ul_10_20.fits
#pset dmextract bkg="real_pwn.img[bin sky=@bg.reg]"
#pset dmextract exp=broad_thresh.expmap
#pset dmextract bkgexp=broad_thresh.expmap
#pset dmextract opt=generic
#pset dmextract clobber+
#dmextract mode=h
##用python画图
#from pycrates import read_file
#import matplotlib.pylab as plt
#import numpy as np
#
#counts_data = read_file(r"ul_c_10_20.fits")
#flux_data = read_file(r"ul_10_20.fits")
#xx = flux_data.get_column("rmid").values
#xs = xx/2
#yy = flux_data.get_column("sur_flux").values
#counts_ye = counts_data.get_column("sur_flux_err").values
#counts_yy = counts_data.get_column("sur_flux").values
#flux_ye = yy*counts_ye/counts_yy
#plt.errorbar(xs,yy,yerr=flux_ye, marker="o")
##plt.xscale("log")
##plt.yscale("log")
#plt.xlabel("R_MID (arcsec)")
#plt.ylabel("SUR_BRI (photons/cm**2/pixel**2/s)")
#plt.title('ul_10_20')
#plt.plot(xs,yy)
#plt.show()
