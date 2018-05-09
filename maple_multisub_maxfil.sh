#!/bin/bash

usage="$(basename "$0") [-h] [-s -b -f] -- Program for Maxfilter 2.2.15  automation. USE: -s "\""subject1 subjectn.."\"" -b "\""badch1 bachn.."\"" -f "\""project folder"\"""
extrainfo=" -- UNDER CONSTRUCTION as of May 2018 --. Mario.Perez@dzne.de."

# CLI arguments parser
while getopts "hs:b:f:" opt; do
    case "${opt}" in
       h)
            echo $usage
            echo $extrainfo
            exit;;
       s)
            idsb=("$OPTARG");;
       b)
            badchan=${OPTARG};;
       f)
            studyfold=${OPTARG};;
    esac
done

ctc=/neuro/databases/ctc/ct_sparse.fif
cal=/neuro/databases/sss/sss_cal.dat
stp2=lp  #name of the output fifles from the second step (low pass filter).
stp3=sss
#stp2b=mvcmp

for id in $idsb; do

    cd $studyfold/*$id*/*/

for fifles in $(find .  -type f -name "*$id.fif" -o  -name "*$id-1.fif" -o -name "*$id-2.fif"); do

    #Estimate head position
    if [ ! -f  "${fifles%.*}_quat.fif" ]; then
    /neuro/bin/util/maxfilter -f ${fifles} -ctc $ctc -cal $cal -autobad off -headpos -hp ${fifles%.*}_hdposdat.log -v | tee ${fifles%.*}_fulllog_hdposdat.log ;
    else echo "-- Headpos already estimated for $fifles --"; fi  # headpos estimation does SSS!
    #Perform low pass filtering- maxfilter may not manage to low pass or downsample at the same time as SSS
    if [ ! -f "${fifles%.*}_$stp2.fif" ]; then
    /neuro/bin/util/maxfilter -f ${fifles} -o ${fifles%.*}_$stp2.fif -lpfilt 150 -nosss -v | tee ${fifles%.*}_$stp2.log;
    else echo "-- Low pass filtering done for $fifles --"; fi
    #Step 3 - Perform SSS (no transformation to any head coordinates - done later )
    if [ ! -f "${fifles%.*}_$stp2\_$stp3.fif" ]; then
    /neuro/bin/util/maxfilter -f ${fifles%.*}_$stp2.fif -o ${fifles%.*}_$stp2\_$stp3.fif -ctc $ctc  -cal $cal -autobad on -bad ${badchan} -v | tee ${fifles%.*}_$stp2\_$stp3\.log;
    else echo "-- SSS was already applied for $fifles--"; fi
    #Step 2B- Perform movement compensation and SSS using no filtered data, movement comepensation (if extraction fails, to the last known position)
    #/neuro/bin/util/maxfilter -f ${fifle} -o ${fifle%.*}_$stp2b.fif -ctc $ctc -cal $cal  -movecomp inter -hpistep 200 -autobad on -force | tee ${fifle%.*}_$stp2b.log

done
done
