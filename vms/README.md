
```
ENVIRONMENT=dev VM_NAME=alma-vm1 bash scripts/setup-devops.sh
```

```
ENVIRONMENT=dev VM_NAME=alma-vm1 bash setup.sh
```


```
ENVIRONMENT=dev VM_NAME=alma-vm1 bash /opt/lz/devops/vms/setup.sh
```


```
systemctl --user status example-api.service
systemctl --user status nginx.service

journalctl --user -u example-api.service -b
```