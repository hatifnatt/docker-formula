{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'pip' in d.server and d.server.pip %}
docker_server_software_pip:
  pkg.installed:
    - name: {{ d.server.pip.package }}

docker_server_software_pip_pkgs:
  pip.installed:
    - pkgs: {{ d.server.pip.pkgs|tojson }}
    - require:
      - pkg: docker_server_software_pip

{%- else %}
docker_server_software_pip_notice:
  test.show_notification:
    - name: docker_server_software_pip_notice
    - text: |
        'docker:server:pip' is not present or empty - no packages will be installed via pip

{%- endif %}
