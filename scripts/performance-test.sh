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
