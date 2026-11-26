```
podman kube down vm/containers/adguard/deployment.yaml
podman volume rm adguard-conf-pvc
podman kube play vm/containers/adguard/deployment.yaml

```
















```
ENVIRONMENT=dev VM_NAME=alma-vm1 bash vm/update.sh
```


```
ENVIRONMENT=dev VM_NAME=alma-vm1 bash /opt/lz/devops/vm/update.sh
```


```
systemctl --user status example-api.service
systemctl --user status nginx.service

journalctl --user -u example-api.service -b
```