# ocp-agent-install-config-examples

## Prior to Install

Prior to the install, you must open the firewall and ports between the machines. 

* [Configuring Firewall](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/installation_configuration/configuring-firewall#configuring-firewall_configuring-firewall)
* [Network Connectivity Requirements](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-network-connectivity-user-infra_installing-bare-metal)
* [Ensuring required ports are open](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#network-requirements-ensuring-required-ports-are-open_ipi-install-prerequisites)

## Gather the Cluster Install Information

Below are the values an enterprise typically has to gather or create for installing OpenShift. The Pod Subnet and Service Subnet are run in the software defined network (SDN) so if those values conflict with existing subnets AND your pods in the cluster will want to route to those outside services with conflicting IPs, you will need to provide different subnets. 

| Variable                  | Example Value             | Description                                 | 
| ---                       | ---                       | ---                                         |
| Bastion IP                | 10.1.0.4                  | IP or hostname for the bastion host         |
| DNS                       | dns1.basedomain.com,etc   | IP or hostname for the DNS hosts            |
| NTP                       | ntp.basedomain.com,etc    | IP or hostname for the NTP hosts            |
| Cluster Name              | poc                       | Name of the cluster                         |
| Base Domain               | ocp.basedomain.com        | Name of the domain                          |
| Machine Subnet            | 10.1.0.0/24 (vlan - 123)  | Subnet/vlan for all machines/ips in cluster |
| Pod Subnet                | 10.128.0.0/14             | Subnet for pod SDN                          |
| Pod Subnet - Host Prefix  | 23                        | Host prefix for Subnet for pod SDN          |
| Service Subnet            | 172.30.0.0/16             | Subnet for service SDN                      |
| API VIP                   | 10.1.0.9                  | VIP for the MetalLB API Endpoint            |
| Ingress VIP               | 10.1.0.10                 | VIP for the MetalLB Ingress Endpoint        |

[Pod Subnet - Host Prefix](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#CO63-10)  
[CIDR Subnet Reference](https://docs.netgate.com/pfsense/en/latest/network/cidr.html#understanding-cidr-subnet-mask-notation)

## Gather the Machine Information

Typically, machines will have more than one NIC and these will be setup in a bond. Please collect the interface names and MAC addresses for ALL NICS and the install disk location on the machines. You provide the hostnames, IPs. IPs need to be located in the machine configuration subnet used on the install. 

| Type  | Hostname  | Interface | MAC Address       | IP Address    | Disk Hint |
| ---   | ---       | ---       | ---               | ---           | ---       |
| cp    | cp-1      | eno1      | A0-B1-C2-D3-E4-E1 | 10.1.0.11     | /dev/sda  |
|       |           | eno2      | A0-B1-C2-D3-E4-E2 |               |           |
| cp    | cp-2      | eno1      | A0-B1-C2-D3-E4-E3 | 10.1.0.12     | /dev/sda  |
|       |           | eno2      | A0-B1-C2-D3-E4-E4 |               |           |
| cp    | cp-3      | eno1      | A0-B1-C2-D3-E4-E5 | 10.1.0.13     | /dev/sda  |
|       |           | eno2      | A0-B1-C2-D3-E4-E6 |               |           |
| w     | worker-1  | eno1      | A0-B1-C2-D3-E4-F1 | 10.1.0.21     | /dev/sda  |
|       |           | eno2      | A0-B1-C2-D3-E4-F2 |               |           |
| w     | worker-2  | eno1      | A0-B1-C2-D3-E4-F3 | 10.1.0.22     | /dev/sda  |
|       |           | eno2      | A0-B1-C2-D3-E4-F4 |               |           |
| w     | worker-3  | eno1      | A0-B1-C2-D3-E4-F5 | 10.1.0.23     | /dev/sda  |
|       |           | eno2      | A0-B1-C2-D3-E4-F6 |               |           |

cp = Control Plane  
w  = Worker

## Create DNS Entries

Create the following A records in your DNS based on the values from above. 

| A Record                      | IP Address  | Description                         | 
| ---                           | ---         | ---                                 |
| api.poc.ocp.basedomain.com    | 10.1.0.9    | Virtual IP for the API endpoint     |
| *.apps.poc.ocp.basedomain.com | 10.1.0.10   | Virtual IP for the ingress endpoint |


https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-dns-user-infra_installing-bare-metal-network-customizations

## Create Bastion Host

* Download [Red Hat Enterprise Linux 9.x Binary DVD](https://access.redhat.com/downloads/content/rhel)
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

### Install the Following Operators
* Kubernetes NMState Operator 
* Node Feature Discovery
* Node Health Check Operator
* Self Node Remediation Operator
* Kube Descheduler Operator

### Install Storage

### Install Additional Operators
* OpenShift Virtualization
* cert-manager Operator for Red Hat OpenShift
* Logging [link](https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.3/html/installing_logging/installing-logging#installing-loki-and-logging-gui_installing-logging)
  * Loki Operator
  * Red Hat OpenShift Logging


## Documentation

* Minimum resource requirements for cluster installation - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-minimum-resource-requirements_installing-bare-metal-network-customizations 
* DNS Requirements - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-dns-user-infra_installing-bare-metal-network-customizations
* Installing on Bare Metal - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index
* Configuring Firewall - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/installation_configuration/configuring-firewall#configuring-firewall_configuring-firewall
* Network Connectivity Requirements - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-network-connectivity-user-infra_installing-bare-metal
* Ensuring required ports are open - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#network-requirements-ensuring-required-ports-are-open_ipi-install-prerequisites


## Install Debugging

### Modify the Boot Parameters (GRUB/Boot Menu)

This is often the most reliable way to get a shell or verbose output when direct TTY switching fails. You'll need to intercept the boot process.

* Reboot the machine with the ISO.
* At the GRUB (bootloader) menu: As soon as you see the initial boot menu (often "OpenShift Installer" or similar), press an arrow key (up/down) to stop the automatic countdown.
* Edit the boot entry:
  * Select the installer's default boot entry (usually the first one).
  * Press the e key to edit the boot parameters.
  * Locate the linux or linuxefi line: This line contains the kernel arguments.
  * Add debug/shell parameters to force an emergency shell. Go to the end of the linux or linuxefi line and add `rd.break` or `rd.break=pre-mount`. This will drop you into an initramfs shell before the root filesystem is mounted. It's a very minimal environment but allows ip a show, dmesg, and looking at files in the initramfs.