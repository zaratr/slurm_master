#!/usr/bin/env bash
set -euo pipefail

echo "== Nodes =="
sinfo -N -l
echo
echo "== Queue =="
squeue -o "%.18i %.10P %.24j %.8u %.2t %.10M %.6D %R %b"
echo
echo "== Accounting =="
sacct -X --format=JobID,JobName,Partition,Account,AllocCPUS,State,Elapsed,MaxRSS
echo
echo "== Licenses =="
eda-license-status
