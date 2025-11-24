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

# Switch back to root untuk CMD
USER root

# Expose SSH port
EXPOSE 22

# Start SSH daemon
CMD ["/usr/sbin/sshd", "-D", "-e"]

# Copy scripts ke container
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh && \
    chown -R mpiuser:mpiuser /scripts
