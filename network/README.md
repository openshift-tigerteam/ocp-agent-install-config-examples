# OpenShift Networking with NMState

You start with NodeNetworkConfigurationPolicy (NNCP) to create the types:  

* [ethernet](https://nmstate.io/examples.html#interfaces-ethernet)
* [bond](https://nmstate.io/examples.html#interfaces-bond)
* [vlan](https://nmstate.io/examples.html#interfaces-vlan)

Once those are setup and validated, you can then create: 

* [ovs-bridge](https://nmstate.io/examples.html#interfaces-ovs-bridge)
* [ovn:bridge-mappings](https://docs.rs/nmstate/latest/nmstate/struct.OvnConfiguration.html)

After that, you move out of NNCP and create a ClusterUserDefinedNetwork (CUDN):

* [cudn](https://ovn-kubernetes.io/api-reference/userdefinednetwork-api-spec/#clusteruserdefinednetwork)

## Docs

[nmstate] (https://docs.rs/nmstate/latest/nmstate/index.html)