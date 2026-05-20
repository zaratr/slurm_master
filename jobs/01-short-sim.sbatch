#!/usr/bin/env bash
#SBATCH --partition=debug
#SBATCH --job-name=short-cadence
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --licenses=cadence:1
#SBATCH --output=/logs/jobs/slurm-%j.out

cadence-run --case short-sim --duration 8 --mem-mb 32
