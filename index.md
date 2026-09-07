---
layout: page
title: Philadelphia Flight Control Laboratory
subtitle: Technion – Israel Institute of Technology
hide_hero: false
carousel:
  - caption: Photograph of the PFCL flight testbeds
  - caption: Photograph of researchers operating a quadcopter experiment
  - caption: "Research-figure slide — [Placeholder: caption of concept figure]"
---

## Welcome

[Placeholder: two-to-three paragraph welcome text describing PFCL — the umbrella facility for Guidance, Navigation, and Control research in the Faculty of Aerospace Engineering, its scope, and its constituent groups.]

<div class="buttons">
  <a href="{{ '/labs/' | relative_url }}" class="button is-primary">Research groups</a>
  <a href="{{ '/projects/' | relative_url }}" class="button is-primary is-outlined">Available student projects</a>
</div>

{% include carousel.html %}

## Research groups

[Placeholder: optional one-line introduction to the groups below.]

<div class="columns is-multiline">
  {% assign labs = site.labs | sort: 'order' %}
  {% for lab in labs %}
    <div class="column is-6-desktop is-12-tablet">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>

## Selected student projects

<p class="pfcl-placeholder">[Placeholder: teaser list of currently available student projects — fed from the <code>_projects</code> collection.]</p>

## News &amp; updates

{% include news_feed.html limit=4 %}

## Partners

[Placeholder: partner and funding logos.]

<div class="pfcl-partners">
  <div class="pfcl-partner-placeholder">Technion</div>
  <div class="pfcl-partner-placeholder">Faculty of Aerospace Engineering</div>
  <div class="pfcl-partner-placeholder">[Additional partners]</div>
</div>
