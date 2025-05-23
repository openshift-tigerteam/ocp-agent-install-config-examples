# ocp-agent-install-config-examples

# Create Bastion Host

* Download Red Hat Enterprise Linux 9.x Binary DVD from https://access.redhat.com/downloads/content/rhel
* Boot host from ISO and perform install as Server with GUI
* Make sure to enable SSH for user
* Reboot and SSH into bastion host as administrative user

> **Everything from here on out is done on the bastion host.**

## Register Bastion RHEL Box
```
sudo subscription-manager register # Enter username/password
sudo subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms
sudo subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms
sudo dnf update -y
```

# Download Tools Commands

```shell
wget -q -O openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz
tar -xvzf openshift-client-linux.tar.gz 
wget -q -O openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz
tar -xvzf openshift-install-linux.tar.gz 

sudo mv openshift-install /usr/local/bin/
sudo mv oc /usr/local/bin/
sudo chmod +x /usr/local/bin/openshift-install /usr/local/bin/oc

sudo dnf install -y nmstate git
```

# Install Commands

```shell
mkdir -p ocp && cd ocp
vi install-config.yaml 
vi agent-config.yaml
rm -rf install
mkdir install
cp install-config.yaml agent-config.yaml install
openshift-install agent create image --dir=install --log-level=debug
```

Copy the ISO to the storage where you can boot from. 
```
scp snimmo@192.168.122.187:/home/snimmo/ocp/install/agent.x86_64.iso ~/iso/
```

Boot hosts with created ISO

```shell
openshift-install agent wait-for bootstrap-complete --dir=install --log-level=debug
```

```shell
openshift-install agent wait-for install-complete --dir=install --log-level=debug
```

> You don't have to do the bootstrap-complete command at all, you can just run the install-complete...

# Post Install

```shell
oc delete pods --all-namespaces --field-selector=status.phase=Succeeded
oc delete pods --all-namespaces --field-selector=status.phase=Failed
```

## Install ODF

```shell
git clone https://github.com/openshift-tigerteam/ocp-agent-install-config-examples.git
oc apply -f ocp-agent-install-config-examples/postinstall/openshift-data-foundation.yaml
```

### Wiping Disks
```shell
ssh -i ~/.ssh/ocp core@10.3.0.11
sudo fdisk /dev/nvme0n1
g
w
```