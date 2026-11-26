
# Cloudinit

```
cloud-init status --long
sudo vi /var/log/cloud-init-output.log
sudo vi /var/log/cloud-init.log

cd /var/lib/cloud/
```

todo implement:
---
#cloud-config
users:
  - default

groups:
  - admingroup: [root,sys]
  - cloud-users

 'lock_passwd', 'sudo', 'ssh_authorized_keys', 'ssh_redirect_user'

system user:  system: true
ssh redirect user: ssh_redirect_user
custom home directory: homedir: /local/testdir
sudo config:  sudo: ["ALL=(ALL) NOPASSWD:ALL"]

run commands:

generate root password hash:
```
openssl passwd -6 'root'
```

 - path: /home/admin/write_files.txt
   owner: admin:admin
   permissions: '0644'
   defer: true
   content: |
     hello this is me and here is some conent XD


write_files:
  - path: /var/www/html/index.html
    content: |
      <h1>Provisioned via cloud-init smile...</h1>

----


# check if cloud init is valid
```
sudo cloud-init schema --config-file user-data --annotate
```

# check if yml is valid
```
python3 -c 'import yaml, sys; yaml.safe_load(open(sys.argv[1]))' ./meta-data
python3 -c 'import yaml, sys; f=sys.argv[1]; content=open(f).read(); yaml.safe_load(content); print(f"ALL GOOD: {f} is valid:\n{content}")' ./meta-data
```
```
ruby -ryaml -e "YAML.load_file('meta-data')"
ruby -ryaml -e "f='meta-data'; YAML.safe_load_file(f); puts \"ALL GOOD: #{f} is valid:\n#{File.read(f)}\""
```


