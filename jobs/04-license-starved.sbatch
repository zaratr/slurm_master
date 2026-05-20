#!/usr/bin/env bash
#SBATCH --partition=eda
#SBATCH --job-name=license-starved
#SBATCH --array=1-3
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --licenses=cadence:1
#SBATCH --output=/logs/jobs/slurm-%A_%a.out

cadence-run --case "license-starved-${SLURM_ARRAY_TASK_ID}" --duration 30 --mem-mb 32
