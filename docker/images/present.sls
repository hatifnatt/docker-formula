{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if 'images' in d and d.images %}
  {%- set present_count = 0 %}
  {%- for id, image in d.images|dictsort %}
    {%- set ensure = image.pop('ensure', 'present') %}
    {%- set name = image.pop('name', '') if 'name' in image else id %}
    {#- If no tag present - salt (docker-py under the hood) will try to pull all available tags, usually it is not what
        user expect. Therefore we explicitly set tag to 'latest' if no tag provided. This behavior depends on the
        version of docker-py library, i.e. docs for v3.4.0 which is used in Debian 10:
        https://docker-py.readthedocs.io/en/3.4.0/images.html#docker.models.images.ImageCollection.pull
        docker-py switched to pull only 'latest' tag if no tags are present since v4.4.0, check commit
        https://github.com/docker/docker-py/commit/cec152db5f679bc61c2093959bd9109cb9abb169 #}
    {%- set tag = image.pop('tag', 'latest') %}
    {%- if ensure == 'present' %}
      {%- set present_count =  present_count + 1 %}
docker_images_present_{{ id }}:
  docker_image.present:
    - name: {{ name }}
    - tag: {{ tag }}
    {{- format_kwargs(image) }}
    {%- endif %}

    {%- if loop.last and present_count == 0 %}
docker_images_present_zero_count:
  test.show_notification:
    - name: docker_images_present_zero_count
    - text: |
        Zero images is required to be present
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_images_present_notice:
  test.show_notification:
    - name: docker_images_present_notice
    - text: |
        No images defined in pillars.

{%- endif %}
