#!/bin/bash

echo "=== Testing MPI Cluster ==="

# Test single node first
echo "1. Testing single node (node1 only)..."
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec -n 3 python3 hello.py"

echo ""
echo "2. Testing full cluster..."
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --hostfile hostfile -n 6 python3 hello.py"

echo ""
echo "=== MPI Test Completed ==="
