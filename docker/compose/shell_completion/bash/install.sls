{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{#- Install systemwide autocomplete for bash #}
{%- if d.compose.shell_completion.bash.install %}

{%- set bc_source = salt['file.join'](d.compose.shell_completion.bash.download_remote,
                                      d.compose.version,
                                      d.compose.shell_completion.bash.remote_path) %}
docker_compose_shell_completion_bash_install_package:
  pkg.installed:
    - name: {{ d.compose.shell_completion.bash.package }}

docker_compose_shell_completion_bash_install:
  file.managed:
    - name: {{ d.compose.shell_completion.bash.dir }}/docker-compose
    - source: {{ d.compose.shell_completion.bash.source if d.compose.shell_completion.bash.source else bc_source }}
    - skip_verify: true
    - show_changes: false

{%- else %}
docker_compose_shell_completion_bash_install_notice:
  test.show_notification:
    - name: docker_compose_shell_completion_bash_install_notice
    - text: |
        bash completion is not selected for installation, current value
        for 'docker:compose:shell_completion:bash:install': {{ d.compose.shell_completion.bash.install|string|lower }},
        if you want to install bash completion for docker-compose you need to set it to 'true'.

{%- endif %}
