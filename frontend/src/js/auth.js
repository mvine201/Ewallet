import { api, setToken, clearToken, isLoggedIn } from "./api.js";

export function showToast(message, type = "success") {
  let container = document.querySelector(".toast-container");
  if (!container) {
    container = document.createElement("div");
    container.className = "toast-container";
    document.body.appendChild(container);
  }
  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  const icons = { success: "✅", error: "❌", info: "ℹ️" };
  toast.innerHTML = `<span>${icons[type] || ""}</span><span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => { toast.style.opacity = "0"; setTimeout(() => toast.remove(), 300); }, 3000);
}

export function renderLogin() {
  const app = document.getElementById("app");
  app.innerHTML = `
    <div class="login-wrapper">
      <div class="login-card">
        <h1>🏛️ Admin Panel</h1>
        <p class="subtitle">Quản lý ví điện tử sinh viên</p>
        <div id="login-error" class="login-error"></div>
        <form id="login-form">
          <div class="form-group">
            <label>Tài khoản</label>
            <input type="text" id="login-phone" placeholder="Nhập tài khoản admin" autocomplete="username" required />
          </div>
          <div class="form-group">
            <label>Mật khẩu</label>
            <input type="password" id="login-password" placeholder="Nhập mật khẩu" autocomplete="current-password" required />
          </div>
          <button type="submit" class="btn btn-primary" id="login-btn">Đăng nhập</button>
        </form>
      </div>
    </div>
  `;
  document.getElementById("login-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const phone = document.getElementById("login-phone").value.trim();
    const password = document.getElementById("login-password").value;
    const btn = document.getElementById("login-btn");
    const errDiv = document.getElementById("login-error");
    btn.disabled = true;
    btn.textContent = "Đang đăng nhập...";
    errDiv.style.display = "none";
    const { ok, data } = await api.login(phone, password);
    if (ok && data.data?.user?.role === "admin") {
      setToken(data.data.token);
      showToast("Đăng nhập thành công!");
      window.initApp();
    } else {
      errDiv.textContent = data.data?.user?.role !== "admin" && ok
        ? "Tài khoản không có quyền admin"
        : data.message || "Đăng nhập thất bại";
      errDiv.style.display = "block";
      btn.disabled = false;
      btn.textContent = "Đăng nhập";
    }
  });
}
