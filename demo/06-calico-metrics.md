Calico Component Metrics

Use Prometheus configured for Calico components to get valuable metrics about the health of Calico on a Graphana dashboard.

Felix is a daemon that runs on every machine that implements network policy. Felix is the brains of Calico. Typha is an optional set of pods that extends Felix to scale traffic between Calico nodes and the datastore. The kube-controllers pod runs a set of controllers which are responsible for a variety of control plane functions, such as resource garbage collection and synchronization with the Kubernetes API.

You can configure Felix, Typha, and/or kube-controllers to provide metrics to Prometheus.

## Configure Calico to enable metrics reporting
   
1. Felix configuration

   Felix prometheus metrics are disabled by default. Use the following command to enable Felix metrics.

   ```bash
   kubectl patch felixconfiguration default --type merge --patch '{"spec":{"prometheusMetricsEnabled": true}}'
   ```

2. Creating a service to expose Felix metrics
   
   Prometheus uses Kubernetes services to dynamically discover endpoints. Here you will create a service named felix-metrics-svc which Prometheus will use to discover all the Felix metrics endpoints. Felix by default uses port 9091 TCP to publish its metrics.

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
   
   An Operator installation of Calico automatically deploys one or more Typha instances depending on the scale of your cluster. By default metrics for these instances are disabled.

   Use the following command to instruct tigera-operator to enable Typha metrics.

   ```bash
   kubectl patch installation default --type=merge -p '{"spec": {"typhaMetricsPort":9093}}'
   ```

4. Creating a service to expose Typha metrics

   Typha uses port 9091 TCP by default to publish its metrics. However, if Calico is installed using yaml file this port will be 9093 as its set manually via TYPHA_PROMETHEUSMETRICSPORT environment variable.

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

   You need to provide Prometheus a serviceAccount with required permissions to collect information from Calico.

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


