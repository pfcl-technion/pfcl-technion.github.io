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
  - caption: "Research-figure slide — [To be updated: caption of concept figure]"
---

## Welcome

The Philadelphia Flight Control Laboratory, also known as the Control Lab in the Stephen B. Klein faculty of Aerospace Engineering, is comprised of research groups and teaching labs in the fields of Guidance, Navigation, and Control (GNC).

## News &amp; updates

{% include news_feed.html limit=4 %}

<div class="buttons">
  <a href="{{ '/news/' | relative_url }}" class="button is-primary is-outlined">All news &amp; updates</a>
</div>

## Selected projects looking for students

<div class="columns is-multiline">
{% assign available_projects = site.projects | where: "published", true | where: "recruitment_status", "available" | sort: 'order' %}
{% for project in available_projects limit: 3 %}
  <div class="column is-4-desktop is-6-tablet is-12-mobile">
    {% include project_card.html project=project %}
  </div>
{% endfor %}
</div>

<div class="buttons mt-4">
  <a href="{{ '/projects/' | relative_url }}" class="button is-primary is-outlined">All student projects &rarr;</a>
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

<div class="mt-6">
{% include carousel.html %}
</div>

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

