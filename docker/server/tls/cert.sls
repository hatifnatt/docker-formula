{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs, build_source %}

{#- Manage certificates if apropriate options are present in daemon configuration #}
{%- if 'tls' in d.server.config.data and d.server.config.data.tls
        or 'tlsverify' in d.server.config.data and d.server.config.data.tlsverify %}

  {#- TLS would not work without 'tlscert' parameter - show info #}
  {%- if 'tlscert' not in d.server.config.data
          or ('tlscert' in d.server.config.data and d.server.config.data.tlscert|length == 0) %}
docker_server_tls_cert_no_tlscert_parameter_warning:
  test.show_notification:
    - name: docker_server_tls_cert_no_tlscert_parameter_warning
    - text: |
        One of 'tls' or 'tlsverify' parameter is set to 'true' in Docker daemon configuration, but
        'tlscert' parameter is not present or it's an empty string.
        Please note - without a valid 'tlscert', TLS protected socket can't be created
        Recommended value for 'tlscert': '/etc/docker/tls/server-cert.pem'

  {#- Proceed to tlscert management #}
  {%- else %}
    {#- Do we really need default here? Probably not... #}
    {%- set key_file = d.server.config.data.get('tlskey', '') %}
    {%- set cert_file = d.server.config.data.get('tlscert', '') %}
    {%- set cert_dir = salt['file.dirname'](cert_file) %}

    {#- If data required for cert management is provided:
        * include related states
        * create dir where 'tlscert' will be saved #}
    {%- if ('source' in d.server.tls.cert and d.server.tls.cert.source)
            or ('content' in d.server.tls.cert and d.server.tls.cert.content)
            or ('params' in d.server.tls.cert and d.server.tls.cert.params) %}
include:
  - .packages
  - .key
  - {{ tplroot }}.server.service

docker_server_tls_cert_dir:
  file.directory:
    - name: {{ cert_dir }}
    - makedirs: true
    {%- endif %}

    {#- If 'source' or 'content' is provided for private cert - manage file #}
    {%- if ('source' in d.server.tls.cert and d.server.tls.cert.source)
            or ('content' in d.server.tls.cert and d.server.tls.cert.content) %}
      {#- Create symlink if requested #}
      {%- if d.server.tls.cert.symlink %}
        {#- 'content' will be ignored if 'symlink: true' and 'source' is present
            Symlink target must be a local file on the minion - perform basic check #}
        {%- if 'source' in d.server.tls.cert and d.server.tls.cert.source
                and d.server.tls.cert.source.startswith('/') %}
docker_server_tls_cert_symlink:
  file.symlink:
    - name: "{{ cert_file }}"
    - target: "{{ d.server.tls.cert.source }}"
    - force: true
    - require:
      - file: docker_server_tls_cert_dir
    - watch_in:
      - service: docker_server_service_running

        {%- else %}
docker_server_tls_cert_symlink_fail:
  test.fail_without_changes:
    - name: docker_server_tls_cert_symlink_fail
    - comment: |
        Symlink can only be created from the file located on the minion, please provide absolute path
        (it must start with '/') in 'docker.server.tls.cert.source' key.
        Current 'docker.server.tls.cert.source' value: {{ d.server.tls.cert.source }}

          {#- Show warning (failure) if contet present, source is missing and symlink: true #}
          {%- if 'content' in d.server.tls.cert and d.server.tls.cert.content %}
docker_server_tls_cert_symlink_missing_source:
  test.fail_without_changes:
    - name: docker_server_tls_cert_symlink_missing_source
    - comment: |
        Symlink can't be created form text content provided via 'docker.server.tls.cert.content'
        Symlink can only be created from local (to minion) file, please provide absolute path
        (it must start with '/') in 'docker.server.tls.cert.source' key.
          {%- endif %}
        {%- endif %}

      {#- Symlink not requested, manage file: copy from source or create with content  #}
      {%- else %}
docker_server_tls_cert_provided_cert:
  file.managed:
    - name: "{{ cert_file }}"
        {#- cert data from pillar have more priority than source file #}
        {%- if 'content' in d.server.tls.cert and d.server.tls.cert.content %}
    - contents: {{ d.server.tls.cert.content|tojson }}
        {%- else %}
    - source: {{ build_source(d.server.tls.cert.source, path_prefix='files/tls') }}
        {%- endif %}
    - mode: 440
    - show_changes: {{ d.server.tls.cert.get('show_changes', False) }}
    - follow_symlinks: false
    - require:
      - file: docker_server_tls_cert_dir
    - watch_in:
      - service: docker_server_service_running
      {%- endif %}

    {%- elif 'params' in d.server.tls.cert and d.server.tls.cert.params %}
docker_server_tls_cert_selfsigned_cert:
  x509.certificate_managed:
    - name: "{{ cert_file }}"
    - signing_private_key: {{ key_file }}
    - mode: 440
    {{- format_kwargs(d.server.tls.cert.params) }}
    - require:
      - pkg: docker_server_tls_prereq_packages
      - file: docker_server_tls_cert_dir
      - sls: {{ tplroot }}.server.tls.key
    - watch_in:
      - service: docker_server_service_running

    {%- else %}
docker_server_tls_cert_missing_sources_warning:
  test.show_notification:
    - name: docker_server_tls_cert_missing_sources_warning
    - text: |
        No sources provided for 'tlscert' file won't be managed.
        If you have existing TLS cert file you can provide its location via 'docker.server.tls.cert.source'
        or it can be inserted directly in pillar under 'docker.server.tls.cert.content' key.
        Alternatively new private cert can be generated, to do this
        you must at least specify the cert CN in 'docker.server.tls.cert.params.CN' key.
    {%- endif %}

  {%- endif %}
{%- endif %}
