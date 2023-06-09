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
---
title: Example Vote Application
---
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

load generator

```mermaid
---
title: Microservice - Load Generator
---
flowchart TB
subgraph Cluster
    subgraph namespace vote
        A[l o a d\n g e n e r a t o r]
        B[vote]
        F[result]
        style A fill:#da0,stroke:#007,color:#000,stroke-width:5px
    end
    A -->|TCP 80| B
    A -->|TCP 80| F
end
```

vote

```mermaid
---
title: Microservice - Vote
---
flowchart TD
subgraph The Internet
    Z[clients]
end
Z -->|\nnodePort 30081 \n port TCP 80| B
subgraph Cluster
    subgraph namespace vote
        A[load\n generator]
        B[v o t e]
        C[redis]
        style B fill:#da0,stroke:#007,color:#000,stroke-width:5px
    end
    A -->|TCP 80| B
    B -->|TCP 6379| C
end
```

Redis

```mermaid
---
title: Microservice - Redis
---
flowchart TB
subgraph Cluster
    subgraph namespace vote
        B[vote]
        C[r e d i s]
        D[worker] 
        style C fill:#da0,stroke:#007,color:#000,stroke-width:5px
    end
    B -->|TCP 6379| C
    D -->|TCP 6379| C
end
```

Worker

```mermaid
---
title: Microservice - Worker
---
flowchart TB
subgraph Cluster
    subgraph namespace vote
        C[redis]
        D[w o r k e r] 
        E[db]
        style D fill:#da0,stroke:#007,color:#000,stroke-width:5px
    end
    D -->|TCP 6379| C
    D -->|TCP 5432| E
end
```

Data Base
 
```mermaid
---
title: Microservicos - Data Base
---
flowchart TB
subgraph Cluster
    subgraph namespace vote
        D[worker] 
        E[d b]
        F[result]
        style E fill:#da0,stroke:#007,color:#000,stroke-width:5px
    end
    D -->|TCP 5432| E
    F -->|TCP 5432| E
end
```

Result

```mermaid
---
title: Microservice - Result
---
flowchart TD
subgraph The Internet
    Z[clients]
end
Z -->|\nnodePort 30081 \n port TCP 80| F
subgraph Cluster
    subgraph namespace vote
        A[load\n generator]
        E[db]
        F[r e s u l t]
        style F fill:#da0,stroke:#007,color:#000,stroke-width:5px
    end
    A -->|TCP 80| F
    F -->|TCP 5432| E
end
```