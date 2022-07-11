{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'directory' in d.file and d.file.directory %}
  {%- for id, directory in d.file.directory|dictsort %}
    {%- set ensure = directory.pop('ensure', 'present') %}
    {%- set name = directory.pop('name', '') if 'name' in directory else id %}
    {#- Remove directory if it's marked for removal #}
    {%- if ensure in ('absent') %}
docker_file_directory_absent_{{ id }}:
  file.absent:
    - name: {{ name }}

    {%- elif ensure in ('present') %}
docker_file_directory_{{ id }}:
  file.directory:
    - name: {{ name }}
    {{- format_kwargs(directory) }}
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_file_directory_notice:
  test.show_notification:
    - name: docker_file_directory_notice
    - text: |
        No directories to manage are defined in pillars.

{%- endif %}
