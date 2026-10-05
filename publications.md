---
layout: page
title: Publications
subtitle: Final publications from PFCL research groups
permalink: /publications/
---

{% assign publications = site.data.generated.publications %}
{% if publications and publications.size > 0 %}
  {% assign publication_groups = publications | group_by: 'year' | sort: 'name' | reverse %}
  <div class="pfcl-publications">
    {% for group in publication_groups %}
      <section class="pfcl-publication-year" aria-labelledby="publications-{{ group.name | escape }}">
        <h2 id="publications-{{ group.name | escape }}" class="title is-3">{{ group.name | escape }}</h2>
        <ol class="pfcl-publication-list">
          {% for publication in group.items %}
            {% assign author_list = publication.authors | join: ', ' %}
            <li class="pfcl-publication-item">
              <h3 class="title is-5 mb-2">
                <a href="{{ publication.canonical_url | escape }}" target="_blank" rel="noopener noreferrer">
                  {{ publication.title | escape }}
                </a>
              </h3>
              <p class="pfcl-publication-authors mb-1">{{ author_list | escape }}</p>
              {% if publication.venue %}
                <p class="pfcl-publication-venue mb-2">{{ publication.venue | escape }}</p>
              {% endif %}
              <p class="pfcl-publication-meta is-size-7">
                <span class="pfcl-publication-labs">
                  Research groups:
                  {% for lab_id in publication.lab_ids %}
                    {% assign lab = site.labs | where: 'slug', lab_id | first %}
                    <span>{{ lab.short_name | default: lab.title | default: lab_id | escape }}</span>{% unless forloop.last %}, {% endunless %}
                  {% endfor %}
                </span>
                <span aria-hidden="true"> · </span>
                <span class="pfcl-publication-sources">
                  Source{% if publication.source_names.size > 1 %}s{% endif %}:
                  {% for source_name in publication.source_names %}
                    <span>{{ source_name | escape }}</span>{% unless forloop.last %}, {% endunless %}
                  {% endfor %}
                </span>
              </p>
            </li>
          {% endfor %}
        </ol>
      </section>
    {% endfor %}
  </div>
{% else %}
  <p class="has-text-grey">No publications are available at this time.</p>
{% endif %}
