---
layout: page
title: Student Projects
subtitle: Available and ongoing student research projects
permalink: /projects/
---

[Placeholder: introduction for students — how to read statuses and apply.]

<div data-project-list>
  {% include project_filters.html %}

  {% assign projects = site.projects | where: 'published', true | sort: 'order' %}
  {% if projects.size == 0 %}
    <p class="pfcl-placeholder" data-project-empty>[Placeholder: student projects will be listed here once the <code>_projects</code> collection is populated.]</p>
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
  {% endif %}
</div>

<script src="{{ '/assets/js/projects.js' | relative_url }}" defer></script>
