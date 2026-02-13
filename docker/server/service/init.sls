{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}

{%- if grains.init == 'systemd' %}
docker_server_service_systemd_service_override:
  file.managed:
    - name: /etc/systemd/system/{{ d.server.service.name }}.service.d/salt.conf
    - source: salt://{{ tplroot }}/files/systemd/service_override.jinja
    - mode: 644
    - makedirs: true
    - template: jinja
    - context:
        args: {{ d.server.service.daemon_args }}
    - watch_in:
      - module: docker_server_service_reload_systemd

{#- Reload systemd after new unit file added, like `systemctl daemon-reload` #}
docker_server_service_reload_systemd:
  module.wait:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}

docker_server_service_socket:
  service:
    - name: {{ d.server.service.socket.name }}
    - {{ d.server.service.status }}
    - enable: {{ d.server.service.enable }}
    - require:
      - service: docker_server_service_running

# If docker.socket seems running but socket file is not present - restart docker.socket
# this happens after fresh installation of the official docker packages on Deb 12 and 13
docker_server_service_socket_restart:
  module.run:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.restart:
      - name: docker.socket
  {%- else %}
    - name: service.systemctl_reload
    - m_name: docker.socket
  {%- endif %}
    - unless:
      - 'test -S {{ d.server.service.socket.path }}'
    - require:
      - service: docker_server_service_running
      - service: docker_server_service_socket
{%- endif %}

docker_server_service_running:
  service:
    - name: {{ d.server.service.name }}
    - {{ d.server.service.status }}
    - enable: {{ d.server.service.enable }}
    {%- if d.server.service.status == 'running' %}
    - reload: {{ d.server.service.reload }}
    {%- endif %}
