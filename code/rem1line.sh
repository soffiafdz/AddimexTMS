for mat in $(ls -d */*/*/*/*{r,z}.csv); do 
	sed -i '1d' $mat;
done
