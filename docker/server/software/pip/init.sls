{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'pip' in d.server and d.server.pip %}
  {#- Since Salt 3006 onedir is a main installation variant for Salt and Salt onedir does have
      bundled pip so additional package in not required in this case #}
  {%- if 'package' in d.server.pip and d.server.pip.package %}
docker_server_software_pip:
  pkg.installed:
    - name: {{ d.server.pip.package }}
    - require_in:
      - pip: docker_server_software_pip_pkgs
{%- endif %}

  {#- By default if bin_env parameter is not set Salt onedir will use bundled pip and will install pip packages
      into Salt onedir venv, that's exactly what we need, in this formula we only using pip to install
      extra Python modules (packages) solely for Salt itself #}
docker_server_software_pip_pkgs:
  pip.installed:
    - pkgs: {{ d.server.pip.pkgs|tojson }}
    - reload_modules: true

{%- else %}
docker_server_software_pip_notice:
  test.show_notification:
    - name: docker_server_software_pip_notice
    - text: |
        'docker:server:pip' is not present or empty - no packages will be installed via pip

{%- endif %}
