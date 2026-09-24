// PFCL student-project filters: hides non-matching cards. The full list
// remains in the HTML, so links work with JavaScript disabled.
(function () {
  "use strict";

  var root = document.querySelector("[data-project-list]");
  if (!root) return;

  var selects = Array.prototype.slice.call(root.querySelectorAll("select[data-filter]"));
  var cards = Array.prototype.slice.call(root.querySelectorAll("[data-project-card]"));

  var emptyNotice = root.querySelector("[data-empty-filter]");

  function cardValues(card, name) {
    return (card.getAttribute("data-" + name) || "").split(/\s+/).filter(Boolean);
  }

  function applyFilters() {
    var visibleCount = 0;
    cards.forEach(function (card) {
      var visible = selects.every(function (select) {
        var value = select.value;
        if (!value) return true;
        return cardValues(card, select.getAttribute("data-filter")).indexOf(value) !== -1;
      });
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
})();
