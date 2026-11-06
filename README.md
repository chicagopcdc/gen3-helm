
# gen3-helm
<img src="docs/images/gen3-blue-dark.png" width=250px>


Helm charts for deploying [Gen3](https://gen3.org) on any kubernetes cluster.

# Deploying gen3 with helm

## TL;DR
```
helm repo add gen3 https://helm.gen3.org
helm repo update
helm upgrade --install gen3 gen3/gen3 -f ./values.yaml
```

For more information on how to deploy Gen3 with helm, please see the [Gen3 Example Deployment Guide](https://docs.gen3.org/gen3-resources/operator-guide/helm/)

https://docs.gen3.org


## Configuration

For a full set of configuration options see the [CONFIGURATION.md](./docs/CONFIGURATION.md) for a more in depth instructions on how to configure each service.

There's also an auto-generated table of basic configuration options here:

[README.md for gen3 chart](./helm/gen3/README.md) (auto-generated documentation) or


To see documentation around setting up gen3 developer environments see [our Example Deployment](https://docs.gen3.org/gen3-resources/operator-guide/helm/helm-deploy-example/).


Use the following as a template for your `values.yaml` file for a minimum deployment of gen3 using these helm charts.



```yaml
global:
  hostname: example-commons.com

fence:
  FENCE_CONFIG:
    # Any fence-config overrides here.
```


## Gen3 Login Options
Gen3 does not have any IDP, but can integrate with many. We will cover Google login here, but refer to the fence documentation for additional options.

TL/DR: At minimum to have google logins working you need to set these settings in your `values.yaml` file

```
fence:
  FENCE_CONFIG:
    OPENID_CONNECT:
      google:
        client_id: "insert.google.client_id.here"
        client_secret: "insert.google.client_secret.here"
```


#### Google login generation

You need to set up a google credential for google login as that's the default enabled option in fence.


The following steps explain how to create credentials for your gen3

Go to the [Credentials page](https://console.developers.google.com/apis/credentials).

Click Create credentials > OAuth client ID.

Select the Web application application type.
Name your OAuth 2.0 client and click Create.

For `Authorized Javascript Origins` add `https://<hostname>`

For `"Authorized redirect URIs"` add  `https://<hostname>/user/login/google/login/`

After configuration is complete, take note of the client ID that was created. You will need the client ID and client secret to complete the next steps.


# Troubleshooting

## Sanity checks

* If deploying from the local repo, make sure you followed the steps for `helm dependency update`. If you make any changes, this must be repeated for those changes to propagate.

* Make sure `kubectl` and `helm` are pointed at the right cluster. Both use your current kubeconfig context, so if you were last working against OpenShift you will see errors like `dial tcp: lookup api.bsd-openshift-prod.bsd.uchicago.edu: no such host` (that host only resolves on the campus network/VPN).

### Switching to a local Kubernetes cluster for local dev

```
# list available contexts and see which one is active (marked with *)
kubectl config get-contexts

# switch to your local cluster (use the name shown above)
kubectl config use-context docker-desktop    # Docker Desktop
kubectl config use-context minikube          # minikube
kubectl config use-context kind-kind         # kind
kubectl config use-context rancher-desktop   # Rancher Desktop

# verify
kubectl config current-context
kubectl get nodes
```

If no local context is listed, start/enable a local cluster first:
* Docker Desktop: Settings > Kubernetes > Enable Kubernetes
* minikube: `minikube start`
* kind: `kind create cluster`

You can also target a cluster for a single command without switching: `helm upgrade --install gen3 ./helm/gen3 -f ./values.yaml --kube-context docker-desktop`

Use your local values file for local dev, not an OpenShift-specific one (e.g. `secret-values.yaml.openshift`). OpenShift-specific settings such as security contexts, routes, and storage classes may not work locally.

To go back to OpenShift, connect to the VPN and run `kubectl config use-context <openshift-context>` (or `oc login`).

## Debugging helm chart issues

* Sometimes there are cryptic errors that occur during use of the helm chart, such as duplicate env vars or other items. Try rendering the resources to a file, in debug mode, and it will help determine where the issues may be taking place

`helm template --debug gen3 ./helm/gen3 -f ./values.yaml > test.yaml`

## Other useful commands

In any folder containing a `Chart.yaml`:
```
helm lint .
```

Install a chart locally for testing:
```
helm install my-release-name . --namespace mynamespace --create-namespace
```

helm upgrade my-release-name . -n mynamespace

helm uninstall my-release-name -n mynamespace


OR just

Install, upgrade, remove a chart locally for testing:
```
helm install my-release-name . 

helm upgrade my-release-name . 

helm uninstall my-release-name 
```

