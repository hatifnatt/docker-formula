{#- Install docker server via official packages
    https://docs.docker.com/engine/install/#server #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if d.server.install %}
  {#- Install Docker server from official repository #}
  {%- if d.server.use_upstream in ('repo', 'package') %}
include:
  - {{ tplroot }}.repo
    {%- if 'pip' in d.server and d.server.pip %}
  - {{ tplroot }}.server.software.pip
    {%- endif %}
    {#- We have some configuration data, let's configure docker after installation #}
    {%- if d.server.config.data %}
  - {{ tplroot }}.server.config
    {%- endif %}
  - {{ tplroot }}.server.service

docker_server_software_package_install_extra:
  pkg.installed:
    - pkgs: {{ d.server.extra.pkgs|tojson }}

docker_server_software_package_install:
  pkg.installed:
    - pkgs: {{ d.server.package.pkgs|tojson }}
    - hold: {{ d.server.package.hold }}
    - update_holds: {{ d.server.package.update_holds }}
    - watch_in:
      - service: docker_server_service_running
    - require:
      - sls: {{ tplroot }}.repo
      - pkg: docker_server_software_package_install_extra
    {#- We have some configuration data, let's configure docker after installation #}
    {%- if d.server.config.data %}
    - require_in:
      - sls: {{ tplroot }}.server.config
    {%- endif %}

  {#- Another installation method is selected #}
  {%- else %}
docker_server_software_package_install_method:
  test.show_notification:
    - name: docker_server_software_package_install_method
    - text: |
        Another installation method is selected. If you want to use package
        installation method set 'docker:server:use_upstream' to 'repo' or 'package'.
        Current value of docker:server:use_upstream: '{{ d.server.use_upstream }}'
  {%- endif %}

{#- Docker server is not selected for installation #}
{%- else %}
docker_server_software_package_install_notice:
  test.show_notification:
    - name: docker_server_software_package_install
    - text: |
        Docker server is not selected for installation, current value
        for 'docker:server:install': {{ d.server.install|string|lower }}, if you want to install Docker server
        you need to set it to 'true'.

{%- endif %}
