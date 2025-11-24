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
