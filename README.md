# Kubernetes on Openstack with Terraform

forked from [kelseyhightower/kubernetes](https://github.com/kelseyhightower/kubernetes)

Provision a Kubernetes cluster with [Packer](https://packer.io) and [Terraform](https://www.terraform.io) on Openstack

## Status

Ready for testing. Over the next couple of weeks the repo should be generic enough for reuse with complete documentation.

## Prep

- [Install Packer](https://packer.io/docs/installation.html)
- [Install Terraform](https://www.terraform.io/intro/getting-started/install.html)

The Packer and Terraform configs assume the following environment vars are set:
`OS_USERNAME` `OS_PASSWORD` and `OS_AUTH_URL`

## Packer Images

Immutable infrastructure is the future. Instead of using cloud-init to provision machines at boot we'll create a custom image using Packer.

### Create the kubernetes Base Image

This assumes you already have a coreos image in glance. You may need to 
adjust `packer/settings.json` to match settings in your OpenStack cloud.

```
$ . ~/.stackrc
$ cd packer
$ packer build -var-file=settings.json kubestack-openstack.json
```

## Terraform

Terraform will be used to declare and provision a Kubernetes cluster. By default it will be a single controller with a single compute node. You can add more nodes by adjusting the `compute_workers` variable.

The compute workers (for now) do not have a floating ip, this means to `ssh` to them you must `ssh -A` to the controller node first.

### Prep

Ensure your local ssh-agent is running and your ssh key has been added. This step is required by the terraform provisioner.

```
$ eval $(ssh-agent -s)
$ ssh-add ~/.ssh/id_rsa
```


### Provision the Kubernetes Cluster

```
$ cd terraform
$ export DISCOVERY_URL=$(curl -s 'https://discovery.etcd.io/new?size=1')
$ terraform plan \
      -var "username=$OS_USERNAME" \
      -var "password=$OS_PASSWORD" \
      -var "tenant=$OS_TENANT_NAME" \
      -var "auth_url=$OS_AUTH_URL" \
      -var "discovery_url=${DISCOVERY_URL}"

$ terraform apply \
      -var "username=$OS_USERNAME" \
      -var "password=$OS_PASSWORD" \
      -var "tenant=$OS_TENANT_NAME" \
      -var "auth_url=$OS_AUTH_URL" \
      -var "discovery_url=${DISCOVERY_URL}"
...
...
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

  kubernetes-controller = $ ssh -A core@xx.xx.xx.xx
```

## Next Steps

### Check its up

```
$ ssh -A core@xx.xx.xx.xx

$ /opt/bin/kubectl config use-context kubernetes
switched to context "kubernetes".

$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://127.0.0.1:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: admin
  name: kubernetes
current-context: kubernetes
kind: Config
preferences: {}
users:
- name: admin
  user:
    token: kubernetes

$ kubectl get nodes  
NAME          LABELS                               STATUS    AGE
10.230.7.23   kubernetes.io/hostname=10.230.7.23   Ready     5m
```

### Run a container

```
$ kubectl run my-nginx --image=nginx --replicas=1 --port=80
replicationcontroller "my-nginx" created

$ kubectl get pods
NAME             READY     STATUS    RESTARTS   AGE
my-nginx-k1zoe   1/1       Running   0          1m
```

### Destroy it

```
$ terraform destroy \
      -var "username=$OS_USERNAME" \
      -var "password=$OS_PASSWORD" \
      -var "tenant=$OS_TENANT_NAME" \
      -var "auth_url=$OS_AUTH_URL" \
      -var "discovery_url=${DISCOVERY_URL}"
Do you really want to destroy?
  Terraform will delete all your managed infrastructure.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
...
...
openstack_compute_secgroup_v2.kubernetes_controller: Destruction complete
openstack_compute_secgroup_v2.kubernetes_internal: Destruction complete

Apply complete! Resources: 0 added, 0 changed, 12 destroyed.      
```
