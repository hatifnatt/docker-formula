{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import docker as d %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{#  Image removal process can be optimized by building list of images to remove and then run
    docker_images_absent:
      docker_image.absent:
        - images: [list, of, images]
    but I prefer to stick to common pattern of state files in this
    formula - iterating over list of objects one by one -#}

{%- if 'images' in d and d.images %}
  {%- set absent_count = 0 %}
  {%- for id, image in d.images|dictsort %}
    {%- set ensure = image.pop('ensure', '') %}
    {%- set name = image.pop('name', '') if 'name' in image else id %}
    {#- 'docker_image.absent' doesn't have 'tag' argument, it expect image name in format 'image_name:tag' but
        'docker_image.present' does have 'tag' argument, therefore for 'docker_image.absent' we have to translate from
        'docker_image.present' format with dedicated 'tag' argument to single string in 'image_name:tag' format #}
    {%- set tag = image.pop('tag', 'latest') %}
    {%- if tag %}
      {%- set name = name ~ ':' ~ tag %}
    {%- endif %}
    {%- if ensure == 'absent' %}
      {%- set absent_count =  absent_count + 1 %}
docker_images_absent_{{ id }}:
  docker_image.absent:
    - name: {{ name }}
    - force: {{ image.get('force', 'false') }}
    {%- endif %}

    {%- if loop.last and absent_count == 0 %}
docker_images_absent_zero_count:
  test.show_notification:
    - name: docker_images_absent_zero_count
    - text: |
        Zero images is required to be absent
    {%- endif %}

  {%- endfor %}

{%- else %}
docker_images_absent_notice:
  test.show_notification:
    - name: docker_images_absent_notice
    - text: |
        No images defined in pillars.

{%- endif %}
