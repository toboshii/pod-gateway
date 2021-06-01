# pod-gateway

This container includes scripts used to route traafic from pods through another gateway pod. Typically
the gateway pod then runs a openvpn client to forward the traffic.

The connection between the pods is done via a vxlan. The gatway provides a DHCP server to let client
pods to get automatically an IP.

Ougoing traffic is masqueraded (SNAT). It is also possible to define port forwardind so ports of client
pods can be reached from the outside.

The [.github](.github) folder will get PRs from this template so you can apply the latest workflows.

## Prereqs

You need to create the following secrets (not needed within the k8s-at-home org - there we use org-wide secrets):
- WORKFLOW_REPO_SYNC_TOKEN # Needed to do PRs that update the workflows
- GHCR_USERNAME # Needed to upload container to the Github Container Registry
- GHCR_TOKEN # Needed to upload container to the Github Container Registry

## How to build

1. Build the container
   ```bash
   make
   ```

Testing requires multiple containers - see
[Helm chart](https://github.com/k8s-at-home/charts/tree/master/charts/stable/pod-gateway-setter)
and check the [Makefile] for other build targets.


