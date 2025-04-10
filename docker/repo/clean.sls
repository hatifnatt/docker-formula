{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}

{#- Remove any configured repo form the system #}
docker_repo_clean:
{%- if grains.os_family != 'Debian' %}
  pkgrepo.absent:
    - name: {{ d.repo.config.name | yaml_dquote }}
{%- else %}
{#- Due bug in pkgrepo.absent we need to manually remove repository '.list' files
    See https://github.com/saltstack/salt/issues/61602 #}
  file.absent:
    - name: {{ d.repo.config.file }}
{%- endif %}

{#- Remove keyring if present #}
{%- if 'keyring' in d.repo.config and d.repo.config.keyring %}
docker_repo_clean_keyring:
  file.absent:
    - name: /etc/apt/keyrings/docker.asc
{%- endif %}

