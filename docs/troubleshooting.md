# Troubleshooting

## Nodes stay down

Run:

```bash
sinfo -R
scontrol show nodes
```

Then check container logs:

```powershell
docker compose logs slurmctld
docker compose logs compute1
docker compose logs compute2
```

If this is a fresh start and services raced during boot, restart workers:

```powershell
docker compose restart compute1 compute2
```

## Accounting is empty

Wait a few seconds after job completion, then run:

```bash
sacct -X --format=JobID,JobName,State,Elapsed
```

Check `slurmdbd` if it remains empty:

```powershell
docker compose logs slurmdbd
```

## License jobs remain pending

That is expected for `04-license-starved.sbatch`. Inspect the reason:

```bash
squeue -o "%.18i %.24j %.2t %.10M %R %b"
scontrol show licenses
```

## Reset the lab

```powershell
docker compose down -v
docker compose build --no-cache
docker compose up -d
```
