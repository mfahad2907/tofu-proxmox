#!/bin/bash

# --- CONFIGURATION ---
NODES=("192.168.80.20" "192.168.80.21" "192.168.80.22")
USER="ubuntu"
SSH_KEY="~/.ssh/id_rsa"
MASTER_IP=${NODES[0]}

TYPE=$1

if [[ -z "$TYPE" ]]; then
    echo "Usage: ./deploy.sh [k0s|k3s|rke2|cleanup]"
    exit 1
fi

# --- SAFETY CHECK LOGIC ---
check_already_installed() {
    echo "Checking if a cluster already exists..."
    # Checks if k3s, k0s, or rke2 processes are running on the Master node
    if ssh -o ConnectTimeout=5 $USER@$MASTER_IP "pgrep -f 'k3s|k0s|rke2'" > /dev/null 2>&1; then
        echo "------------------------------------------------------------"
        echo "ERROR: It looks like a Kubernetes flavor is already running!"
        echo "To prevent conflicts, you must run: ./deploy.sh cleanup"
        echo "------------------------------------------------------------"
        exit 1
    fi
}

# --- 1. K0S LOGIC ---
install_k0s() {
    check_already_installed
    if [[ ! -f "k0sctl.yaml.tmpl" ]]; then
        echo "Error: k0sctl.yaml.tmpl not found!" ; exit 1
    fi
    echo "Generating k0sctl.yaml..."
    sed -e "s/{{NODE0}}/${NODES[0]}/g" \
        -e "s/{{NODE1}}/${NODES[1]}/g" \
        -e "s/{{NODE2}}/${NODES[2]}/g" \
        k0sctl.yaml.tmpl > k0sctl.yaml

    k0sctl apply --config k0sctl.yaml
    
    echo "Downloading Kubeconfig..."
    k0sctl kubeconfig --config k0sctl.yaml > k0s.config
    echo "Done! Use: export KUBECONFIG=\$PWD/k0s.config"
}

# --- 2. K3S LOGIC ---
install_k3s() {
    check_already_installed
    echo "Installing k3s server on $MASTER_IP..."
    ssh $USER@$MASTER_IP "curl -sfL https://get.k3s.io | sh -"
    
    TOKEN=$(ssh $USER@$MASTER_IP "sudo cat /var/lib/rancher/k3s/server/node-token")
    
    for IP in ${NODES[@]:1}; do
        echo "Joining worker $IP..."
        ssh $USER@$IP "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN sh -"
    done

    scp $USER@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ./k3s.config
    sed -i "s/127.0.0.1/$MASTER_IP/g" ./k3s.config
    echo "Done! Use: export KUBECONFIG=\$PWD/k3s.config"
}

# --- 3. RKE2 LOGIC ---
install_rke2() {
    check_already_installed
    echo "Installing RKE2 server on $MASTER_IP..."
    ssh $USER@$MASTER_IP "curl -sfL https://get.rke2.io | sh - && sudo systemctl enable rke2-server --now"
    
    TOKEN=$(ssh $USER@$MASTER_IP "sudo cat /var/lib/rancher/rke2/server/node-token")
    
    for IP in ${NODES[@]:1}; do
        ssh $USER@$IP "sudo mkdir -p /etc/rancher/rke2/ && echo -e \"server: https://$MASTER_IP:9345\ntoken: $TOKEN\" | sudo tee /etc/rancher/rke2/config.yaml"
        ssh $USER@$IP "curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE='agent' sh - && sudo systemctl enable rke2-agent --now"
    done

    scp $USER@$MASTER_IP:/etc/rancher/rke2/rke2.yaml ./rke2.config
    sed -i "s/127.0.0.1/$MASTER_IP/g" ./rke2.config
    echo "Done! Use: export KUBECONFIG=\$PWD/rke2.config"
}

cleanup() {
    echo "Wiping Kubernetes from all nodes..."
    for IP in "${NODES[@]}"; do
        echo "Deep cleaning $IP..."
        ssh -t $USER@$IP "
            # 1. Stop and Disable ALL possible services
            sudo systemctl stop k3s k3s-agent rke2-server rke2-agent k0scontroller k0sworker 2>/dev/null
            sudo systemctl disable k3s k3s-agent rke2-server rke2-agent k0scontroller k0sworker 2>/dev/null

            # 2. Delete Service Files
            sudo rm -f /etc/systemd/system/k3s* /etc/systemd/system/rke2* /etc/systemd/system/k0s*

            # 3. Official Reset
            sudo k0s reset 2>/dev/null

            # 4. Lazy Unmount stuck volumes (The fix for 'Device Busy')
            sudo mount | grep -E 'k0s|rancher|containerd' | awk '{print \$3}' | xargs -r sudo umount -l

            # 5. Wipe Directories
            sudo rm -rf /var/lib/rancher /var/lib/k0s /etc/rancher /etc/k0s /run/k3s /run/k0s

            # 6. Reload Systemd so it 'forgets' the services
            sudo systemctl daemon-reload
            sudo systemctl reset-failed
        "
    done
    rm -f k0sctl.yaml *.config
    echo "Cleanup complete. Systemd is clear!"
}
# --- EXECUTION ---
case $TYPE in
    k0s)     install_k0s ;;
    k3s)     install_k3s ;;
    rke2)    install_rke2 ;;
    cleanup) cleanup ;;
    *)       echo "Invalid option: $TYPE" ;;
esac
