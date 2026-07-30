# Inception of Things

A hands-on introduction to Kubernetes built in four progressively richer parts.
Every stage runs on a self-provisioned virtual machine and can be brought up
with a single `vagrant up`, so the whole stack — from a bare Ubuntu box to a
GitOps pipeline backed by a locally hosted GitLab — is reproducible from
scratch.

The project follows the [`Inception-of-Things`](https://cdn.intra.42.fr/pdf/pdf/145333/en.subject.pdf)
subject; the folder layout (`p1`, `p2`, `p3`, `bonus`) is dictated by the
subject itself.

## What you will find here

| Folder | Stack | Purpose |
|---|---|---|
| `p1/` | K3s + Vagrant, 2 VMs | Two-node K3s cluster: one control-plane, one agent. Warm-up with the basics of provisioning and cluster join. |
| `p2/` | K3s + Traefik Ingress | Single-node cluster running three demo apps behind a host-based Ingress (`app1.com`, `app2.com`, default fallback). Illustrates Deployments, ReplicaSets, Services and Ingress. |
| `p3/` | k3d + Argo CD, GitOps | Kubernetes now runs inside Docker via k3d. Argo CD watches this GitHub repository and rolls out the `wil42/playground` application into the `dev` namespace. Bumping the image tag on Git triggers an automatic rollout. |
| `bonus/` | k3d + Argo CD + local GitLab (Helm) | Replaces GitHub with a self-hosted GitLab installed via its official Helm chart. On first boot the script imports this repository into GitLab, and Argo CD is reconfigured to sync from that local mirror. |
| `manifests/` | Shared Kubernetes manifests | Application manifests read by Argo CD in both `p3` and `bonus`. Single source of truth, no duplication. |

## Concepts covered

- **Vagrant** for reproducible VM provisioning
- **K3s** vs **k3d**: two lightweight Kubernetes distributions, one running on
  the host OS, one inside Docker containers
- **Traefik Ingress** and host-based routing
- **Deployments, Services, Replicas, Namespaces**
- **Helm** with a custom `values.yaml` to install and slim down a heavy
  upstream chart (GitLab)
- **GitOps with Argo CD**: declarative desired state stored in Git,
  automatic sync and self-heal
- **Local GitLab** as an in-cluster Git server, populated on install by
  importing an upstream repository through the GitLab API

## How to run each part

Each folder is self-contained and boots the exact stack described above.

```bash
# Part 1
cd p1 && vagrant up

# Part 2
cd p2 && vagrant up

# Part 3
cd p3 && vagrant up

# Bonus (heavier: expect 20–30 minutes on the first boot)
cd bonus && vagrant up
```

Requirements on the host:

- Vagrant 2.4+
- A virtualization provider (VirtualBox 7+ recommended)
- ~10 GB of free disk space for images and boxes
- 8 GB of free RAM for the bonus

## Repository layout

```
.
├── manifests/          # Kubernetes manifests read by Argo CD (p3 + bonus)
├── p1/                 # K3s + Vagrant (2 VMs)
├── p2/                 # K3s + Ingress (1 VM, 3 apps)
├── p3/                 # k3d + Argo CD (GitOps from GitHub)
└── bonus/              # k3d + Argo CD + local GitLab (GitOps from GitLab)
```

Inside each `pN` / `bonus` folder:

```
Vagrantfile             # VM definition
scripts/                # Provisioning scripts (install tools, set up cluster)
confs/                  # Kubernetes / Helm configuration applied on the VM
```

## Reproducibility

Every external download and container image is pinned to a specific version,
so a `vagrant up` today and one in six months produce the same stack:

- Vagrant box (`bento/ubuntu-24.04`)
- K3s, k3d, kubectl, Helm, Argo CD manifests
- GitLab Helm chart
- Application container images (`wil42/playground`, `traefik/whoami`)

To bump a component, edit the version string in the corresponding script or
manifest — there is no floating `latest` or `stable` tag anywhere in the
repository.

## Notes on the local environment

- On Apple Silicon hosts the VMs are ARM64 while the `wil42/playground` image
  is x86_64. The provisioner installs `qemu-user-static` and `binfmt-support`
  so the amd64 binaries run transparently under emulation. On x86_64 hosts
  those packages are installed but do nothing, keeping the setup portable.
- The GitLab chart is installed with a minimal `values.yaml` that disables
  the components not needed for this lab (registry, prometheus, runner,
  cert-manager, nginx-ingress). GitLab is reached only through the internal
  cluster DNS.
