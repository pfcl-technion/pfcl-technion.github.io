---
layout: page
title: Research Groups & Units
subtitle: Constituent laboratories and shared facilities
permalink: /labs/
---

<div class="columns is-multiline">
  {% assign sorted_labs = site.labs | sort: "order" %}
  {% for lab in sorted_labs %}
    <div class="column is-6">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>

