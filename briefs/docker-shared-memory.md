---
title: Docker Shared Memory (SHM)
description: Understanding shared memory in Docker containers, why it's needed, and when to configure it
created: 2026-02-16
updated: 2026-02-16
tags:
  - docker
  - shm
  - memory
  - performance
  - containers
  - ipc
category: Docker
---

# Docker Shared Memory (SHM)

## What is Shared Memory?

Shared Memory (SHM) is a POSIX-compliant mechanism that allows multiple processes to access the same memory space for fast inter-process communication (IPC). In Linux, this is typically mounted at `/dev/shm` and backed by RAM rather than disk.

In Docker containers:
- Default SHM size: **64 MB**
- Location: `/dev/shm` (tmpfs mount)
- Purpose: Fast IPC and temporary storage in RAM

## Why Docker Containers Need SHM

Applications that use shared memory for:
1. **Inter-Process Communication (IPC)**: Processes within the container need to share data
2. **Parallel Processing**: Multi-threaded/multi-process applications (e.g., Python multiprocessing)
3. **Large Datasets**: Applications loading large datasets into memory
4. **Database Operations**: PostgreSQL, Oracle, and other databases use SHM for caching

### Common Symptoms of Insufficient SHM

```
Bus error (core dumped)
OSError: [Errno 28] No space left on device
Cannot allocate memory
Shared memory segment error
```

These errors often occur even when the container has plenty of disk space, because `/dev/shm` has its own limit.

## When to Increase SHM Size

### Use Cases Requiring Larger SHM

1. **Machine Learning & Data Science**
   - PyTorch DataLoader with `num_workers > 0`
   - TensorFlow data pipelines
   - NumPy/Pandas operations with large arrays
   - Multiprocessing with large shared data

2. **Databases**
   - PostgreSQL with high shared_buffers
   - Oracle Database
   - MongoDB (sometimes)
   - Redis (when using unix sockets)

3. **Web Browsers in Containers**
   - Selenium/Chrome/Firefox headless browsers
   - Chromium-based applications

4. **Message Queues & Caching**
   - RabbitMQ
   - Memcached
   - Some Redis configurations

5. **Multimedia Processing**
   - FFmpeg with parallel processing
   - Image processing with Python multiprocessing
   - Video encoding/transcoding

## How to Configure SHM in Docker

### Method 1: Using `shm_size` (Recommended)

**Docker Compose:**
```yaml
services:
  myapp:
    image: python:3.11
    shm_size: '2gb'  # or '2g', '512mb', etc.
```

**Docker Run:**
```bash
docker run --shm-size=2g myimage
```

### Method 2: Mount Host's /dev/shm (Advanced)

```yaml
services:
  myapp:
    image: python:3.11
    volumes:
      - /dev/shm:/dev/shm
```

**Warning**: This shares the host's SHM with the container, which may have security implications.

### Method 3: Use IPC Mode (For Multiple Containers)

When multiple containers need to share memory:

```yaml
services:
  worker1:
    image: python:3.11
    shm_size: '2gb'
    
  worker2:
    image: python:3.11
    ipc: "service:worker1"  # Share SHM with worker1
```

## Size Guidelines

| Use Case | Recommended SHM Size |
|----------|---------------------|
| Default (most apps) | 64 MB (default) |
| Light ML training | 256 MB - 512 MB |
| PyTorch DataLoader | 1 GB - 2 GB |
| Large database cache | 2 GB - 8 GB |
| Heavy ML/data processing | 4 GB - 16 GB |
| Selenium/Browser automation | 512 MB - 2 GB |

**Rule of Thumb**: SHM should be ~10-20% of your container's memory limit for data-intensive applications.

## Practical Examples

### Example 1: PyTorch Training Container

```yaml
services:
  pytorch-trainer:
    image: pytorch/pytorch:2.0.0
    shm_size: '4gb'  # Essential for DataLoader with multiple workers
    environment:
      - PYTHONUNBUFFERED=1
    volumes:
      - ./data:/workspace/data
      - ./models:/workspace/models
    command: python train.py --num-workers 8
```

**Why**: PyTorch's DataLoader uses shared memory when `num_workers > 0` to share tensors between worker processes.

### Example 2: PostgreSQL with High Cache

```yaml
services:
  postgres:
    image: postgres:15
    shm_size: '2gb'
    environment:
      - POSTGRES_PASSWORD=securepass
      - POSTGRES_SHARED_BUFFERS=1GB  # Must be less than shm_size
```

**Why**: PostgreSQL uses SHM for shared buffers. The `shared_buffers` setting must fit within available SHM.

### Example 3: Selenium with Chrome

```yaml
services:
  selenium:
    image: selenium/standalone-chrome:latest
    shm_size: '2gb'  # Chrome needs substantial SHM for rendering
    ports:
      - "4444:4444"
```

**Why**: Chrome uses `/dev/shm` extensively for tab rendering and IPC between processes.

### Example 4: Python Multiprocessing

```yaml
services:
  data-processor:
    image: python:3.11-slim
    shm_size: '1gb'
    volumes:
      - ./app:/app
    command: python process_large_dataset.py
```

**Example Python code** that would need this:
```python
from multiprocessing import Pool, Array
import numpy as np

# Shared memory array
shared_array = Array('d', 10000000)  # 10M doubles = ~76MB

def process_chunk(chunk_id):
    # Access shared array
    return np.sum(shared_array[chunk_id*1000:(chunk_id+1)*1000])

with Pool(processes=8) as pool:
    results = pool.map(process_chunk, range(10000))
```

## Monitoring SHM Usage

### Inside the Container

```bash
# Check current usage
df -h /dev/shm

# Watch in real-time
watch -n 1 df -h /dev/shm

# List files in SHM
ls -lh /dev/shm
```

### From the Host

```bash
# Find container ID
docker ps

# Check SHM usage
docker exec <container_id> df -h /dev/shm

# Inspect SHM configuration
docker inspect <container_id> | grep -i shm
```

## Best Practices

1. **Start Conservative**: Begin with 256-512 MB and increase if you see errors
2. **Monitor Usage**: Use `df -h /dev/shm` to track actual usage
3. **Set Limits**: Don't set SHM larger than the container's memory limit
4. **Document Why**: Comment in your compose file why a specific SHM size is needed
5. **Clean Up**: Some apps don't clean up SHM files; restart containers periodically
6. **Security**: Avoid mounting host's `/dev/shm` in production

## Common Pitfalls

### ❌ Setting SHM Too Large
```yaml
services:
  app:
    image: myapp
    shm_size: '64gb'  # Probably excessive
    mem_limit: '2gb'  # SHM is part of container's memory!
```

### ✅ Balanced Configuration
```yaml
services:
  app:
    image: myapp
    mem_limit: '8gb'
    shm_size: '2gb'  # ~25% of memory limit
```

### ❌ Ignoring SHM Errors
```python
# App crashes with "Bus error" or "No space left"
# Developer thinks it's a disk space issue
# Actually it's SHM exhaustion
```

### ✅ Proactive Configuration
```yaml
# Check documentation for your base image
# ML/data science images often need larger SHM
services:
  ml-app:
    image: tensorflow/tensorflow:latest
    shm_size: '2gb'  # Set upfront based on known requirements
```

## Debugging SHM Issues

### Step 1: Verify the Problem
```bash
# Inside container
df -h /dev/shm
# If Usage is at 100%, that's your issue
```

### Step 2: Check Application Logs
```bash
docker logs <container_name> 2>&1 | grep -i "memory\|shm\|bus error"
```

### Step 3: Increase SHM
```yaml
services:
  app:
    shm_size: '1gb'  # Start here and adjust
```

### Step 4: Verify Fix
```bash
docker compose up -d
docker exec <container> df -h /dev/shm
# Should show larger size now
```

## Related Docker Settings

- **`mem_limit`**: Total container memory (includes SHM)
- **`memswap_limit`**: Memory + swap limit
- **`ipc`**: IPC namespace sharing between containers
- **`tmpfs`**: Alternative to SHM for some use cases

## Further Reading

- [Docker Run Reference - IPC Settings](https://docs.docker.com/engine/reference/run/#ipc-settings---ipc)
- [Linux `/dev/shm` Documentation](https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html)
- [PostgreSQL Shared Buffers](https://www.postgresql.org/docs/current/runtime-config-resource.html)
- [PyTorch DataLoader Issues](https://github.com/pytorch/pytorch/issues/2244)
