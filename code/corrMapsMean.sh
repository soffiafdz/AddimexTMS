#!/bin/bash
for dir in r z; do
    echo "Doing average of ${dir} correlations"
    for GSR in [0-9]_corr* _woGSR_corr*; do 
        for stimZs in $(ls ${dir}/sub-007*${GSR}); do
            for stimZ in ${stimZs#${dir}/sub-00?}; do
                fslmerge -t ${dir}/meanSeries${stimZ} ${dir}/sub*${stimZ}
                fslmaths ${dir}/meanSeries${stimZ} -Tmean ${dir}/mean${stimZ} -odt input
            done
        done
    done
    echo "Done with ${dir} average"
done

    
