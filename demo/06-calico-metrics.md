# 6 - Calico Component Metrics

Use Prometheus configured for Calico components to get valuable metrics about the health of Calico on a Graphana dashboard.

Felix is a daemon that runs on every machine that implements network policy. Felix is the brains of Calico. Typha is an optional set of pods that extends Felix to scale traffic between Calico nodes and the data store. The kube-controllers pod runs a set of controllers responsible for various control plane functions, such as resource garbage collection and synchronization with the Kubernetes API.

You can configure Felix, Typha, and/or kube-controllers to provide metrics to Prometheus.

## Configure Calico to enable metrics reporting
   
1. Felix configuration

   Felix Prometheus metrics are disabled by default. Use the following command to enable Felix metrics.

   ```bash
   kubectl patch felixconfiguration default --type merge --patch '{"spec":{"prometheusMetricsEnabled": true}}'
   ```

2. Creating a service to expose Felix metrics
   
   Prometheus uses Kubernetes services to discover endpoints dynamically. Here you will create a service named felix-metrics-svc which Prometheus will use to discover all the Felix metrics endpoints. Felix, by default, uses port 9091 TCP to publish its metrics.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Service
   metadata:
     name: felix-metrics-svc
     namespace: calico-system
   spec:
     clusterIP: None
     selector:
       k8s-app: calico-node
     ports:
     - port: 9091
       targetPort: 9091
   EOF
   ```

3. Typha Configuration
   
   An Operator installation of Calico automatically deploys one or more Typha instances depending on the scale of your cluster. By default, metrics for these instances are disabled.

   Use the following command to instruct tigera-operator to enable Typha metrics.

   ```bash
   kubectl patch installation default --type=merge -p '{"spec": {"typhaMetricsPort":9093}}'
   ```

4. Creating a service to expose Typha metrics

   Typha uses port 9091 TCP by default to publish its metrics. However, if Calico is installed using yaml file, this port will be 9093 as its set manually via `TYPHA_PROMETHEUSMETRICSPORT` environment variable.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Service
   metadata:
     name: typha-metrics-svc
     namespace: calico-system
   spec:
     clusterIP: None
     selector:
       k8s-app: calico-typha
     ports:
     - port: 9093
       targetPort: 9093
   EOF
   ```

5. kube-controllers configuration

   Prometheus metrics are enabled by default on TCP port 9094 for calico-kube-controllers. The operator automatically creates a service that exposes these metrics.
   You can use the following command to verify it.
   
   ```bash
   kubectl get svc -n calico-system
   ```

   You should see a result similar to:

   <pre>
   NAME                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
   calico-kube-controllers-metrics   ClusterIP   None             &lt;none&gt;        9095/TCP   43h
   </pre>

---

## Cluster preparation

1. Namespace creation

   Namespace isolates resources in your cluster. Here you will create a Namespace called calico-monitoring to hold your monitoring resources.

   ```yaml
   kubectl create -f -<<EOF
   apiVersion: v1
   kind: Namespace
   metadata:
     name: calico-monitoring
     labels:
       app:  ns-calico-monitoring
       role: monitoring
   EOF
   ```

2. Service account creation

   You need to provide Prometheus a service account with the required permissions to collect information from Calico.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: calico-prometheus-user
   rules:
   - apiGroups: [""]
     resources:
     - endpoints
     - services
     - pods
     verbs: ["get", "list", "watch"]
   - nonResourceURLs: ["/metrics"]
     verbs: ["get"]
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: calico-prometheus-user
     namespace: calico-monitoring
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: calico-prometheus-user
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: calico-prometheus-user
   subjects:
   - kind: ServiceAccount
     name: calico-prometheus-user
     namespace: calico-monitoring
   EOF
   ```


## Install Prometheus

1. Create prometheus config file.
   
   We can configure Prometheus using a ConfigMap to persistently store the desired settings.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: prometheus-config
     namespace: calico-monitoring
   data:
     prometheus.yml: |-
       global:
         scrape_interval:   15s
         external_labels:
           monitor: 'tutorial-monitor'
       scrape_configs:
       - job_name: 'prometheus'
         scrape_interval: 5s
         static_configs:
         - targets: ['localhost:9090']
       - job_name: 'felix_metrics'
         scrape_interval: 5s
         scheme: http
         kubernetes_sd_configs:
         - role: endpoints
         relabel_configs:
         - source_labels: [__meta_kubernetes_service_name]
           regex: felix-metrics-svc
           replacement: $1
           action: keep
       - job_name: 'typha_metrics'
         scrape_interval: 5s
         scheme: http
         kubernetes_sd_configs:
         - role: endpoints
         relabel_configs:
         - source_labels: [__meta_kubernetes_service_name]
           regex: typha-metrics-svc
           replacement: $1
           action: keep
         - source_labels: [__meta_kubernetes_pod_container_port_name]
           regex: calico-typha
           action: drop
       - job_name: 'kube_controllers_metrics'
         scrape_interval: 5s
         scheme: http
         kubernetes_sd_configs:
         - role: endpoints
         relabel_configs:
         - source_labels: [__meta_kubernetes_service_name]
           regex: calico-kube-controllers-metrics
           replacement: $1
           action: keep
   EOF
   ```

2. Create Prometheus pod

   Now that you have a service account with permissions to gather metrics and have a valid config file for your Prometheus, it's time to create the Prometheus pod.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: prometheus-pod
     namespace: calico-monitoring
     labels:
       app: prometheus-pod
       role: monitoring
   spec:
     serviceAccountName: calico-prometheus-user
     containers:
     - name: prometheus-pod
       image: prom/prometheus
       resources:
         limits:
           memory: "128Mi"
           cpu: "500m"
       volumeMounts:
       - name: config-volume
         mountPath: /etc/prometheus/prometheus.yml
         subPath: prometheus.yml
       ports:
       - containerPort: 9090
     volumes:
     - name: config-volume
       configMap:
         name: prometheus-config
   EOF
   ```
   
   Check your cluster pods to assure pod creation was successful and prometheus pod is Running.
   
   ```bash
   kubectl get pods prometheus-pod -n calico-monitoring
   ```

   It should return something like the following.
   
   <pre>
   NAME             READY   STATUS    RESTARTS   AGE
   prometheus-pod   1/1     Running   0          16s
   </pre>

## View metrics

Create a nodeport service to expose your Prometheus dashboard. 

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus-dashboard-svc-external
    role: monitoring
  name: prometheus
  namespace: calico-monitoring
spec:
  ports:
  - nodePort: 30090
    port: 9090
    protocol: TCP
    targetPort: 9090
  selector:
    app: prometheus-pod
    role: monitoring
  type: NodePort
EOF
```

Browse to http://<control-plane_public_ip>:9090 and you should be able to see the Prometheus dashboard. Type `felix_active_local_endpoints` in the Expression input textbox, then hit the execute button. The console table should be populated with all your nodes and the quantity of endpoints in each of them.

> **Note** : A list of Felix metrics can be [found at this link](https://docs.tigera.io/calico/latest/reference/felix/prometheus). Similar lists can be found for kube-controllers and Typha.

Push the `Add Graph` button. You should be able to see the metric plotted on a Graph.

Now you can install and configure Graphana to visualise the Calico statistics.

---

[:arrow_right: 7 - Visualizing Metrics via Grafana](/demo/07-graphana-installation.md) <br>

[:arrow_left: 5 - Protect Your Application with **Security Policies**](/demo/05-security-policy.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)  

