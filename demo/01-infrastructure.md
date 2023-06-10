# 1 - Infrastructure for the Demo

The environment for the demonstration was built on AWS using Terraform. If you desire to become more familiar with terraform, it's time! : ) You will need an AWS account and Terraform installed on your computer.

1. Start by cloning this repository:

```bash
git clone https://github.com/regisftm/owasp-toronto
```

2. Change the directory to Terraform, and run the Terraform initialization:

```bash
cd owasp-toronto/terraform
terraform init
```

3. Edit the `variables.tf` file and change accordingly. The default value will generate 1 EC2 instance type t3.small for the control-plane and 1 EC2 instance type t3.medium for the worker node. The AWS region selected is `ca-central-1`. Feel free to change the variable values to whatever you want in your environment. I can't promise that it will work well if you use smaller instance types.

```bash
vi variables.tf
```

4. Apply the Terraform code. This code will build the EC2 instances and install Kubernetes and other software used in this demonstration.

```bash
terraform apply --auto-approve
```
5. After a few minutes, you will see the output containing the created public IPs for the EC2 instances. 

```console
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

control_plane_public_ip = "3.96.49.113"
workers_public_ips = {
  "worker-01" = "3.99.20.164"
}
```

Go to the next step to finalize the **Kubernetes Cluster Configuration** and configure & install the Calico CNI.

---

[:arrow_right: 2 - Kubernetes Cluster Configuration](/demo/02-k8s-config.md) <br>

[:leftwards_arrow_with_hook: Back to Main](/README.md)  








