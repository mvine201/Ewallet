import { api } from "./api.js";
import { showToast } from "./auth.js";

const SERVICE_TYPES = [
  { value: "tuition", label: "Học phí", icon: "📚" },
  { value: "parking", label: "Phí giữ xe", icon: "🏍️" },
  { value: "canteen", label: "Phí căn tin", icon: "🍜" },
  { value: "union_fee", label: "Đoàn phí", icon: "🏫" },
  { value: "library", label: "Thư viện", icon: "📖" },
  { value: "dormitory", label: "Ký túc xá", icon: "🏠" },
  { value: "insurance", label: "Bảo hiểm", icon: "🛡️" },
  { value: "other", label: "Khác", icon: "💳" },
];

const CATEGORY_LABEL = {
  internal: "Nội bộ nhà trường",
  external: "Dịch vụ ngoài",
};

const SCOPE_LABEL = {
  school: "Toàn trường",
  cohort: "Theo khoá",
  faculty: "Theo khoa",
  cohort_faculty: "Theo khoá và khoa",
};

let currentServices = [];

function closeModal() {
  const m = document.querySelector(".modal-overlay");
  if (m) m.remove();
}

function formatMoney(n) {
  return (Number(n) || 0).toLocaleString("vi-VN") + "₫";
}

function dateInputValue(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const pad = (n) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function serviceTypeLabel(type) {
  return SERVICE_TYPES.find((item) => item.value === type)?.label || type;
}

function showServiceModal(service, onSave) {
  closeModal();
  const isEdit = Boolean(service);
  const s = service || {};
  const paymentWindow = s.paymentWindow || {};
  const parkingConfig = s.parkingConfig || {};
  const modal = document.createElement("div");
  modal.className = "modal-overlay";
  modal.innerHTML = `
    <div class="modal" style="width:760px;max-height:90vh;overflow-y:auto">
      <h2>${isEdit ? "✏️ Sửa dịch vụ" : "➕ Thêm dịch vụ mới"}</h2>
      <form id="service-form">
        <div class="detail-grid">
          <div class="form-group">
            <label>Tên dịch vụ *</label>
            <input class="form-input" id="svc-name" value="${s.name || ""}" placeholder="VD: Học phí học kỳ 1 K28 CNTT" required />
          </div>
          <div class="form-group">
            <label>Icon</label>
            <input class="form-input" id="svc-icon" value="${s.icon || "💳"}" />
          </div>
          <div class="form-group">
            <label>Nhóm dịch vụ *</label>
            <select class="form-select" id="svc-category">
              <option value="internal" ${s.category !== "external" ? "selected" : ""}>Nội bộ nhà trường</option>
              <option value="external" ${s.category === "external" ? "selected" : ""}>Dịch vụ ngoài</option>
            </select>
          </div>
          <div class="form-group">
            <label>Loại dịch vụ *</label>
            <select class="form-select" id="svc-type">
              ${SERVICE_TYPES.map(t => `<option value="${t.value}" ${s.type === t.value ? "selected" : ""}>${t.icon} ${t.label}</option>`).join("")}
            </select>
          </div>
          <div class="form-group">
            <label>Phạm vi áp dụng</label>
            <select class="form-select" id="svc-scope">
              <option value="school" ${(s.scopeType || "school") === "school" ? "selected" : ""}>Toàn trường</option>
              <option value="cohort" ${s.scopeType === "cohort" ? "selected" : ""}>Theo khoá</option>
              <option value="faculty" ${s.scopeType === "faculty" ? "selected" : ""}>Theo khoa</option>
              <option value="cohort_faculty" ${s.scopeType === "cohort_faculty" ? "selected" : ""}>Theo khoá và khoa</option>
            </select>
          </div>
          <div class="form-group">
            <label>Giá mặc định (VNĐ)</label>
            <input class="form-input" id="svc-price" type="number" value="${s.price || 0}" min="0" />
          </div>
          <div class="form-group" id="cohort-group">
            <label>Khoá áp dụng</label>
            <input class="form-input" id="svc-cohorts" value="${(s.applicableCohorts || []).join(", ")}" placeholder="VD: K28, K29" />
          </div>
          <div class="form-group" id="faculty-group">
            <label>Khoa áp dụng</label>
            <input class="form-input" id="svc-faculties" value="${(s.applicableFaculties || []).join(", ")}" placeholder="VD: Công nghệ thông tin, Kế toán" />
          </div>
        </div>

        <div class="form-group">
          <label>Mô tả</label>
          <input class="form-input" id="svc-desc" value="${s.description || ""}" placeholder="Mô tả ngắn..." />
        </div>

        <div id="tuition-section" style="display:none;background:var(--bg-glass);border:1px solid var(--border-glass);border-radius:var(--radius-sm);padding:16px;margin-bottom:20px">
          <h3 style="font-size:1rem;margin-bottom:14px">Cấu hình học phí</h3>
          <div class="detail-grid">
            <div class="form-group">
              <label>Bắt đầu nộp</label>
              <input class="form-input" id="svc-start" type="datetime-local" value="${dateInputValue(paymentWindow.startAt)}" />
            </div>
            <div class="form-group">
              <label>Hạn cuối</label>
              <input class="form-input" id="svc-end" type="datetime-local" value="${dateInputValue(paymentWindow.endAt)}" />
            </div>
          </div>
          <div class="form-group">
            <label>Ngày nhắc trước hạn</label>
            <input class="form-input" id="svc-reminders" value="${(paymentWindow.reminderDaysBeforeDue || [5, 3, 1]).join(", ")}" placeholder="VD: 5, 3, 1" />
          </div>
        </div>

        <div id="parking-section" style="display:none;background:var(--bg-glass);border:1px solid var(--border-glass);border-radius:var(--radius-sm);padding:16px;margin-bottom:20px">
          <h3 style="font-size:1rem;margin-bottom:14px">Cấu hình phí giữ xe</h3>
          <div class="detail-grid">
            <div class="form-group">
              <label>Giá mỗi lượt (VNĐ)</label>
              <input class="form-input" id="svc-parking-use" type="number" min="0" value="${parkingConfig.perUsePrice || 0}" />
            </div>
            <div class="form-group" style="display:flex;align-items:center;gap:10px;margin-top:28px">
              <input type="checkbox" id="svc-parking-monthly-enabled" ${parkingConfig.monthlyPassEnabled ? "checked" : ""} />
              <label for="svc-parking-monthly-enabled" style="margin:0">Có gói giữ xe theo tháng</label>
            </div>
            <div class="form-group">
              <label>Giá gói tháng (VNĐ)</label>
              <input class="form-input" id="svc-parking-monthly-price" type="number" min="0" value="${parkingConfig.monthlyPassPrice || 0}" />
            </div>
            <div class="form-group">
              <label>Mở bán từ ngày</label>
              <input class="form-input" id="svc-parking-day-from" type="number" min="1" max="31" value="${parkingConfig.monthlyPassOpenDayFrom || 1}" />
            </div>
            <div class="form-group">
              <label>Mở bán đến ngày</label>
              <input class="form-input" id="svc-parking-day-to" type="number" min="1" max="31" value="${parkingConfig.monthlyPassOpenDayTo || 5}" />
            </div>
          </div>
        </div>

        <div class="detail-grid">
          <div class="form-group" style="display:flex;align-items:center;gap:10px">
            <input type="checkbox" id="svc-verify" ${s.requireVerification !== false ? "checked" : ""} />
            <label for="svc-verify" style="margin:0">Yêu cầu xác thực sinh viên</label>
          </div>
          <div class="form-group" style="display:flex;align-items:center;gap:10px">
            <input type="checkbox" id="svc-active-student" ${s.requireActiveStudent !== false ? "checked" : ""} />
            <label for="svc-active-student" style="margin:0">Yêu cầu còn đang học</label>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline btn-sm" id="svc-cancel">Huỷ</button>
          <button type="submit" class="btn btn-primary btn-sm">${isEdit ? "Cập nhật" : "Thêm"}</button>
        </div>
      </form>
    </div>`;

  document.body.appendChild(modal);
  modal.querySelector("#svc-cancel").onclick = closeModal;
  modal.addEventListener("click", (e) => { if (e.target === modal) closeModal(); });

  const refreshDynamicSections = () => {
    const category = document.getElementById("svc-category").value;
    const type = document.getElementById("svc-type").value;
    const scope = document.getElementById("svc-scope").value;
    const isInternal = category === "internal";

    document.getElementById("svc-scope").disabled = !isInternal;
    document.getElementById("svc-active-student").disabled = !isInternal;
    document.getElementById("cohort-group").style.display = isInternal && ["cohort", "cohort_faculty"].includes(scope) ? "block" : "none";
    document.getElementById("faculty-group").style.display = isInternal && ["faculty", "cohort_faculty"].includes(scope) ? "block" : "none";
    document.getElementById("tuition-section").style.display = isInternal && type === "tuition" ? "block" : "none";
    document.getElementById("parking-section").style.display = isInternal && type === "parking" ? "block" : "none";
  };

  ["svc-category", "svc-type", "svc-scope"].forEach((id) => {
    document.getElementById(id).addEventListener("change", refreshDynamicSections);
  });
  refreshDynamicSections();

  modal.querySelector("#service-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const category = document.getElementById("svc-category").value;
    const payload = {
      name: document.getElementById("svc-name").value.trim(),
      category,
      type: document.getElementById("svc-type").value,
      scopeType: category === "internal" ? document.getElementById("svc-scope").value : "school",
      price: Number(document.getElementById("svc-price").value) || 0,
      icon: document.getElementById("svc-icon").value.trim() || "💳",
      description: document.getElementById("svc-desc").value.trim(),
      applicableCohorts: document.getElementById("svc-cohorts").value,
      applicableFaculties: document.getElementById("svc-faculties").value,
      requireVerification: document.getElementById("svc-verify").checked,
      requireActiveStudent: document.getElementById("svc-active-student").checked,
      paymentWindow: {
        startAt: document.getElementById("svc-start").value,
        endAt: document.getElementById("svc-end").value,
        reminderDaysBeforeDue: document.getElementById("svc-reminders").value
          .split(",")
          .map((n) => Number(n.trim()))
          .filter((n) => Number.isFinite(n) && n > 0),
      },
      parkingConfig: {
        perUsePrice: Number(document.getElementById("svc-parking-use").value) || 0,
        monthlyPassEnabled: document.getElementById("svc-parking-monthly-enabled").checked,
        monthlyPassPrice: Number(document.getElementById("svc-parking-monthly-price").value) || 0,
        monthlyPassOpenDayFrom: Number(document.getElementById("svc-parking-day-from").value) || 1,
        monthlyPassOpenDayTo: Number(document.getElementById("svc-parking-day-to").value) || 5,
      },
    };

    if (!payload.name) return showToast("Vui lòng nhập tên dịch vụ", "error");
    closeModal();
    await onSave(payload);
  });
}

export async function renderServices(container) {
  container.innerHTML = `
    <div class="page-header">
      <div><h1>⚡ Quản lý Dịch vụ</h1><p>Quản lý dịch vụ nội bộ, dịch vụ ngoài, học phí và phí giữ xe</p></div>
      <button class="btn btn-primary btn-sm" id="add-service-btn">➕ Thêm dịch vụ</button>
    </div>
    <div class="table-card">
      <div class="table-header"><h3>Danh sách dịch vụ</h3></div>
      <div id="services-table-body"><div class="loading"><div class="spinner"></div>Đang tải...</div></div>
    </div>`;

  document.getElementById("add-service-btn").addEventListener("click", () => {
    showServiceModal(null, async (payload) => {
      const { ok, data } = await api.createService(payload);
      showToast(data.message, ok ? "success" : "error");
      if (ok) loadServices(container);
    });
  });

  document.getElementById("services-table-body").addEventListener("click", async (e) => {
    const btn = e.target.closest("[data-action]");
    if (!btn) return;
    const id = btn.dataset.id;
    const action = btn.dataset.action;

    if (action === "edit") {
      const svc = currentServices.find(s => s._id === id);
      if (!svc) return;
      showServiceModal(svc, async (payload) => {
        const { ok, data } = await api.updateService(id, payload);
        showToast(data.message, ok ? "success" : "error");
        if (ok) loadServices(container);
      });
    } else if (action === "delete") {
      const name = btn.dataset.name;
      if (!confirm(`Vô hiệu hoá dịch vụ "${name}"?`)) return;
      const { ok, data } = await api.deleteService(id);
      showToast(data.message, ok ? "success" : "error");
      if (ok) loadServices(container);
    }
  });

  await loadServices(container);
}

async function loadServices(container) {
  const tbody = document.getElementById("services-table-body");
  const { ok, data } = await api.getServices();
  if (!ok) {
    tbody.innerHTML = `<div class="empty-state"><p>Không thể tải dữ liệu</p></div>`;
    return;
  }

  currentServices = data.data;
  if (!currentServices.length) {
    tbody.innerHTML = `<div class="empty-state"><div class="empty-icon">⚡</div><p>Chưa có dịch vụ nào. Hãy thêm dịch vụ mới!</p></div>`;
    return;
  }

  tbody.innerHTML = `
    <div style="overflow-x:auto">
      <table class="service-table">
        <thead><tr><th class="col-name">Dịch vụ</th><th class="col-badge">Nhóm</th><th class="col-badge">Loại</th><th class="col-scope">Phạm vi</th><th class="col-price">Giá/Cấu hình</th><th class="col-badge">Điều kiện</th><th class="col-badge">Trạng thái</th><th>Thao tác</th></tr></thead>
        <tbody>${currentServices.map(s => `
          <tr style="${!s.isActive ? 'opacity:0.5' : ''}">
            <td class="col-name"><div class="svc-name-cell"><span class="svc-icon">${s.icon || "💳"}</span><div class="svc-info"><strong>${s.name}</strong>${s.description ? `<span class="svc-desc">${s.description}</span>` : ""}</div></div></td>
            <td class="col-badge"><span class="badge ${s.category === "external" ? "badge-muted" : "badge-info"}">${CATEGORY_LABEL[s.category || "internal"]}</span></td>
            <td class="col-badge"><span class="badge badge-info">${serviceTypeLabel(s.type)}</span></td>
            <td class="col-scope">${scopeSummary(s)}</td>
            <td class="col-price">${priceSummary(s)}</td>
            <td class="col-badge">${conditionSummary(s)}</td>
            <td class="col-badge">${s.isActive ? '<span class="badge badge-success">Hoạt động</span>' : '<span class="badge badge-danger">Đã tắt</span>'}</td>
            <td>
              <div class="actions">
                <button class="btn-icon" title="Sửa" data-action="edit" data-id="${s._id}">✏️</button>
                ${s.isActive ? `<button class="btn-icon" title="Vô hiệu hoá" data-action="delete" data-id="${s._id}" data-name="${s.name}">🗑️</button>` : ""}
              </div>
            </td>
          </tr>`).join("")}
        </tbody>
      </table>
    </div>`;
}

function scopeSummary(service) {
  if (service.category === "external") return "Không giới hạn sinh viên";
  const scope = service.scopeType || "school";
  const parts = [SCOPE_LABEL[scope] || scope];
  if (service.applicableCohorts?.length) parts.push(service.applicableCohorts.join(", "));
  if (service.applicableFaculties?.length) parts.push(service.applicableFaculties.join(", "));
  return parts.join("<br>");
}

function priceSummary(service) {
  if (service.type === "parking") {
    const parking = service.parkingConfig || {};
    const lines = [`Lượt: ${formatMoney(parking.perUsePrice || service.price)}`];
    if (parking.monthlyPassEnabled) {
      lines.push(`Tháng: ${formatMoney(parking.monthlyPassPrice)}`);
      lines.push(`Mở ngày ${parking.monthlyPassOpenDayFrom || 1}-${parking.monthlyPassOpenDayTo || 5}`);
    }
    return lines.join("<br>");
  }

  if (service.type === "tuition") {
    const window = service.paymentWindow || {};
    const lines = [formatMoney(service.price)];
    if (window.startAt && window.endAt) {
      lines.push(`${new Date(window.startAt).toLocaleString("vi-VN")} - ${new Date(window.endAt).toLocaleString("vi-VN")}`);
    }
    if (window.reminderDaysBeforeDue?.length) {
      lines.push(`Nhắc trước: ${window.reminderDaysBeforeDue.join(", ")} ngày`);
    }
    return lines.join("<br>");
  }

  return formatMoney(service.price);
}

function conditionSummary(service) {
  const conditions = [];
  if (service.requireVerification) conditions.push("Cần xác thực SV");
  if (service.requireActiveStudent) conditions.push("Còn đang học");
  return conditions.length ? conditions.join("<br>") : "Không bắt buộc";
}
