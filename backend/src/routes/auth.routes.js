import { Router } from "express";
import {
  register,
  login,
  verifyStudent,
  changePassword,
  getMe,
} from "../controllers/auth.controller.js";
import { protect } from "../middlewares/auth.middleware.js";

const router = Router();

router.post("/register", register);
router.post("/login", login);
router.post("/verify-student", protect, verifyStudent); // cần đăng nhập trước
router.post("/change-password", protect, changePassword);
router.get("/me", protect, getMe);

export default router;
