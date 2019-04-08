#!/bin/bash
##Run from directory of seeds "Seeds3"

## name     sub x   y   z 
## stimZ    002 -35 61  78  

 
home=$(pwd)
std=${FSLDIR}/data/standard/MNI152_T1_3mm.nii.gz
stdMsk=${FSLDIR}/data/standard/MNI152_T1_3mm_brain_mask.nii.gz
csv=$1

point() { #t1
    # Create point in specific location in MNI map
    fslmaths $std -mul 0 -add 1 -roi ${coords} ${sub}_${name}_pnt -odt float;
    fslmaths ${sub}_${name}_pnt -bin ${sub}_${name}_pnt
}

sphere() { #${sub}_pnt
    # Create sphere
    fslmaths $1 -kernel sphere 2 -fmean -thr 0.001 -bin ${sub}_${name}_sph -odt float;
}


cone() { #${sub}_pnt
## Create cone shaped ROI for TMS FC

    # Create spheres for each size.
    fslmaths $1 -kernel sphere 2 -fmean -bin pre_sphere2mm -odt float;
    fslmaths $1 -kernel sphere 4 -fmean -bin pre_sphere4mm -odt float;
    fslmaths $1 -kernel sphere 7 -fmean -bin pre_sphere7mm -odt float;
    fslmaths $1 -kernel sphere 9 -fmean -bin pre_sphere9mm -odt float;
    fslmaths $1 -kernel sphere 12 -fmean -thr 0.001 -bin pre_sphere12mm -odt float;

    # Cut each sphere so they fit one inside the other.
    fslmaths pre_sphere12mm -sub pre_sphere9mm pre_sphere12mm -odt float;
    fslmaths pre_sphere9mm -sub pre_sphere7mm pre_sphere9mm -odt float;
    fslmaths pre_sphere7mm -sub pre_sphere4mm pre_sphere7mm -odt float;
    fslmaths pre_sphere4mm -sub pre_sphere2mm pre_sphere4mm -odt float;

    # Give intensities to each sphere.
    fslmaths pre_sphere2mm -mul 5 pre_sphere2mm -odt float;
    fslmaths pre_sphere4mm -mul 4 pre_sphere4mm -odt float;
    fslmaths pre_sphere7mm -mul 3 pre_sphere7mm -odt float;
    fslmaths pre_sphere9mm -mul 2 pre_sphere9mm -odt float;
    fslmaths pre_sphere12mm -mul 1 pre_sphere12mm -odt float;

    # Cut outside cortex.
    fslmaths pre_sphere2mm -mul $stdMsk pre_sphere2mm -odt float;
    fslmaths pre_sphere4mm -mul $stdMsk pre_sphere4mm -odt float;
    fslmaths pre_sphere7mm -mul $stdMsk pre_sphere7mm -odt float;
    fslmaths pre_sphere9mm -mul $stdMsk pre_sphere9mm -odt float;
    fslmaths pre_sphere12mm -mul $stdMsk pre_sphere12mm -odt float;

    # Combine masks.
    fslmaths pre_sphere2mm -add pre_sphere4mm -add pre_sphere7mm -add pre_sphere9mm -add pre_sphere12mm ${sub}_cone -odt float;

    # Normalize intensity to 1
    fslmaths ${sub}_cone -inm 1 ${sub}_cone_norm -odt float
  
    # Remove preliminary files
    rm pre* 
}



while IFS="," read name sub x y z; do 
    coords="$x 1 $y 1 $z 1 0 1"
    echo "#######Point#######"
    point $std #[or MNI???]
    echo "#######Sphere#######"
    sphere ${sub}_${name}_pnt
    echo "#######Cone#######"
    cone ${sub}_${name}_pnt
done < $csv





