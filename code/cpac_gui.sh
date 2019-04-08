#!/bin/bash

singularity run \
        -B /run/media/sofdez/Alpha/TMS/bids:/bids_dataset \
        -B /run/media/sofdez/Alpha/TMS/cpac:/outputs \
        /home/sofdez/singularity_images/bids_cpac*.img \
        /bids_dataset \
        /outputs\
        GUI
