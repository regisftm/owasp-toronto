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
flowchart LR
subgraph Cluster
    subgraph namespace vote
        A[load\n generator]
        B[vote]
        C[redis]
        D[worker]
        E[db]
        F[result]
    end
    subgraph kube-System
        G[Pods\nk8s-app == core-dns ]
    end
    A[load\n generator] -->|egress\n UDP 53| G[Pods\nk8s-app == core-dns ]
    B[vote] -->|egress\n UDP 53| G[Pods\nk8s-app == core-dns ]
    C[redis] -->|egress\n UDP 53| G[Pods\nk8s-app == core-dns ]
    D[worker] -->|egress\n UDP 53| G[Pods\nk8s-app == core-dns ]
    E[db] -->|egress\n UDP 53| G[Pods\nk8s-app == core-dns ]
    F[result] -->|egress\n UDP 53| G[Pods\nk8s-app == core-dns ]
end
subgraph The Internet
    A[load\n generator] <--|ingress| Z[clients]
    F[result] <--|ingress| Z[clients]
    Z[clients]
end
```


