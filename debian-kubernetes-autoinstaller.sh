# ---------------------------------------------Functions--------------------------------------------
# Basic lines
function line {
    echo -e "\033[31m __________________________________________________________ \033[0m"
}

function dashLine {
    echo -e "\033[31m .......................................................... \033[0m"
}

# Color text ouput
green_color() {
  GREEN='\033[0;32m'
  RESET='\033[0m'
  echo -e "${GREEN}$1${RESET}"
}


# Other parts
# Info seciton with requirements
function importantInformationSection {
    green_color "Important information"
    dashLine
    echo "1. Please make sure that you run this program in sudo mode"
    echo "2. Two CPUs or more"
    echo "3. 2GB of free memory"
    echo "4. 20GB of free disk space"
    echo "5. Internet connection"
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
}

function installDocker {
    green_color "Installing docker"
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    green_color "Adding the repositories to the apt sources"
    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update

    # Install latest version
    green_color "Installing latest docker version"
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    dashLine

    # Testing docker
    green_color "Testing docker"
    sudo docker run hello-world
}

# Combining uninstall and install docker for reinstall
function reinstallDocker {
    removeDocker
    dashLine
    installDocker
}

# Package updates
function updatePackages {
    # Updating packages
    green_color "Updating all apt packages"
    sudo apt update
    sudo apt dist-upgrade
}

# Fetching of kubernetes by specified version
function fetchAssociatedVersionData {
    green_color "Fetching data associated with the provided version"
    if [version != "stable"]; then
        sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    else
        sudo curl -LO https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl
    fi

    dashLine

    # Validate
    green_color "Validating the binary"
    
    sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

    dashLine

    green_color "Validation results"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
}

# Installing minkube
function installMinikube {
    green_color "Installing minikube"
    sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
}

function attemptMinikubeStart {
    green_color "Attempting to start minikube"
    # TODO: Implement this without --force
    minikube start --force --driver=docker
}

function installKubectl {
    # Install kubectl
    green_color "Installing kubectl cli tool"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    dashLine

    # Validating kubectl
    green_color "Validating kubectl"
    kubectl version --client --output=yaml
}

function showFinishMessage {
    green_color "Everything has been installed!"
}















# ----------------------------------------Program--------------------------------------------------
echo "Installing kubernetes for debian"
importantInformationSection

# Collect necessary information for the program to run
read -p "Enter the version you want to use or type stable (e.g. v1.30.0): " version

# Line break
line
updatePackages

# Line break
line
reinstallDocker


# Line break
line
fetchAssociatedVersionData


# Line break
line
installKubectl


# Line break
line
installMinikube


# Line break
line
showFinishMessage


# Line break
line
attemptMinikubeStart