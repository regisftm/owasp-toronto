# 3 - Install and Configure the Calico CNI

Install Calico to provide both networking and network policy for self-managed on-premises deployments.


### Calico Installation

Calico is installed by an operator which manages the installation, upgrade, and general lifecycle of a Calico cluster. The operator is installed directly on the cluster as a Deployment, and is configured through one or more custom Kubernetes API resources.

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
```

### Calico Configuration

You can download the custom resources necessary to configure Calico using the command bellow.

```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/custom-resources.yaml -O
```

If you wish to customize the Calico install, customize the downloaded custom-resources.yaml manifest locally.

The following `yaml` is the custom resources configuration that we will use in this demostration. Copy and apply it to the control-plane node.


```yaml
kubectl apply -f - <<-EOF
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    bgp: Disabled
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
```

You can watch the tigera-operation to install the Calico CNI componets using k9s -A (yes, I included it in the installation. Pretty handy, eh?), or using the following command.

```bash
watch kubectl get tigerastatus
```

Wait until the output to look like this:

<pre>
Every 2.0s: kubectl get tigerastatus                                           control-plane: Fri Jun  9 19:59:50 2023

NAME        AVAILABLE   PROGRESSING   DEGRADED   SINCE
apiserver   True        False         False      3m
calico      True        False         False      3m
</pre>

Finally, check the STATUS of the nodes again:

```bash
kubectl get nodes -o wide
```

If everything went well, the output will be similar to the following.

```bash
NAME            STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
control-plane   Ready    control-plane   16m   v1.26.5   172.31.47.191   <none>        Ubuntu 20.04.6 LTS   5.15.0-1037-aws   containerd://1.7.2
worker-01       Ready    <none>          16m   v1.26.5   172.31.38.151   <none>        Ubuntu 20.04.6 LTS   5.15.0-1037-aws   containerd://1.7.2
```

Congratulations! You have your Kubernetes cluster up and running with Calico CNI. The next step will be to build and scan images for vulnerabilities using the `tigera-scanner`.

---

[:arrow_right: 4 - Scan Images for Vulnerabilities with **tigera-scanner**](/demo/04-tigera-scanner.md) <br>

[:arrow_left: 2 - Kubernetes Cluster Configuration](/demo/02-k8s-config.md)   
[:leftwards_arrow_with_hook: Back to Main](/README.md)  