for i in $(ls */*/fmap/*.json); do     
    base=${i%/*/*} #sub-029/ses-t0;
    ses=${base#*/}
    base=${base/\//_};      
    if grep -q FM_DTI $i; then         
        echo "$i is a fieldmap for DTI";         
        sed -i "s|\"IntendedFor.*|\"IntendedFor\": \"${ses}/dwi/${base}_dwi.json\"|" $i;      
    else          
        echo "$i is not a fieldmap for DTI, so it's for EPI";         
        sed -i "s|\"IntendedFor.*|\"IntendedFor\": \"${ses}/func/${base}_task-rest_bold.json\"|" $i;     
    fi; 
done


for i in $(ls */*/func/*.json); do
    
