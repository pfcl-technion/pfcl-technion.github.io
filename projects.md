---
layout: page
title: Student Projects
subtitle: Available and ongoing student research projects
permalink: /projects/
---

Explore available research and experimental projects across PFCL laboratories. Use the filters below to browse by research group, student level, or project type, and contact the listed project advisor to apply.

<div data-project-list>
{% include project_filters.html %}

{% assign projects = site.projects | where: 'published', true | sort: 'order' %}
{% if projects.size == 0 %}
<p class="has-text-grey" data-project-empty>No student projects are currently listed. Please check back later or contact our research groups directly.</p>
{% else %}
<div class="columns is-multiline">
{% for project in projects %}
  <div class="column is-6-desktop is-12-tablet" data-project-card
       data-labs="{{ project.lab_ids | join: ' ' }}"
       data-status="{{ project.recruitment_status }}"
       data-types="{{ project.project_types | join: ' ' }}"
       data-levels="{{ project.student_levels | join: ' ' }}">
    <div class="card pfcl-card">
      <div class="card-content">
        <p class="title is-5">{{ project.title }}</p>
        <p class="subtitle is-6">{{ project.advisor_names | join: ', ' }}</p>
        <div class="content">{{ project.summary }}</div>
      </div>
    </div>
  </div>
{% endfor %}
</div>
<div class="notification is-light mt-4 is-hidden" data-empty-filter>
  No student projects match the selected filter criteria.
</div>
{% endif %}
</div>

<script src="{{ '/assets/js/projects.js' | relative_url }}?v={{ site.time | date: '%s' }}" defer></script>
