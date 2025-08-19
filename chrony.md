# ntp server setup

```
server 10.1.0.1 iburst
server 10.2.0.1 iburst
server 10.3.0.1 iburst
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
```

to encode
```
cat chrony.conf | base64 -w0
```

to decode
```
echo "c2VydmVyIDEwLjEuMC4xIGlidXJzdApzZXJ2ZXIgMTAuMi4wLjEgaWJ1cnN0CnNlcnZlciAxMC4zLjAuMSBpYnVyc3QKZHJpZnRmaWxlIC92YXIvbGliL2Nocm9ueS9kcmlmdApydGNzeW5jCm1ha2VzdGVwIDEwIDMK" | base64 --decode
```

```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-ntp-servers
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
        - contents:
            source: data:text/plain;charset=utf-8;base64,c2VydmVyIDEwLjEuMC4xIGlidXJzdApzZXJ2ZXIgMTAuMi4wLjEgaWJ1cnN0CnNlcnZlciAxMC4zLjAuMSBpYnVyc3QKZHJpZnRmaWxlIC92YXIvbGliL2Nocm9ueS9kcmlmdApydGNzeW5jCm1ha2VzdGVwIDEwIDM=
          mode: 0644
          overwrite: true
          path: /etc/chrony.conf
---
# This MachineConfig updates the chrony.conf file for all worker nodes.
# It uses the same NTP servers as the masters to ensure consistent time.
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-ntp-servers
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
        - contents:
            source: data:text/plain;charset=utf-8;base64,c2VydmVyIDEwLjEuMC4xIGlidXJzdApzZXJ2ZXIgMTAuMi4wLjEgaWJ1cnN0CnNlcnZlciAxMC4zLjAuMSBpYnVyc3QKZHJpZnRmaWxlIC92YXIvbGliL2Nocm9ueS9kcmlmdApydGNzeW5jCm1ha2VzdGVwIDEwIDM=
          mode: 0644
          overwrite: true
          path: /etc/chrony.conf