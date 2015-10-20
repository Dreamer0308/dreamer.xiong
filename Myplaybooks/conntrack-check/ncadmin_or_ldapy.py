#!/usr/bin/env python
#coding=utf-8

import commands
import re

def host_ldap():
    count = 0
    origin = open("/home/dreamer.xiong/conntrack-check/conntrack.hosts", "r")
    servers = origin.readlines()
    server_list = servers
    ldap_res = open("server_ldap", "w")
    nc_res = open("server_nc", "w")
    config_str = commands.getoutput("""cat /etc/ssh/ssh_config |grep -v ^$| sed 's/^ *//g' | grep -v ^#""")
    for hostname in server_list:
        if hostname != "":
            if hostname.endswith("\n"):
                hostname = hostname.split()[0]
                m = re.search(r'host\s+' + hostname + r'.*\nhostname\s+(?P<IP>\d+.\d+.\d+.\d+)+.*\nport\s+(?P<PORT>.*)', config_str)
                if m:
                    IP = m.group(1)
                    PORT = m.group(2).strip()
                    if len(PORT) == 5 and PORT.startswith("6"):
                        ldap_res.write(
                                  hostname +
                                  " ansible_ssh_host=" +
                                  IP +
                                  " ansible_ssh_port=" +
                                  PORT + "\n"
                            )
                        count = count + 1
                    else:
                        nc_res.write(
                                  hostname +
                                  " ansible_ssh_host=" +
                                  IP +
                                  " ansible_ssh_port=" +
                                  PORT + "\n"
                            )
                        #res.write(hostname +  "\tssh_port= " + PORT + "\n")
                else:
                    nc_res.write(hostname +  "\n")

    origin.close()
    ldap_res.close()
    nc_res.close()
    print count


if __name__ == "__main__":
    host_ldap()
