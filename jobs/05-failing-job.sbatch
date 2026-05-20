#!/usr/bin/env bash
#SBATCH --partition=debug
#SBATCH --job-name=failing-eda
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --licenses=synopsys:1
#SBATCH --output=/logs/jobs/slurm-%j.out

synopsys-run --case failing-job --duration 5 --mem-mb 32 --fail
