#!/bin/bash
password='***************'
#bash test.sh test.host|grep 'running\|clean\|^\[2015\|^srv' |grep -v 'erwen.tian'
for i in $(cat $1)
do
	/usr/bin/expect <<-EOF
	set timeout 3
	spawn /usr/bin/ssh -t ncadmin@$i
	expect {
	"*yes/no" { send "yes\r"; exp_continue}
	"*assword:" { send "$password\r" }
	}
	expect "*#"
	send "hostname\r"
	send " ps aux | grep aegis && echo 'aegis is running'|| echo 'aegis Not running'\r"
	send "sudo cat /usr/local/aegis/aegis_client/aegis_00_79/data/data.2 |grep root|grep -i clean || echo 'No need to clean'\r"
	expect eof
	interact
	EOF
	echo -e '\n'

done
