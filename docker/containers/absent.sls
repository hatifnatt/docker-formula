{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

include:
  - .stopped

{%- if 'containers' in d and d.containers %}
  {%- set absent_count = 0 %}
  {%- for id, container in d.containers|dictsort %}
    {%- set ensure = container.pop('ensure', '') %}
    {%- set name = container.pop('name', '') if 'name' in container else id %}
    {%- if ensure == 'absent' %}
      {%- set absent_count =  absent_count + 1 %}
docker_containers_absent_{{ id }}:
  docker_container.absent:
    - name: {{ name }}
    - require:
      - sls: {{ tplroot }}.containers.stopped
    {%- endif %}

    {%- if absent_count == 0 %}
docker_containers_absent_zero_count:
  test.show_notification:
    - name: docker_containers_absent_zero_count
    - text: |
        Zero containers is required to be absent
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_containers_absent_notice:
  test.show_notification:
    - name: docker_containers_absent_notice
    - text: |
        No containers defined in pillars.

{%- endif %}
