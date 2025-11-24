# Dokumentasi Praktikum MPI Cluster dengan Docker

## 📋 Daftar Isi
- [Overview](#overview)
- [Struktur Project](#struktur-project)
- [Prerequisites](#prerequisites)
- [Setup Awal](#setup-awal)
- [Konfigurasi Docker](#konfigurasi-docker)
- [Menjalankan Cluster](#menjalankan-cluster)
- [Testing MPI](#testing-mpi)
- [Advanced Testing](#advanced-testing)
- [Performance Analysis](#performance-analysis)
- [Kesimpulan](#kesimpulan)

## 🎯 Overview

Praktikum ini mengimplementasikan **MPI (Message Passing Interface) Cluster** menggunakan Docker container. Cluster terdiri dari 3 node yang saling terhubung dan dapat menjalankan program MPI secara terdistribusi.

## 📁 Struktur Project

```
mpi-cluster-docker/
├── docker-compose.yml
├── Dockerfile
├── hosts
├── scripts/
│   ├── hello.py
│   ├── hello_detailed.py
│   ├── compute_intensive.py
│   ├── setup-cluster.sh
│   ├── test-mpi-proper.sh
│   ├── test-oversubscribe.sh
│   ├── test-oversubscribe-detailed.sh
│   └── performance-test.sh
└── README.md
```

## ⚙️ Prerequisites

- Docker
- Docker Compose
- Linux/macOS/WSL2 environment

## 🚀 Setup Awal

### 1. Persiapan Direktori

```bash
# Buat direktori project
mkdir mpi-cluster-docker
cd mpi-cluster-docker

# Buat struktur direktori
mkdir scripts config
```

### 2. File Konfigurasi Jaringan

**File: `hosts`**
```
172.20.0.10 node1
172.20.0.11 node2
172.20.0.12 node3
```

## 🐳 Konfigurasi Docker

### 1. Dockerfile

**File: `Dockerfile`**
```dockerfile
FROM ubuntu:22.04

# Set environment variables untuk non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update system dan install packages
RUN apt-get update && apt-get install -y \
    tzdata \
    openssh-server \
    openmpi-bin \
    openmpi-common \
    libopenmpi-dev \
    python3 \
    python3-pip \
    sudo \
    net-tools \
    iputils-ping \
    vim \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Python packages
RUN pip3 install mpi4py numpy

# Setup SSH
RUN mkdir -p /var/run/sshd

# Setup root password
RUN echo 'root:password' | chpasswd

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config && \
    echo "AddressFamily inet" >> /etc/ssh/sshd_config

# Create mpiuser
RUN useradd -m -s /bin/bash mpiuser && \
    echo 'mpiuser:password' | chpasswd && \
    usermod -aG sudo mpiuser && \
    echo 'mpiuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to mpiuser untuk setup SSH keys
USER mpiuser
WORKDIR /home/mpiuser

# Generate SSH keys
RUN mkdir -p /home/mpiuser/.ssh && \
    ssh-keygen -t rsa -f /home/mpiuser/.ssh/id_rsa -N '' && \
    cp /home/mpiuser/.ssh/id_rsa.pub /home/mpiuser/.ssh/authorized_keys && \
    chmod 700 /home/mpiuser/.ssh && \
    chmod 600 /home/mpiuser/.ssh/*

# Create MPI project directory
RUN mkdir -p /home/mpiuser/mpi_project

# Copy scripts ke container
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh && \
    chown -R mpiuser:mpiuser /scripts

# Switch back to root untuk CMD
USER root

# Expose SSH port
EXPOSE 22

# Start SSH daemon
CMD ["/usr/sbin/sshd", "-D", "-e"]
```

### 2. Docker Compose

**File: `docker-compose.yml`**
```yaml
services:
  node1:
    build: .
    container_name: node1
    hostname: node1
    tty: true
    stdin_open: true
    volumes:
      - ./scripts:/scripts:ro
      - ./hosts:/hosts:ro
    networks:
      mpi_net:
        ipv4_address: 172.20.0.10

  node2:
    build: .
    container_name: node2
    hostname: node2
    tty: true
    stdin_open: true
    volumes:
      - ./scripts:/scripts:ro
      - ./hosts:/hosts:ro
    networks:
      mpi_net:
        ipv4_address: 172.20.0.11

  node3:
    build: .
    container_name: node3
    hostname: node3
    tty: true
    stdin_open: true
    volumes:
      - ./scripts:/scripts:ro
      - ./hosts:/hosts:ro
    networks:
      mpi_net:
        ipv4_address: 172.20.0.12

networks:
  mpi_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
```

## 🏃‍♂️ Menjalankan Cluster

### 1. Build dan Start Container

```bash
# Build dan jalankan cluster
docker-compose up -d --build

# Periksa status container
docker ps
```

**Output yang diharapkan:**
```
CONTAINER ID   IMAGE                      COMMAND               CREATED         STATUS         PORTS     NAMES
...            mpi-cluster-docker-node1   "/usr/sbin/sshd -D"   10 seconds ago  Up 10 seconds  22/tcp    node1
...            mpi-cluster-docker-node2   "/usr/sbin/sshd -D"   10 seconds ago  Up 10 seconds  22/tcp    node2  
...            mpi-cluster-docker-node3   "/usr/sbin/sshd -D"   10 seconds ago  Up 10 seconds  22/tcp    node3
```

### 2. Setup Cluster Otomatis

**File: `scripts/setup-cluster.sh`**
```bash
#!/bin/bash

echo "=== Setting up MPI Cluster ==="

# Setup hosts file di semua nodes
echo "Setting up /etc/hosts..."
for node in node1 node2 node3; do
    echo "Configuring $node..."
    docker exec $node bash -c "cat >> /etc/hosts << 'EOL'
172.20.0.10 node1
172.20.0.11 node2
172.20.0.12 node3
EOL"
done

# Setup SSH known hosts
echo "Setting up SSH known hosts..."
for node in node1 node2 node3; do
    echo "Setting up SSH for $node..."
    docker exec $node sudo -u mpiuser bash -c "ssh-keyscan -H node1 node2 node3 >> ~/.ssh/known_hosts 2>/dev/null"
done

# Test SSH connections
echo "Testing SSH connections..."
for node in node1 node2 node3; do
    for target in node1 node2 node3; do
        echo -n "Testing $node -> $target: "
        docker exec $node sudo -u mpiuser ssh -o ConnectTimeout=2 $target "echo 'success'" &>/dev/null && echo "✓" || echo "✗"
    done
done

# Copy MPI program ke semua nodes
echo "Copying MPI programs..."
for node in node1 node2 node3; do
    echo "Copying to $node..."
    docker exec $node sudo -u mpiuser cp /scripts/hello.py /home/mpiuser/mpi_project/ 2>/dev/null && echo "✓" || echo "✗"
done

# Create hostfile di node1
echo "Creating hostfile..."
docker exec node1 sudo -u mpiuser bash -c "cat > /home/mpiuser/mpi_project/hostfile << 'EOL'
node1 slots=2
node2 slots=2
node3 slots=2
EOL" && echo "✓" || echo "✗"

echo ""
echo "=== Setup completed! ==="
echo "To run MPI program, execute:"
echo "  docker exec -it node1 sudo -u mpiuser bash"
echo "Then inside container:"
echo "  cd ~/mpi_project"
echo "  mpiexec --hostfile hostfile -n 6 python3 hello.py"
```

**Jalankan setup:**
```bash
chmod +x scripts/setup-cluster.sh
./scripts/setup-cluster.sh
```

## 🧪 Testing MPI

### 1. Program MPI Dasar

**File: `scripts/hello.py`**
```python
from mpi4py import MPI
import socket

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
hostname = socket.gethostname()

print(f"Halo! Saya Rank {rank}, berjalan di mesin: {hostname}")
```

### 2. Test Basic MPI

**File: `scripts/test-mpi-proper.sh`**
```bash
#!/bin/bash

echo "=== Proper MPI Testing ==="

echo "1. Testing Python script syntax..."
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && python3 -c 'from mpi4py import MPI; print(\"MPI4Py import success\")'"

echo ""
echo "2. Testing single process MPI..."
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec -n 1 python3 hello.py"

echo ""
echo "3. Testing multi-process single node..."
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec -n 3 python3 hello.py"

echo ""
echo "4. Testing full cluster..."
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --hostfile hostfile -n 6 python3 hello.py"
```

**Jalankan test:**
```bash
chmod +x scripts/test-mpi-proper.sh
./scripts/test-mpi-proper.sh
```

**Output yang diharapkan:**
```
=== Proper MPI Testing ===
1. Testing Python script syntax...
MPI4Py import success

2. Testing single process MPI...
Halo! Saya Rank 0, berjalan di mesin: node1

3. Testing multi-process single node...
Halo! Saya Rank 0, berjalan di mesin: node1
Halo! Saya Rank 1, berjalan di mesin: node1
Halo! Saya Rank 2, berjalan di mesin: node1

4. Testing full cluster...
Halo! Saya Rank 0, berjalan di mesin: node1
Halo! Saya Rank 1, berjalan di mesin: node1
Halo! Saya Rank 2, berjalan di mesin: node2
Halo! Saya Rank 3, berjalan di mesin: node2
Halo! Saya Rank 4, berjalan di mesin: node3
Halo! Saya Rank 5, berjalan di mesin: node3
```

## 🔬 Advanced Testing

### 1. Program MPI Detail

**File: `scripts/hello_detailed.py`**
```python
from mpi4py import MPI
import socket
import time

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
hostname = socket.gethostname()

# Simulate some work
if rank == 0:
    print(f"=== MPI Job Started ===")
    print(f"Total processes: {size}")
    print(f"Running on hosts with oversubscribe")
    print("=" * 40)

# Small delay to see the order
time.sleep(rank * 0.1)

print(f"Rank {rank:2d}/{size} running on: {hostname}")

if rank == 0:
    time.sleep(0.5)  # Wait for all outputs
    print("=" * 40)
    print("Job completed!")
```

### 2. Test dengan Oversubscribe

**File: `scripts/test-oversubscribe.sh`**
```bash
#!/bin/bash

echo "=== Testing MPI dengan --oversubscribe ==="

echo ""
echo "1. Normal execution (6 processes - sesuai hostfile):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --hostfile hostfile -n 6 python3 hello.py"

echo ""
echo "2. Oversubscribe dengan 8 processes (melebihi slot):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe --hostfile hostfile -n 8 python3 hello.py"

echo ""
echo "3. Oversubscribe dengan 12 processes (2x lipat):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe --hostfile hostfile -n 12 python3 hello.py"

echo ""
echo "4. Single node oversubscribe (10 processes):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe -n 10 python3 hello.py"

echo ""
echo "5. Extreme oversubscribe (20 processes):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe --hostfile hostfile -n 20 python3 hello.py"
```

## 📊 Performance Analysis

### 1. Program Compute Intensive

**File: `scripts/compute_intensive.py`**
```python
from mpi4py import MPI
import socket
import time
import math

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
hostname = socket.gethostname()

start_time = time.time()

# Compute intensive task - calculate pi using Leibniz formula
if rank == 0:
    print(f"Starting compute-intensive task with {size} processes")
    print("Calculating pi using Leibniz formula...")

terms = 1000000
local_terms = terms // size
start_index = rank * local_terms
end_index = start_index + local_terms if rank != size - 1 else terms

local_sum = 0.0
for i in range(start_index, end_index):
    local_sum += (-1) ** i / (2 * i + 1)

# Reduce all local sums to rank 0
global_sum = comm.reduce(local_sum, op=MPI.SUM, root=0)

end_time = time.time()

if rank == 0:
    pi_estimate = global_sum * 4
    print(f"Estimated pi: {pi_estimate}")
    print(f"Error: {abs(pi_estimate - math.pi)}")
    print(f"Execution time: {end_time - start_time:.4f} seconds")
    print(f"Processes: {size}, Oversubscribed: {'Yes' if size > 6 else 'No'}")

print(f"Rank {rank} on {hostname} completed in {end_time - start_time:.4f}s")
```

### 2. Performance Test

**File: `scripts/performance-test.sh`**
```bash
#!/bin/bash

echo "=== Performance Test: Normal vs Oversubscribe ==="

echo ""
echo "1. Normal execution (6 processes):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --hostfile hostfile -n 6 python3 compute_intensive.py"

echo ""
echo "2. Oversubscribe (12 processes):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe --hostfile hostfile -n 12 python3 compute_intensive.py"

echo ""
echo "3. Extreme oversubscribe (24 processes):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe --hostfile hostfile -n 24 python3 compute_intensive.py"
```

**Hasil Performance:**
```
6 processes: 0.2262 seconds (baseline)
12 processes: 0.2729 seconds (+20% slower) 
24 processes: 0.4611 seconds (+104% slower)
```

## 🎯 Manual Testing

### Akses ke Cluster

```bash
# Akses ke node1 sebagai mpiuser
docker exec -it node1 sudo -u mpiuser bash

# Di dalam container, test berbagai skenario:
cd ~/mpi_project

# Test single node
mpiexec -n 3 python3 hello.py

# Test full cluster
mpiexec --hostfile hostfile -n 6 python3 hello.py

# Test dengan oversubscribe
mpiexec --oversubscribe --hostfile hostfile -n 10 python3 hello.py
```

## 🧹 Cleanup

```bash
# Hentikan dan hapus cluster
docker-compose down

# Hapus semua resources Docker yang tidak digunakan
docker system prune -f
```

## 📈 Kesimpulan

### ✅ **Yang Berhasil Dicapai:**

1. **MPI Cluster Setup** - Berhasil membuat cluster 3 node dengan Docker
2. **Distributed Computing** - Program MPI berjalan terdistribusi di multiple nodes
3. **Oversubscribe Testing** - Memahami konsep dan trade-off oversubscribe
4. **Performance Analysis** - Analisis performa normal vs oversubscribe
5. **Automated Setup** - Script otomatis untuk setup dan testing

### 🎓 **Pembelajaran:**

1. **MPI Architecture** - Pemahaman distributed memory programming
2. **Cluster Management** - Konfigurasi jaringan dan SSH di multi-node environment
3. **Performance Trade-offs** - Understanding resource contention dalam oversubscribe
4. **Docker untuk HPC** - Penggunaan container untuk development cluster

### 🚀 **Aplikasi di Dunia Nyata:**

Teknik ini dapat diaplikasikan dalam:
- Scientific computing dan simulations
- Distributed machine learning training
- Big data processing
- High Performance Computing (HPC) applications

**Praktikum ini berhasil menunjukkan konsep fundamental MPI Cluster dan distributed computing menggunakan teknologi container modern!** 🎉
