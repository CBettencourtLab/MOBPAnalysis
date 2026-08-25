#!/bin/bash
#SBATCH --export=ALL # export all environment variables to the batch job.
#SBATCH -p mrcq # submit to queue
#SBATCH --time=14:00:00 # Maximum wall time 
#SBATCH -A Research_Project-T112069
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=32gb 
#SBATCH --ntasks-per-node=16
#SBATCH --mail-type=END
#SBATCH --mail-user=J.D.Harvey@exeter.ac.uk
#SBATCH --error=/lustre/projects/Research_Project-T112069/Genetics/MOBP/11_STAR/error_allign.err
#SBATCH --job-name=STAR_align
#SBATCH --array=0-15
#SBATCH --output=logs/star_%A_%a.out
#SBATCH --error=logs/star_%A_%a.err

echo Loading STAR

module load STAR

echo Reading Samples

# Get sample name for this task
samples=($(ls /lustre/projects/Research_Project-T112069/Genetics/MOBP/11_fastp_trimmed/*_R1_001_fastp.fastq.gz | sed 's/_R1_001_fastp.fastq.gz//')) 
samples=($(for s in "${samples[@]}"; do echo "${s##*/}"; done))

n_samples=${#samples[@]}

echo "${n_samples} being processed"

window=$(( n_samples / SLURM_ARRAY_TASK_COUNT + 1))
lower=$(( SLURM_ARRAY_TASK_ID * window ))
next=$(( SLURM_ARRAY_TASK_ID + 1 ))
upper=$(( next * window ))

if [ "$SLURM_ARRAY_TASK_ID" -eq "$SLURM_ARRAY_TASK_MAX"]; then
  upper=$n_samples
fi

for((i=$lower;i<$upper;i++))
do  
  echo ${i}
  name=${samples[$i]}

  echo "Processing ${name}"

  R1=/lustre/projects/Research_Project-T112069/Genetics/MOBP/11_fastp_trimmed/${name}_R1_001_fastp.fastq.gz
  R2=/lustre/projects/Research_Project-T112069/Genetics/MOBP/11_fastp_trimmed/${name}_R2_001_fastp.fastq.gz

  echo ${R1}
  echo ${R2}

  save_directory=/lustre/projects/Research_Project-T112069/Genetics/MOBP/11_STAR/${name}

  mkdir -p ${save_directory}

  OUTBAM=${save_directory}/${name}Aligned.out.sam
  LOGFILE=${save_directory}/${name}_Log.final.out

  if [ -f "$OUTBAM" ] && [ -f "$LOGFILE" ]; then
    echo "Skipping ${name} — already completed"
    exit 0
  fi

    STAR \
      --genomeDir /lustre/projects/Research_Project-T112069/Reference/Genomes \
      --readFilesIn ${R1} ${R2} \
      --readFilesCommand zcat \
      --twopassMode Basic \
      --outSAMstrandField intronMotif \
      --outSAMtype BAM SortedByCoordinate \
      --runThreadN 16 \
      --outFileNamePrefix ${save_directory}/${name}_

  echo "Processed ${name}" 
done


