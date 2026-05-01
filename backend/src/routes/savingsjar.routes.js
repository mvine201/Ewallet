import { Router } from "express";
import {
  getSavingsJars,
  getSavingsJarDetail,
  createSavingsJar,
  updateSavingsJar,
  depositToJar,
  withdrawFromJar,
  deleteSavingsJar,
} from "../controllers/savingsjar.controller.js";
import { protect } from "../middlewares/auth.middleware.js";

const router = Router();

// Tất cả routes đều yêu cầu đăng nhập
router.use(protect);

// CRUD
router.get("/", getSavingsJars);
router.post("/", createSavingsJar);
router.get("/:id", getSavingsJarDetail);
router.put("/:id", updateSavingsJar);

// Nạp / Rút tiền
router.post("/:id/deposit", depositToJar);
router.post("/:id/withdraw", withdrawFromJar);

// Huỷ hũ
router.delete("/:id", deleteSavingsJar);

export default router;
