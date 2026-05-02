import { Router } from "express";
import multer from "multer";
import {
  getDashboard,
  getUsers,
  getUserDetail,
  lockUser,
  unlockUser,
  lockWallet,
  unlockWallet,
  resetPassword,
  getStudents,
  importStudents,
  updateCohortStatus,
  deleteStudent,
  deleteStudentsBulk,
  getServices,
  createService,
  deleteService,
  exportServicePayments,
  getNotificationsAdmin,
  createNotification,
  updateNotification,
  deleteNotification
} from "../controllers/admin.controller.js";
import { protect, adminOnly } from "../middlewares/auth.middleware.js";

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    if (
      file.mimetype ===
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
      file.mimetype === "application/vnd.ms-excel"
    ) {
      cb(null, true);
    } else {
      cb(new Error("Chỉ chấp nhận file Excel (.xlsx, .xls)"));
    }
  },
});

const uploadDoc = multer({
  storage: multer.memoryStorage(), // We will save to disk in controller
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    if (
      file.mimetype === "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ||
      file.originalname.endsWith('.docx')
    ) {
      cb(null, true);
    } else {
      cb(new Error("Chỉ chấp nhận file .docx"));
    }
  },
});

// Tất cả routes đều yêu cầu admin
router.use(protect, adminOnly);

// Dashboard
router.get("/dashboard", getDashboard);

// Quản lý người dùng / ví
router.get("/users", getUsers);
router.get("/users/:id", getUserDetail);
router.patch("/users/:id/lock", lockUser);
router.patch("/users/:id/unlock", unlockUser);
router.patch("/users/:id/lock-wallet", lockWallet);
router.patch("/users/:id/unlock-wallet", unlockWallet);
router.patch("/users/:id/reset-password", resetPassword);

// Quản lý sinh viên
router.get("/students", getStudents);
router.post("/students/import", upload.single("file"), importStudents);
router.patch("/students/cohort-status", updateCohortStatus);
router.delete("/students/bulk", deleteStudentsBulk);
router.delete("/students/:id", deleteStudent);

// Quản lý dịch vụ
router.get("/services", getServices);
router.post("/services", createService);
router.get("/services/:id/payments/export", exportServicePayments);
router.put("/services/:id", updateService);
router.delete("/services/:id", deleteService);

// Quản lý thông báo
router.get("/notifications", getNotificationsAdmin);
router.post("/notifications", uploadDoc.single("file"), createNotification);
router.put("/notifications/:id", uploadDoc.single("file"), updateNotification);
router.delete("/notifications/:id", deleteNotification);

export default router;
