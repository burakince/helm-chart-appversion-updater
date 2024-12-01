# Helm Chart AppVersion Updater

Helm Chart AppVersion and Chart version updater DroneCI Plugin

## Environment Variables

| Env Variable      | Description        | Required | Default |
| ----------------- | ------------------ | -------- | ------- |
| PLUGIN_SSH_URL    | Repository SSH URL | Yes      |         |
| PLUGIN_SSH_KEY    | SSH Private Key    | Yes      |         |
| PLUGIN_NAME       | Git user name      | Yes      |         |
| PLUGIN_EMAIL      | Git user email     | Yes      |         |
| PLUGIN_IMAGE_TAG  | New image tag      | Yes      |         |
| PLUGIN_CHART_PATH | Helm Chart path    | Yes      |         |
| PLUGIN_DEBUG      | Enable debug mode  | No       | false   |

## Image Usage

```
docker run \
  -e PLUGIN_SSH_URL="git@gitea-ssh.gitea.svc.cluster.local:myuser/my-argocd-tracked-helm-chart-repo" \
  -e PLUGIN_SSH_KEY="myPrivateSshKey"
  -e PLUGIN_NAME="myname surname" \
  -e PLUGIN_EMAIL="myemail@mydomain.com" \
  -e PLUGIN_IMAGE_TAG="a1b2c3d4" \
  -e PLUGIN_CHART_PATH="charts/mychart" \
  --rm -it burakince/helm-chart-appversion-updater
```

## [Drone CI](https://www.drone.io/) or [Woodpecker CI](https://woodpecker-ci.org/) Plugin Usage

```
kind: pipeline
name: default

steps:
  - name: update-chart-appversion
    image: burakince/helm-chart-appversion-updater:1.0.0
    pull: if-not-exists
    settings:
      ssh_url: "git@gitea-ssh.gitea.svc.cluster.local:myuser/my-argocd-tracked-helm-chart-repo"
      ssh_key:
        from_secret: ssh_key
      name: "myname surname"
      email: "myemail@mydomain.com"
      image_tag: "${DRONE_COMMIT:0:7}"
      chart_path: "charts/mychart"
```
