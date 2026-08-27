---
layout: page
title: Laboratory Team & Personnel
subtitle: Faculty, researchers, engineers, and staff
permalink: /team/
---

{% for cat in site.data.taxonomies.team_categories %}
  {% assign members = site.team | where: "category", cat.id | sort: "order" %}
  {% if members.size > 0 %}
    <h2 class="title is-4 mt-5 mb-4">{{ cat.label }}</h2>
    <div class="columns is-multiline mb-5">
      {% for person in members %}
        <div class="column is-4">
          {% include team_card.html person=person %}
        </div>
      {% endfor %}
    </div>
  {% endif %}
{% endfor %}

