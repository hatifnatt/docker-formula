{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'containers' in d and d.containers %}
  {%- set stopped_count = 0 %}
  {%- for id, container in d.containers|dictsort %}
    {%- set ensure = container.pop('ensure', '') %}
    {%- set name = container.pop('name', '') if 'name' in container else id %}
    {#- Stop container if it supposed to be stopped or removed #}
    {%- if ensure in ('stopped', 'absent') %}
      {%- set stopped_count =  stopped_count + 1 %}
docker_containers_stopped_{{ id }}:
  docker_container.stopped:
    - name: {{ name }}
    {{- format_kwargs(container) }}
    {%- endif %}

    {%- if loop.last and stopped_count == 0 %}
docker_containers_stopped_zero_count:
  test.show_notification:
    - name: docker_containers_stopped_zero_count
    - text: |
        Zero containers is required to be stopped
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_containers_stopped_notice:
  test.show_notification:
    - name: docker_containers_stopped_notice
    - text: |
        No containers defined in pillars.

{%- endif %}
