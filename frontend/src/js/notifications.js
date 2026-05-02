import { api } from "./api.js";
import { showToast } from "./auth.js";

export function renderNotifications(container) {
  container.innerHTML = `
    <div class="header">
      <div>
        <h2>Quản lý Thông báo</h2>
        <p class="subtitle">Gửi thông báo đến tất cả sinh viên</p>
      </div>
    </div>
    
    <div class="card form-card">
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
        </div>
        
        <div class="form-actions">
          <button type="submit" class="btn btn-primary" id="btn-send-notif">
            Gửi Thông Báo
          </button>
        </div>
      </form>
    </div>
  `;

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
    btn.textContent = "Đang gửi...";
    btn.disabled = true;

    try {
      const res = await api.createNotification(title, message, link, file);
      if (res.ok) {
        showToast("Đã gửi thông báo thành công", "success");
        document.getElementById("notification-form").reset();
      } else {
        showToast(res.data?.message || "Lỗi khi gửi thông báo", "error");
      }
    } catch (error) {
      showToast("Lỗi kết nối", "error");
    } finally {
      btn.textContent = originalText;
      btn.disabled = false;
    }
  });
}
