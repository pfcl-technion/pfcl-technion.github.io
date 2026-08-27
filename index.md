---
layout: default
title: Home
---

<section class="pfcl-hero hero">
  <div class="container">
    <h1 class="title is-1">Philadelphia Flight Control Laboratory</h1>
    <p class="subtitle is-4 mt-3">
      Advancing autonomous flight, navigation, perception, and aerospace control systems at the Technion Faculty of Aerospace Engineering.
    </p>
    <div class="buttons mt-5">
      <a href="{{ '/projects/' | relative_url }}" class="button is-warning has-text-weight-bold">Explore Available Projects</a>
      <a href="{{ '/labs/' | relative_url }}" class="button is-light is-outlined has-text-weight-bold">Research Groups</a>
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="columns is-vcentered mb-6">
      <div class="column is-8">
        <h2 class="title is-3">About the Laboratory</h2>
        <p class="is-size-5 mb-4">
          The Philadelphia Flight Control Laboratory (PFCL) serves as the umbrella facility bringing together cutting-edge research groups, specialized flight testing infrastructure, and hands-on teaching laboratories within the Technion's Faculty of Aerospace Engineering.
        </p>
        <p class="is-size-6">
          Our constituent laboratories pioneer algorithmic and theoretical breakthroughs in autonomous navigation, guidance and control, differential games, multi-robot coordination, and perception in GPS-denied environments.
        </p>
      </div>
      <div class="column is-4 has-text-centered">
        <div class="box has-background-light p-5">
          <p class="heading">Constituent Units</p>
          <p class="title is-1 has-text-primary">{{ site.labs.size }}</p>
          <p class="is-size-7 has-text-grey">Research Groups, Teaching Labs & Facilities</p>
        </div>
      </div>
    </div>

    <!-- Featured Research Groups -->
    <div class="mb-6">
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Research Groups & Facilities</h2>
        <a href="{{ '/labs/' | relative_url }}" class="is-size-6 has-text-weight-semibold">View All &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% for lab in site.labs limit:3 %}
          <div class="column is-4">
            {% include lab_card.html lab=lab %}
          </div>
        {% endfor %}
      </div>
    </div>

    <!-- Available Student Projects -->
    <div class="mb-6">
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Featured Student Projects</h2>
        <a href="{{ '/projects/' | relative_url }}" class="is-size-6 has-text-weight-semibold">All Projects &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% assign available_projects = site.projects | where: "recruitment_status", "available" %}
        {% for project in available_projects limit:2 %}
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
