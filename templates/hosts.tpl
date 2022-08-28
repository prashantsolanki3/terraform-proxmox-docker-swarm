[docker_workers]
%{ for ip in docker_workers ~}
${ip}
%{ endfor ~}

[docker_managers]
%{ for ip in docker_managers ~}
${ip}
%{ endfor ~}