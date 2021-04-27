{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs, build_source %}

{#- Manage certificates if apropriate options are present in daemon configuration #}
{%- if 'tls' in d.server.config.data and d.server.config.data.tls
        or 'tlsverify' in d.server.config.data and d.server.config.data.tlsverify %}

  {#- TLS would not work without 'tlskey' parameter - show info #}
  {%- if 'tlskey' not in d.server.config.data
          or ('tlskey' in d.server.config.data and d.server.config.data.tlskey|length == 0) %}
docker_server_tls_key_no_tlskey_parameter_warning:
  test.show_notification:
    - name: docker_server_tls_key_no_tlskey_parameter_warning
    - text: |
        One of 'tls' or 'tlsverify' parameter is set to 'true' in Docker daemon configuration, but
        'tlskey' parameter is not present or it's an empty string.
        Please note - without a valid 'tlskey', TLS protected socket can't be created
        Recommended value for 'tlskey': '/etc/docker/tls/server-key.pem'

  {#- Proceed to tlskey management #}
  {%- else %}
    {#- Do we really need default here? Probably not... #}
    {%- set key_file = d.server.config.data.get('tlskey', '') %}
    {%- set key_dir = salt['file.dirname'](key_file) %}

    {#- If data required for key management is provided:
        * include related states
        * create dir where 'tlskey' will be saved #}
    {%- if ('source' in d.server.tls.key and d.server.tls.key.source)
            or ('content' in d.server.tls.key and d.server.tls.key.content)
            or ('params' in d.server.tls.key and d.server.tls.key.params) %}
include:
  - .packages
  - {{ tplroot }}.server.service

docker_server_tls_key_dir:
  file.directory:
    - name: {{ key_dir }}
    - makedirs: true
    {%- endif %}

    {#- If 'source' or 'content' is provided for private key - manage file #}
    {%- if ('source' in d.server.tls.key and d.server.tls.key.source)
            or ('content' in d.server.tls.key and d.server.tls.key.content) %}
      {#- Create symlink if requested #}
      {%- if d.server.tls.key.symlink %}
        {#- 'content' will be ignored if 'symlink: true' and 'source' is present
            Symlink target must be a local file on the minion - perform basic check #}
        {%- if 'source' in d.server.tls.key and d.server.tls.key.source
                and d.server.tls.key.source.startswith('/') %}
docker_server_tls_key_symlink:
  file.symlink:
    - name: "{{ key_file }}"
    - target: "{{ d.server.tls.key.source }}"
    - force: true
    - require:
      - file: docker_server_tls_key_dir
    - watch_in:
      - service: docker_server_service_running

        {%- else %}
docker_server_tls_key_symlink_fail:
  test.fail_without_changes:
    - name: docker_server_tls_key_symlink_fail
    - comment: |
        Symlink can only be created from the file located on the minion, please provide absolute path
        (it must start with '/') in 'docker.server.tls.key.source' key.
        Current 'docker.server.tls.key.source' value: {{ d.server.tls.key.source }}

          {#- Show warning (failure) if contet present, source is missing and symlink: true #}
          {%- if 'content' in d.server.tls.key and d.server.tls.key.content %}
docker_server_tls_key_symlink_missing_source:
  test.fail_without_changes:
    - name: docker_server_tls_key_symlink_missing_source
    - comment: |
        Symlink can't be created form text content provided via 'docker.server.tls.key.content'
        Symlink can only be created from local (to minion) file, please provide absolute path
        (it must start with '/') in 'docker.server.tls.key.source' key.
          {%- endif %}
        {%- endif %}

      {#- Symlink not requested, manage file: copy from source or create with content  #}
      {%- else %}
docker_server_tls_key_provided_key:
  file.managed:
    - name: "{{ key_file }}"
        {#- Key data from pillar have more priority than source file #}
        {%- if 'content' in d.server.tls.key and d.server.tls.key.content %}
    - contents: {{ d.server.tls.key.content|tojson }}
        {%- else %}
    - source: {{ build_source(d.server.tls.key.source, path_prefix='files/tls') }}
        {%- endif %}
    - mode: 440
    - show_changes: {{ d.server.tls.key.get('show_changes', False) }}
    - follow_symlinks: false
    - require:
      - file: docker_server_tls_key_dir
    - watch_in:
      - service: docker_server_service_running
      {%- endif %}

    {%- elif 'params' in d.server.tls.key and d.server.tls.key.params %}
docker_server_tls_key_selfsigned_key:
  x509.private_key_managed:
    - name: "{{ key_file }}"
    - mode: 440
    {{- format_kwargs(d.server.tls.key.params) }}
    - require:
      - pkg: docker_server_tls_prereq_packages
      - file: docker_server_tls_key_dir
    - watch_in:
      - service: docker_server_service_running

    {%- else %}
docker_server_tls_key_missing_sources_warning:
  test.show_notification:
    - name: docker_server_tls_key_missing_sources_warning
    - text: |
        No sources provided for 'tlskey' file won't be managed.
        If you have existing TLS key file you can provide its location via 'docker.server.tls.key.source'
        or it can be inserted directly in pillar under 'docker.server.tls.key.content' key.
        Alternatively new private key can be generated, to do this
        you must at least specify the key length in 'docker.server.tls.key.params.bits' key.
    {%- endif %}

  {%- endif %}
{%- endif %}
