import { Router } from "express";
import { setPin, lookupReceiver, transfer } from "../controllers/transfer.controller.js";
import { protect } from "../middlewares/auth.middleware.js";

const router = Router();

router.post("/pin", protect, setPin);             // Thiết lập PIN
router.get("/lookup", protect, lookupReceiver);   // Tìm người nhận
router.post("/", protect, transfer);              // Chuyển tiền

export default router;
