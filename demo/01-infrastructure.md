# 1 - Infrastructure for the Demo

The environment for the demostration was built on AWS using terraform. If you are not familiar with terraform, its time! : )
You will need an AWS account and Terraform installed on your computer.

1. Start by cloning this repository:

```bash
git clone https://github.com/regisftm/owasp-toronto && \

```

2. Change directory to terraform and run the terraform initialization:

```bash
cd owasp-toronto/terraform
terraform init
```

3. Edit the `variables.tf` file and change accordingly. The default value will generate 1 EC2 instance type t3.small for control-plane and 1 EC2 instance type t3.medium for the worker node. The AWS region selected is the `ca-central-1`. Feel free to change the variable values to whatever you want to have in your environment. I can't promisse that it will work well with limited resources though.

```bash
vi variables.tf
```

4. Apply the terraform code. This will build the EC2 instances, install Kubernetes and other software used during the demo.

```bash
terraform apply --auto-approve
```
5. After a few minutes, you will see the output containing the public ips for the EC2s created. 

<pre>

</pre>

Go to the next steps to finalize the Kubernetes cluster configuration and configure & install the Calico CNI.

---

[:arrow_right: 2 - Kubernetes Cluster Configuration](/demo/02-k8s-config.md) <br>

[:leftwards_arrow_with_hook: Back to Main](/README.md)  







