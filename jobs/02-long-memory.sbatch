#!/usr/bin/env bash
#SBATCH --partition=long
#SBATCH --job-name=long-synopsys
#SBATCH --cpus-per-task=1
#SBATCH --mem=768M
#SBATCH --licenses=synopsys:1
#SBATCH --output=/logs/jobs/slurm-%j.out

synopsys-run --case long-memory --duration 45 --mem-mb 256
