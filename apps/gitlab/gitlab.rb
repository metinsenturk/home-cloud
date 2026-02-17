# --- Essential Connectivity ---
# Note: Replace ${DOMAIN} with your actual domain if not using env interpolation
external_url "http://gitlab.example.com" 
gitlab_rails['gitlab_shell_ssh_port'] = 2222

# --- Performance Tuning for Single User ---
# Description: The number of child processes Puma spawns to handle web requests.
# Why it is needed: Each worker consumes significant RAM (400MB+). "0" enables single-process mode.
# Default value: Based on CPU cores (minimum 2).
# Link to documentation: https://docs.gitlab.com
# Suggested values: 0 (for single user), 2 (for 2-5 users).
puma['worker_processes'] = 0

# Description: The number of threads Sidekiq uses to process background jobs.
# Why it is needed: Lowering threads reduces CPU spikes and memory usage during background tasks.
# Default value: 20
# Link to documentation: https://docs.gitlab.com
# Suggested values: 5 (min needed for functionality), 10 (moderate), 20+ (high load).
sidekiq['concurrency'] = 5

# Description: The amount of memory the database uses for shared memory buffers.
# Why it is needed: GitLab defaults to 25% of total system RAM, which is excessive for one user.
# Default value: 25% of total RAM.
# Link to documentation: https://docs.gitlab.com
# Suggested values: 128MB (min), 256MB (ideal for homelab), 512MB+ (for large repos).
postgresql['shared_buffers'] = "256MB"

# Description: Toggles the internal Prometheus monitoring stack (Prometheus, Grafana, Exporters).
# Why it is needed: These services run 24/7 and consume ~500MB of RAM regardless of usage.
# Default value: true
# Link to documentation: https://docs.gitlab.com
# Suggested values: false (to save maximum RAM), true (if you need performance graphs).
prometheus_monitoring['enable'] = false

# Description: Limits the amount of memory the Git backend (Gitaly) can consume.
# Why it is needed: Prevents a large git operation from crashing the entire container/server.
# Default value: Unlimited (unless constrained by Docker).
# Link to documentation: https://docs.gitlab.com
# Suggested values: 512MB (min), 1GB (safe), 2GB+ (large binary files).
gitaly['configuration'] = {
  memory: {
    max_boundary: 536870912 # 512MB in bytes
  }
}
