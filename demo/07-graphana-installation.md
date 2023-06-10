# Visualizing Metrics via Grafana

Use Grafana dashboard to view Calico component metrics.

## Preparing Prometheus

Here you will create a service to make your prometheus visible to Grafana.

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: prometheus-dashboard-svc
  namespace: calico-monitoring
spec:
  selector:
      app:  prometheus-pod
      role: monitoring
  ports:
  - port: 9090
    targetPort: 9090
EOF
```

## Preparing Grafana pod

1. Provisioning datasource
   
   Grafana datasources are storage backends for your time series data. Each data source has a specific Query Editor that is customized for the features and capabilities that the particular data source exposes.

   Setup a datasource and point it to the Prometheus service in your cluster.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: grafana-config
     namespace: calico-monitoring
   data:
     prometheus.yaml: |-
       {
           "apiVersion": 1,
           "datasources": [
               {
                  "access":"proxy",
                   "editable": true,
                   "name": "calico-demo-prometheus",
                   "orgId": 1,
                   "type": "prometheus",
                   "url": "http://prometheus-dashboard-svc.calico-monitoring.svc:9090",
                   "version": 1
               }
           ]
       }
   EOF
   ```

2. Provisioning Calico dashboards
 
   Create a configmap with Felix and Typha dashboards.

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/grafana-dashboards.yaml
   ```

3. Creating Grafana pod

   Create the Grafana pod using the config file that was created earlier. Grafana uses port 3000 by default.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: grafana-pod
     namespace: calico-monitoring
     labels:
       app:  grafana-pod
       role: monitoring
   spec:
     containers:
     - name: grafana-pod
       image: grafana/grafana:latest
       resources:
         limits:
           memory: "128Mi"
           cpu: "500m"
       volumeMounts:
       - name: grafana-config-volume
         mountPath: /etc/grafana/provisioning/datasources
       - name: grafana-dashboards-volume
         mountPath: /etc/grafana/provisioning/dashboards
       - name: grafana-storage-volume
         mountPath: /var/lib/grafana
       ports:
       - containerPort: 3000
     volumes:
     - name: grafana-storage-volume
       emptyDir: {}
     - name: grafana-config-volume
       configMap:
         name: grafana-config
     - name: grafana-dashboards-volume
       configMap:
         name: grafana-dashboards-config
   EOF
   ```

4. Accessing Grafana Dashboard

   To view your Grafana dashboards create the following nodeport service.

   ```yaml
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       app: grafana
     name: grafana
     namespace: calico-monitoring
   spec:
     ports:
     - name: 3000-3000
       nodePort: 30000
       port: 3000
       protocol: TCP
       targetPort: 3000
     selector:
       app: grafana-pod
     type: NodePort
   EOF
   ```

   Access Grafana web-ui at http://<control-plane_public_ip>:30000.

   > **NOTE** : Both `username` and `password` are `admin`.

   After login you will be prompted to change the default password, you can either change it here (Recommended) and click Save or click Skip and do it later from settings.

---

# Congratulation you have arrived at the end of the demo! I hope you have enjoyed!

---

[:leftwards_arrow_with_hook: Back to Main](/README.md) <br>

[:arrow_left: 6 - Calico Components Metrics](/demo/06-calico-metrics.md)  
