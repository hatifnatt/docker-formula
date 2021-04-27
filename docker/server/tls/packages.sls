{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}

{#- Install packages required for self signed certificates only in case
    when data required for certificate issue is provided #}
{% if 'params' in d.server.tls.key and d.server.tls.key.params
      or 'params' in d.server.tls.cert and d.server.tls.cert.params -%}
docker_server_tls_packages_required:
  pkg.installed:
    - pkgs: {{ d.server.tls.pkgs|tojson }}

{% endif -%}
