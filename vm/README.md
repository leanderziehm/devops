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