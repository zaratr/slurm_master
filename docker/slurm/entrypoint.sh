#!/usr/bin/env bash
set -euo pipefail

role="${1:-login}"

prepare_runtime() {
  mkdir -p /run/munge /run/slurm /var/log/munge /var/log/slurm /var/spool/slurm/ctld /var/spool/slurm/d /logs/jobs /scratch/eda-licenses
  chown -R munge:munge /run/munge /var/log/munge
  chown -R slurm:slurm /var/log/slurm /var/spool/slurm
  chown -R hpcuser:hpcuser /logs /scratch || true

  if [[ -d /config/slurm ]]; then
    install -o root -g root -m 0644 /config/slurm/slurm.conf /etc/slurm/slurm.conf
    [[ -f /config/slurm/cgroup.conf ]] && install -o root -g root -m 0644 /config/slurm/cgroup.conf /etc/slurm/cgroup.conf
    [[ -f /config/slurm/slurmdbd.conf ]] && install -o slurm -g slurm -m 0600 /config/slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf
  fi

  if [[ -f /munge/munge.key ]]; then
    install -o munge -g munge -m 0400 /munge/munge.key /etc/munge/munge.key
  fi

  if [[ -f /etc/munge/munge.key ]]; then
    munged --force
  fi

  if [[ -x /tools/eda-mock/cadence-run ]]; then
    ln -sf /tools/eda-mock/cadence-run /usr/local/bin/cadence-run
    ln -sf /tools/eda-mock/synopsys-run /usr/local/bin/synopsys-run
    ln -sf /tools/eda-mock/siemens-run /usr/local/bin/siemens-run
    ln -sf /tools/eda-mock/eda-license-status /usr/local/bin/eda-license-status
    ln -sf /tools/eda-mock/hpc-metrics /usr/local/bin/hpc-metrics
  fi
  if [[ -x /tools/scheduler-wrappers/bsub ]]; then
    ln -sf /tools/scheduler-wrappers/bsub /usr/local/bin/bsub
    ln -sf /tools/scheduler-wrappers/qsub /usr/local/bin/qsub
    ln -sf /tools/scheduler-wrappers/rtda-submit /usr/local/bin/rtda-submit
  fi
}

case "$role" in
  init-munge-key)
    mkdir -p /munge
    if [[ ! -f /munge/munge.key ]]; then
      dd if=/dev/urandom of=/munge/munge.key bs=1024 count=1 status=none
    fi
    chown munge:munge /munge/munge.key
    chmod 0400 /munge/munge.key
    ;;
  slurmdbd)
    prepare_runtime
    until mariadb-admin ping -h mariadb -uslurm -pslurm --silent; do
      sleep 2
    done
    exec slurmdbd -D -vvv
    ;;
  slurmctld)
    prepare_runtime
    sleep 4
    exec slurmctld -D -vvv
    ;;
  slurmd)
    prepare_runtime
    sleep 8
    exec slurmd -D -vvv
    ;;
  login)
    prepare_runtime
    ssh-keygen -A
    /usr/sbin/sshd
    printf 'Microchip-style Slurm lab login node ready. Use: docker compose exec -u hpcuser login bash\n'
    exec tail -f /dev/null
    ;;
  metrics)
    prepare_runtime
    exec /usr/local/bin/hpc-metrics
    ;;
  *)
    prepare_runtime
    exec "$@"
    ;;
esac
