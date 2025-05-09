# ocp-agent-install-config-examples

# Create Bastion Host

* Download Red Hat Enterprise Linux 9.x Binary DVD from https://access.redhat.com/downloads/content/rhel
* Boot host from ISO and perform install as Server with GUI
* Make sure to enable SSH for user

## Register Bastion RHEL Box
```
sudo subscription-manager register
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

sudo dnf install -y nmstate
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

```shell
openshift-install agent wait-for bootstrap-complete --dir=install --log-level=debug
```

```shell
openshift-install agent wait-for install-complete --dir=install --log-level=debug
```

# Post Install

```shell
oc delete pods --all-namespaces --field-selector=status.phase=Succeeded
oc delete pods --all-namespaces --field-selector=status.phase=Failed
```