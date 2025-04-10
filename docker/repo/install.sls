{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if d.server.install %}
  {#- If docker:server:use_upstream is 'repo' or 'package' official repo will be configured #}
  {%- if d.server.use_upstream in ('repo', 'package') %}

    {#- Install prerequisite packages if defined #}
    {%- if d.repo.prerequisites %}
docker_repo_install_prerequisites:
  pkg.installed:
    - pkgs: {{ d.repo.prerequisites|tojson }}
    {%- endif %}

    {#- Install keyring if provided, for Debian based systems only #}
    {%- if 'keyring' in d.repo.config and d.repo.config.keyring %}
docker_repo_install_keyring:
  file.managed:
    - name: /etc/apt/keyrings/docker.asc
    - source: {{ d.repo.config.pop('keyring') }}
      {%- if 'keyring_source_hash' in d.repo.config and d.repo.config.keyring_source_hash %}
    - source_hash: {{ d.repo.config.pop('keyring_source_hash') }}
    - skip_verify: false
      {%- else %}
    - skip_verify: true
      {%- endif %}
    {%- endif %}

docker_repo_install:
  pkgrepo.managed:
    {{- format_kwargs(d.repo.config) }}
    {%- if 'keyring' in d.repo.config and d.repo.config.keyring %}
    - require:
      - file: docker_repo_install_keyring
    {%- endif %}

  {#- Another installation method is selected, official repo configuration is not required #}
  {%- else %}
docker_repo_install_method:
  test.show_notification:
    - name: docker_repo_install_method
    - text: |
        Another installation method is selected. Repo configuration is not required.
        If you want to configure repository set 'docker:server:use_upstream' to 'repo' or 'package'.
        Current value of docker:server:use_upstream: '{{ d.server.use_upstream }}'
  {%- endif %}

{#- docker server is not selected for installation #}
{%- else %}
docker_repo_install_notice:
  test.show_notification:
    - name: docker_repo_install
    - text: |
        Docker Engine (server) is not selected for installation, current value
        for 'docker:server:install': {{ d.server.install|string|lower }}, if you want to install docker
        you need to set it to 'true'.

{%- endif %}
