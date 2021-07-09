{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if d.repo.prerequisites and d.server.use_upstream in ('repo', 'package') %}
docker_repo_prerequisites:
  pkg.installed:
    - pkgs: {{ d.repo.prerequisites|tojson }}
    - require_in:
      - pkgrepo: docker_repo
{%- endif %}

{#- If docker:server:use_upstream is 'repo' or 'package' official repo
    will be configured in other cases repo will be removed from the system #}
docker_repo:
  pkgrepo:
{%- if d.server.use_upstream in ('repo', 'package') %}
    - managed
    {{- format_kwargs(d.repo.config) }}
{%- else %}
    - absent
    - name: {{ d.repo.config.name }}
{%- endif %}
