---
layout: page
title: About PFCL
subtitle: The umbrella laboratory for GNC research at Technion
permalink: /about/
---

[Placeholder: concise institutional overview — 2–3 paragraphs about the Philadelphia Flight Control Laboratory.]

## Constituent research groups

[Placeholder: short introduction.]

<div class="columns is-multiline">
  {% assign labs = site.labs | sort: 'order' %}
  {% for lab in labs %}
    <div class="column is-6-desktop is-12-tablet">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>

## Location

Philadelphia Flight Control Laboratory
Faculty of Aerospace Engineering
Lady Davis Building
Technion – Israel Institute of Technology
Haifa 32000, Israel
