# ocp-agent-install-config-examples

## Gather the Machine Information

| Type | Hostname | Interface | MAC Address | IP Address | Disk Hint |
| cp | cp-1 | eno1 | A0-B1-C2-D3-E4-F5 | 10.1.0.12 | /dev/sda |
| cp | cp-2 | eno1 | A0-B1-C2-D3-E4-F5 | 10.1.0.13 | /dev/sda |
| cp | cp-3 | eno1 | A0-B1-C2-D3-E4-F5 | 10.1.0.14 | /dev/sda |
| w | worker-1 | eno1 | A0-B1-C2-D3-E4-F5 | 10.1.0.15 | /dev/sda |
| w | worker-2 | eno1 | A0-B1-C2-D3-E4-F5 | 10.1.0.16 | /dev/sda |
| w | worker-3 | eno1 | A0-B1-C2-D3-E4-F5 | 10.1.0.15 | /dev/sda |

## Create Bastion Host

* Download Red Hat Enterprise Linux 9.x Binary DVD from https://access.redhat.com/downloads/content/rhel
* Boot host from ISO and perform install as Server with GUI
* Make sure to enable SSH for user
* Reboot and SSH into bastion host as administrative user

> **Everything from here on out is done on the bastion host.**

### Register Bastion RHEL Box
```
sudo subscription-manager register # Enter username/password
sudo subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms
sudo subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms
sudo dnf update -y
```

## Download Tools Commands

### Install needed tools on bastion
```shell
OCP_VERSION=4.19
wget "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-${OCP_VERSION}/openshift-install-linux.tar.gz" -P /tmp
sudo tar -xvzf /tmp/openshift-install-linux.tar.gz -C /usr/local/bin
wget "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-${OCP_VERSION}/openshift-client-linux.tar.gz" -P /tmp
sudo tar -xvzf /tmp/openshift-client-linux.tar.gz -C /usr/local/bin
rm /tmp/openshift-install-linux.tar.gz /tmp/openshift-client-linux.tar.gz
sudo sudo dnf install nmstate git
```

### Check the versions of needed tools
```shell
openshift-install version
oc version
nmstatectl -V
git -v
```

### Get the Pull Secret
Pull Secret is available at https://console.redhat.com/openshift/install/pull-secret
Download to `~/.pull-secret`

### Create SSH Key
```shell 
ssh-keygen -t ed25519 -f ~/.ssh/ocp_ed25519
```

## OpenShift Agent Based Install Commands

Create the ISO. For the install-config.yaml and agent-config.yaml, you can use the examples from the folders in this repo. 

> There is a reason we copy the config files into an install directory and run it from there. The agent create image process is destructive to the configuration files so it's smart to keep a copy outside the target directory so if we need to regenerate the iso from the configurations, it can be done easily. 

```shell
mkdir -p ocp && cd ocp
vi install-config.yaml  # Add your specific configuration - Need pull secret and SSH key from above
vi agent-config.yaml    # Add your specific configuration
#
rm -rf install
mkdir install
cp -r install-config.yaml agent-config.yaml install
openshift-install agent create image --dir=install --log-level=debug
```

Wait for the agent create image command to complete and you will have a iso file. 

Example Copy the ISO to the storage where you can boot from. 
```shell
scp snimmo@192.168.122.187:~/ocp/install/agent.x86_64.iso ~/iso/
```

Boot hosts with created ISO...

Wait for Bootstrap Complete
```shell
openshift-install agent wait-for bootstrap-complete --dir=install --log-level=debug
```

Wait for Install Complete
```shell
openshift-install agent wait-for install-complete --dir=install --log-level=debug
```

> You don't have to do the bootstrap-complete command at all, you can just run the install-complete...

## Post Install

Login to the Cluster
```shell
oc login --server=https://api.cluster.basedomain.com:6443 -u kubeadmin -p <password>
```

Cleanup the install pods
```shell
oc delete pods --all-namespaces --field-selector=status.phase=Succeeded
oc delete pods --all-namespaces --field-selector=status.phase=Failed
```


## Documentation

* Installing on Bare Metal - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index
* Configuring Firewall - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/installation_configuration/configuring-firewall#configuring-firewall_configuring-firewall
* Network Connectivity Requirements - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-network-connectivity-user-infra_installing-bare-metal
* Ensuring required ports are open - https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_bare_metal/index#network-requirements-ensuring-required-ports-are-open_ipi-install-prerequisites
* 