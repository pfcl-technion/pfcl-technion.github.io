---
layout: showcase
title: PFCL Laboratory Showcase
permalink: /showcase/
---

<div id="showcase-slider" class="showcase-slider">

  {% assign empty_array = '' | split: '' %}

  {% comment %} --- Available Student Projects (Native + Aggregated) --- {% endcomment %}
  {% assign native_projects = site.projects | where: 'published', true | where: 'recruitment_status', 'available' | where_exp: 'p', 'p.external != true' | sort: 'order' %}
  {% assign generated_projects = site.data.generated.projects | default: empty_array | where: 'recruitment_status', 'available' | sort_natural: 'title' %}
  {% assign all_projects = native_projects | concat: generated_projects %}

  {% for project in all_projects %}
    {% assign qr_url = project.canonical_url | default: project.url %}
    {% unless qr_url contains '://' %}
      {% assign qr_url = qr_url | absolute_url %}
    {% endunless %}

    {% assign hero_img = project.thumbnail | default: project.image | default: '/assets/images/drone2.jpg' %}

    <article class="showcase-slide" data-category="STUDENT PROJECT" data-accent="emerald" data-qr-url="{{ qr_url | escape }}">
      <div class="showcase-hero-layer">
        <img src="{{ hero_img | escape }}" alt="{{ project.title | escape }}" class="showcase-hero-bg" loading="lazy">
        <div class="showcase-hero-scrim"></div>
      </div>

      <div class="showcase-slide-content">
        <div class="showcase-pane-info">
          <div class="showcase-pill-row">
            <span class="showcase-pill pill-emerald">AVAILABLE STUDENT PROJECT</span>
            <span class="showcase-lab-badge">{{ project.source_name | default: 'PFCL' }}</span>
            {% if project.duration %}
              <span class="showcase-tag"><i class="far fa-clock mr-1"></i>{{ project.duration }}</span>
            {% elsif project.student_levels %}
              <span class="showcase-tag">{{ project.student_levels | join: ', ' | upcase }}</span>
            {% endif %}
          </div>

          <h2 class="showcase-title">{{ project.title }}</h2>

          {% if project.advisor_names and project.advisor_names.size > 0 %}
            <div class="showcase-advisor-strip">
              {% for advisor_name in project.advisor_names %}
                {% assign advisor_alias_key = advisor_name | downcase | strip %}
                {% assign advisor_slug = site.data.external_advisor_aliases[advisor_alias_key] %}
                {% assign advisor_member = site.team | where: "slug", advisor_slug | first %}
                <div class="showcase-advisor-item">
                  {% if advisor_member and advisor_member.photo %}
                    <img src="{{ advisor_member.photo | relative_url }}" alt="{{ advisor_name | escape }}" class="showcase-advisor-avatar">
                  {% else %}
                    <span class="showcase-advisor-avatar-placeholder"><i class="fas fa-user"></i></span>
                  {% endif %}
                  <div class="showcase-advisor-text">
                    <span class="showcase-advisor-label">Advisor</span>
                    <span class="showcase-advisor-name">{{ advisor_name }}</span>
                  </div>
                </div>
              {% endfor %}
              {% if project.contact_email %}
                <span class="showcase-contact-email"><i class="far fa-envelope mr-1"></i>{{ project.contact_email }}</span>
              {% endif %}
            </div>
          {% endif %}

          <p class="showcase-summary">{{ project.summary }}</p>

          {% if project.prerequisites and project.prerequisites.size > 0 %}
            <div class="showcase-badges">
              {% for prereq in project.prerequisites %}
                <span class="showcase-badge"><i class="fas fa-check-circle mr-1"></i>{{ prereq }}</span>
              {% endfor %}
            </div>
          {% elsif project.project_types %}
            <div class="showcase-badges">
              {% for ptype in project.project_types %}
                <span class="showcase-badge">{{ ptype }}</span>
              {% endfor %}
            </div>
          {% endif %}
        </div>

        <div class="showcase-pane-aside">
          <aside class="showcase-qr-card" aria-label="QR code linking to this project page">
            <div class="showcase-qr-frame" data-qr-target></div>
            <span class="showcase-qr-caption">Scan with phone<br>to view &amp; apply</span>
          </aside>
        </div>
      </div>
    </article>
  {% endfor %}

  {% comment %} --- News & Publications (Native + Aggregated) --- {% endcomment %}
  {% assign native_news = site.news | where: 'show_on_showcase', true | sort: 'date' | reverse %}
  {% assign generated_updates = site.data.generated.updates | default: empty_array | where: 'show_on_showcase', true | sort: 'date' | reverse | slice: 0, 15 %}
  {% assign all_updates = native_news | concat: generated_updates %}

  {% for item in all_updates %}
    {% assign is_pub = false %}
    {% if item.category == 'publication' or item.category == 'research-highlight' %}
      {% assign is_pub = true %}
    {% endif %}

    {% assign qr_url = item.canonical_url %}
    {% unless qr_url contains '://' %}
      {% assign qr_url = qr_url | absolute_url %}
    {% endunless %}

    {% assign fallback_hero = '/assets/images/drone2.jpg' %}
    {% if item.lab_id == 'anpl' %}
      {% assign fallback_hero = '/assets/images/drone2.jpg' %}
    {% elsif item.lab_id == 'connect' %}
      {% assign fallback_hero = '/assets/images/PFCL-1.png' %}
    {% endif %}
    {% assign hero_img = item.image | default: fallback_hero %}

    <article class="showcase-slide" data-category="{% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS{% endif %}" data-accent="{% if is_pub %}cyan{% else %}amber{% endif %}" data-qr-url="{{ qr_url | escape }}">
      <div class="showcase-hero-layer">
        <img src="{{ hero_img | escape }}" alt="{{ item.title | escape }}" class="showcase-hero-bg" loading="lazy">
        <div class="showcase-hero-scrim"></div>
      </div>

      <div class="showcase-slide-content">
        <div class="showcase-pane-info">
          <div class="showcase-pill-row">
            <span class="showcase-pill {% if is_pub %}pill-cyan{% else %}pill-amber{% endif %}">
              {% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS &amp; ANNOUNCEMENT{% endif %}
            </span>
            <span class="showcase-lab-badge">{{ item.source_name | default: 'PFCL' }}</span>
            <span class="showcase-tag">{{ item.date | date: "%B %-d, %Y" }}</span>
          </div>

          <h2 class="showcase-title">{{ item.title }}</h2>

          <div class="showcase-news-meta">
            <span class="showcase-meta-label">Research Group</span>
            <strong>{{ item.source_name | default: 'PFCL' }}</strong>
          </div>

          <p class="showcase-summary">{{ item.excerpt }}</p>

          <p class="showcase-link-note">
            <i class="fas fa-external-link-alt mr-1"></i> Read online via source publication
          </p>
        </div>

        <div class="showcase-pane-aside">
          <aside class="showcase-qr-card" aria-label="QR code linking to the full story">
            <div class="showcase-qr-frame" data-qr-target></div>
            <span class="showcase-qr-caption">Scan with phone<br>to read details</span>
          </aside>
        </div>
      </div>
    </article>
  {% endfor %}

</div>
