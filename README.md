Initial project

Terraform

cat /var/log/cloud-init-output.log

---

Calico Installation

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
```

Calico configuration

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

---

Image scanner

```bash
git clone https://github.com/regisftm/website.git
```

---

he following image is an illustration for `deny-app-policy`:
```mermaid
flowchart LR
subgraph Cluster
    subgraph namespace a
        A[Pods]
    end
    subgraph namespace b
        B[Pods]
    end
    subgraph kube-System
        C[Pods\nk8s-app == core-dns ]
    end
    A[Pods] -->|egress\n UDP 53| C[Pods\nk8s-app == core-dns ]
    B[Pods] -->|egress\n UDP 53| C[Pods\nk8s-app == core-dns ]
    A[Pods] x--x|ingress\negress| B[Pods]
end
subgraph External resources
    A[Pods] x--x|ingress\negress| Z[The Internet]
    B[Pods] x--x|ingress\negress| Z[The Internet]
    Z[The Internet]
end
```

```mermaid
flowchart TD
subgraph Cluster
    subgraph namespace vote
        A[load\n generator] -->|TCP 80| B
        A -->|TCP 80| F
        B[vote] -->|TCP 6379| C[redis]
        D[worker] -->|TCP 6379| C[redis]
        D[worker] -->|TCP 5432| E[db]
        F[result] -->|TCP 5432| E[db]
 
    end
end
subgraph The Internet
    Z[clients] -->|HTTP\n TCP 30080| B
    Z[clients] -->|HTTP\n TCP 30081| F
end
```


