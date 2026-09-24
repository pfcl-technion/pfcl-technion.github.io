---
layout: page
title: Student Projects
subtitle: Available and ongoing student research projects
permalink: /projects/
---

The Control Lab offers diverse research and engineering project opportunities for undergraduate and graduate students. Browse currently available and active projects below, filter by topic or research group, or click any project to view its full details and prerequisites.

<div data-project-list>
{% include project_filters.html %}

{% assign projects = site.projects | where: 'published', true | sort: 'order' %}
{% if projects.size == 0 %}
<p class="pfcl-placeholder" data-project-empty>No student projects are currently published.</p>
{% else %}
<div class="columns is-multiline">
{% for project in projects %}
  <div class="column is-4-desktop is-6-tablet is-12-mobile" data-project-card
       data-labs="{{ project.lab_ids | join: ' ' }}"
       data-status="{{ project.recruitment_status }}"
       data-type="{{ project.project_type }}">
    {% include project_card.html project=project %}
  </div>
{% endfor %}
</div>
<div class="notification is-light mt-4 is-hidden pfcl-empty-filter" data-empty-filter>
  No student projects match the selected search and filter criteria.
</div>
{% endif %}

<!-- Inquiry Modal -->
<div class="modal" id="pfcl-project-modal" aria-hidden="true">
  <div class="modal-background" data-modal-close></div>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title is-size-5" id="pfcl-modal-title">Inquire about project</p>
      <button class="delete" aria-label="close" data-modal-close></button>
    </header>
    <section class="modal-card-body">
      {% if site.project_inquiry_form_url and site.project_inquiry_form_url != '' %}
        <iframe id="pfcl-modal-iframe" src="{{ site.project_inquiry_form_url }}" width="100%" height="480" frameborder="0">Loading inquiry form...</iframe>
      {% else %}
        <div class="content">
          <p>Interested in learning more or applying for this project? Reach out to the lab and advisor directly:</p>
          <p id="pfcl-modal-direct-contact"></p>
          <div class="buttons mt-4">
            <a id="pfcl-modal-email-btn" href="mailto:{{ site.email }}" class="button is-primary">
              <i class="fas fa-envelope mr-2"></i>Send Email Inquiry
            </a>
          </div>
        </div>
      {% endif %}
    </section>
    <footer class="modal-card-foot">
      <button class="button is-small" data-modal-close>Close</button>
    </footer>
  </div>
</div>

</div>

<script src="{{ '/assets/js/projects.js' | relative_url }}?v={{ site.time | date: '%s' }}" defer></script>
