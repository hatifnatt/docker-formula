{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'recurse' in d.file and d.file.recurse %}
  {%- for id, recurse in d.file.recurse|dictsort %}
    {%- set ensure = recurse.pop('ensure', 'present') %}
    {%- set name = recurse.pop('name', '') if 'name' in recurse else id %}
    {#- Remove recurse if it supposed to be removed #}
    {%- if ensure in ('absent') %}
docker_file_recurse_absent_{{ id }}:
  file.absent:
    - name: {{ name }}

    {%- elif ensure in ('present') %}
docker_file_recurse_{{ id }}:
  file.recurse:
    - name: {{ name }}
    {{- format_kwargs(recurse) }}
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_file_recurse_notice:
  test.show_notification:
    - name: docker_file_recurse_notice
    - text: |
        No recurse directories are defined in pillars.

{%- endif %}
