import { Router } from "express";
import { getNotifications, markAsRead } from "../controllers/notification.controller.js";
import { protect } from "../middlewares/auth.middleware.js";

const router = Router();

// Yêu cầu đăng nhập
router.use(protect);

router.get("/", getNotifications);
router.put("/:id/read", markAsRead);

export default router;
