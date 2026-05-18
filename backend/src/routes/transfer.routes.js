import { Router } from "express";
import { setPin, lookupReceiver, transfer } from "../controllers/transfer.controller.js";
import { protect, requireStudentVerification } from "../middlewares/auth.middleware.js";

const router = Router();

router.post("/pin", protect, requireStudentVerification, setPin);             // Thiết lập PIN
router.get("/lookup", protect, requireStudentVerification, lookupReceiver);   // Tìm người nhận
router.post("/", protect, requireStudentVerification, transfer);              // Chuyển tiền

export default router;
