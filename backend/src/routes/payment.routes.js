import { Router } from "express";
import {
  getAvailableServices,
  getMyPayments,
  getPaymentDetail,
  payService,
} from "../controllers/payment.controller.js";
import { protect } from "../middlewares/auth.middleware.js";

const router = Router();

// Tất cả routes đều yêu cầu đăng nhập
router.use(protect);

// Xem danh sách dịch vụ khả dụng (đã lọc theo khoá/khoa/trạng thái)
router.get("/services", getAvailableServices);

// Xem lịch sử thanh toán dịch vụ
router.get("/", getMyPayments);

// Chi tiết một khoản thanh toán
router.get("/:id", getPaymentDetail);

// Thanh toán dịch vụ
router.post("/pay", payService);

export default router;
