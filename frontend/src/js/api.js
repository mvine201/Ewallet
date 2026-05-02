const BASE_URL = "https://ewallet-hn0m.onrender.com/api";

function getToken() {
  return localStorage.getItem("admin_token");
}

export function setToken(token) {
  localStorage.setItem("admin_token", token);
}

export function clearToken() {
  localStorage.removeItem("admin_token");
}

export function isLoggedIn() {
  return Boolean(getToken());
}

async function request(path, options = {}) {
  const token = getToken();
  const headers = { ...options.headers };

  if (token) headers["Authorization"] = `Bearer ${token}`;
  if (!(options.body instanceof FormData)) {
    headers["Content-Type"] = "application/json";
  }

  const res = await fetch(`${BASE_URL}${path}`, { ...options, headers });
  const data = await res.json();

  if (res.status === 401 && path !== "/auth/login") {
    clearToken();
    window.location.reload();
  }

  return { ok: res.ok, status: res.status, data };
}

export const api = {
  // Auth
  login: (phone, password) =>
    request("/auth/login", {
      method: "POST",
      body: JSON.stringify({ phone, password }),
    }),

  // Dashboard
  getDashboard: () => request("/admin/dashboard"),

  // Users
  getUsers: (page = 1, search = "") =>
    request(`/admin/users?page=${page}&limit=15&search=${encodeURIComponent(search)}`),
  getUserDetail: (id) => request(`/admin/users/${id}`),
  lockUser: (id) => request(`/admin/users/${id}/lock`, { method: "PATCH" }),
  unlockUser: (id) => request(`/admin/users/${id}/unlock`, { method: "PATCH" }),
  lockWallet: (id) => request(`/admin/users/${id}/lock-wallet`, { method: "PATCH" }),
  unlockWallet: (id) => request(`/admin/users/${id}/unlock-wallet`, { method: "PATCH" }),
  resetPassword: (id) => request(`/admin/users/${id}/reset-password`, { method: "PATCH" }),

  // Students
  getStudents: (page = 1, search = "", cohort = "", faculty = "", academicStatus = "") =>
    request(`/admin/students?page=${page}&limit=15&search=${encodeURIComponent(search)}&cohort=${encodeURIComponent(cohort)}&faculty=${encodeURIComponent(faculty)}&academicStatus=${encodeURIComponent(academicStatus)}`),
  importStudents: (file) => {
    const form = new FormData();
    form.append("file", file);
    return request("/admin/students/import", { method: "POST", body: form });
  },
  updateCohortStatus: (payload) =>
    request("/admin/students/cohort-status", {
      method: "PATCH",
      body: JSON.stringify(payload),
    }),
  deleteStudentsBulk: (ids) =>
    request("/admin/students/bulk", {
      method: "DELETE",
      body: JSON.stringify({ ids }),
    }),
  deleteStudent: (id) => request(`/admin/students/${id}`, { method: "DELETE" }),

  // Services
  getServices: () => request("/admin/services"),
  createService: (data) =>
    request("/admin/services", { method: "POST", body: JSON.stringify(data) }),
  updateService: (id, data) =>
    request(`/admin/services/${id}`, { method: "PUT", body: JSON.stringify(data) }),
  deleteService: (id) => request(`/admin/services/${id}`, { method: "DELETE" }),
  exportServicePayments: async (id) => {
    const token = getToken();
    const headers = {};
    if (token) headers["Authorization"] = `Bearer ${token}`;
    const res = await fetch(`${BASE_URL}/admin/services/${id}/payments/export`, { headers });
    if (!res.ok) {
      const data = await res.json().catch(() => ({ message: "Xuất Excel thất bại" }));
      return { ok: false, data };
    }
    const blob = await res.blob();
    return { ok: true, blob };
  },

  // Notifications
  createNotification: (title, message, link, file) => {
    const form = new FormData();
    form.append("title", title);
    form.append("message", message);
    if (link) form.append("link", link);
    if (file) form.append("file", file);
    return request("/admin/notifications", { method: "POST", body: form });
  },
};
