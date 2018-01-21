{%
  set js_commons = [
    'src/utils.js',
    'src/motion.js'
  ]
%}

{% for common in js_commons %}
  <script type="text/javascript" src="{{ url_for(theme.js) }}/{{ common }}?v={{ theme.version }}"></script>
  <script src="/plugins/highlight/highlight.pack.js"></script>
  <script>hljs.initHighlightingOnLoad();</script>
{% endfor %}
