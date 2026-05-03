import { Router } from "express";
import { getAnalyticsAIPlan, getAnalyticsStats } from "../controllers/analytics.controller.js";
import { protect } from "../middlewares/auth.middleware.js";

const router = Router();

router.use(protect);
router.get("/stats", getAnalyticsStats);
router.get("/ai-plan", getAnalyticsAIPlan);

export default router;
