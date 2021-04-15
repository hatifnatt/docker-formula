{#- Install docker server via static binaries
    https://docs.docker.com/engine/install/binaries/ #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if d.server.install %}
  {#- Install Docker server via binary method  #}
  {%- if d.server.use_upstream in ('binary') %}
include:
    {%- if 'pip' in d.server and d.server.pip %}
  - {{ tplroot }}.server.software.pip
    {%- endif %}
  - {{ tplroot }}.server.service

docker_server_software_binary_install:
  test.fail_without_changes:
    - name: docker_server_software_binary_install
    - comment: Binary installation is not implemented yet
    - require_in:
      - service: docker_server_service_running

  {#- Another installation method is selected #}
  {%- else %}
docker_server_software_binary_install_method:
  test.show_notification:
    - name: docker_server_software_binary_install_method
    - text: |
        Another installation method is selected. If you want to use binary
        installation method set 'docker:server:use_upstream' to 'binary'.
        Current value of 'docker:server:use_upstream': '{{ d.server.use_upstream }}'

  {%- endif %}

{#- Docker server is not selected for installation #}
{%- else %}
docker_server_software_binary_install_notice:
  test.show_notification:
    - name: docker_server_software_binary_install
    - text: |
        Docker server is not selected for installation, current value
        for 'docker:server:install': {{ d.server.install|string|lower }}, if you want to install Docker server
        you need to set it to 'true'.

{%- endif %}
