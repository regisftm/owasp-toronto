# 2 - Kubernetes Cluster Configuration

After installing kubeadm, kubectl, and kubelet on both nodes and initializing the control-plane node with kubeadm, the next step is to join the worker node(s) to the cluster. Follow the instructions below to complete this process:

1. The Terraform generated and saved a key pair in the `terraform` folder. Utilize this key to establish an SSH connection with the control-plane node and retrieve the kubeadm join command. Locate this command in the `/var/log/cloud-init-output.log` file.

   ```bash
   ssh -i owasp-key ubuntu@<control_plane_public_ip_address>
   ```

   ```bash
   grep "kubeadm.*discovery\|discovery.*kubeadm" /var/log/cloud-init-output.log
   ```
   
   The output will be something like:
   
   <pre>
   kubeadm join <control_plane_private_ip>:6443 --token 9lbxla.pjsptj0m9wra8tyi --discovery-token-ca-cert-hash sha256:bfd99111c1f98dcb4ec225d2ec56fee13d2207057a2811eb67b217be8330c6ed
   </pre>

2. Using the same key, open another terminal and ssh to the worker node (if you have more than one, repeat these steps for all of them).

   ```bash
   ssh -i owasp-key ubuntu@<worker_node_public_ip_address>
   ```
   ```bash
   sudo su - root
   ```

   Paste the `kubeadm join` command copied from the control-plane node.

   The output will look like the following:

   <pre>
   root@worker-01:~# kubeadm join 172.31.44.20:6443 --token 92ap7u.vwmkiesc0cjcdphp --discovery-token-ca-cert-hash sha256:d60463cc14666f454579eca7c26b61569b90da4d75aa912a293529f49194d50a
   [preflight] Running pre-flight checks
   [preflight] Reading configuration from the cluster...
   [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
   [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
   [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
   [kubelet-start] Starting the kubelet
   [kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...
   
   This node has joined the cluster:
   * Certificate signing request was sent to apiserver and a response was received.
   * The Kubelet was informed of the new secure connection details.
   
   Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
   
   root@worker-01:~#
   </pre>

   After joining the worker node to the cluster, you can close the terminal connected to the worker node.

3. From the terminal connected to the control-plane, verify if the node successfully joined the cluster by running the following command as `root`:

   ```bash
   sudo su - root
   kubectl get nodes
   ```

   The output should be:

   <pre>
   NAME            STATUS     ROLES           AGE     VERSION
   control-plane   NotReady   control-plane   22m     v1.26.5
   worker-01       NotReady   &lt;none&gt;          2m36s   v1.26.5
   </pre>

   The current status is "**NotReady**" due to the absence of the CNI (Container Networking Interface) installation. Let's proceed to the next step, which involves configuring and installing the Calico CNI to resolve this issue.

---

[:arrow_right: 3 - Install and Configure the Calico CNI](/demo/03-calico-installation.md) <br>

[:arrow_left: 1 - Infrastructure for the Demo](/demo/01-infrastructure.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)  