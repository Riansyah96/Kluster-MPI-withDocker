#!/bin/bash

echo "=== Detailed Oversubscribe Test ==="

echo ""
echo "1. Normal (6 processes):"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --hostfile hostfile -n 6 python3 hello_detailed.py"

echo ""
echo "2. Oversubscribe 8 processes:"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe --hostfile hostfile -n 8 python3 hello_detailed.py"

echo ""
echo "3. Oversubscribe 15 processes:"
docker exec node1 sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && mpiexec --oversubscribe --hostfile hostfile -n 15 python3 hello_detailed.py"
