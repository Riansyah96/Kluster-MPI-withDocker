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
