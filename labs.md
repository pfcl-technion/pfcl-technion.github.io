---
layout: page
title: Research Groups
subtitle: Constituent research groups and laboratories
permalink: /labs/
---

<div class="columns is-multiline">
{% assign labs = site.labs | where: "kind", "research-group" | sort: 'order' %}
{% for lab in labs %}
  <div class="column is-6-desktop is-12-tablet">
    {% include lab_card.html lab=lab %}
  </div>
{% endfor %}
</div>
