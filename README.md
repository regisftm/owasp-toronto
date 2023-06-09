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


```mermaid
flowchart TD
subgraph The Internet
    Z[clients]
end
Z -->|\nnodePort 30080 \n port TCP 80| B
Z -->|\nnodePort 30081 \n port TCP 80| F
subgraph Cluster
    subgraph namespace vote
        A[load\n generator]
        B[vote]
        C[redis]
        D[worker] 
        E[db]
        F[result]
    end
    A -->|TCP 80| B
    A -->|TCP 80| F
    B -->|TCP 6379| C
    D -->|TCP 6379| C
    D -->|TCP 5432| E
    F -->|TCP 5432| E
end
```

Workloads

vote

```mermaid
flowchart TD
subgraph The Internet
    Z[clients]
end
Z -->|\nnodePort 30081 \n port TCP 80| B
subgraph Cluster
    subgraph namespace vote
        A[load\n generator]
        B[vote]
        C[redis]
        style B fill:#da0,stroke:#009,color:#fff,stroke-width:4px
    end
    A -->|TCP 80| B
    B -->|TCP 6379| C
end
```


