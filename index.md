---
layout: default
title: Home
---

<section class="pfcl-hero hero">
  <div class="container">
    <div class="columns is-vcentered">
      <div class="column is-8">
        <h1 class="title is-1">Philadelphia Flight Control Laboratory</h1>
        <p class="subtitle is-4 mt-3">
          The heart of Guidance, Navigation, and Control (GNC) research within the Faculty of Aerospace Engineering at the Technion.
        </p>
        <div class="buttons mt-5">
          <a href="{{ '/projects/' | relative_url }}" class="button is-warning has-text-weight-bold">Explore Open Projects</a>
          <a href="{{ '/labs/' | relative_url }}" class="button is-light is-outlined has-text-weight-bold">Research Groups</a>
        </div>
      </div>
      <div class="column is-4 has-text-centered is-hidden-touch">
        <img src="{{ '/assets/images/PFCL-2.png' | relative_url }}" alt="PFCL Emblem" style="max-height: 180px; filter: brightness(0) invert(1); opacity: 0.95;">
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="columns is-vcentered mb-6">
      <div class="column is-8">
        <h2 class="title is-3">About Our Institution</h2>
        <p class="is-size-5 mb-4">
          The Philadelphia Flight Control Laboratory (PFCL) is the heart of the Guidance, Navigation, and Control (GNC) research group within the Faculty of Aerospace Engineering.
        </p>
        <p class="is-size-6" style="line-height: 1.6;">
          The scope of the interdisciplinary research performed in the lab includes high-level control objectives such as cooperative team mission planning (task assignment) and multi-robot coordination, motion planning (guidance) with regard to optimizing trajectories for dynamical systems, trajectory-following, low-level control objectives focused on the control of single vehicles and/or platforms, and vision-aided single- and multi-vehicle autonomous navigation in uncertain environments. Additional research topics pursued in the lab are advanced flight displays, pilot-vehicle modelling, and active manipulators.
        </p>
      </div>
      <div class="column is-4 has-text-centered">
        <div class="box p-5">
          <p class="heading">Constituent Units</p>
          <p class="title is-1 has-text-primary">{{ site.labs.size }}</p>
          <p class="is-size-7 has-text-grey">Research Groups & Teaching Labs</p>
        </div>
      </div>
    </div>

    <!-- Featured Research Groups -->
    <div class="mb-6">
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Research Groups in Our Laboratory</h2>
        <a href="{{ '/labs/' | relative_url }}" class="is-size-6 has-text-weight-semibold">View All &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% for lab in site.labs %}
          <div class="column is-4">
            {% include lab_card.html lab=lab %}
          </div>
        {% endfor %}
      </div>
    </div>

    <!-- Available Student Projects -->
    <div class="mb-6">
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Selected Student Projects</h2>
        <a href="{{ '/projects/' | relative_url }}" class="is-size-6 has-text-weight-semibold">All Projects &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% assign available_projects = site.projects | where: "recruitment_status", "available" %}
        {% for project in available_projects limit:4 %}
          <div class="column is-6">
            {% include project_card.html project=project %}
          </div>
        {% endfor %}
      </div>
    </div>

    <!-- Recent News & Highlights -->
    <div>
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Latest Updates & News</h2>
        <a href="{{ '/news/' | relative_url }}" class="is-size-6 has-text-weight-semibold">Full News Feed &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% for item in site.news limit:3 %}
          <div class="column is-12">
            {% include news_card.html item=item %}
          </div>
        {% endfor %}
      </div>
    </div>
  </div>
</section>
