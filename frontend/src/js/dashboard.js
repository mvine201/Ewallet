import { api } from "./api.js";
import { showToast } from "./auth.js";

function fmt(n) {
  return (n || 0).toLocaleString("vi-VN");
}

export async function renderDashboard(container) {
  container.innerHTML = `<div class="loading"><div class="spinner"></div>Đang tải...</div>`;

  const { ok, data } = await api.getDashboard();
  if (!ok) {
    container.innerHTML = `<div class="empty-state"><p>Không thể tải dữ liệu</p></div>`;
    return;
  }
  const d = data.data;

  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1>📊 Dashboard</h1>
        <p>Tổng quan hệ thống ví điện tử sinh viên</p>
      </div>
    </div>
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon purple">👥</div>
        <div class="stat-value">${fmt(d.users.total)}</div>
        <div class="stat-label">Tổng người dùng</div>
        <div class="stat-detail">
          <span>✅ ${d.users.verified} đã xác thực</span>
          <span>⏳ ${d.users.unverified} chưa xác thực</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon green">💰</div>
        <div class="stat-value">${fmt(d.wallets.total)}</div>
        <div class="stat-label">Tổng ví</div>
        <div class="stat-detail">
          <span>🟢 ${d.wallets.active} hoạt động</span>
          <span>🔒 ${d.wallets.locked} bị khoá</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon blue">🎓</div>
        <div class="stat-value">${fmt(d.students.total)}</div>
        <div class="stat-label">Sinh viên trong hệ thống</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon orange">⚡</div>
        <div class="stat-value">${fmt(d.services.total)}</div>
        <div class="stat-label">Dịch vụ</div>
        <div class="stat-detail">
          <span>🟢 ${d.services.active} hoạt động</span>
        </div>
      </div>
    </div>
    <div class="stats-grid" style="grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));">
      <div class="stat-card">
        <div class="stat-icon green">💎</div>
        <div class="stat-value" style="font-size:1.4rem">${fmt(d.wallets.totalBalance)}₫</div>
        <div class="stat-label">Tổng số dư toàn hệ thống</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon purple">📝</div>
        <div class="stat-value">${fmt(d.transactions.total)}</div>
        <div class="stat-label">Tổng giao dịch</div>
      </div>
    </div>
    <div class="table-card">
      <div class="table-header">
        <h3>🕐 Giao dịch gần đây</h3>
      </div>
      <div style="overflow-x:auto">
        <table>
          <thead><tr>
            <th>Người dùng</th><th>Loại</th><th>Số tiền</th><th>Trạng thái</th><th>Thời gian</th>
          </tr></thead>
          <tbody>
            ${d.recentTransactions.length === 0
              ? `<tr><td colspan="5" style="text-align:center;color:var(--text-muted);padding:40px">Chưa có giao dịch</td></tr>`
              : d.recentTransactions.map(t => `
                <tr>
                  <td>${t.user?.fullName || "N/A"}</td>
                  <td><span class="badge badge-info">${t.type}</span></td>
                  <td style="font-weight:600">${fmt(t.amount)}₫</td>
                  <td><span class="badge ${t.status==="success"?"badge-success":t.status==="pending"?"badge-warning":"badge-danger"}">${t.status}</span></td>
                  <td style="color:var(--text-muted)">${new Date(t.createdAt).toLocaleString("vi-VN")}</td>
                </tr>`).join("")}
          </tbody>
        </table>
      </div>
    </div>
  `;
}
