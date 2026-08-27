---
layout: page
title: News & Activity Feed
subtitle: Updates, research highlights, and events from PFCL and constituent labs
permalink: /news/
---

<div class="columns is-multiline">
  {% for item in site.news %}
    <div class="column is-12">
      {% include news_card.html item=item %}
    </div>
  {% endfor %}
  {% for item in site.data.generated.updates %}
    <div class="column is-12">
      {% include news_card.html item=item %}
    </div>
  {% endfor %}
</div>
