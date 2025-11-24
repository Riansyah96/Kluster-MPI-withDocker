from mpi4py import MPI
import socket

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
hostname = socket.gethostname()

print(f"Halo! Saya Rank {rank}, berjalan di mesin: {hostname}")
