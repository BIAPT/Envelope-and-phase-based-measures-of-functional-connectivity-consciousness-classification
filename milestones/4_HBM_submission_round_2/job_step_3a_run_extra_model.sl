#!/bin/bash
#SBATCH --job-name=run_extra_model
#SBATCH --account=def-sblain
#SBATCH --mem=90000      # increase as needed
#SBATCH --time=0-00:20:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=q2h3s6p4k0e9o7a5@biaptlab.slack.com # adjust this to match your email address
#SBATCH --mail-type=ALL

module load python/3.7.4

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip
pip install --no-index scikit-learn
pip install --no-index pandas
python -u step_3_run_final_model/run_final_extra_model.py $ANALYSIS_PARAM