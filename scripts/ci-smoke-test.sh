#!/usr/bin/env bash
set -euo pipefail

run_login() {
  docker compose exec -T -u hpcuser login bash -lc "$*"
}

dump_slurm_debug() {
  echo "== docker compose ps ==" >&2
  docker compose ps >&2 || true
  echo "== sinfo ==" >&2
  run_login "sinfo -N -l" >&2 || true
  echo "== nodes ==" >&2
  run_login "scontrol show nodes" >&2 || true
  echo "== slurmctld logs ==" >&2
  docker compose logs --no-color slurmctld >&2 || true
  echo "== slurmdbd logs ==" >&2
  docker compose logs --no-color slurmdbd >&2 || true
  echo "== compute1 logs ==" >&2
  docker compose logs --no-color compute1 >&2 || true
  echo "== compute2 logs ==" >&2
  docker compose logs --no-color compute2 >&2 || true
}

retry() {
  local description="$1"
  local max_attempts="$2"
  local sleep_seconds="$3"
  shift 3

  local attempt=1
  until "$@"; do
    if (( attempt >= max_attempts )); then
      echo "${description} failed after ${attempt} attempts." >&2
      return 1
    fi
    echo "${description} failed; retrying in ${sleep_seconds}s (${attempt}/${max_attempts})..." >&2
    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
  done
}

wait_for() {
  local description="$1"
  local command="$2"
  local timeout="${3:-120}"
  local start
  start="$(date +%s)"

  until eval "$command"; do
    if (( "$(date +%s)" - start > timeout )); then
      echo "Timed out waiting for: ${description}" >&2
      if [[ "$description" == Slurm* ]]; then
        dump_slurm_debug
      fi
      return 1
    fi
    sleep 3
  done
}

wait_for_job_state() {
  local job_id="$1"
  local expected="$2"
  local timeout="${3:-120}"
  local start state
  start="$(date +%s)"

  while true; do
    state="$(run_login "sacct -n -X -j ${job_id} -o State | awk 'NF { print \$1; exit }'" | tr -d '[:space:]')"
    if [[ "$state" == "$expected" ]]; then
      return 0
    fi
    if [[ "$state" == FAILED* || "$state" == CANCELLED* || "$state" == TIMEOUT* ]]; then
      echo "Job ${job_id} reached unexpected state: ${state}" >&2
      return 1
    fi
    if (( "$(date +%s)" - start > timeout )); then
      echo "Timed out waiting for job ${job_id} to reach ${expected}; current state: ${state:-unknown}" >&2
      return 1
    fi
    sleep 3
  done
}

docker compose down -v --remove-orphans
retry "Docker Compose build" 3 20 docker compose build
docker compose up -d

wait_for "login container" "docker compose exec -T -u hpcuser login true" 120
wait_for "Slurm idle nodes" "run_login 'sinfo -h -N -o \"%t\"' | awk 'BEGIN { idle=0 } /idle/ { idle++ } END { exit idle >= 2 ? 0 : 1 }'" 300

run_login "sinfo"
run_login "scontrol show licenses | grep -q 'LicenseName=cadence'"
run_login "scontrol show licenses | grep -q 'LicenseName=synopsys'"
run_login "scontrol show licenses | grep -q 'LicenseName=siemens'"

short_job="$(run_login "sbatch /projects/eda/jobs/01-short-sim.sbatch" | awk '{print $4}')"
wait_for_job_state "$short_job" "COMPLETED" 120
run_login "test -f /logs/jobs/slurm-${short_job}.out"
run_login "test -f /logs/jobs/${short_job}/cadence-short-sim.jsonl"

qsub_job="$(run_login "qsub -q debug -N ci-qsub -pe smp 1 -l h_vmem=256M -l license=synopsys:1 synopsys-run --case ci-qsub --duration 3 --mem-mb 16" | awk '{print $4}')"
wait_for_job_state "$qsub_job" "COMPLETED" 120

rtda_job="$(run_login "rtda-submit --queue debug --name ci-rtda --cores 1 --mem 256M --license siemens:1 siemens-run --case ci-rtda --duration 3 --mem-mb 16" | awk '/Submitted batch job/ { print $4 }')"
wait_for_job_state "$rtda_job" "COMPLETED" 120

license_job="$(run_login "sbatch /projects/eda/jobs/04-license-starved.sbatch" | awk '{print $4}')"
wait_for "license-constrained pending task" "run_login 'squeue -h -j ${license_job} -o \"%R\"' | grep -q Licenses" 30
run_login "scancel ${license_job}"

run_login "curl -fsS http://monitoring:9100/metrics | grep -q 'slurm_lab_nodes_known 2'"
run_login "curl -fsS http://monitoring:9100/metrics | grep -q 'slurm_lab_jobs_completed'"

run_login "sacct -X --format=JobID,JobName,State,ExitCode,Elapsed,AllocCPUS"
