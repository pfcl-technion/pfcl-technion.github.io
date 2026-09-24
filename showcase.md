---
layout: showcase
title: PFCL Laboratory Showcase
permalink: /showcase/
---

<div id="showcase-slider" class="showcase-slider">

  {% comment %} --- Available Student Projects --- {% endcomment %}
  {% assign showcase_projects = site.projects | where: "recruitment_status", "available" | where: "show_on_showcase", true | sort: "order" %}
  {% for project in showcase_projects %}
  <article class="showcase-slide" data-category="STUDENT PROJECT" data-accent="emerald" data-qr-url="{{ project.url | absolute_url }}">
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
        <aside class="showcase-qr-aside" aria-label="QR code linking to this project page">
          <div class="showcase-qr-frame" data-qr-target></div>
          <span class="showcase-qr-caption">Scan to view<br>this project</span>
        </aside>
      </div>
    </div>
  </article>
  {% endfor %}

  {% comment %} --- News & Publications --- {% endcomment %}
  {% assign showcase_news = site.news | where: "show_on_showcase", true | sort: "date" | reverse %}
  {% for item in showcase_news %}
    {% assign is_pub = false %}
    {% if item.category == 'publication' or item.category == 'research-highlight' %}
      {% assign is_pub = true %}
    {% endif %}

    {% assign qr_url = '' %}
    {% if item.canonical_url %}
      {% assign qr_url = item.canonical_url %}
      {% unless qr_url contains '://' %}
        {% assign qr_url = qr_url | absolute_url %}
      {% endunless %}
    {% endif %}

    <article class="showcase-slide" data-category="{% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS{% endif %}" data-accent="{% if is_pub %}purple{% else %}amber{% endif %}" {% if qr_url != '' %}data-qr-url="{{ qr_url }}"{% endif %}>
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
          {% if qr_url != '' %}
          <aside class="showcase-qr-aside" aria-label="QR code linking to the full story">
            <div class="showcase-qr-frame" data-qr-target></div>
            <span class="showcase-qr-caption">Scan to<br>read more</span>
          </aside>
          {% endif %}
        </div>
      </div>
    </article>
  {% endfor %}

</div>
