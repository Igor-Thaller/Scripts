# ---------------------------------------------Functions--------------------------------------------
# Basic lines
function line {
    echo "----------------------------------------------------------"
}

function dashLine {
    echo ".........................................................."
}

# Other parts
# Info seciton with requirements
function importantInformationSection {
    line

    echo "Important information"
    dashLine
    echo "1. Please make sure that you run this program in sudo mode"
    echo "2. Two CPUs or more"
    echo "3. 2GB of free memory"
    echo "4. 20GB of free disk space"
    echo "5. Internet connection"

    line
}

# Docker
# Removing docker
function removeDocker {
    dashLine
    # Removing docker if installed
    echo "Removing docker if installed"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    sudo apt-get purge aufs-tools docker-ce docker-ce-cli containerd.io pigz cgroupfs-mount -y
    sudo apt-get purge kubeadm kubernetes-cni -y
    sudo rm -rf /etc/kubernetes
    sudo rm -rf $HOME/.kube/config
    sudo rm -rf /var/lib/etcd
    sudo rm -rf /var/lib/docker
    sudo rm -rf /opt/containerd
    sudo apt autoremove -y
    dashLine
}

# Installing docker
# function installDocker {
#     dashLine
#     echo "Installing docker"
#     echo "Updating packages"
#     sudo apt update
#     echo "Downloading prerequisite packages"
#     sudo apt install apt-transport-https ca-certificates curl gnupg
#     echo "Downloading the docker repository"
#     sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
#     echo "Installing the apt docker package"
#     sudo apt install docker
#     dashLine
#     echo "Verifying the docker installation"
#     sudo systemctl status docker
#     dashLine
# }

function installDocker {
    dashLine
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "Adding the repositories to the apt sources"
    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update

    # Install latest version
    echo "Installing latest docker version"
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Testing docker
    # echo "Testing docker"
    # sudo docker run hello-world
    dashLine
}

# Combining uninstall and install docker for reinstall
function reinstallDocker {
    line
    removeDocker
    installDocker
    line
}

# Package updates
function updatePackages {
    line
    # Updating packages
    echo "Updating all apt packages"
    sudo apt update
    sudo apt dist-upgrade
    line
}

# Fetching of kubernetes by specified version
function fetchAssociatedVersionData {
    line
    echo "Fetching data"
    if [version != "stable"]; then
        sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    else
        sudo curl -LO https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl
    fi

    dashLine

    # Validate
    echo "Validating the binary"
     sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

    echo "Validation results"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

    line
}

# Installing minkube
function installMinikube {
    line

    echo "Installing minikube"
    sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

    line
}

function attemptMinikubeStart {
    line

    echo "Attempting to start minikube"
    minikube start

    line
}

function installKubectl {
    line

    # Install kubectl
    echo "Installing kubectl cli tool"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # Could still install even without sudo
    # chmod +x kubectl
    # mkdir -p ~/.local/bin
    # mv ./kubectl ~/.local/bin/kubectl
    # and then append (or prepend) ~/.local/bin to $PATH

    # Validating kubectl
    echo "Validating kubectl"
    kubectl version --client --output=yaml

    line
}

function showFinishMessage {
    line

    echo "Everything has been installed!"

    line
}


















# ----------------------------------------Program--------------------------------------------------
echo "Installing kubernetes for debian"
importantInformationSection

line

# Collect necessary information for the program to run
read -p "Enter the version you want to use or type stable (e.g. v1.30.0): " version

line

reinstallDocker

fetchAssociatedVersionData

installKubectl

installMinikube

showFinishMessage

attemptMinikubeStart


