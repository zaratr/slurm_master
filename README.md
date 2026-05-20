# Slurm Style HPC Lab

This repo builds a local Docker Desktop lab that approximates the environment HPC Engineering: RHEL-family Linux, Slurm as the open-source scheduler analog for LSF/SGE/RTDA-style grids, shared project/scratch paths, scheduler-visible EDA licenses, mock Cadence/Synopsys/Siemens jobs, accounting, and monitoring.

Traditional HPC side:
You are running Slurm, slurmctld, slurmd, slurmdbd, Munge auth, MariaDB accounting, partitions, node visibility, job submission, and license-aware scheduling. That shows you understand the older infrastructure model that engineering teams already depend on.

Modern platform side:
You are packaging the stack into one Rocky Linux container image, deploying it through Kubernetes, using Services, Deployments, StatefulSets, PVCs, ConfigMaps, Secrets, and namespace isolation. That shows you can move legacy scheduler infrastructure onto a cloud-native substrate without pretending Kubernetes replaces every HPC concern.

Distributed AI side:
The same worker image includes OpenMPI, Python, TensorFlow, and mpi4py. When you submit a Slurm job that runs mpirun and TensorFlow inside the cluster, you are proving that AI workloads can run through the same scheduling path as traditional batch workloads.

## Quick Start

```powershell
docker compose build
docker compose up -d
docker compose exec -u hpcuser login bash
```

Inside the `login` container:

```bash
sinfo
sbatch /projects/eda/jobs/01-short-sim.sbatch
squeue
sacct -X --format=JobID,JobName,State,Elapsed,AllocCPUS
eda-license-status
```

Prometheus is available at `http://localhost:9090`.
Grafana is available at `http://localhost:3000` with `admin` / `admin`.

## How To use Flow

Run these from the login container:

```bash
sbatch /projects/eda/jobs/01-short-sim.sbatch
sbatch /projects/eda/jobs/02-long-memory.sbatch
sbatch /projects/eda/jobs/03-regression-array.sbatch
sbatch /projects/eda/jobs/04-license-starved.sbatch
sbatch /projects/eda/jobs/05-failing-job.sbatch
/projects/eda/jobs/06-utilization-report.sh
```

The license-starved example requests one Cadence license for three array tasks. Because `slurm.conf` declares only `cadence:1`, the pending/running behavior is visible with `squeue` and `scontrol show job`.

## Compatibility Wrappers

These wrappers submit Slurm jobs while preserving the feel of common semiconductor grid schedulers:

```bash
bsub -q eda -J lsf-demo -n 1 -M 256 -lic cadence:1 cadence-run --case bsub --duration 10
qsub -q eda -N sge-demo -pe smp 1 -l h_vmem=256M -l license=synopsys:1 synopsys-run --case qsub --duration 10
rtda-submit --queue eda --name rtda-demo --cores 1 --mem 256M --license siemens:1 siemens-run --case rtda --duration 10
```

## Useful Paths

- `/home/hpcuser`
- `/projects/eda`
- `/scratch`
- `/tools/eda-mock`
- `/logs/jobs`

## Cleanup

```powershell
docker compose down
docker compose down -v
```

Use `down -v` only when you want to delete Slurm accounting state, logs, and shared lab data.

## CI

GitHub Actions runs `scripts/ci-smoke-test.sh` on pushes, pull requests, and manual dispatch. The workflow builds the Rocky Slurm image, starts Docker Compose, verifies Slurm nodes and license pools, runs short mock EDA jobs, checks wrapper submissions, validates a license-starved pending job, and confirms the metrics endpoint.

Run the same smoke test from a Linux shell or WSL:

```bash
bash scripts/ci-smoke-test.sh
```
