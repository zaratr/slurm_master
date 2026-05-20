# Kubernetes Follow-Up

The first Kubernetes version should preserve the Slurm model rather than replacing it with plain Kubernetes Jobs.

Recommended order:

1. Keep this Docker Compose lab as the source of truth.
2. Move Munge, MariaDB, SlurmDBD, Slurm controller, and workers into Kubernetes.
3. Use persistent volumes for `/home`, `/projects`, `/scratch`, `/logs`, Slurm state, and MariaDB data.
4. Keep Slurm as the scheduler for EDA workloads.
5. Add Kubernetes-native services only for supporting concerns such as dashboards, metrics, docs, and later ML/AI side workloads.

SchedMD Slinky containers are the likely next research target for a production-shaped Slurm-on-Kubernetes implementation:

https://slinky.schedmd.com/projects/containers
