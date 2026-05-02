import { api } from "./api.js";
import { showToast } from "./auth.js";

let notifications = [];
let editingId = null;

export async function renderNotifications(container) {
  container.innerHTML = `
    <div class="header">
      <div>
        <h2>Quản lý Thông báo</h2>
        <p class="subtitle">Gửi thông báo đến tất cả sinh viên</p>
      </div>
    </div>
    
    <div class="layout-2col" style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
      <div class="card form-card">
        <h3 id="form-title" style="margin-top: 0">Tạo thông báo mới</h3>
        <form id="notification-form" class="service-form">
          <div class="form-group">
            <label for="notif-title">Tiêu đề thông báo *</label>
            <input type="text" id="notif-title" required placeholder="Nhập tiêu đề">
          </div>
          
          <div class="form-group">
            <label for="notif-message">Nội dung chi tiết *</label>
            <textarea id="notif-message" rows="5" required placeholder="Nhập nội dung thông báo"></textarea>
          </div>
          
          <div class="form-group">
            <label for="notif-link">Đường dẫn đính kèm (Tuỳ chọn)</label>
            <input type="url" id="notif-link" placeholder="https://...">
          </div>
          
          <div class="form-group">
            <label for="notif-file">File đính kèm (.docx) (Tuỳ chọn)</label>
            <input type="file" id="notif-file" accept=".docx,application/vnd.openxmlformats-officedocument.wordprocessingml.document">
            <small id="notif-file-help" style="color: #666; display: none;">Để trống nếu không muốn thay đổi file cũ</small>
          </div>
          
          <div class="form-actions" style="display: flex; gap: 10px;">
            <button type="submit" class="btn btn-primary" id="btn-send-notif">
              Gửi Thông Báo
            </button>
            <button type="button" class="btn btn-secondary" id="btn-cancel-edit" style="display: none;">
              Huỷ
            </button>
          </div>
        </form>
      </div>
      
      <div class="card list-card">
        <h3 style="margin-top: 0">Danh sách thông báo</h3>
        <div class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>Tiêu đề</th>
                <th>Ngày tạo</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody id="notifications-tbody">
              <tr><td colspan="3" style="text-align: center;">Đang tải...</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `;

  await loadNotifications();

  document.getElementById("notification-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    
    const title = document.getElementById("notif-title").value.trim();
    const message = document.getElementById("notif-message").value.trim();
    const link = document.getElementById("notif-link").value.trim();
    const fileInput = document.getElementById("notif-file");
    const file = fileInput.files[0];

    if (!title || !message) {
      return showToast("Vui lòng nhập tiêu đề và nội dung", "error");
    }

    const btn = document.getElementById("btn-send-notif");
    const originalText = btn.textContent;
    btn.textContent = "Đang xử lý...";
    btn.disabled = true;

    try {
      let res;
      if (editingId) {
        res = await api.updateNotification(editingId, title, message, link, file);
      } else {
        res = await api.createNotification(title, message, link, file);
      }
      
      if (res.ok) {
        showToast(editingId ? "Cập nhật thành công" : "Đã gửi thông báo thành công", "success");
        resetForm();
        await loadNotifications();
      } else {
        showToast(res.data?.message || "Lỗi khi lưu thông báo", "error");
      }
    } catch (error) {
      showToast("Lỗi kết nối", "error");
    } finally {
      btn.textContent = originalText;
      btn.disabled = false;
    }
  });

  document.getElementById("btn-cancel-edit").addEventListener("click", resetForm);

  document.getElementById("notifications-tbody").addEventListener("click", async (e) => {
    const btnEdit = e.target.closest(".btn-edit");
    const btnDelete = e.target.closest(".btn-delete");

    if (btnEdit) {
      const id = btnEdit.dataset.id;
      editNotification(id);
    } else if (btnDelete) {
      const id = btnDelete.dataset.id;
      if (confirm("Bạn có chắc chắn muốn xoá thông báo này?")) {
        try {
          const res = await api.deleteNotification(id);
          if (res.ok) {
            showToast("Đã xoá thông báo", "success");
            if (editingId === id) resetForm();
            await loadNotifications();
          } else {
            showToast(res.data?.message || "Lỗi khi xoá", "error");
          }
        } catch (error) {
          showToast("Lỗi kết nối", "error");
        }
      }
    }
  });
}

async function loadNotifications() {
  try {
    const res = await api.getNotificationsAdmin();
    if (res.ok) {
      notifications = res.data.data;
      renderTable();
    }
  } catch (error) {
    console.error(error);
  }
}

function renderTable() {
  const tbody = document.getElementById("notifications-tbody");
  if (!notifications.length) {
    tbody.innerHTML = '<tr><td colspan="3" style="text-align: center;">Chưa có thông báo nào</td></tr>';
    return;
  }
  
  tbody.innerHTML = notifications.map(notif => `
    <tr>
      <td>
        <div style="font-weight: 500">${notif.title}</div>
        <div style="font-size: 12px; color: #666; max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
          ${notif.message}
        </div>
      </td>
      <td>${new Date(notif.createdAt).toLocaleDateString("vi-VN")}</td>
      <td>
        <div class="action-buttons">
          <button class="btn-icon btn-edit" data-id="${notif._id}" title="Sửa">✏️</button>
          <button class="btn-icon btn-delete" data-id="${notif._id}" title="Xoá">🗑️</button>
        </div>
      </td>
    </tr>
  `).join("");
}

function editNotification(id) {
  const notif = notifications.find(n => n._id === id);
  if (!notif) return;
  
  editingId = id;
  document.getElementById("form-title").textContent = "Sửa thông báo";
  document.getElementById("btn-send-notif").textContent = "Cập nhật";
  document.getElementById("btn-cancel-edit").style.display = "inline-block";
  document.getElementById("notif-file-help").style.display = "block";
  
  document.getElementById("notif-title").value = notif.title || "";
  document.getElementById("notif-message").value = notif.message || "";
  document.getElementById("notif-link").value = notif.link || "";
  document.getElementById("notif-file").value = "";
}

function resetForm() {
  editingId = null;
  document.getElementById("form-title").textContent = "Tạo thông báo mới";
  document.getElementById("btn-send-notif").textContent = "Gửi Thông Báo";
  document.getElementById("btn-cancel-edit").style.display = "none";
  document.getElementById("notif-file-help").style.display = "none";
  document.getElementById("notification-form").reset();
}
