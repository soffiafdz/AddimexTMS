#!/bin/bash

###Insert warning and usage if no arguments supplied#####

usg="Usage: $0 <sourcedir> <coordinates CSV file>"

stdFile=/run/media/soffiafdz/Omega/TMS/sourcedata/standards
std=MNI152_T1_2mm.nii.gz
stdMsk=MNI152_T1_2mm_brain_mask.nii.gz
dir=$1
csv=$2

# Functions
point() { #t1wDirectory #outDirectory #name
    # Create point in specific location in native map
    docker run --rm -v ${dir}:/data bids/base_fsl \
        fslmaths /data/${1} \
        -mul 0 \
        -add 1 \
        -roi ${coords} \
        /data/${2}/${3} \
        -odt float;
    docker run --rm -v ${dir}:/data bids/base_fsl \
        fslmaths /data/${2}/${3} \
        -bin \
        /data/${2}/${3};
}

normalization() { #inFile #outFile
    docker run --rm -v ${dir}:/data -v ${stdFile}:/stdDir soff/ants \
        ANTS 3 \
        -m CC[/stdDir/${std},/data/${1},1,4] \
        -i 50x20x10 \
        -o /data/${2} \
        -t SyN[0.1,3,0]
}

warpAnts() { #inFile #Warp/Affine #outFile
    docker run --rm -v ${dir}:/data -v ${stdFile}:/stdDir soff/ants \
        WarpImageMultiTransform 3 /data/${1} \
        /data/${3}.nii.gz \
        -R /stdDir/$std /data/${2}Warp.nii.gz \
        /data/${2}Affine.txt;

}

sphere() { #inFile #outDir #outFile
    # Create sphere
    dock_fsl="docker run --rm -v ${dir}:/data bids/base_fsl"
    $dock_fsl fslmaths /data/$1 \
        -kernel sphere 2 \
        -fmean \
        -thr 0.001 \
        -bin /data/${2}/${3} \
        -odt float;
}

cone() { #inFile #outDir #outFile
## Create cone shaped ROI for TMS FC
    dock_fsl="docker run --rm -v ${dir}:/data -v ${stdFile}:/stdDir bids/base_fsl"

    # Create spheres for each size.
    $dock_fsl fslmaths /data/$1 \
        -kernel sphere 2 \
        -fmean -bin \
        /data/${2}/pre_sphere2mm \
        -odt float;
    $dock_fsl fslmaths /data/$1 \
        -kernel sphere 4 \
        -fmean -bin \
        /data/${2}/pre_sphere4mm \
        -odt float;
    $dock_fsl fslmaths /data/$1 \
        -kernel sphere 7 \
        -fmean -bin \
        /data/${2}/pre_sphere7mm \
        -odt float;
    $dock_fsl fslmaths /data/$1 \
        -kernel sphere 9 \
        -fmean -bin \
        /data/${2}/pre_sphere9mm \
        -odt float;
    $dock_fsl fslmaths /data/$1 \
        -kernel sphere 12 \
        -fmean -thr 0.001 -bin \
        /data/${2}/pre_sphere12mm \
        -odt float;

    # Cut each sphere so they fit one inside the other.
    $dock_fsl fslmaths /data/${2}/pre_sphere12mm \
        -sub /data/${2}/pre_sphere9mm \
        /data/${2}/pre_sphere12mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere9mm \
        -sub /data/${2}/pre_sphere7mm \
        /data/${2}/pre_sphere9mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere7mm \
        -sub /data/${2}/pre_sphere4mm \
        /data/${2}/pre_sphere7mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere4mm \
        -sub /data/${2}/pre_sphere2mm \
        /data/${2}/pre_sphere4mm \
        -odt float;

    # Give intensities to each sphere.
    $dock_fsl fslmaths /data/${2}/pre_sphere2mm \
        -mul 5 \
        /data/${2}/pre_sphere2mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere4mm \
        -mul 4 \
        /data/${2}/pre_sphere4mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere7mm \
        -mul 3 \
        /data/${2}/pre_sphere7mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere9mm \
        -mul 2 \
        /data/${2}/pre_sphere9mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere12mm \
        -mul 1 \
        /data/${2}/pre_sphere12mm \
        -odt float;

    # Cut outside cortex.
    $dock_fsl fslmaths /data/${2}/pre_sphere2mm \
        -mul /stdDir/$stdMsk \
        /data/${2}/pre_sphere2mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere4mm \
        -mul /stdDir/$stdMsk \
        /data/${2}/pre_sphere4mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere7mm \
        -mul /stdDir/$stdMsk \
        /data/${2}/pre_sphere7mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere9mm \
        -mul /stdDir/$stdMsk \
        /data/${2}/pre_sphere9mm \
        -odt float;
    $dock_fsl fslmaths /data/${2}/pre_sphere12mm \
        -mul /stdDir/$stdMsk \
        /data/${2}/pre_sphere12mm \
        -odt float;

    # Combine masks.
    $dock_fsl fslmaths /data/${2}/pre_sphere2mm \
        -add /data/${2}/pre_sphere4mm \
        -add /data/${2}/pre_sphere7mm \
        -add /data/${2}/pre_sphere9mm \
        -add /data/${2}/pre_sphere12mm \
        /data/${2}/${3} \
        -odt float;

    # Normalize intensity to 1
    $dock_fsl fslmaths /data/${2}/${3} \
        -inm 1 \
        /data/${2}/${3}Norm \
        -odt float

    # Remove preliminary files
    rm ${dir}/${2}/pre*
}


#Body
if [ $# -lt 2 ]; then
    echo $usg;
    exit 0;
elif [ ! -e $1 ]; then
    echo "can't find source directory";
    exit 0;
elif [ ! -e $2 ]; then
    echo "can't find CSV files";
    exit 0;
else
    while IFS="," read rid x y z ; do
        coords="$x 1 $y 1 $z 1 0 1"
        t1w=lin_correg/${rid}/vit/structural_head.nii.gz
        echo "#####"$rid"######"

        #echo "##### Normalizing t1w #####"
        #mkdir -p ${dir}/mni_norm/${rid}
        #normalization $t1w \
            #mni_norm/${rid}/${rid}_2_mni

        echo "##### Making stim-point mask in native space #####"
        mkdir -p ${dir}/nativeStimPnt
        point $t1w \
            nativeStimPnt \
            ${rid}nativePnt;

        echo "##### Warping stim-point #####"
        mkdir -p ${dir}/mniStimSite
        warpAnts nativeStimPnt/${rid}nativePnt \
            mni_norm/${rid}/${rid}_2_mni \
            mniStimSite/${rid}mniPnt;


        echo "##### Making stim-point spheres #####"
        mkdir -p ${dir}/coneSeedsMNI
        sphere mniStimSite/${rid}mniPnt \
            coneSeedsMNI \
            ${rid}mniSphere;
        echo "##### Making stim-point spheres #####"
        cone mniStimSite/${rid}mniPnt \
            coneSeedsMNI \
            ${rid}mniCone
    done < $csv
fi
