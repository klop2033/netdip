[bastion]
%{ for ip in bastion_ips ~}
${ip}
%{ endfor ~}

[nginx_servers]
%{ for ip in nginx_ips1 ~}
${ip}
%{ endfor ~}
%{ for ip in nginx_ips2 ~}
${ip}
%{ endfor ~}

[nginx_server1]
%{ for ip in nginx_ips1 ~}
${ip}
%{ endfor ~}

[nginx_server2]
%{ for ip in nginx_ips2 ~}
${ip}
%{ endfor ~}

[zabbix_servers]
%{ for ip in zb_ips ~}
${ip}
%{ endfor ~}

[elastic_servers]
%{ for ip in lastik_ips ~}
${ip}
%{ endfor ~}

[kibana_servers]
%{ for ip in kibana_ips ~}
${ip}
%{ endfor ~}

[all:vars]
ansible_user=tet
ansible_ssh_private_key_file=~/.ssh/id_ed25519

[nginx_servers:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q tet@%{ for ip in bastion_ips ~}${ip}%{ endfor ~}"'

[nginx_server1:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q tet@%{ for ip in bastion_ips ~}${ip}%{ endfor ~}"'

[nginx_server2:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q tet@%{ for ip in bastion_ips ~}${ip}%{ endfor ~}"'

[zabbix_servers:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q tet@%{ for ip in bastion_ips ~}${ip}%{ endfor ~}"'

[elastic_servers:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q tet@%{ for ip in bastion_ips ~}${ip}%{ endfor ~}"'

[kibana_servers:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q tet@%{ for ip in bastion_ips ~}${ip}%{ endfor ~}"'