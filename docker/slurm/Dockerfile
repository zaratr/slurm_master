FROM rockylinux:9

RUN printf '%s\n' \
      'retries=5' \
      'timeout=60' \
      'minrate=1000' \
      'max_parallel_downloads=3' \
      'fastestmirror=True' \
      'skip_if_unavailable=True' \
      >> /etc/dnf/dnf.conf && \
    dnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False install epel-release && \
    dnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False install \
      bash-completion \
      bind-utils \
      hostname \
      iproute \
      jq \
      less \
      lsof \
      mariadb \
      munge \
      munge-libs \
      ncurses \
      openssh-server \
      procps-ng \
      python3 \
      python3-flask \
      slurm \
      slurm-devel \
      slurm-perlapi \
      slurm-slurmctld \
      slurm-slurmd \
      slurm-slurmdbd \
      sudo \
      tar \
      time \
      vim-minimal \
      which && \
    dnf clean all && \
    rm -rf /var/cache/dnf/*

RUN getent group slurm >/dev/null || groupadd -r slurm && \
    id slurm >/dev/null 2>&1 || useradd -r -g slurm -d /var/lib/slurm -s /sbin/nologin slurm && \
    groupadd -g 2000 hpcuser && \
    useradd -m -u 2000 -g 2000 -s /bin/bash hpcuser && \
    echo 'hpcuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/hpcuser && \
    chmod 0440 /etc/sudoers.d/hpcuser && \
    mkdir -p /etc/slurm /var/spool/slurm/ctld /var/spool/slurm/d /var/log/slurm \
      /run/munge /var/log/munge /munge /projects/eda /scratch /tools/eda-mock /logs/jobs && \
    chown -R slurm:slurm /var/spool/slurm /var/log/slurm && \
    chown -R munge:munge /run/munge /var/log/munge /munge && \
    chown -R hpcuser:hpcuser /projects /scratch /logs

COPY docker/slurm/entrypoint.sh /usr/local/sbin/slurm-lab-entrypoint
COPY tools/eda-mock/ /opt/eda-mock/
COPY tools/scheduler-wrappers/ /opt/scheduler-wrappers/

RUN chmod +x /usr/local/sbin/slurm-lab-entrypoint /opt/eda-mock/* /opt/scheduler-wrappers/* && \
    ln -sf /opt/eda-mock/cadence-run /usr/local/bin/cadence-run && \
    ln -sf /opt/eda-mock/synopsys-run /usr/local/bin/synopsys-run && \
    ln -sf /opt/eda-mock/siemens-run /usr/local/bin/siemens-run && \
    ln -sf /opt/eda-mock/eda-license-status /usr/local/bin/eda-license-status && \
    ln -sf /opt/eda-mock/hpc-metrics /usr/local/bin/hpc-metrics && \
    ln -sf /opt/scheduler-wrappers/bsub /usr/local/bin/bsub && \
    ln -sf /opt/scheduler-wrappers/qsub /usr/local/bin/qsub && \
    ln -sf /opt/scheduler-wrappers/rtda-submit /usr/local/bin/rtda-submit

EXPOSE 22 6817 6818 6819 9100

ENTRYPOINT ["/usr/local/sbin/slurm-lab-entrypoint"]
CMD ["login"]
