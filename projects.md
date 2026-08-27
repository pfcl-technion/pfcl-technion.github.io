---
layout: page
title: Student Projects
subtitle: Available, ongoing, and completed student research projects
permalink: /projects/
---

{% include project_filters.html %}

<div id="pfcl-project-list" class="columns is-multiline">
  {% assign sorted_projects = site.projects | sort: "updated_at" | reverse %}
  {% for project in sorted_projects %}
    <div class="column is-6">
      {% include project_card.html project=project %}
    </div>
  {% endfor %}
</div>
