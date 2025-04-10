{#- Install docker-compose from official binary
    https://docs.docker.com/compose/install/ #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if d.compose.install %}
  {#- Install docker-compose via binary method  #}
  {%- if d.compose.install_method in ('binary') %}
include:
  - {{ tplroot }}.compose.shell_completion

    {%- set dc_versioned_bin = salt['file.join'](d.compose.version_dir,
                                                'docker-compose-' ~ d.compose.version) %}
    {#- Platform and version specific source binary and hash file names #}
    {%- set dc_bin = 'docker-compose-' ~ grains.kernel ~ '-' ~ grains.cpuarch %}
    {%- set dc_hash = 'docker-compose-' ~ grains.kernel ~ '-' ~ grains.cpuarch ~ '.sha256' %}
    {#- Full uri of compose binary and hash file #}
    {%- set dc_source = salt['file.join'](d.compose.binary.download_remote, d.compose.version, dc_bin) %}
    {%- set dc_source_hash = salt['file.join'](d.compose.binary.download_remote, d.compose.version, dc_hash) %}

docker_compose_software_binary_install_version_dir:
  file.directory:
    - name: {{ d.compose.version_dir }}
    - makedirs: true

docker_compose_software_binary_install:
  file.managed:
    - name: {{ dc_versioned_bin }}
    - source: {{ d.compose.binary.source if d.compose.binary.source else dc_source }}
    {%- if dc_source_hash or ('source_hash' in d.compose.binary and d.compose.binary.source_hash) %}
    - source_hash: {{ d.compose.binary.source_hash if d.compose.binary.source_hash else dc_source_hash }}
    {%- else %}
    - skip_verify: true
    {%- endif %}
    - show_changes: false
    - mode: '0755'
    - makedirs: true
    - require:
      - file: docker_compose_software_binary_install_version_dir

{#- Create symlink into system bin dir #}
docker_compose_software_binary_install_symlink:
  file.symlink:
    - name: {{ d.compose.bin }}
    - target: {{ dc_versioned_bin }}
    - force: true
    - require:
      - file: docker_compose_software_binary_install

  {#- Another installation method is selected #}
  {%- else %}
docker_compose_software_binary_install_method:
  test.show_notification:
    - name: docker_compose_software_binary_install_method
    - text: |
        Another installation method is selected. If you want to use binary
        installation method set 'docker:compose:install_method' to 'binary'.
        Current value of 'docker:compose:install_method': '{{ d.compose.install_method }}'

  {%- endif %}

{%- else %}
docker_compose_software_binary_install_notice:
  test.show_notification:
    - name: docker_compose_software_binary_install_notice
    - text: |
        docker-compose not selected for installation, current value
        for 'docker:compose:install': {{ d.compose.install|string|lower }},
        if you want to install LEGACY docker-compose v1 you need to set it to 'true'.

{%- endif %}
