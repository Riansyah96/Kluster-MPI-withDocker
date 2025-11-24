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
