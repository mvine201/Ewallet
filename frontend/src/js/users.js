import { api } from "./api.js";
import { showToast } from "./auth.js";

let currentPage = 1;
let searchQuery = "";
let searchTimeout = null;

function fmt(n) { return (n || 0).toLocaleString("vi-VN"); }

function closeModal() {
  const m = document.querySelector(".modal-overlay");
  if (m) m.remove();
}

function showUserDetail(user) {
  closeModal();
  const modal = document.createElement("div");
  modal.className = "modal-overlay";
  modal.innerHTML = `
    <div class="modal" style="width:600px">
      <h2>👤 Chi tiết: ${user.fullName}</h2>
      <div class="detail-grid">
        <div class="detail-item"><label>Họ tên</label><div class="value">${user.fullName}</div></div>
        <div class="detail-item"><label>Điện thoại</label><div class="value">${user.phone}</div></div>
        <div class="detail-item"><label>Email</label><div class="value">${user.email || "—"}</div></div>
        <div class="detail-item"><label>MSSV</label><div class="value">${user.studentId || "—"}</div></div>
        <div class="detail-item"><label>Tài khoản</label><div class="value">${user.isActive ? '<span class="badge badge-success">Hoạt động</span>' : '<span class="badge badge-danger">Bị khoá</span>'}</div></div>
        <div class="detail-item"><label>Xác thực SV</label><div class="value">${user.isVerified ? '<span class="badge badge-success">Đã xác thực</span>' : '<span class="badge badge-warning">Chưa</span>'}</div></div>
        <div class="detail-item"><label>Số dư ví</label><div class="value" style="color:var(--success);font-weight:700">${user.wallet ? fmt(user.wallet.balance) + "₫" : "—"}</div></div>
        <div class="detail-item"><label>Trạng thái ví</label><div class="value">${user.wallet ? (user.wallet.status === "active" ? '<span class="badge badge-success">Hoạt động</span>' : '<span class="badge badge-danger">Bị khoá</span>') : "—"}</div></div>
      </div>
      <div class="detail-item" style="margin-bottom:16px"><label>Ngày tạo</label><div class="value">${new Date(user.createdAt).toLocaleString("vi-VN")}</div></div>
      <div class="modal-footer">
        <button class="btn btn-outline btn-sm" onclick="this.closest('.modal-overlay').remove()">Đóng</button>
      </div>
    </div>`;
  modal.addEventListener("click", (e) => { if (e.target === modal) closeModal(); });
  document.body.appendChild(modal);
}

async function confirmAction(msg) {
  return new Promise(resolve => {
    const modal = document.createElement("div");
    modal.className = "modal-overlay";
    modal.innerHTML = `
      <div class="modal" style="width:400px">
        <h2>⚠️ Xác nhận</h2>
        <p style="color:var(--text-secondary);margin-bottom:20px">${msg}</p>
        <div class="modal-footer">
          <button class="btn btn-outline btn-sm" id="confirm-no">Huỷ</button>
          <button class="btn btn-danger btn-sm" id="confirm-yes">Xác nhận</button>
        </div>
      </div>`;
    document.body.appendChild(modal);
    modal.querySelector("#confirm-yes").onclick = () => { modal.remove(); resolve(true); };
    modal.querySelector("#confirm-no").onclick = () => { modal.remove(); resolve(false); };
    modal.addEventListener("click", (e) => { if (e.target === modal) { modal.remove(); resolve(false); } });
  });
}

async function handleLockUser(id, fullName, container) {
  if (!(await confirmAction(`Khoá tài khoản "${fullName}"?`))) return;
  const { ok, data } = await api.lockUser(id);
  showToast(data.message, ok ? "success" : "error");
  if (ok) renderUsers(container);
}

async function handleUnlockUser(id, fullName, container) {
  if (!(await confirmAction(`Mở khoá tài khoản "${fullName}"?`))) return;
  const { ok, data } = await api.unlockUser(id);
  showToast(data.message, ok ? "success" : "error");
  if (ok) renderUsers(container);
}

async function handleLockWallet(id, container) {
  if (!(await confirmAction("Khoá ví người dùng này?"))) return;
  const { ok, data } = await api.lockWallet(id);
  showToast(data.message, ok ? "success" : "error");
  if (ok) renderUsers(container);
}

async function handleUnlockWallet(id, container) {
  if (!(await confirmAction("Mở khoá ví người dùng này?"))) return;
  const { ok, data } = await api.unlockWallet(id);
  showToast(data.message, ok ? "success" : "error");
  if (ok) renderUsers(container);
}

async function handleResetPassword(id, fullName) {
  if (!(await confirmAction(`Reset mật khẩu cho "${fullName}"? Mật khẩu mới sẽ được tạo ngẫu nhiên.`))) return;
  const { ok, data } = await api.resetPassword(id);
  if (ok) {
    closeModal();
    const modal = document.createElement("div");
    modal.className = "modal-overlay";
    modal.innerHTML = `
      <div class="modal" style="width:420px">
        <h2>🔑 Mật khẩu mới</h2>
        <p style="color:var(--text-secondary);margin-bottom:16px">Mật khẩu đã được reset cho <strong>${data.data.fullName}</strong></p>
        <div style="background:var(--bg-glass);border:1px solid var(--border-glass);border-radius:var(--radius-sm);padding:16px;text-align:center;margin-bottom:16px">
          <p style="color:var(--text-muted);font-size:0.8rem;margin-bottom:8px">Mật khẩu mới</p>
          <p style="font-size:1.4rem;font-weight:700;letter-spacing:2px;color:var(--warning)" id="new-pw">${data.data.newPassword}</p>
        </div>
        <p style="color:var(--danger);font-size:0.8rem">⚠️ Hãy ghi lại mật khẩu này và gửi cho người dùng. Mật khẩu sẽ không hiển thị lại.</p>
        <div class="modal-footer">
          <button class="btn btn-outline btn-sm" id="copy-pw">📋 Sao chép</button>
          <button class="btn btn-primary btn-sm" onclick="this.closest('.modal-overlay').remove()">Đóng</button>
        </div>
      </div>`;
    document.body.appendChild(modal);
    modal.querySelector("#copy-pw").addEventListener("click", () => {
      navigator.clipboard.writeText(data.data.newPassword);
      showToast("Đã sao chép mật khẩu", "info");
    });
  } else {
    showToast(data.message, "error");
  }
}

export async function renderUsers(container) {
  container.innerHTML = `
    <div class="page-header">
      <div><h1>👥 Quản lý Người dùng</h1><p>Quản lý tài khoản và ví người dùng</p></div>
    </div>
    <div class="table-card">
      <div class="table-header">
        <h3>Danh sách người dùng</h3>
        <div class="table-actions">
          <input type="text" class="search-input" id="user-search" placeholder="🔍 Tìm theo tên, SĐT, MSSV..." value="${searchQuery}" />
        </div>
      </div>
      <div id="users-table-body"><div class="loading"><div class="spinner"></div>Đang tải...</div></div>
    </div>`;

  document.getElementById("user-search").addEventListener("input", (e) => {
    searchQuery = e.target.value;
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => { currentPage = 1; loadUsers(container); }, 400);
  });
  await loadUsers(container);
}

async function loadUsers(container) {
  const tbody = document.getElementById("users-table-body");
  const { ok, data } = await api.getUsers(currentPage, searchQuery);
  if (!ok) { tbody.innerHTML = `<div class="empty-state"><p>Không thể tải dữ liệu</p></div>`; return; }

  const users = data.data.users;
  const pg = data.data.pagination;

  if (users.length === 0) {
    tbody.innerHTML = `<div class="empty-state"><div class="empty-icon">🔍</div><p>Không tìm thấy người dùng nào</p></div>`;
    return;
  }

  tbody.innerHTML = `
    <div style="overflow-x:auto">
      <table>
        <thead><tr>
          <th>Họ tên</th><th>SĐT</th><th>MSSV</th><th>Số dư</th><th>Tài khoản</th><th>Ví</th><th>Xác thực</th><th>Thao tác</th>
        </tr></thead>
        <tbody>${users.map(u => `
          <tr>
            <td><strong>${u.fullName}</strong></td>
            <td>${u.phone}</td>
            <td>${u.studentId || '<span style="color:var(--text-muted)">—</span>'}</td>
            <td style="font-weight:600;color:var(--success)">${u.wallet ? (u.wallet.balance || 0).toLocaleString("vi-VN") + "₫" : "—"}</td>
            <td>${u.isActive ? '<span class="badge badge-success">Hoạt động</span>' : '<span class="badge badge-danger">Bị khoá</span>'}</td>
            <td>${u.wallet ? (u.wallet.status === "active" ? '<span class="badge badge-success">Active</span>' : '<span class="badge badge-danger">Locked</span>') : '<span class="badge badge-muted">N/A</span>'}</td>
            <td>${u.isVerified ? '<span class="badge badge-success">✓</span>' : '<span class="badge badge-warning">✗</span>'}</td>
            <td>
              <div class="actions">
                <button class="btn-icon" title="Chi tiết" data-action="detail" data-id="${u._id}">👁️</button>
                ${u.isActive
                  ? `<button class="btn-icon" title="Khoá TK" data-action="lock-user" data-id="${u._id}" data-name="${u.fullName}">🔒</button>`
                  : `<button class="btn-icon" title="Mở khoá TK" data-action="unlock-user" data-id="${u._id}" data-name="${u.fullName}">🔓</button>`}
                ${u.wallet ? (u.wallet.status === "active"
                  ? `<button class="btn-icon" title="Khoá ví" data-action="lock-wallet" data-id="${u._id}">💳</button>`
                  : `<button class="btn-icon" title="Mở ví" data-action="unlock-wallet" data-id="${u._id}">💰</button>`) : ""}
                <button class="btn-icon" title="Reset MK" data-action="reset-pw" data-id="${u._id}" data-name="${u.fullName}">🔑</button>
              </div>
            </td>
          </tr>`).join("")}
        </tbody>
      </table>
    </div>
    <div class="pagination">
      <button ${currentPage <= 1 ? "disabled" : ""} id="pg-prev">← Trước</button>
      <span class="page-info">Trang ${pg.page} / ${pg.totalPages} (${pg.total} người dùng)</span>
      <button ${currentPage >= pg.totalPages ? "disabled" : ""} id="pg-next">Sau →</button>
    </div>`;

  // Event delegation
  tbody.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-action]");
    if (!btn) return;
    const action = btn.dataset.action;
    const id = btn.dataset.id;
    const name = btn.dataset.name;
    const user = users.find(u => u._id === id);

    switch (action) {
      case "detail": if (user) showUserDetail(user); break;
      case "lock-user": handleLockUser(id, name, container); break;
      case "unlock-user": handleUnlockUser(id, name, container); break;
      case "lock-wallet": handleLockWallet(id, container); break;
      case "unlock-wallet": handleUnlockWallet(id, container); break;
      case "reset-pw": handleResetPassword(id, name); break;
    }
  });

  document.getElementById("pg-prev")?.addEventListener("click", () => { currentPage--; loadUsers(container); });
  document.getElementById("pg-next")?.addEventListener("click", () => { currentPage++; loadUsers(container); });
}
