# 3 - Install and Configure the Calico CNI

Install Calico to provide both networking and network policy for self-managed on-premises deployments.


### Calico Installation

The operator installs directly on the cluster as a Deployment and requires configuration through one or more custom Kubernetes API resources to manage the installation, upgrade, and general lifecycle of a Calico cluster.

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
```

### Calico Configuration

**Optionally** You can download the custom resources necessary to configure Calico using the command below.

```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/custom-resources.yaml -O
```

**Optionally** You can download the custom resources necessary to configure Calico using the command below.

The following `yaml` is the custom resources configuration we will use in this demonstration. Copy and apply it to the control-plane node.

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

You can watch the tigera-operation to install the Calico CNI components using `k9s -A` (yes, I included it in the installation. Pretty handy, eh?) or using the following command.

```bash
watch kubectl get tigerastatus
```

Wait until the output looks like this:

<pre>
Every 2.0s: kubectl get tigerastatus                                           control-plane: Fri Jun  9 19:59:50 2023

NAME        AVAILABLE   PROGRESSING   DEGRADED   SINCE
apiserver   True        False         False      102s
calico      True        False         False      117s
</pre>

Finally, recheck the status of the nodes:

```bash
kubectl get nodes -o wide
```

If everything goes well, the output will be similar to the following.

```bash
NAME            STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
control-plane   Ready    control-plane   26m   v1.26.5   172.31.47.191   <none>        Ubuntu 20.04.6 LTS   5.15.0-1037-aws   containerd://1.7.2
worker-01       Ready    <none>          18m   v1.26.5   172.31.38.151   <none>        Ubuntu 20.04.6 LTS   5.15.0-1037-aws   containerd://1.7.2
```

Congratulations! You have your Kubernetes cluster up and running with Calico CNI. The next step will be to build and scan images for vulnerabilities using the `tigera-scanner`.

---

[:arrow_right: 4 - Scan Images for Vulnerabilities with **tigera-scanner**](/demo/04-tigera-scanner.md) <br>

[:arrow_left: 2 - Kubernetes Cluster Configuration](/demo/02-k8s-config.md)   
[:leftwards_arrow_with_hook: Back to Main](/README.md)  