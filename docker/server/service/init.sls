{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

docker_server_service_running:
  service:
    - name: {{ d.server.service.name }}
    - {{ d.server.service.status }}
    - enable: {{ d.server.service.enable }}
    {%- if d.server.service.status == 'running' %}
    - reload: {{ d.server.service.reload }}
    {%- endif %}
