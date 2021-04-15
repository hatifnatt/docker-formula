{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'networks' in d and d.networks %}
  {%- for nid, net in d.networks|dictsort %}
    {%- set ensure = net.pop('ensure', 'present') %}
    {%- set name = net.pop('name', '') if 'name' in net else nid %}
docker_networks_manage_{{ nid }}_{{ ensure }}:
  docker_network:
    - name: {{ name }}
    {%- if ensure == 'absent' %}
    - absent
    {%- elif ensure == 'present' %}
    - present
    {{- format_kwargs(net) }}
    {%- endif %}
  {%- endfor %}

{%- else %}
docker_networks_notice:
  test.show_notification:
    - name: docker_networks_notice
    - text: |
        No networks defined in pillars.

{%- endif %}
