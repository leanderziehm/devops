```
ENVIRONMENT=dev VM_NAME=alma-vm1 bash vms/update.sh
```


```
ENVIRONMENT=dev VM_NAME=alma-vm1 bash /opt/lz/devops/vms/update.sh
```


```
systemctl --user status example-api.service
systemctl --user status nginx.service

journalctl --user -u example-api.service -b
```