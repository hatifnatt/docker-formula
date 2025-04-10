{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}

{#- If docker:server:use_upstream is 'repo' or 'package' official repo
    will be configured in other cases repo will be removed from the system #}
include:
  {%- if d.server.use_upstream in ('repo', 'package') %}
  - .install
  {%- else %}
  - .clean
  {%- endif %}

# Workaround for issue https://github.com/saltstack/salt/issues/65080
# require will fail if a requisite only include other .sls
# Adding dummy state as a workaround
docker_repo_install_init_dummy:
  test.show_notification:
    - text: "Workaround for salt issue #65080"
