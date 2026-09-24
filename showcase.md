---
layout: showcase
title: PFCL Laboratory Showcase
permalink: /showcase/
---

<div id="showcase-slider" class="showcase-slider">

  {% comment %} --- Category 1: Research Groups --- {% endcomment %}
  {% assign labs = site.labs | where: "kind", "research-group" | sort: "order" %}
  {% for lab in labs %}
  <article class="showcase-slide" data-category="RESEARCH GROUP" data-accent="cyan">
    <div class="showcase-card showcase-card-lab">
      <div class="showcase-card-header">
        <span class="showcase-pill pill-cyan">RESEARCH GROUP</span>
        {% if lab.short_name %}<span class="showcase-tag">{{ lab.short_name }}</span>{% endif %}
      </div>
      <div class="showcase-card-body">
        <div class="showcase-card-left">
          {% if lab.logo %}
            <img src="{{ lab.logo | relative_url }}" alt="{{ lab.title }}" class="showcase-lab-logo">
          {% endif %}
          <div class="showcase-leader-box">
            <span class="showcase-meta-label">Group Leader</span>
            <p class="showcase-leader-name">{{ lab.leader_names | join: ', ' }}</p>
            {% if lab.leader_email %}
              <p class="showcase-leader-email"><i class="fa-solid fa-envelope"></i> {{ lab.leader_email }}</p>
            {% endif %}
          </div>
        </div>
        <div class="showcase-card-right">
          <h2 class="showcase-title">{{ lab.title }}</h2>
          <p class="showcase-summary">{{ lab.summary }}</p>
          {% if lab.website %}
            <p class="showcase-link-note"><i class="fa-solid fa-globe"></i> {{ lab.website }}</p>
          {% endif %}
        </div>
      </div>
    </div>
  </article>
  {% endfor %}

  {% comment %} --- Category 2: Available Student Projects --- {% endcomment %}
  {% assign showcase_projects = site.projects | where: "recruitment_status", "available" | where: "show_on_showcase", true | sort: "order" %}
  {% for project in showcase_projects %}
  <article class="showcase-slide" data-category="STUDENT PROJECT" data-accent="emerald">
    <div class="showcase-card showcase-card-project">
      <div class="showcase-card-header">
        <span class="showcase-pill pill-emerald">AVAILABLE STUDENT PROJECT</span>
        {% if project.student_levels %}
          <span class="showcase-tag">{{ project.student_levels | join: ', ' | upcase }}</span>
        {% endif %}
      </div>
      <div class="showcase-card-body">
        <div class="showcase-card-main">
          <h2 class="showcase-title">{{ project.title }}</h2>
          <div class="showcase-advisors">
            <span class="showcase-meta-label">Advisor:</span>
            <strong>{{ project.advisor_names | join: ', ' }}</strong>
            {% if project.contact_email %}
              <span class="showcase-contact-email"><i class="fa-solid fa-envelope"></i> {{ project.contact_email }}</span>
            {% endif %}
          </div>
          <p class="showcase-summary">{{ project.summary }}</p>
          {% if project.project_types %}
            <div class="showcase-badges">
              {% for ptype in project.project_types %}
                <span class="showcase-badge">{{ ptype }}</span>
              {% endfor %}
            </div>
          {% endif %}
        </div>
      </div>
    </div>
  </article>
  {% endfor %}

  {% comment %} --- Category 3 & 4: News & Publications --- {% endcomment %}
  {% assign showcase_news = site.news | where: "show_on_showcase", true | sort: "date" | reverse %}
  {% for item in showcase_news %}
    {% assign is_pub = false %}
    {% if item.category == 'publication' or item.category == 'research-highlight' %}
      {% assign is_pub = true %}
    {% endif %}

    <article class="showcase-slide" data-category="{% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS{% endif %}" data-accent="{% if is_pub %}purple{% else %}amber{% endif %}">
      <div class="showcase-card {% if is_pub %}showcase-card-pub{% else %}showcase-card-news{% endif %}">
        <div class="showcase-card-header">
          <span class="showcase-pill {% if is_pub %}pill-purple{% else %}pill-amber{% endif %}">
            {% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS &amp; ANNOUNCEMENT{% endif %}
          </span>
          <span class="showcase-tag">{{ item.date | date: "%B %-d, %Y" }}</span>
        </div>
        <div class="showcase-card-body">
          <div class="showcase-card-main">
            <h2 class="showcase-title">{{ item.title }}</h2>
            <div class="showcase-news-meta">
              <span class="showcase-meta-label">Source:</span>
              <strong>{{ item.source_name | default: 'PFCL' }}</strong>
            </div>
            <p class="showcase-summary">{{ item.excerpt }}</p>
            {% if item.canonical_url %}
              <p class="showcase-link-note"><i class="fa-solid fa-arrow-up-right-from-square"></i> Read online</p>
            {% endif %}
          </div>
        </div>
      </div>
    </article>
  {% endfor %}

</div>
