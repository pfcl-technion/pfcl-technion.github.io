---
layout: showcase
title: PFCL Laboratory Showcase
permalink: /showcase/
---

<div id="showcase-slider" class="showcase-slider">

  {% assign empty_array = '' | split: '' %}

  {% comment %} ========================================================= {% endcomment %}
  {% comment %} --- Available Student Projects (Native + Aggregated) ---   {% endcomment %}
  {% comment %} ========================================================= {% endcomment %}
  {% assign native_projects = site.projects | where: 'published', true | where: 'recruitment_status', 'available' | where_exp: 'p', 'p.external != true' | sort: 'order' %}
  {% assign generated_projects = site.data.generated.projects | default: empty_array | where: 'recruitment_status', 'available' | sort_natural: 'title' %}
  {% assign all_projects = native_projects | concat: generated_projects %}

  {% for project in all_projects %}
    {% assign hero_img = project.thumbnail | default: project.image | default: '/assets/images/drone2.jpg' %}

    <article class="showcase-slide" data-category="STUDENT PROJECT" data-accent="emerald">
      <div class="showcase-hero-layer">
        <img src="{{ hero_img | escape }}" alt="" class="showcase-hero-bg" loading="lazy">
        <div class="showcase-hero-scrim"></div>
      </div>

      <div class="showcase-slide-content">
        <div class="showcase-category-ribbon ribbon-project">
          <h1 class="showcase-ribbon-title">Project for students</h1>
        </div>

        <div class="showcase-slide-text">
          <h2 class="showcase-title">{{ project.title }}</h2>

          <p class="showcase-summary">{{ project.summary }}</p>

          <div class="showcase-tags-strip">
            <span class="showcase-tag-item tag-lab"><i class="fas fa-flask mr-1"></i>{{ project.source_name | default: 'PFCL' }}</span>
            {% if project.advisor_names and project.advisor_names.size > 0 %}
              <span class="showcase-tag-item tag-advisor"><i class="fas fa-user mr-1"></i>Advisor: {{ project.advisor_names | join: ', ' }}</span>
            {% endif %}
            {% if project.duration %}
              <span class="showcase-tag-item tag-duration"><i class="far fa-clock mr-1"></i>{{ project.duration }}</span>
            {% elsif project.student_levels %}
              <span class="showcase-tag-item tag-level"><i class="fas fa-graduation-cap mr-1"></i>{{ project.student_levels | join: ', ' | upcase }}</span>
            {% endif %}
            {% if project.prerequisites and project.prerequisites.size > 0 %}
              {% for prereq in project.prerequisites %}
                <span class="showcase-tag-item tag-prereq"><i class="fas fa-check-circle mr-1"></i>{{ prereq }}</span>
              {% endfor %}
            {% endif %}
          </div>
        </div>

        <div class="showcase-slide-visual">
          <div class="showcase-visual-frame">
            <img src="{{ hero_img | escape }}" alt="{{ project.title | escape }}" class="showcase-visual-img" loading="lazy">
          </div>
        </div>
      </div>
    </article>
  {% endfor %}

  {% comment %} ========================================================= {% endcomment %}
  {% comment %} --- News & Publications (Native + Aggregated) ---          {% endcomment %}
  {% comment %} ========================================================= {% endcomment %}
  {% assign native_news = site.news | where: 'show_on_showcase', true | sort: 'date' | reverse %}
  {% assign generated_updates = site.data.generated.updates | default: empty_array | where: 'show_on_showcase', true | sort: 'date' | reverse | slice: 0, 15 %}
  {% assign all_updates = native_news | concat: generated_updates %}

  {% for item in all_updates %}
    {% assign is_pub = false %}
    {% if item.category == 'publication' or item.category == 'research-highlight' %}
      {% assign is_pub = true %}
    {% endif %}

    {% assign fallback_hero = '/assets/images/drone2.jpg' %}
    {% if item.lab_id == 'anpl' %}
      {% assign fallback_hero = '/assets/images/drone2.jpg' %}
    {% elsif item.lab_id == 'connect' %}
      {% assign fallback_hero = '/assets/images/PFCL-1.png' %}
    {% endif %}
    {% assign hero_img = item.image | default: fallback_hero %}

    <article class="showcase-slide" data-category="{% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS{% endif %}" data-accent="{% if is_pub %}cyan{% else %}amber{% endif %}">
      <div class="showcase-hero-layer">
        <img src="{{ hero_img | escape }}" alt="" class="showcase-hero-bg" loading="lazy">
        <div class="showcase-hero-scrim"></div>
      </div>

      <div class="showcase-slide-content">
        <div class="showcase-category-ribbon {% if is_pub %}ribbon-publication{% else %}ribbon-news{% endif %}">
          <h1 class="showcase-ribbon-title">
            {% if is_pub %}Publication{% else %}News{% endif %}
          </h1>
        </div>

        <div class="showcase-slide-text">
          <h2 class="showcase-title">{{ item.title }}</h2>

          <p class="showcase-summary">{{ item.excerpt }}</p>

          <div class="showcase-tags-strip">
            <span class="showcase-tag-item tag-lab"><i class="fas fa-flask mr-1"></i>{{ item.source_name | default: 'PFCL' }}</span>
            <span class="showcase-tag-item tag-date"><i class="far fa-calendar-alt mr-1"></i>{{ item.date | date: "%B %-d, %Y" }}</span>
          </div>
        </div>

        <div class="showcase-slide-visual">
          <div class="showcase-visual-frame">
            <img src="{{ hero_img | escape }}" alt="{{ item.title | escape }}" class="showcase-visual-img" loading="lazy">
          </div>
        </div>
      </div>
    </article>
  {% endfor %}

</div>
