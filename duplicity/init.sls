{% set hostname=grains['id'] -%}

duplicity_ppa_repo:
  pkgrepo:
    {%- if salt['pillar.get']('duplicity:'+hostname+':install_from_ppa', False) %}
    - managed
    {%- else %}
    - absent
    {%- endif %}
    - ppa: duplicity-team/ppa
    - require_in:
      - pkg: duplicity
    - watch_in:
      - pkg: duplicity

duplicity:
  pkg:
    - installed

# This is to avoid the "no module gio" warning
#python-gobject:
pygobject2:
  pkg:
    - installed

/usr/local/sbin/custom_backup:
  file.managed:
    - template: jinja
    - source: salt://experimental/salt-duplicity/duplicity/custom_backup
    - makedirs: True
    - mode: 700
    - defaults:
        gpg_pw: {{ salt['pillar.get']('duplicity:'+hostname+':gpg_pw', '') }}
        target_pw: {{ salt['pillar.get']('duplicity:'+hostname+':target_pw', '') }}
        aws_key: {{ salt['pillar.get']('duplicity:'+hostname+':aws_key', '') }}
        aws_secret: {{ salt['pillar.get']('duplicity:'+hostname+':aws_secret', '') }}
        target: {{ salt['pillar.get']('duplicity:'+hostname+':target', '') }}
        verbosity: {{ salt['pillar.get']('duplicity:'+hostname+':verbosity', 4) }}
        key_id: {{ salt['pillar.get']('duplicity:'+hostname+':key_id', '') }}
        includes_excludes: {{ salt['pillar.get']('duplicity:'+hostname+':includes_excludes', '') }}
        extra_parms: {{ salt['pillar.get']('duplicity:'+hostname+':extra_parms', '') }}
        pre: {{ salt['pillar.get']('duplicity:'+hostname+':pre', '') != '' }}
        post: {{ salt['pillar.get']('duplicity:'+hostname+':post', '') != '' }}
        remove_older_than: {{ salt['pillar.get']('duplicity:'+hostname+':remove_older_than', '2Y') }}
        remove_all_inc_of_but_n_full: {{ salt['pillar.get']('duplicity:'+hostname+':remove_all_inc_of_but_n_full', '') }}
        full_if_older_than: {{ salt['pillar.get']('duplicity:'+hostname+':full_if_older_than', '1M') }}
        source: {{ salt['pillar.get']('duplicity:'+hostname+':source', '/') }}
      
{% set when_to_run = salt['pillar.get']('duplicity:'+hostname+':when_to_run', '0 4 * * *') %}
/etc/cron.d/duplicity:
  file.managed:
    - mode: 600
    - contents: "{{ when_to_run }} root /usr/local/sbin/custom_backup scheduled\n"

{% set pre = salt['pillar.get']('duplicity:'+hostname+':pre', 'False') %}
{% set post = salt['pillar.get']('duplicity:'+hostname+':post', 'False') %}

{% if pre %}
/etc/duplicity/pre:
  file.managed:
    - mode: 700
    - contents: |
        {{ pre.replace("\n", "\n        ") }}
    - makedirs: True
{% endif %}

{% if post %}
/etc/duplicity/post:
  file.managed:
    - mode: 700
    - contents: |
        {{ post.replace("\n", "\n        ") }}
    - makedirs: True
{% endif %}
