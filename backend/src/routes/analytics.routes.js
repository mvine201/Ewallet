import { Router } from "express";
import { getAnalyticsAIPlan, getAnalyticsStats } from "../controllers/analytics.controller.js";
import { protect, requireStudentVerification } from "../middlewares/auth.middleware.js";

const router = Router();

router.use(protect, requireStudentVerification);
router.get("/stats", getAnalyticsStats);
router.get("/ai-plan", getAnalyticsAIPlan);

export default router;
