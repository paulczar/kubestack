account_file = "/etc/kubestack-account.json"
flannel_backend = "vxlan"
flannel_network = "10.10.0.0/16"
etcd_image = "coreos-alpha-884-0-0"
kubernetes_image = "kubernetes-1.2.0-alpha.5"
portal_net = "10.200.0.0/16"
cluster_name = "kubestack-testing"

public_key_path = "~/.ssh/id_rsa.pub"
network_name = "internal"
floatingip_pool = "external"

project = "kubestack"
etcd_flavor = "m1.medium"
