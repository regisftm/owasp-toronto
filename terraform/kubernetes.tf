
###############################################################################
# TLS Keys Creation
###############################################################################

resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "owasp-key"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "owasp-key.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Key pair used for SSH access into the instances
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "owasp-key"
  public_key = tls_private_key.global_key.public_key_openssh
}


###############################################################################
# EC2 Instances creation
###############################################################################

# Security Groups creation for Kubernetes nodes

resource "aws_security_group" "sg_allow_k8s" {
  name        = "${var.prefix}-allow-k8s"
  description = "Allow all traffic to SSH and NodePorts"
}

resource "aws_vpc_security_group_ingress_rule" "local" {
  security_group_id = aws_security_group.sg_allow_k8s.id

  cidr_ipv4   = data.aws_vpc.default.cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "${var.prefix}-k8s-ingress-rule-local"
  }
}

resource "aws_vpc_security_group_ingress_rule" "k8s_ippool" {
  security_group_id = aws_security_group.sg_allow_k8s.id

  cidr_ipv4   = "192.168.0.0/16"
  ip_protocol = "-1"

  tags = {
    Name = "${var.prefix}-k8s-ingress-rule-k8s-ippool"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.sg_allow_k8s.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = {
    Name = "${var.prefix}-k8s-ingress-rule-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "node_ports" {
  security_group_id = aws_security_group.sg_allow_k8s.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 30000
  to_port     = 32767
  ip_protocol = "tcp"

  tags = {
    Name = "${var.prefix}-k8s-ingress-rule-node-ports"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.sg_allow_k8s.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "${var.prefix}-k8s-egress-rule-all"
  }  
}

### EC2 Instances creation for Kubernetes nodes

resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.cp_instance_type
  key_name               = aws_key_pair.ssh_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_allow_k8s.id]
  source_dest_check      = false

  root_block_device {
    volume_size = 16
  }

  user_data = <<-EOFF
    #!/bin/bash
    
    hostnamectl set-hostname control-plane
    timedatectl set-timezone America/Toronto
    
    echo "$(hostname -i) contro-lplane" >> /etc/hosts
    
    # Terminal setup
    apt-get update
    apt-get install -y bash-completion binutils jq
    echo 'colorscheme ron' >> ~/.vimrc
    echo 'set tabstop=2' >> ~/.vimrc
    echo 'set shiftwidth=2' >> ~/.vimrc
    echo 'set expandtab' >> ~/.vimrc
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'alias k=kubectl' >> ~/.bashrc
    echo 'alias c=clear' >> ~/.bashrc
    echo 'complete -F __start_kubectl k' >> ~/.bashrc
    sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc
    
    
    # Kubernetes pre-req
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF
    
    sudo modprobe overlay
    sudo modprobe br_netfilter
    
    # sysctl params required by setup, params persist across reboots
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF
    
    # Apply sysctl params without reboot
    sudo sysctl --system
    
    lsmod | grep br_netfilter
    lsmod | grep overlay
    
    sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
    
    # Installing container.d
    curl -OL https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz 
    tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
    
    sudo curl -fsSLo /usr/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
    
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    systemctl daemon-reload
    systemctl enable --now containerd
    
    # Installing runc
    curl -OL https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64
    install -m 755 runc.amd64 /usr/local/sbin/runc
    
    # Installing Kubernetes
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    mkdir -p /etc/apt/keyrings
    sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update && \
    sudo apt-get install -y kubelet=1.26.5-00 kubeadm=1.26.5-00  kubectl=1.26.5-00 
    sudo apt-mark hold kubelet kubeadm kubectl
    
    # Initialize the node
    kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.26.5 --skip-token-print
    
    cat <<EOF | sudo tee /etc/crictl.yaml
    runtime-endpoint: unix:///run/containerd/containerd.sock
    EOF
    
    sudo mkdir -p /root/.kube
    sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown $(id -u):$(id -g) /root/.kube/config
    
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
     
    # Remove the taint from controlplane
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-
    
    echo "### COMMAND TO ADD A WORKER NODE ###"
    kubeadm token create --print-join-command --ttl 0

    # Install docker.io
    sudo apt-get install -y docker.io

    # Install k9s
    curl -OL https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz
    tar -xvf k9s_Linux_amd64.tar.gz
    mv ./k9s /usr/local/bin/
    
    # Install tigera-scanner
    curl -Lo tigera-scanner https://installer.calicocloud.io/tigera-scanner/v3.16.1-11/image-assurance-scanner-cli-linux-amd64
    chmod +x ./tigera-scanner
    mv ./tigera-scanner /usr/local/bin/

    # Install HELM
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    sudo apt-get install apt-transport-https --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install -y helm

  EOFF
 
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.global_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]
  }

  tags = {
    Name = "${var.prefix}-k8s-control-plane"
  }
}

resource "aws_instance" "worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.wk_instance_type
  key_name               = aws_key_pair.ssh_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_allow_k8s.id]
  source_dest_check      = false
  count                  = var.wk_instance_count


  root_block_device {
    volume_size = 16
  }

  user_data = <<-EOFF
    #!/bin/bash
    
    hostnamectl set-hostname ${format("worker-%02d", count.index + 1)}
    timedatectl set-timezone America/Toronto
    
    echo "$(hostname -i) ${format("worker-%02d", count.index + 1)}" >> /etc/hosts
    
    # Terminal setup
    apt-get update
    apt-get install -y bash-completion binutils jq
    echo 'colorscheme ron' >> ~/.vimrc
    echo 'set tabstop=2' >> ~/.vimrc
    echo 'set shiftwidth=2' >> ~/.vimrc
    echo 'set expandtab' >> ~/.vimrc
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'alias k=kubectl' >> ~/.bashrc
    echo 'alias c=clear' >> ~/.bashrc
    echo 'complete -F __start_kubectl k' >> ~/.bashrc
    sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc
    
    
    # Kubernetes pre-req
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF
    
    sudo modprobe overlay
    sudo modprobe br_netfilter
    
    # sysctl params required by setup, params persist across reboots
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF
    
    # Apply sysctl params without reboot
    sudo sysctl --system
    
    lsmod | grep br_netfilter
    lsmod | grep overlay
    
    sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
    
    # Installing container.d
    curl -OL https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz 
    tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
    
    sudo curl -fsSLo /usr/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
    
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    systemctl daemon-reload
    systemctl enable --now containerd
    
    # Installing runc
    curl -OL https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64
    install -m 755 runc.amd64 /usr/local/sbin/runc
    
    # Installing Kubernetes
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    mkdir -p /etc/apt/keyrings
    sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update && \
    sudo apt-get install -y kubelet=1.26.5-00 kubeadm=1.26.5-00  kubectl=1.26.5-00 
    sudo apt-mark hold kubelet kubeadm kubectl
 
    cat <<EOF | sudo tee /etc/crictl.yaml
    runtime-endpoint: unix:///run/containerd/containerd.sock
    EOF
    
    sudo mkdir -p /root/.kube
    sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown $(id -u):$(id -g) /root/.kube/config
    
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

  EOFF

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.global_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]
  }

  tags = {
    Name = "${var.prefix}-k8s-${format("worker-%02d", count.index + 1)}"
  }
}