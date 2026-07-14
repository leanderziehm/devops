echo wordpress
ssh wordpress 'bash -s' < ./info.sh
echo database
ssh database 'bash -s' < ./info.sh
echo observe
ssh observe 'bash -s' < ./info.sh
echo java
ssh java 'bash -s' < ./info.sh