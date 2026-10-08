---
layout: page
title: Control Lab
subtitle: Stephen B. Klein Faculty of Aerospace Engineering
hide_hero: false
hero_image: "/assets/images/drone2.jpg"
---

## Welcome

The Philadelphia Flight Control Laboratory, also known as the Control Lab in the Stephen B. Klein faculty of Aerospace Engineering, is comprised of research groups and teaching labs in the fields of Guidance, Navigation, and Control (GNC).

{% assign empty_projects = '' | split: '' %}
{% assign native_available = site.projects | where: 'published', true | where: 'recruitment_status', 'available' | where_exp: 'project', 'project.external != true' | sort: 'order' %}
{% assign generated_available = site.data.generated.projects | default: empty_projects | where: 'recruitment_status', 'available' | sort_natural: 'title' %}
{% assign available_projects = native_available | concat: generated_available %}
{% if available_projects.size > 0 %}
<hr class="pfcl-section-divider">

## Selected projects looking for students

<div class="pfcl-project-showcase-section" data-project-showcase>
  <div class="level is-mobile mb-3">
    <div class="level-left">
      <div class="pfcl-showcase-dots" data-showcase-dots aria-label="Showcase slide indicators"></div>
    </div>
    <div class="level-right pfcl-showcase-nav-desktop">
      <div class="buttons has-addons mb-0">
        <button class="button is-small is-outlined is-primary pfcl-showcase-btn" data-showcase-prev aria-label="Previous projects">
          <i class="fas fa-chevron-left"></i>
        </button>
        <button class="button is-small is-outlined is-primary pfcl-showcase-btn" data-showcase-next aria-label="Next projects">
          <i class="fas fa-chevron-right"></i>
        </button>
      </div>
    </div>
  </div>

  <div class="pfcl-showcase-track" data-showcase-track tabindex="0" aria-label="Student projects showcase">
    {% assign slide_size = 3 %}
    {% assign total_projects = available_projects.size %}
    {% assign total_slides = total_projects | plus: slide_size | minus: 1 | divided_by: slide_size %}

    {% for slide_idx in (0..total_slides) %}
      {% assign offset = slide_idx | times: slide_size %}
      {% if offset < total_projects %}
        <div class="pfcl-showcase-slide" data-showcase-slide data-slide-index="{{ slide_idx }}">
          <div class="columns is-multiline">
            {% for project in available_projects limit: slide_size offset: offset %}
              <div class="column is-4-desktop is-6-tablet is-12-mobile">
                {% include project_card.html project=project %}
              </div>
            {% endfor %}
          </div>
        </div>
      {% endif %}
    {% endfor %}
  </div>

  <div class="buttons mt-4">
    <a href="{{ '/projects/' | relative_url }}" class="button is-primary is-outlined">All student projects &rarr;</a>
  </div>
</div>
{% endif %}

<hr class="pfcl-section-divider">

## News &amp; updates

{% include news_feed.html limit=4 %}

<div class="buttons">
  <a href="{{ '/news/' | relative_url }}" class="button is-primary is-outlined">All news &amp; updates</a>
</div>

<hr class="pfcl-section-divider">

## Research groups

<div class="columns is-multiline">
{% assign labs = site.labs | where: "kind", "research-group" | sort: 'order' %}
{% for lab in labs %}
  <div class="column is-6-desktop is-12-tablet">
    {% include lab_card.html lab=lab %}
  </div>
{% endfor %}
</div>

{% if available_projects.size > 0 %}
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

<script src="{{ '/assets/js/projects.js' | relative_url }}?v={{ site.time | date: '%s' }}" defer></script>
<script src="{{ '/assets/js/project-showcase.js' | relative_url }}?v={{ site.time | date: '%s' }}" defer></script>
{% endif %}

