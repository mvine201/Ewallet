import { Router } from "express";
import {
  createTopup,
  vnpayReturn,
  vnpayIPN,
  getTopupStatus,
  getMyWallet,
  getTransactions,
} from "../controllers/wallet.controller.js";
import { protect } from "../middlewares/auth.middleware.js";

const router = Router();

// Xem ví & lịch sử giao dịch
router.get("/me", protect, getMyWallet);
router.get("/transactions", protect, getTransactions);

// Nạp tiền VNPay
router.post("/topup", protect, createTopup);          // Bước 1: tạo URL
router.get("/topup/status/:orderId", protect, getTopupStatus);
router.get("/topup/vnpay-return", vnpayReturn);        // Bước 2: VNPay redirect về (FE xem kết quả)
router.get("/topup/vnpay-ipn", vnpayIPN);              // Bước 3: VNPay gọi server-to-server (cộng tiền thật)

export default router;
