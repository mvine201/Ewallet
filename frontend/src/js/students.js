import { api } from "./api.js";
import { showToast } from "./auth.js";

let currentPage = 1;
let searchQuery = "";
let selectedCohort = "";
let selectedFaculty = "";
let selectedStatus = "";
let searchTimeout = null;
let filterOptions = { cohorts: [], faculties: [] };
let selectedStudentIds = new Set();

const STATUS_LABEL = {
  studying: "Đang học",
  graduated: "Đã tốt nghiệp",
};

export async function renderStudents(container) {
  container.innerHTML = `
    <div class="page-header">
      <div><h1>🎓 Quản lý Sinh viên</h1><p>Quản lý sinh viên theo khoá, khoa và trạng thái học tập</p></div>
    </div>
    <div class="upload-area" id="upload-zone">
      <div class="upload-icon">📂</div>
      <p>Kéo thả file Excel vào đây hoặc <strong>nhấn để chọn file</strong></p>
      <p class="upload-hint">Hỗ trợ .xlsx — Cột: MSSV, Họ tên, Ngày sinh, Email, Khoa, Lớp. Khoá được tự tách từ 2 số đầu MSSV, ví dụ 28211... là K28.</p>
      <input type="file" id="excel-input" accept=".xlsx,.xls" style="display:none" />
    </div>
    <div id="import-result" style="display:none;margin-bottom:20px"></div>
    <div class="table-card">
      <div class="table-header">
        <h3>Danh sách sinh viên</h3>
        <div class="table-actions" style="flex-wrap:wrap">
          <input type="text" class="search-input" id="student-search" placeholder="🔍 Tìm MSSV, tên, khoa..." value="${searchQuery}" />
          <select class="form-select" id="cohort-filter" style="width:auto;min-width:120px"></select>
          <select class="form-select" id="faculty-filter" style="width:auto;min-width:180px"></select>
          <select class="form-select" id="status-filter" style="width:auto;min-width:140px">
            <option value="">Tất cả trạng thái</option>
            <option value="studying" ${selectedStatus === "studying" ? "selected" : ""}>Đang học</option>
            <option value="graduated" ${selectedStatus === "graduated" ? "selected" : ""}>Đã tốt nghiệp</option>
          </select>
          <button class="btn btn-warning btn-sm" id="graduate-btn">Đánh dấu tốt nghiệp</button>
          <button class="btn btn-outline btn-sm" id="studying-btn">Mở lại đang học</button>
          <button class="btn btn-danger btn-sm" id="bulk-delete-btn" disabled>Xoá đã chọn</button>
        </div>
      </div>
      <div id="students-table-body"><div class="loading"><div class="spinner"></div>Đang tải...</div></div>
    </div>`;

  setupControls(container);
  await loadStudents(container);
}

function setupControls(container) {
  const zone = document.getElementById("upload-zone");
  const fileInput = document.getElementById("excel-input");

  zone.addEventListener("click", () => fileInput.click());
  zone.addEventListener("dragover", (e) => {
    e.preventDefault();
    zone.classList.add("dragover");
  });
  zone.addEventListener("dragleave", () => zone.classList.remove("dragover"));
  zone.addEventListener("drop", (e) => {
    e.preventDefault();
    zone.classList.remove("dragover");
    handleFile(e.dataTransfer.files[0], container);
  });
  fileInput.addEventListener("change", (e) => {
    if (e.target.files[0]) handleFile(e.target.files[0], container);
  });

  document.getElementById("student-search").addEventListener("input", (e) => {
    searchQuery = e.target.value;
    selectedStudentIds.clear();
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
      currentPage = 1;
      loadStudents(container);
    }, 400);
  });

  document.getElementById("cohort-filter").addEventListener("change", (e) => {
    selectedCohort = e.target.value;
    selectedStudentIds.clear();
    currentPage = 1;
    loadStudents(container);
  });

  document.getElementById("faculty-filter").addEventListener("change", (e) => {
    selectedFaculty = e.target.value;
    selectedStudentIds.clear();
    currentPage = 1;
    loadStudents(container);
  });

  document.getElementById("status-filter").addEventListener("change", (e) => {
    selectedStatus = e.target.value;
    selectedStudentIds.clear();
    currentPage = 1;
    loadStudents(container);
  });

  document.getElementById("graduate-btn").addEventListener("click", () => {
    updateSelectedScopeStatus("graduated", container);
  });

  document.getElementById("studying-btn").addEventListener("click", () => {
    updateSelectedScopeStatus("studying", container);
  });

  document.getElementById("bulk-delete-btn").addEventListener("click", () => {
    deleteSelectedStudents(container);
  });

  const tbody = document.getElementById("students-table-body");
  tbody.addEventListener("change", (e) => {
    if (e.target.matches("#select-all-students")) {
      const checked = e.target.checked;
      tbody.querySelectorAll(".student-checkbox").forEach((checkbox) => {
        checkbox.checked = checked;
        if (checked) {
          selectedStudentIds.add(checkbox.value);
        } else {
          selectedStudentIds.delete(checkbox.value);
        }
      });
      updateBulkDeleteButton();
      return;
    }

    if (e.target.matches(".student-checkbox")) {
      if (e.target.checked) {
        selectedStudentIds.add(e.target.value);
      } else {
        selectedStudentIds.delete(e.target.value);
      }
      syncSelectAllState();
      updateBulkDeleteButton();
    }
  });

  tbody.addEventListener("click", async (e) => {
    const btn = e.target.closest("[data-action='delete']");
    if (!btn) return;
    await deleteStudents([btn.dataset.id], `Xoá sinh viên "${btn.dataset.name}"?`, container);
  });
}

async function handleFile(file, container) {
  if (!file) return;
  const resultDiv = document.getElementById("import-result");
  resultDiv.style.display = "block";
  resultDiv.innerHTML = `<div class="loading"><div class="spinner"></div>Đang import...</div>`;

  const { ok, data } = await api.importStudents(file);
  if (ok) {
    resultDiv.innerHTML = `
      <div style="background:rgba(0,206,201,0.08);border:1px solid rgba(0,206,201,0.2);border-radius:var(--radius-sm);padding:16px">
        <p style="color:var(--success);font-weight:600;margin-bottom:8px">✅ ${data.message}</p>
        <p style="color:var(--text-secondary);font-size:0.85rem">Mới: ${data.data.imported} | Cập nhật: ${data.data.updated} | Tổng xử lý: ${data.data.totalProcessed}</p>
        ${data.data.errors.length ? `<p style="color:var(--warning);font-size:0.8rem;margin-top:8px">⚠️ Lỗi: ${data.data.errors.join(", ")}</p>` : ""}
      </div>`;
    showToast(data.message, "success");
    currentPage = 1;
    loadStudents(container);
  } else {
    resultDiv.innerHTML = `
      <div style="background:rgba(255,107,107,0.08);border:1px solid rgba(255,107,107,0.2);border-radius:var(--radius-sm);padding:16px">
        <p style="color:var(--danger);font-weight:600">❌ ${data.message}</p>
      </div>`;
    showToast(data.message, "error");
  }
}

async function updateSelectedScopeStatus(academicStatus, container) {
  if (!selectedCohort) {
    showToast("Vui lòng chọn một khoá trước khi cập nhật trạng thái", "error");
    return;
  }

  const statusText = STATUS_LABEL[academicStatus];
  const scopeText = selectedFaculty ? `${selectedCohort} - ${selectedFaculty}` : selectedCohort;
  const okToUpdate = confirm(`Cập nhật tất cả sinh viên thuộc ${scopeText} sang trạng thái "${statusText}"?`);
  if (!okToUpdate) return;

  const { ok, data } = await api.updateCohortStatus({
    cohort: selectedCohort,
    faculty: selectedFaculty,
    academicStatus,
  });

  showToast(data.message, ok ? "success" : "error");
  if (ok) loadStudents(container);
}

async function deleteSelectedStudents(container) {
  const ids = [...selectedStudentIds];
  if (!ids.length) {
    showToast("Vui lòng chọn sinh viên cần xoá", "error");
    return;
  }

  await deleteStudents(ids, `Xoá ${ids.length} sinh viên đã chọn?`, container);
}

async function deleteStudents(ids, confirmMessage, container) {
  if (!ids.length) return;
  if (!confirm(confirmMessage)) return;

  const { ok, data } = ids.length === 1
    ? await api.deleteStudent(ids[0])
    : await api.deleteStudentsBulk(ids);

  showToast(data.message, ok ? "success" : "error");
  if (ok) {
    ids.forEach((id) => selectedStudentIds.delete(id));
    await loadStudents(container);
  }
}

async function loadStudents(container) {
  const tbody = document.getElementById("students-table-body");
  const { ok, data } = await api.getStudents(
    currentPage,
    searchQuery,
    selectedCohort,
    selectedFaculty,
    selectedStatus
  );

  if (!ok) {
    tbody.innerHTML = `<div class="empty-state"><p>Không thể tải dữ liệu</p></div>`;
    return;
  }

  filterOptions = data.data.filterOptions || filterOptions;
  renderFilterOptions();

  const students = data.data.students;
  const pg = data.data.pagination;

  if (!students.length) {
    tbody.innerHTML = `<div class="empty-state"><div class="empty-icon">🎓</div><p>Không có sinh viên phù hợp với bộ lọc hiện tại.</p></div>`;
    updateBulkDeleteButton();
    return;
  }

  tbody.innerHTML = `
    <div style="overflow-x:auto">
      <table>
        <thead><tr><th><input type="checkbox" id="select-all-students" /></th><th>MSSV</th><th>Khoá</th><th>Họ tên</th><th>Ngày sinh</th><th>Email</th><th>Khoa</th><th>Lớp</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
        <tbody>${students.map(s => `
          <tr>
            <td><input type="checkbox" class="student-checkbox" value="${s._id}" ${selectedStudentIds.has(s._id) ? "checked" : ""} /></td>
            <td><strong>${s.studentId}</strong></td>
            <td><span class="badge badge-info">${s.cohort || deriveCohort(s.studentId) || "—"}</span></td>
            <td>${s.fullName}</td>
            <td>${s.dateOfBirth}</td>
            <td>${s.email || "—"}</td>
            <td>${s.faculty || "—"}</td>
            <td>${s.className || "—"}</td>
            <td>${statusBadge(s.academicStatus)}</td>
            <td><button class="btn-icon" title="Xoá" data-action="delete" data-id="${s._id}" data-name="${s.fullName}">🗑️</button></td>
          </tr>`).join("")}
        </tbody>
      </table>
    </div>
    <div class="pagination">
      <button ${currentPage <= 1 ? "disabled" : ""} id="spg-prev">← Trước</button>
      <span class="page-info">Trang ${pg.page} / ${pg.totalPages} (${pg.total} sinh viên)</span>
      <button ${currentPage >= pg.totalPages ? "disabled" : ""} id="spg-next">Sau →</button>
    </div>`;

  syncSelectAllState();
  updateBulkDeleteButton();

  document.getElementById("spg-prev")?.addEventListener("click", () => {
    selectedStudentIds.clear();
    currentPage--;
    loadStudents(container);
  });
  document.getElementById("spg-next")?.addEventListener("click", () => {
    selectedStudentIds.clear();
    currentPage++;
    loadStudents(container);
  });
}

function updateBulkDeleteButton() {
  const button = document.getElementById("bulk-delete-btn");
  if (!button) return;
  const count = selectedStudentIds.size;
  button.disabled = count === 0;
  button.textContent = count ? `Xoá đã chọn (${count})` : "Xoá đã chọn";
}

function syncSelectAllState() {
  const selectAll = document.getElementById("select-all-students");
  if (!selectAll) return;

  const checkboxes = [...document.querySelectorAll(".student-checkbox")];
  const checkedCount = checkboxes.filter((checkbox) => checkbox.checked).length;
  selectAll.checked = checkboxes.length > 0 && checkedCount === checkboxes.length;
  selectAll.indeterminate = checkedCount > 0 && checkedCount < checkboxes.length;
}

function renderFilterOptions() {
  const cohortFilter = document.getElementById("cohort-filter");
  const facultyFilter = document.getElementById("faculty-filter");

  cohortFilter.innerHTML = `
    <option value="">Tất cả khoá</option>
    ${filterOptions.cohorts.map(cohort => `<option value="${cohort}" ${selectedCohort === cohort ? "selected" : ""}>${cohort}</option>`).join("")}
  `;

  facultyFilter.innerHTML = `
    <option value="">Tất cả khoa</option>
    ${filterOptions.faculties.map(faculty => `<option value="${faculty}" ${selectedFaculty === faculty ? "selected" : ""}>${faculty}</option>`).join("")}
  `;
}

function deriveCohort(studentId) {
  const match = String(studentId || "").trim().match(/^(\d{2})/);
  return match ? `K${match[1]}` : "";
}

function statusBadge(status) {
  if (status === "graduated") {
    return `<span class="badge badge-danger">Đã tốt nghiệp</span>`;
  }
  return `<span class="badge badge-success">Đang học</span>`;
}
