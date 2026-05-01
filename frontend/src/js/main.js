import { isLoggedIn, clearToken } from "./api.js";
import { renderLogin, showToast } from "./auth.js";
import { renderDashboard } from "./dashboard.js";
import { renderUsers } from "./users.js";
import { renderStudents } from "./students.js";
import { renderServices } from "./services.js";

let currentPage = "dashboard";

const NAV_ITEMS = [
  { id: "dashboard", icon: "📊", label: "Dashboard" },
  { id: "users", icon: "👥", label: "Người dùng" },
  { id: "students", icon: "🎓", label: "Sinh viên" },
  { id: "services", icon: "⚡", label: "Dịch vụ" },
];

function renderLayout() {
  const app = document.getElementById("app");
  app.innerHTML = `
    <div class="layout">
      <aside class="sidebar" id="sidebar">
        <div class="sidebar-logo">
          <h2>💰 Student eWallet</h2>
          <span>Admin Dashboard</span>
        </div>
        <nav class="sidebar-nav" id="sidebar-nav">
          ${NAV_ITEMS.map(item => `
            <button class="nav-item ${item.id === currentPage ? "active" : ""}" data-page="${item.id}">
              <span class="icon">${item.icon}</span>
              <span>${item.label}</span>
            </button>
          `).join("")}
        </nav>
        <div class="sidebar-footer">
          <button class="nav-item" id="logout-btn">
            <span class="icon">🚪</span>
            <span>Đăng xuất</span>
          </button>
        </div>
      </aside>
      <main class="main-content" id="main-content"></main>
    </div>`;

  // Nav click handlers
  document.getElementById("sidebar-nav").addEventListener("click", (e) => {
    const btn = e.target.closest("[data-page]");
    if (!btn) return;
    navigateTo(btn.dataset.page);
  });

  // Logout
  document.getElementById("logout-btn").addEventListener("click", () => {
    clearToken();
    showToast("Đã đăng xuất", "info");
    initApp();
  });

  navigateTo(currentPage);
}

function navigateTo(page) {
  currentPage = page;
  // Update active nav
  document.querySelectorAll(".nav-item[data-page]").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.page === page);
  });

  const content = document.getElementById("main-content");
  switch (page) {
    case "dashboard": renderDashboard(content); break;
    case "users": renderUsers(content); break;
    case "students": renderStudents(content); break;
    case "services": renderServices(content); break;
  }
}

function initApp() {
  if (isLoggedIn()) {
    renderLayout();
  } else {
    renderLogin();
  }
}

// Make initApp globally accessible for auth.js callback
window.initApp = initApp;

// Start
initApp();
