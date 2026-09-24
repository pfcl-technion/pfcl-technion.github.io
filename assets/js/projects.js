// PFCL student-project filters and inquiry modal.
(function () {
  "use strict";

  var root = document.querySelector("[data-project-list]");
  var modal = document.getElementById("pfcl-project-modal");

  // Filter Logic
  if (root) {
    var searchInput = root.querySelector("#pfcl-project-search");
    var selects = Array.prototype.slice.call(root.querySelectorAll("select[data-filter]"));
    var cards = Array.prototype.slice.call(root.querySelectorAll("[data-project-card]"));
    var emptyNotice = root.querySelector("[data-empty-filter]");

    function cardValues(card, name) {
      return (card.getAttribute("data-" + name) || "").split(/\s+/).filter(Boolean);
    }

    function applyFilters() {
      var query = searchInput ? searchInput.value.trim().toLowerCase() : "";
      var visibleCount = 0;

      cards.forEach(function (card) {
        var matchesDropdowns = selects.every(function (select) {
          var value = select.value;
          if (!value) return true;
          return cardValues(card, select.getAttribute("data-filter")).indexOf(value) !== -1;
        });

        var matchesSearch = !query || card.textContent.toLowerCase().indexOf(query) !== -1;
        var visible = matchesDropdowns && matchesSearch;

        card.hidden = !visible;
        card.style.display = visible ? "" : "none";
        card.classList.toggle("is-hidden", !visible);
        if (visible) visibleCount++;
      });

      if (emptyNotice) {
        emptyNotice.style.display = visibleCount === 0 ? "" : "none";
        emptyNotice.classList.toggle("is-hidden", visibleCount > 0);
      }
    }

    selects.forEach(function (select) {
      select.addEventListener("change", applyFilters);
    });

    if (searchInput) {
      searchInput.addEventListener("input", applyFilters);
    }
  }

  // Inquiry Modal Logic (works on both listing page and detail pages)
  if (modal) {
    var modalTitle = modal.querySelector("#pfcl-modal-title");
    var modalContact = modal.querySelector("#pfcl-modal-direct-contact");
    var modalEmailBtn = modal.querySelector("#pfcl-modal-email-btn");

    function openModal(btn) {
      var pTitle = btn.getAttribute("data-project-title") || "Student Project";
      var pAdvisor = btn.getAttribute("data-project-advisor") || "";
      var pEmail = btn.getAttribute("data-project-contact") || "pfcl@technion.ac.il";

      if (modalTitle) modalTitle.textContent = "Inquire: " + pTitle;
      if (modalContact) {
        modalContact.innerHTML = "<strong>Project:</strong> " + pTitle + "<br><strong>Advisor:</strong> " + pAdvisor;
      }
      if (modalEmailBtn) {
        var subject = encodeURIComponent("Inquiry regarding project: " + pTitle);
        var body = encodeURIComponent("Hello,\n\nI am interested in learning more about the project \"" + pTitle + "\".\n\nName:\nDegree/Year:\nQuestions/Background:\n");
        modalEmailBtn.setAttribute("href", "mailto:" + pEmail + "?subject=" + subject + "&body=" + body);
      }

      modal.classList.add("is-active");
      modal.setAttribute("aria-hidden", "false");
    }

    function closeModal() {
      modal.classList.remove("is-active");
      modal.setAttribute("aria-hidden", "true");
    }

    document.addEventListener("click", function (e) {
      var btn = e.target.closest("[data-inquiry-btn]");
      if (btn) {
        e.preventDefault();
        openModal(btn);
      }
    });

    var closeTriggers = modal.querySelectorAll("[data-modal-close]");
    Array.prototype.slice.call(closeTriggers).forEach(function (trigger) {
      trigger.addEventListener("click", closeModal);
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && modal.classList.contains("is-active")) {
        closeModal();
      }
    });
  }
})();
