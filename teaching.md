---
layout: page
title: Teaching Laboratories
subtitle: Experimental education and student coursework facilities
permalink: /teaching/
---

<p class="is-size-5 mb-5">
  PFCL hosts hands-on teaching laboratories that introduce aerospace engineering students to experimental flight dynamics, automatic attitude control, sensor calibration, and drone piloting.
</p>

<div class="columns is-multiline">
  {% assign teaching_units = site.labs | where: "kind", "teaching-lab" %}
  {% for lab in teaching_units %}
    <div class="column is-6">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>
