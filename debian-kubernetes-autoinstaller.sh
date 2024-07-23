# ---------------------------------------------Functions--------------------------------------------
# Color text ouput
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

# Other parts
# Info seciton with requirements
function importantInformationSection {
    green_color "⚠️ Important information"
    echo "1. Make sure that you run this program in sudo mode"
    echo "2. This will install version v1.30"
    echo "3. Port 6443 is not taken"
    echo "4. MAC address and product_uuid are unique for every node"
    echo "5. Two CPUs or more required"
    echo "6. 2GB of free memory required"
    echo "7. 20GB of free disk space required"
    echo "8. Internet connection required"

    echo "More details here: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
    red_color "IF ANY OF THE POINTS LISTED ABOVE AREN'T FULFILLED IT WILL NOT WORK!"
}

# Docker
# Removing docker
function removeDocker {
    # Removing docker if installed
    green_color "Removing docker if installed"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    sudo apt-get purge aufs-tools docker-ce docker-ce-cli containerd.io pigz cgroupfs-mount -y
    sudo apt-get purge kubeadm kubernetes-cni -y
    sudo rm -rf /etc/kubernetes
    sudo rm -rf $HOME/.kube/config
    sudo rm -rf /var/lib/etcd
    sudo rm -rf /var/lib/docker
    sudo rm -rf /opt/containerd
    sudo apt autoremove -y

    # Removing docker ce
    sudo apt remove docker-ce docker-ce-cli containerd.io -y
}

function installDocker {
    green_color "Installing docker"
    sudo apt install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    green_color "Adding the repositories to the apt sources"
    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update

    # Install latest version
    green_color "Installing latest docker version"
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io  -y

}

# Combining uninstall and install docker for reinstall
function reinstallDocker {
    removeDocker
    installDocker
}

# Package updates
function updatePackages {
    # Updating packages
    green_color "Updating all apt packages"
    sudo apt update
    sudo apt dist-upgrade -y
}

# Displaying the finish message after everything has been installed
function showFinishMessage {
    green_color "The installation process is complete!"
}

# Swap disabling
function disableSwap() {
    green_color "Disabling swap...."
    sudo swapoff -a
    sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

function checkIfPortIsAvailable {
    green_color "Checking if the port 6443 is already occupied"
    nc localhost 6443 -v &>/dev/null
    output = echo $?

    if [ $output != "1" ]; then
        red_color "The required port 6443 is already taken"
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

function installContainerd {
    green_color "Installing containerd"
    wget https://github.com/containerd/containerd/releases/download/v1.7.20/containerd-1.7.20-linux-amd64.tar.gz
    tar Cxzvf /usr/local containerd-1.6.2-linux-amd64.tar.gz
    
    green_color "Checking if containerd has been installed successfully"
    cri-dockerd -v

    green_color "Configuring systemd for containerd"
    wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
    sudo mv containerd.service /usr/local/lib/systemd/system/containerd.service

    green_color "Starting the service with containerd enabled"
    systemctl daemon-reload
    systemctl enable --now containerd.service

    green_color "Verifying that containerd is running"
    systemctl status containerd.service
}

function installRunc {
    green_color "Installing runc"
    wget https://github.com/opencontainers/runc/releases/download/v1.2.0-rc.2/runc.amd64
    sudo install -m 755 runc.amd64 /usr/local/sbin/runc
}

function installCNIPlugin {
    green_color "Installing CNI plugin"
    wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
    sudo mkdir -p /opt/cni/bin
    tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
}

function installKubeTools {
    green_color "Installing kube tools"
    sudo apt-get update

    green_color "Installing necessary packages"
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg

    green_color "Fetching public signing key for kubernetes packages"
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    green_color "Overwriting existing configuration"
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    green_color "Installing kubelet, kubeadm and kubectl"
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

    # Optional
    green_color "Enabling the kubelet service before running kubeadm"
    sudo systemctl enable --now kubelet
}




# ----------------------------------------Program--------------------------------------------------
# Welcome information
importantInformationSection

# Docker
updatePackages
#reinstallDocker

# Kubernetes (v1.30)
disableSwap

# Enable routing
enableRouting

# Verify port availability
checkIfPortIsAvailable

# Install container runtime
installContainerd
installRunc
installCNIPlugin # Currently here's a problem with the tar unpacking

# Install kube tools
#installKubeTools

# Finish message
showFinishMessage