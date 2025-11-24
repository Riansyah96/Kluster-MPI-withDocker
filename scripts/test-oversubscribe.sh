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
