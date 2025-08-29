# ocp-agent-install-config-examples

## Prior to Install

Prior to the install, you must open the firewall to connect to Red Hat's servers and ports between the machines. 

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

> [Pod Subnet - Host Prefix](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#CO63-10)  
> [CIDR Subnet Reference](https://docs.netgate.com/pfsense/en/latest/network/cidr.html#understanding-cidr-subnet-mask-notation)

## Gather the Machine Information

Typically, machines will have more than one NIC and these will be setup in a bond. Please collect the interface names and MAC addresses for ALL NICS and the install disk location on the machines. You provide the hostnames, IPs. IPs need to be located in the machine configuration subnet used on the install. Below is an example table of values needed for collection. 

| Hostname                  | Interface | MAC Address       | IP Address    | Disk Hint |
| ---                       | ---       | ---               | ---           | ---       |
| openshift-control-plane-0 | eno1      | A0-B1-C2-D3-E4-E1 | 10.1.0.11     | /dev/sda  |
|                           | eno2      | A0-B1-C2-D3-E4-E2 |               |           |
| openshift-control-plane-1 | eno1      | A0-B1-C2-D3-E4-E3 | 10.1.0.12     | /dev/sda  |
|                           | eno2      | A0-B1-C2-D3-E4-E4 |               |           |
| openshift-control-plane-2 | eno1      | A0-B1-C2-D3-E4-E5 | 10.1.0.13     | /dev/sda  |
|                           | eno2      | A0-B1-C2-D3-E4-E6 |               |           |
| openshift-worker-0        | eno1      | A0-B1-C2-D3-E4-F1 | 10.1.0.21     | /dev/sda  |
|                           | eno2      | A0-B1-C2-D3-E4-F2 |               |           |
| openshift-worker-1        | eno1      | A0-B1-C2-D3-E4-F3 | 10.1.0.22     | /dev/sda  |
|                           | eno2      | A0-B1-C2-D3-E4-F4 |               |           |
| openshift-worker-2        | eno1      | A0-B1-C2-D3-E4-F5 | 10.1.0.23     | /dev/sda  |
|                           | eno2      | A0-B1-C2-D3-E4-F6 |               |           |

## Create DNS Entries

Create the following A records in your DNS based on the values from above. 

| A Record                      | IP Address  | Description                         | 
| ---                           | ---         | ---                                 |
| api.poc.ocp.basedomain.com    | 10.1.0.9    | Virtual IP for the API endpoint     |
| *.apps.poc.ocp.basedomain.com | 10.1.0.10   | Virtual IP for the ingress endpoint |

You can validate the DNS using dig

```shell
dig +noall +answer @<nameserver_ip> api.<cluster_name>.<base_domain>
dig +noall +answer @<nameserver_ip> test.apps.<cluster_name>.<base_domain>
```

> [DNS requirements](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#network-requirements-dns_ipi-install-prerequisites)  
> [Validating DNS resolution for user-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-user-provisioned-validating-dns_installing-bare-metal-network-customizations)

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
rm /tmp/openshift-install-linux.tar.gz /tmp/openshift-client-linux.tar.gz -y
sudo dnf install nmstate git podman
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

### Check Connectivity

Here are some tools to check connectivity. 
```shell
ping registry.redhat.io        # ICMP doesn’t always work, but try
curl -vk https://registry.redhat.io/v2/
dig registry.redhat.io +short
nslookup registry.redhat.io
podman login registry.redhat.io
```

## OpenShift Agent Based Install Commands

Create the configs for generating the ISOFor the install-config.yaml and agent-config.yaml, you can use the examples from the folders in this repo. 

```shell
mkdir -p ocp && cd ocp
mkdir -p cluster-manifests
vi install-config.yaml  # Add your specific configuration - Need pull secret and SSH key from above
vi agent-config.yaml    # Add your specific configuration
```

[Example install-config.yaml](./baremetal/install-config.yaml)   
[Example agent-config.yaml](./baremetal/agent-config.bond.yaml)    

> If you have additional manifests to apply at install time, place them in a folder named `cluster-manifests` at the same level as the `install-config.yaml` and `agent-config.yaml`. staticip-48-44

### NTP Setup 

In the `install-config.yaml`, add the spec for the NTP servers in the baremetal config section. 
```
platform:
  baremetal:
    additionalNTPServers: 
      - <ntp_domain_or_ip>
```

In the `agent-config.yaml`, add the spec for the NTP servers in the root for the document.
```
additionalNTPSources: 
  - <ntp_domain_or_ip>
```

> Notice the differences in the name - Servers v Sources...
> [NTP Sync Docs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/installing_on_bare_metal/installer-provisioned-infrastructure#checking-ntp-sync_ipi-install-installation-workflow)

### Creating the Image

From the `~/ocp` directory, you can now create the agent iso. We create an `install` directory and copy the yaml files into the directory because the image creation process consumes and destroys the configuration files. We want to keep a copy in case the process needs to be repeated. 
```shell
rm -rf install
mkdir install
cp -r install-config.yaml agent-config.yaml cluster-manifests install
openshift-install agent create image --dir=install --log-level=debug
```

> There is a shell script in this directory called `create-image.sh` that contains this contents. 

Wait for the agent create image command to complete and you will have a iso file located at `~/ocp/install/agent.x86_64.iso`.

Copy the ISO to the storage where you can boot from. Here's an example using scp.
```shell
scp user@192.168.122.187:~/ocp/install/agent.x86_64.iso ~/iso/
```

Boot hosts with created ISO...

When all the hosts are booted, wait for the install to complete (~15-30 minutes)
```shell
openshift-install agent wait-for bootstrap-complete --dir=install --log-level=debug
openshift-install agent wait-for install-complete --dir=install --log-level=debug
```

At the end of the process, you will be presented with the URL for the cluster endpoint, along with the kubeadmin credentials. 

## Post Install

Login to the Cluster
```shell
oc login --server=https://api.cluster.basedomain.com:6443 -u kubeadmin -p <password>
```

Test Connectivity
```shell
oc debug node/<worker-node-name> -- chroot /host \
  podman pull registry.redhat.io/ubi9/ubi:latest
```

Cleanup the leftover install and configuration pods
```shell
oc delete pods --all-namespaces --field-selector=status.phase=Succeeded
oc delete pods --all-namespaces --field-selector=status.phase=Failed
```

### Install the Following Operators
* Kubernetes NMState Operator 

### Setup NNCPs and UDNs
[Create the networks needed](./network/README.md)

### Install Storage
Install the storage of your choice....

### Install Additional Operators (after storage)
* [OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/virtualization/installing#installing-virt)
* Node Feature Discovery
* [Workload Availability for Red Hat OpenShift](https://docs.redhat.com/en/documentation/workload_availability_for_red_hat_openshift/25.7)
  * Node Health Check Operator
  * Self Node Remediation Operator
  * Fence Agents Remediation Operator
  * Kube Descheduler Operator
* [Configure Registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index)
* [cert-manager Operator for Red Hat OpenShift](https://stephennimmo.com/2024/05/15/generating-lets-encrypt-certificates-with-red-hat-openshift-cert-manager-operator-using-the-cloudflare-dns-solver)
* [Logging](https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.3/html/installing_logging/installing-logging#installing-loki-and-logging-gui_installing-logging)
  * Loki Operator
  * Red Hat OpenShift Logging

[Post Install Configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index)

[Rotate SSH Keys after install](rotate-ssh-keys.md)

## Documentation

* Minimum resource requirements for cluster installation - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-minimum-resource-requirements_installing-bare-metal-network-customizations 
* DNS Requirements - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-dns-user-infra_installing-bare-metal-network-customizations
* Installing on Bare Metal - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index
* Configuring Firewall - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/installation_configuration/configuring-firewall#configuring-firewall_configuring-firewall
* Network Connectivity Requirements - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-network-connectivity-user-infra_installing-bare-metal
* Ensuring required ports are open - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#network-requirements-ensuring-required-ports-are-open_ipi-install-prerequisites
* Adding an additional trust bundle to the openshift install - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_an_on-premise_cluster_with_the_agent-based_installer/index#installing-ocp-agent-basic-inputs_installing-with-agent-basic
* Example: Bond and vlans setup - https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/installing_an_on-premise_cluster_with_the_agent-based_installer/preparing-to-install-with-agent-based-installer#agent-install-sample-config-bonds-vlans_preparing-to-install-with-agent-based-installer


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
  
The two main alternatives are:

systemd.unit=emergency.target

    How it works: This parameter tells the systemd process to boot directly into a minimal shell. It will try to mount the root filesystem as read-only and start only the most essential services required for an emergency shell. This is often the preferred method for general system troubleshooting.

    When to use it: This is a good choice for fixing issues that aren't related to the initial filesystem or the boot process itself, such as a corrupt /etc/fstab or a misconfigured service. It gives you a more complete environment than rd.break but still keeps things simple.

init=/bin/bash

    How it works: This is the most direct and basic method. It tells the kernel to bypass all the normal boot processes and execute /bin/bash directly as the first process (PID 1). This gives you a shell with no services, no network, and the root filesystem mounted as read-only.

    When to use it: Use this as a last resort when other methods fail. It's the most primitive and powerful method, as it gives you control before any other processes or services start. It's ideal for a corrupted boot process or severe filesystem issues where rd.break or emergency.target might fail to load. It also requires you to manually remount the root filesystem as read-write, just like you were doing with rd.break.

To use either of these, follow the same initial steps as with rd.break:

    At the GRUB boot menu, press the 'e' key to edit the boot command line.

Navigate to the line that starts with linux.

Append systemd.unit=emergency.target or init=/bin/bash to the end of the line.

Press Ctrl+X or F10 to boot with the modified parameters.