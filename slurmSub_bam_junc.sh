#!/bin/bash
#SBATCH --export=ALL # export all environment variables to the batch job.
#SBATCH -p mrcq # submit to queue
#SBATCH --time=2:00:00 # Maximum wall time 
#SBATCH -A Research_Project-T112069
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=32gb 
#SBATCH --ntasks-per-node=16
#SBATCH --mail-type=END
#SBATCH --mail-user=J.D.Harvey@exeter.ac.uk
#SBATCH --job-name=bam2junc
#SBATCH --array=0-15
#SBATCH --output=logs/bam2junc_%A_%a.out
#SBATCH --error=logs/bam2junc_%A_%a.err

conda activate leafCutter

samples=($(ls -d *10202*))

n_samples=${#samples[@]}
  
echo "${n_samples} being processed"
  
window=$(( n_samples / SLURM_ARRAY_TASK_COUNT + 1))
lower=$(( SLURM_ARRAY_TASK_ID * window ))
next=$(( SLURM_ARRAY_TASK_ID + 1 ))
upper=$(( next * window ))


if [ "$SLURM_ARRAY_TASK_ID" -eq "$SLURM_ARRAY_TASK_MAX"]; then
  upper=$n_samples
fi

test_juncfiles=/lustre/projects/Research_Project-T112069/Genetics/MOBP/11_STAR/test_juncfiles.txt > ${test_juncfiles}


for((i=$lower;i<$upper;i++))
    do  
    echo ${i}
    name=${samples[$i]}

    echo "Processing ${name}"

    bam_file=/lustre/projects/Research_Project-T112069/Genetics/MOBP/11_STAR/${name}/${name}_Aligned.sortedByCoord.out.bam
    save_directory=/lustre/projects/Research_Project-T112069/Genetics/MOBP/11_STAR/${name}

    echo Converting ${bam_file} to ${bam_file}.junc
    samtools index ${bam_file}
    regtools junctions extract -a 8 -m 50 -s XS -r chr3 -M 500000 ${bam_file} -o ${bam_file}.junc
    echo ${bam_file}.junc >> ${test_juncfiles}

    echo "Processed ${name}" 
done


