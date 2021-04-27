{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs, build_source %}

{#- Manage certificates if apropriate options are present in daemon configuration #}
{%- if 'tls' in d.server.config.data and d.server.config.data.tls
        or 'tlsverify' in d.server.config.data and d.server.config.data.tlsverify %}

  {#- 'tlsverify' would not work without 'tlscacert' parameter - show info #}
  {%- if 'tlsverify' in d.server.config.data and d.server.config.data.tlsverify
          and ('tlscacert' not in d.server.config.data
              or ('tlscacert' in d.server.config.data and d.server.config.data.tlscacert|length == 0)) %}
docker_server_tls_cacert_no_tlscacert_parameter_warning:
  test.show_notification:
    - name: docker_server_tls_cacert_no_tlscacert_parameter_warning
    - text: |
        'tlsverify' parameter is set to 'true' in Docker daemon configuration, but
        'tlscacert' parameter is not present or it's an empty string.
        Please note - without a valid 'tlscacert', 'tlsverify' can't work.
        Recommended value for 'tlscacert': '/etc/docker/tls/ca.pem'

  {#- Proceed to tlscacert management #}
  {%- else %}
    {#- Do we really need default here? Probably not... #}
    {%- set cacert_file = d.server.config.data.get('tlscacert', '') %}
    {%- set cacert_dir = salt['file.dirname'](cacert_file) %}

    {#- If data required for cert management is provided:
        * include related states
        * create dir where 'tlscacert' will be saved #}
    {%- if ('source' in d.server.tls.cacert and d.server.tls.cacert.source)
            or ('content' in d.server.tls.cacert and d.server.tls.cacert.content) %}
include:
  - {{ tplroot }}.server.service

docker_server_tls_cacert_dir:
  file.directory:
    - name: {{ cacert_dir }}
    - makedirs: true
    {%- endif %}

    {#- If 'source' or 'content' is provided for CA cert - manage file #}
    {%- if ('source' in d.server.tls.cacert and d.server.tls.cacert.source)
            or ('content' in d.server.tls.cacert and d.server.tls.cacert.content) %}
      {#- Create symlink if requested #}
      {%- if d.server.tls.cacert.symlink %}
        {#- 'content' will be ignored if 'symlink: true' and 'source' is present
            Symlink target must be a local file on the minion - perform basic check #}
        {%- if 'source' in d.server.tls.cacert and d.server.tls.cacert.source
                and d.server.tls.cacert.source.startswith('/') %}
docker_server_tls_cacert_symlink:
  file.symlink:
    - name: "{{ cacert_file }}"
    - target: "{{ d.server.tls.cacert.source }}"
    - force: true
    - require:
      - file: docker_server_tls_cacert_dir
    - watch_in:
      - service: docker_server_service_running

        {%- else %}
docker_server_tls_cacert_symlink_fail:
  test.fail_without_changes:
    - name: docker_server_tls_cacert_symlink_fail
    - comment: |
        Symlink can only be created from the file located on the minion, please provide absolute path
        (it must start with '/') in 'docker.server.tls.cacert.source' key.
        Current 'docker.server.tls.cacert.source' value: {{ d.server.tls.cacert.source }}

          {#- Show warning (failure) if contet present, source is missing and symlink: true #}
          {%- if 'content' in d.server.tls.cacert and d.server.tls.cacert.content %}
docker_server_tls_cacert_symlink_missing_source:
  test.fail_without_changes:
    - name: docker_server_tls_cacert_symlink_missing_source
    - comment: |
        Symlink can't be created form text content provided via 'docker.server.tls.cacert.content'
        Symlink can only be created from local (to minion) file, please provide absolute path
        (it must start with '/') in 'docker.server.tls.cacert.source' key.
          {%- endif %}
        {%- endif %}

      {#- Symlink not requested, manage file: copy from source or create with content #}
      {%- else %}
docker_server_tls_cacert_provided_cacert:
  file.managed:
    - name: "{{ cacert_file }}"
        {#- cert data from pillar have more priority than source file #}
        {%- if 'content' in d.server.tls.cacert and d.server.tls.cacert.content %}
    - contents: {{ d.server.tls.cacert.content|tojson }}
        {%- else %}
    - source: {{ build_source(d.server.tls.cacert.source, path_prefix='files/tls') }}
        {%- endif %}
    - mode: 440
    - show_changes: {{ d.server.tls.cacert.get('show_changes', False) }}
    - follow_symlinks: false
    - require:
      - file: docker_server_tls_cacert_dir
    - watch_in:
      - service: docker_server_service_running
      {%- endif %}

    {%- else %}
docker_server_tls_cacert_missing_sources_warning:
  test.show_notification:
    - name: docker_server_tls_cacert_missing_sources_warning
    - text: |
        No sources provided for 'tlscacert' file won't be managed.
        If you have existing TLS cert file you can provide its location via 'docker.server.tls.cacert.source'
        or it can be inserted directly in pillar under 'docker.server.tls.cacert.content' cert.
    {%- endif %}

  {%- endif %}
{%- endif %}
