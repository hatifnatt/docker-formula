{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}

{% if d.server.package.get('pin', False)
      and 'version' in d.server and d.server.version and grains.os_family|lower == 'debian' %}
docker_server_software_package_pin:
  file.managed:
    - name: /etc/apt/preferences.d/docker
    - user: root
    - group: root
    - mode: 644
    - contents: |
        ## This file is managed by Salt, {{ tplroot }} formula, your changes will be overwritten
        Package: {{ d.server.package.get('pin_pkgs_prefix', 'docker-ce') }}*
        Pin: version {{ d.server.version }}
        Pin-Priority: 1001

{% elif not d.server.package.get('pin', False) %}
docker_server_software_package_pin_remove:
  file.absent:
    - name: /etc/apt/preferences.d/docker

{% elif grains.os_family|lower != 'debian' %}
docker_server_software_package_pin:
  test.show_notification:
    - name: Available on Debian family OS-es only
    - text: Apt pinning available only on Debian based distributives
{% endif %}
