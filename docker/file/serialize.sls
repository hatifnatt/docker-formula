{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{#- Install packages required for serializer to work if provided #}
{%- if 'serialize_packages' in d.file and d.file.serialize_packages %}
docker_file_serialize_packages:
  pkg.installed:
    - pkgs: {{ d.file.serialize_packages | tojson }}

{%- endif %}

{%- if 'serialize_packages_pip' in d.file and d.file.serialize_packages_pip %}
  {#- By default if bin_env parameter is not set Salt onedir will use bundled pip and will install pip packages
      into Salt onedir venv, that's exactly what we need, in this formula we only using pip to install
      extra Python modules (packages) solely for Salt itself #}
docker_file_serialize_packages_pip:
  pip.installed:
    - pkgs: {{ d.file.serialize_packages_pip | tojson }}
    - reload_modules: true

{%- endif %}

{%- if 'serialize' in d.file and d.file.serialize %}
  {%- for id, serialize in d.file.serialize|dictsort %}
    {%- set ensure = serialize.pop('ensure', 'present') %}
    {%- set name = serialize.pop('name', '') if 'name' in serialize else id %}
    {#- Remove file if it's marked for removal #}
    {%- if ensure in ('absent') %}
docker_file_serialize_absent_{{ id }}:
  file.absent:
    - name: {{ name }}

    {%- elif ensure in ('present') %}
docker_file_serialize_{{ id }}:
  file.serialize:
    - name: {{ name }}
    {{- format_kwargs(serialize) }}
      {%- if 'serialize_packages' in d.file and d.file.serialize_packages
              or 'serialize_packages_pip' in d.file and d.file.serialize_packages_pip %}
    - require:
      - pkg: docker_file_serialize_packages*
      {%- endif %}

    {%- endif %}

  {%- endfor %}

{%- else %}
docker_file_serialize_notice:
  test.show_notification:
    - name: docker_file_serialize_notice
    - text: |
        No files to serialize are defined in pillars.

{%- endif %}
