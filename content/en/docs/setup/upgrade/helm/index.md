---
title: Upgrade with Helm
linktitle: Upgrade with Helm
description: Upgrade and configure Istio for in-depth evaluation.
weight: 27
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: no
---

Follow this guide to upgrade and configure an Istio mesh using
[Helm](https://helm.sh/docs/).  This guide assumes you have already performed an
[installation with Helm](/docs/setup/install/helm) for a previous minor or patch version of Istio.

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-prereqs >}}

## Upgrade steps

Before upgrading Istio, it is recommended to run the `istioctl x precheck` command to make sure the upgrade is compatible with your environment.

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
To get started, check out https://istio.io/latest/docs/setup/getting-started/
{{< /text >}}

{{< warning >}}
[Helm does not upgrade or delete CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#some-caveats-and-explanations) when performing an upgrade. Because of this restriction, an additional step is required when upgrading Istio with Helm.
{{< /warning >}}

### Canary upgrade (recommended)

You can install a canary version of Istio control plane to validate that the new
version is compatible with your existing configuration and data plane using
the steps below:

{{< warning >}}
Note that when you install a canary version of the `istiod` service, the underlying
cluster-wide resources from the base chart are shared across your
primary and canary installations.
{{< /warning >}}

1. Upgrade the Kubernetes custom resource definitions ({{< gloss >}}CRDs{{</ gloss >}}):

    {{< text bash >}}
    $ kubectl apply -f manifests/charts/base/crds
    {{< /text >}}

1. Install a canary version of the Istio discovery chart by setting the revision
   value:

    {{< text bash >}}
    $ helm install istiod-canary istio/istiod \
        --set revision=canary \
        -n istio-system
    {{< /text >}}

1. Verify that you have two versions of `istiod` installed in your cluster:

    {{< text bash >}}
    $ kubectl get pods -l app=istiod -L istio.io/rev -n istio-system
      NAME                            READY   STATUS    RESTARTS   AGE   REV
      istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
      istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
    {{< /text >}}

1. Follow the steps [here](/docs/setup/upgrade/canary/) to test or migrate
   existing workloads to use the canary control plane.

1. Once you have verified and migrated your workloads to use the canary control
   plane, you can uninstall your old control plane:

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Upgrade the Istio base chart, making the new revision the default.

    {{< text bash >}}
    $ helm upgrade istio-base istio/base --defaultRevision canary -n istio-system --skip-crds
    {{< /text >}}

### Stable revision labels (experimental)

{{< boilerplate revision-tags-preamble >}}

#### Usage

{{< boilerplate revision-tags-usage >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags={prod-stable} --set revision=1-9-5 -n istio-system | kubectl apply -f -
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags={prod-canary} --set revision=1-10-0 -n istio-system | kubectl apply -f -
{{< /text >}}

{{< warning >}}
These commands create new `MutatingWebhookConfiguration` resources in your cluster, however, they are not owned by any Helm chart due to `kubectl` manually applying the templates. See the instructions
below to uninstall revision tags.
{{< /warning >}}

{{< boilerplate revision-tags-middle >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags={prod-stable} --set revision=1-10-0 -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-prologue >}}

#### Default tag

{{< boilerplate revision-tags-default-intro >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags={default} --set revision=1-10-0 -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-default-outro >}}

### In place upgrade

You can perform an in place upgrade of Istio in your cluster using the Helm
upgrade workflow.

{{< warning >}}
Add your override values file or custom options to the commands below to
preserve your custom configuration during Helm upgrades.
{{< /warning >}}

1. Upgrade the Kubernetes custom resource definitions ({{< gloss >}}CRDs{{</ gloss >}}):

    {{< text bash >}}
    $ kubectl apply -f manifests/charts/base/crds
    {{< /text >}}

1. Upgrade the Istio base chart:

    {{< text bash >}}
    $ helm upgrade istio-base manifests/charts/base -n istio-system --skip-crds
    {{< /text >}}

1. Upgrade the Istio discovery chart:

    {{< text bash >}}
    $ helm upgrade istiod istio/istiod -n istio-system
    {{< /text >}}

1. (Optional) Upgrade and gateway charts  installed in your cluster:

    {{< text bash >}}
    $ helm upgrade istio-ingress istio/gateway -n istio-ingress
    {{< /text >}}

## Uninstall

Please refer to the uninstall section in our [Helm install guide](/docs/setup/install/helm/#uninstall).