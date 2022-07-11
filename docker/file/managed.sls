{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'managed' in d.file and d.file.managed %}
  {%- for id, managed in d.file.managed|dictsort %}
    {%- set ensure = managed.pop('ensure', 'present') %}
    {%- set name = managed.pop('name', '') if 'name' in managed else id %}
    {#- Remove file if it's marked for removal #}
    {%- if ensure in ('absent') %}
docker_file_managed_absent_{{ id }}:
  file.absent:
    - name: {{ name }}

    {%- elif ensure in ('present') %}
docker_file_managed_{{ id }}:
  file.managed:
    - name: {{ name }}
    {{- format_kwargs(managed) }}
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_file_managed_notice:
  test.show_notification:
    - name: docker_file_managed_notice
    - text: |
        No files to manage are defined in pillars.

{%- endif %}
