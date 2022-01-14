## Local setup

On Arch Linux:

```bash
sudo pacman -S zeromq
Rscript -e 'remotes::install_cran("clustermq")'
```

Save the following to `~/.config/clustermq/SSH.tmpl`:

```r
ssh -o "ExitOnForwardFailure yes" -f \
    -R {{ ctl_port }}:localhost:{{ local_port }} \
    -R {{ job_port }}:localhost:{{ fwd_port }} \
    {{ ssh_host }} \
    "module load R ZeroMQ && \
     R --no-save --no-restore -e \
        'clustermq:::ssh_proxy(ctl={{ ctl_port }}, job={{ job_port }})' \
        > {{ ssh_log | /dev/null }} 2>&1"
```

Next, add the following to your `~/.Rprofile`. **Replace `user@host` with your cluster username and hostname**:

```r
options(
  clustermq.scheduler = "ssh",
  clustermq.ssh.host = "user@host",
  clustermq.ssh.log = "~/cmq_ssh.log", # log for easier debugging
  clustermq.template = "~/.config/clustermq/SSH.tmpl",
  clustermq.ssh.timeout = 20
)
```

Now, SSH into the cluster and save the following to `~/.config/clustermq/SLURM.tmpl`:

```bash
#!/bin/sh
#SBATCH --job-name={{ job_name }}
#SBATCH --output={{ log_file | /dev/null }}
#SBATCH --error={{ log_file | /dev/null }}
#SBATCH --mem-per-cpu={{ memory | 4096 }}
#SBATCH --array=1-{{ n_jobs }}
#SBATCH --cpus-per-task={{ cores | 1 }}
#SBATCH --time={{ time | 30 }}

module load R ZeroMQ
ulimit -v $(( 1024 * {{ memory | 4096 }} ))
CMQ_AUTH={{ auth }} R --no-save --no-restore -e 'clustermq:::worker("{{ master }}")'
```


and add the following to your `~/.Rprofile`:

```r
options(
  clustermq.scheduler = "slurm",
  clustermq.template = "~/.config/clustermq/SLURM.tmpl"
)
```
