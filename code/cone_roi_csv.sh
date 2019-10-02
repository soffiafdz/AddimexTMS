#!/bin/bash

# usage: $0 atlas roi_csv
# atlas: is the standard atlas, i.e. "MNI152_T1_2mm_brain.nii.gz"
# roi_csv: CSV file with the list of names and respective coordinates in MNI in fsl format (no header).
## -roi <xmin> <xsize> <ymin> <ysize> <zmin> <zsize> <tmin> <tsize>: 
### zero outside roi (using voxel coordinates). Inputting -1 for a size will set it to the full image extent for that dimension. 
## example: 
### sub-002,110,1,86,1,71,1,0,1
### sub-004,99,1,80,1,55,1,0,1

cone_roi() {
  # Create cone shaped ROI for TMS FC

  # Create point in specific location
  fslmaths ${FSLDIR}/data/standard/${atlas} -mul 0 -add 1 -roi ${coords} point;

  # Create spheres for each size.
  fslmaths point -kernel sphere 2 -fmean -bin sphere2mm -odt float;
  fslmaths point -kernel sphere 4 -fmean -bin sphere4mm -odt float;
  fslmaths point -kernel sphere 7 -fmean -bin sphere7mm -odt float;
  fslmaths point -kernel sphere 9 -fmean -bin sphere9mm -odt float;
  fslmaths point -kernel sphere 12 -fmean -thr 0.001 -bin sphere12mm -odt float;

  # Cut each sphere so they fit one inside the other.
  fslmaths sphere12mm -sub sphere9mm sphere12mm -odt float;
  fslmaths sphere9mm -sub sphere7mm sphere9mm -odt float;
  fslmaths sphere7mm -sub sphere4mm sphere7mm -odt float;
  fslmaths sphere4mm -sub sphere2mm sphere4mm -odt float;

  # Give intensities to each sphere.
  fslmaths sphere2mm -mul 5 sphere2mm -odt float;
  fslmaths sphere4mm -mul 4 sphere4mm -odt float;
  fslmaths sphere7mm -mul 3 sphere7mm -odt float;
  fslmaths sphere9mm -mul 2 sphere9mm -odt float;
  fslmaths sphere12mm -mul 1 sphere12mm -odt float;

  # Cut outside cortex.
  fslmaths sphere2mm -mul $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz sphere2mm -odt float;
  fslmaths sphere4mm -mul $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz sphere4mm -odt float;
  fslmaths sphere7mm -mul $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz sphere7mm -odt float;
  fslmaths sphere9mm -mul $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz sphere9mm -odt float;
  fslmaths sphere12mm -mul $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz sphere12mm -odt float;

  # Combine masks.
  fslmaths sphere2mm -add sphere4mm -add sphere7mm -add sphere9mm -add sphere12mm cone_roi_${name} -odt float;

  # Normalize intensity to 1
  fslmaths cone_roi_${name} -inm 1 cone_roi_${name}_norm -odt float
  
  # Remove preliminary files
  #rm point* sphere*
  
  echo "cone_roi_${name} is finished"
}

atlas=$1;
roi_csv=$2;

while IFS="," read name xmin xsize ymin ysize zmin zsize tmin tsize; do 
  coords="$xmin $xsize $ymin $ysize $zmin $zsize $tmin $tsize"
  echo "Cone ROI: ${name}; Coordinates: $coords"
  cone_roi
done < $roi_csv
