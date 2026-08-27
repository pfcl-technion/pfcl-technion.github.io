document.addEventListener("DOMContentLoaded", function () {
  // Mobile navbar burger toggle
  const burgers = Array.prototype.slice.call(document.querySelectorAll(".navbar-burger"), 0);
  if (burgers.length > 0) {
    burgers.forEach(function (el) {
      el.addEventListener("click", function () {
        const target = el.dataset.target;
        const targetEl = document.getElementById(target);
        el.classList.toggle("is-active");
        if (targetEl) {
          targetEl.classList.toggle("is-active");
        }
      });
    });
  }

  // Project directory client-side interactive filtering
  const projectCards = document.querySelectorAll(".pfcl-project-item");
  const filterLab = document.getElementById("filter-lab");
  const filterStatus = document.getElementById("filter-status");
  const filterType = document.getElementById("filter-type");
  const filterLevel = document.getElementById("filter-level");
  const countBadge = document.getElementById("filtered-count");

  function applyFilters() {
    if (!projectCards.length) return;

    const selectedLab = filterLab ? filterLab.value : "all";
    const selectedStatus = filterStatus ? filterStatus.value : "all";
    const selectedType = filterType ? filterType.value : "all";
    const selectedLevel = filterLevel ? filterLevel.value : "all";

    let visibleCount = 0;

    projectCards.forEach(function (card) {
      const labs = (card.dataset.labs || "").split(",");
      const status = card.dataset.status || "";
      const types = (card.dataset.types || "").split(",");
      const levels = (card.dataset.levels || "").split(",");

      const matchLab = (selectedLab === "all") || labs.includes(selectedLab);
      const matchStatus = (selectedStatus === "all") || (status === selectedStatus);
      const matchType = (selectedType === "all") || types.includes(selectedType);
      const matchLevel = (selectedLevel === "all") || levels.includes(selectedLevel);

      if (matchLab && matchStatus && matchType && matchLevel) {
        card.classList.remove("is-hidden-by-filter");
        visibleCount++;
      } else {
        card.classList.add("is-hidden-by-filter");
      }
    });

    if (countBadge) {
      countBadge.textContent = visibleCount + " project" + (visibleCount === 1 ? "" : "s") + " matching";
    }
  }

  if (filterLab) filterLab.addEventListener("change", applyFilters);
  if (filterStatus) filterStatus.addEventListener("change", applyFilters);
  if (filterType) filterType.addEventListener("change", applyFilters);
  if (filterLevel) filterLevel.addEventListener("change", applyFilters);

  const resetBtn = document.getElementById("filter-reset-btn");
  if (resetBtn) {
    resetBtn.addEventListener("click", function () {
      if (filterLab) filterLab.value = "all";
      if (filterStatus) filterStatus.value = "all";
      if (filterType) filterType.value = "all";
      if (filterLevel) filterLevel.value = "all";
      applyFilters();
    });
  }
});
