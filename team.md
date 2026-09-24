---
layout: page
title: Team
subtitle: Faculty, staff, and researchers
permalink: /team/
---

{% for cat in site.data.taxonomies.team_categories %}
{% assign members = site.team | where: 'category', cat.id | sort: 'order' %}
{% if members.size > 0 %}
<h2 class="title is-4 mt-5">{{ cat.label }}</h2>
<div class="columns is-multiline">
{% for person in members %}
<div class="column is-4-desktop is-6-tablet">
{% include team_card.html person=person %}
</div>
{% endfor %}
</div>
{% endif %}
{% endfor %}
