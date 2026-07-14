echo wordpress
ssh wordpress 'bash -s' < ../telemetry/info.sh
echo database
ssh database 'bash -s' < ../telemetry/info.sh
echo observe
ssh observe 'bash -s' < ../telemetry/info.sh
echo java
ssh java 'bash -s' < ../telemetry/info.sh