---
layout: page
title: Control Lab
subheading: Stephen B. Klein Faculty of Aerospace Engineering
subtitle: Technion – Israel Institute of Technology
hide_hero: false
hero_image: "/assets/images/drone2.jpg"
carousel:
  - caption: Photograph of the PFCL flight testbeds
  - caption: Photograph of researchers operating a quadcopter experiment
  - caption: "Research-figure slide — [Placeholder: caption of concept figure]"
---

## Welcome

The Philadelphia Flight Control Laboratory, also known as the Control Lab in the Stephen B. Klein faculty of Aerospace Engineering, is comprised of research groups and teaching labs in the fields of Guidance, Navigation, and Control (GNC).

<div class="buttons">
  <a href="{{ '/labs/' | relative_url }}" class="button is-primary">Research groups</a>
  <a href="{{ '/projects/' | relative_url }}" class="button is-primary is-outlined">Available student projects</a>
</div>

{% include carousel.html %}

## News &amp; updates

{% include news_feed.html limit=4 %}

<div class="buttons">
  <a href="{{ '/news/' | relative_url }}" class="button is-primary is-outlined">All news &amp; updates</a>
</div>

## Research groups

<div class="columns is-multiline">
{% assign labs = site.labs | where: "kind", "research-group" | sort: 'order' %}
{% for lab in labs %}
  <div class="column is-6-desktop is-12-tablet">
    {% include lab_card.html lab=lab %}
  </div>
{% endfor %}
</div>

## Selected student projects

<div class="columns is-multiline">
{% assign available_projects = site.projects | where: "published", true | where: "recruitment_status", "available" | sort: 'order' %}
{% for project in available_projects limit: 4 %}
  <div class="column is-6-desktop is-12-tablet">
    <div class="card pfcl-card">
      <div class="card-content">
        <p class="title is-5"><a href="{{ '/projects/' | relative_url }}">{{ project.title }}</a></p>
        <p class="subtitle is-6">{{ project.advisor_names | join: ', ' }}</p>
        <div class="content">{{ project.summary }}</div>
      </div>
    </div>
  </div>
{% endfor %}
</div>

<div class="buttons">
  <a href="{{ '/projects/' | relative_url }}" class="button is-primary is-outlined">All student projects</a>
</div>

