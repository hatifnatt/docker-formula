{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if d.server.install %}
include:
  - {{ tplroot }}.server.service

docker_server_config:
  file.serialize:
    - name: {{ d.server.config.file }}
    - serializer: json
    - dataset: {{ d.server.config.data|tojson }}
    - makedirs: true
    - watch_in:
      - service: docker_server_service_running

{%- else %}
docker_server_config_notice:
  test.show_notification:
    - name: docker_server_config_notice
    - text: |
        Docker server is not selected for installation, current value
        for 'docker:server:install': {{ d.server.install|string|lower }}, if you want to install Docker server
        you need to set it to 'true'.
        Configuration file won't be installed / updated.

{%- endif %}
