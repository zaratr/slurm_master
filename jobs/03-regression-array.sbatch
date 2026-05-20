#!/usr/bin/env bash
#SBATCH --partition=eda
#SBATCH --job-name=siemens-array
#SBATCH --array=1-6%2
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --licenses=siemens:1
#SBATCH --output=/logs/jobs/slurm-%A_%a.out

siemens-run --case "regression-${SLURM_ARRAY_TASK_ID}" --duration 10 --mem-mb 32
