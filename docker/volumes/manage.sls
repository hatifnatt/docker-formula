{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'volumes' in d and d.volumes %}
  {%- for vid, vol in d.volumes|dictsort %}
    {%- set ensure = vol.pop('ensure', 'present') %}
    {%- set name = vol.pop('name', '') if 'name' in vol else vid %}
docker_volumes_manage_{{ vid }}_{{ ensure }}:
  docker_volume:
    - name: {{ name }}
    {%- if ensure == 'absent' %}
    - absent
    {%- elif ensure == 'present' %}
    - present
    {{- format_kwargs(vol) }}
    {%- endif %}
  {%- endfor %}

{%- else %}
docker_volumes_notice:
  test.show_notification:
    - name: docker_volumes_notice
    - text: |
        No volumes defined in pillars.

{%- endif %}
