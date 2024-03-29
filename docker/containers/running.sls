{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

include:
  {#- docker.volumes.manage includes all docker.file.* states
      so they will be rendered before `docker_container.running` states #}
  - {{ tplroot }}.volumes.manage
  - {{ tplroot }}.networks.manage
  {#- Explicitly include states, due bug https://github.com/saltstack/salt/issues/10852 #}
  - {{ tplroot }}.images.absent
  - {{ tplroot }}.images.present

{%- if 'containers' in d and d.containers %}
  {%- set running_count = 0 %}
  {%- for id, container in d.containers|dictsort %}
    {%- set ensure = container.pop('ensure', 'running') %}
    {%- set name = container.pop('name', '') if 'name' in container else id %}
    {%- if ensure == 'running' %}
      {%- set running_count =  running_count + 1 %}
docker_containers_running_{{ id }}:
  docker_container.running:
    - name: {{ name }}
    {{- format_kwargs(container) }}
    - require:
      - sls: {{ tplroot }}.volumes.manage
      - sls: {{ tplroot }}.networks.manage
      - sls: {{ tplroot }}.images.absent
      - sls: {{ tplroot }}.images.present
    {%- endif %}

    {%- if loop.last and running_count == 0 %}
docker_containers_running_zero_count:
  test.show_notification:
    - name: docker_containers_running_zero_count
    - text: |
        Zero containers is required to be running
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_containers_running_notice:
  test.show_notification:
    - name: docker_containers_running_notice
    - text: |
        No containers defined in pillars.

{%- endif %}
