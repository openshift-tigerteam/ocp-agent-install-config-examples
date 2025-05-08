# ocp-agent-install-config-examples

# Download Tools Commands

```
wget -q -O openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz
tar -xvzf openshift-client-linux.tar.gz 
wget -q -O openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz
tar -xvzf openshift-install-linux.tar.gz 

sudo mv openshift-install /usr/local/bin/
sudo mv oc /usr/local/bin/
sudo chmod +x /usr/local/bin/openshift-install /usr/local/bin/oc
```

# Install Commands

```
rm -rf install
mkdir install
cp agent-config.yaml install-config.yaml install
openshift-install agent create image --dir=install --log-level=debug
```

```
openshift-install agent wait-for bootstrap-complete --dir=install --log-level=debug
openshift-install agent wait-for install-complete --dir=install --log-level=debug
```

## Post Install

``` bash
oc delete pods --all-namespaces --field-selector=status.phase=Succeeded
oc delete pods --all-namespaces --field-selector=status.phase=Failed
```