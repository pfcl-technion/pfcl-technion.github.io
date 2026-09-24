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
              <p class="showcase-leader-email"><svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" style="vertical-align: -2px; margin-right: 4px;"><path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg> {{ lab.leader_email }}</p>
            {% endif %}
          </div>
        </div>
        <div class="showcase-card-right">
          <h2 class="showcase-title">{{ lab.title }}</h2>
          <p class="showcase-summary">{{ lab.summary }}</p>
          {% if lab.website %}
            <p class="showcase-link-note"><svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor" style="vertical-align: -2px; margin-right: 4px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg> {{ lab.website }}</p>
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
              <span class="showcase-contact-email"><svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" style="vertical-align: -2px; margin-right: 4px;"><path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg> {{ project.contact_email }}</span>
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
              <p class="showcase-link-note"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align: -2px; margin-right: 4px;"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg> Read online</p>
            {% endif %}
          </div>
        </div>
      </div>
    </article>
  {% endfor %}

</div>
