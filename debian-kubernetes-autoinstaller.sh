#!/bin/bash

# ---------------------------------------------Functions--------------------------------------------
# Color text output
RESET='\033[0m'

# Green
green_color() {
  GREEN='\033[0;32m'
  echo -e "${GREEN}$1${RESET}"
}

# Red
red_color() {
    RED="\033[31m"
    echo -e "${RED}$1${RESET}"
}

# Blue
blue_color() {
    BLUE="\033[34m"
    echo -e "${BLUE}$1${RESET}"
}

# Info section with requirements
function importantInformationSection {
    blue_color "
| |/ /    | |                        | |                /\        | |          |_   _|         | |      | | |
| . /_   _| |__   ___ _ __ _ __   ___| |_ ___  ___     /  \  _   _| |_ ___ ______| |  _ __  ___| |_ __ _| | | ___ _ __
|  <| | | | |_ \ / _ \ .__| ._ \ / _ \ __/ _ \/ __|   / /\ \| | | | __/ _ \______| | | ._ \/ __| __/ _. | | |/ _ \ .__|
| . \ |_| | |_) |  __/ |  | | | |  __/ ||  __/\__ \  / ____ \ |_| | || (_) |    _| |_| | | \__ \ || (_| | | |  __/ |
|_|\_\__._|_.__/ \___|_|  |_| |_|\___|\__\___||___/ /_/    \_\__,_|\__\___/    |_____|_| |_|___/\__\__,_|_|_|\___|_|
    "
    green_color "Important information"
    echo "1. Make sure that you run this program in sudo mode"
    echo "2. This will install version v1.30 with calico running"
    echo "3. Port 6443 is not taken"
    echo "4. MAC address and product_uuid are unique for every node"
    echo "5. Two CPUs or more required"
    echo "6. 2GB of free memory required"
    echo "7. 20GB of free disk space required"
    echo "8. Internet connection required"

    echo "More details here: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
    red_color "IF ANY OF THE POINTS LISTED ABOVE AREN'T FULFILLED IT WILL NOT WORK!"
}

# Package updates
function updatePackages {
    # Updating packages
    # Necessary due to potential time problem
    green_color "Installing chrony"
    sudo apt install chrony -y

    green_color "Stopping chrony"
    sudo systemctl stop chrony
    echo "Successfully stopped chrony"

    green_color "Speeding up the correcting of the time settings"
    sudo chronyd -q 'pool pool.ntp.org iburst'

    green_color "Verify that your computer has the correct time settings"
    date

    # Update
    green_color "Updating all apt packages"
    sudo apt update
    sudo apt dist-upgrade -y

    sudo systemctl start chrony
}

# Displaying the finish message after everything has been installed
function showFinishMessage {
    green_color "The installation process is complete!"
}

# Swap disabling
function disableSwap {
    green_color "Disabling swap...."
    sudo swapoff -a
    sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

function checkIfPortIsAvailable {
    green_color "Checking if the port 6443 is already occupied"
    nc localhost 6443 -v &>/dev/null
    if [ "$?" -ne 1 ]; then
        red_color "The required port 6443 is already taken"
    else
        echo "Check status: ok"
        echo "Port 6443 is not yet taken"
    fi
}

function enableRouting {
    green_color "Enabling routing"
    # sysctl params required by setup, params persist across reboots
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.ipv4.ip_forward = 1
EOF

    # Apply sysctl params without reboot
    sudo sysctl --system
}

function installKubeTools {
    green_color "Installing kube tools"
    sudo apt-get update

    green_color "Installing necessary packages"
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg

    green_color "Fetching public signing key for kubernetes packages"
    sudo mkdir -p -m 755 /etc/apt/keyrings
    sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "Successfully fetched public signing key"

    green_color "Overwriting existing configuration"
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    green_color "Installing kubelet, kubeadm and kubectl"
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

    # Optional
    green_color "Enabling the kubelet service before running"
    sudo systemctl enable --now kubelet
    echo "Successfully enabled the kublet service"
}

# Function to set up the Kubernetes cluster
function setupCluster {
    green_color "Getting the currently running kubectl version"
    kubectl version

    green_color "Checking the IP address being used by kubeadm"
    ip route show | grep "default via"

    green_color "Initializing the cluster"
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16

    green_color "Setting up kubeconfig for the current user"
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    green_color "Installing a Pod network add-on (e.g., Calico)"
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

    green_color "Cluster setup complete. You can now join worker nodes."
}

# Install containerd
function installContainerd {
    green_color "Installing containerd"
    wget https://github.com/containerd/containerd/releases/download/v1.7.20/containerd-1.7.20-linux-amd64.tar.gz
    sudo tar xvf containerd-1.7.20-linux-amd64.tar.gz -C /usr/local/

    green_color "Configuring systemd for containerd"
    sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
    sudo mkdir -p /usr/local/lib/systemd/system/
    sudo mv containerd.service /usr/local/lib/systemd/system/containerd.service

    green_color "Configuring the containerd config.toml file"
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    CONFIG_FILE="/etc/containerd/config.toml"
    sudo sed -i '/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]/,/^\[/{s/^ *SystemdCgroup *= *false/    SystemdCgroup = true/}' $CONFIG_FILE
    echo "Configuration updated successfully"

    green_color "Starting the service with containerd enabled"
    sudo systemctl daemon-reload
    sudo systemctl restart containerd
    sudo systemctl enable --now containerd.service

    green_color "Verifying that containerd is running"
    sudo systemctl --no-pager status containerd.service
}

# Install runc
function installRunc {
    green_color "Installing runc"
    sudo wget https://github.com/opencontainers/runc/releases/download/v1.2.0-rc.2/runc.amd64
    sudo install -m 755 runc.amd64 /usr/local/sbin/runc
}

# Install CNI plugin
function installCNIPlugin {
    green_color "Installing CNI plugin"
    sudo wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
    sudo mkdir -p /opt/cni/bin
    sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz
}

function startWhatsNext {
    green_color "What's next?"
    echo "1. To easily create the kubernetes pod just run: kubectl apply -f https://k8s.io/examples/application/shell-demo.yaml"
    echo "2. To verify that the container is running run: kubectl get pod shell-demo"
    echo "3. To get a shell to the example container run: kubectl exec --stdin --tty shell-demo -- /bin/bash"
    echo "4. To get just a single node cluster run: kubectl taint nodes --all node-role.kubernetes.io/control-plane-"
    green_color "For more information visit: https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/"
}

function getCurrentMode {
    local mode=""

    while getopts "m:" opt; do
        case ${opt} in
            m)
                mode=${OPTARG}
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
        esac
    done

    if [ -z "$mode" ]; then
        echo "Error: Option -m is mandatory and requires either 'master' or 'worker' as argument" >&2
        exit 1
    fi

    local validModes=("master" "worker")
    if [[ ! " ${validModes[@]} " =~ " ${mode} " ]]; then
        echo "Invalid argument passed. The -m flag only accepts the following modes: ${validModes[@]}" >&2
        exit 1
    fi

    echo $mode
}

# ----------------------------------------Program--------------------------------------------------
mode=$(getCurrentMode "$@")

# Check if mode is empty
if [ -z "$mode" ]; then
    exit 1
fi

# Welcome information
importantInformationSection

# Docker
updatePackages

# Kubernetes (v1.30)
disableSwap

# Enable routing
enableRouting

# Verify port availability
checkIfPortIsAvailable

# Install runc, cni and containerd
installRunc
installCNIPlugin
installContainerd

# Install kube tools
installKubeTools

# Setup the cluster
if [ "$mode" == "master" ]; then
    setupCluster
fi

# Show what's next
startWhatsNext

# Finish message
showFinishMessage