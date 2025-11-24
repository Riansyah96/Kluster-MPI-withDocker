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

# Setup SSH known hosts dan test connection
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

# Test MPI installation
echo "Testing MPI installation..."
for node in node1 node2 node3; do
    echo -n "MPI test on $node: "
    docker exec $node sudo -u mpiuser bash -c "cd /home/mpiuser/mpi_project && python3 hello.py" &>/dev/null && echo "✓" || echo "✗"
done

echo ""
echo "=== Setup completed! ==="
echo "To run MPI program, execute:"
echo "  docker exec -it node1 sudo -u mpiuser bash"
echo "Then inside container:"
echo "  cd ~/mpi_project"
echo "  mpiexec --hostfile hostfile -n 6 python3 hello.py"
