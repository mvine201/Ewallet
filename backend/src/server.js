import "dotenv/config";
import express from "express";
import cors from "cors";
import path from "path";
import { connectDB } from "./libs/db.js";
import authRoutes from "./routes/auth.routes.js";
import walletRoutes from "./routes/wallet.routes.js";
import transferRoutes from "./routes/transfer.routes.js";
import adminRoutes from "./routes/admin.routes.js";
import savingsJarRoutes from "./routes/savingsjar.routes.js";
import paymentRoutes from "./routes/payment.routes.js";
import notificationRoutes from "./routes/notification.routes.js";

const app = express();
const PORT = process.env.PORT || 5001;

app.use(cors());
app.use(express.json());

// Phục vụ các file tĩnh (như file .docx upload)
app.use("/uploads", express.static(path.join(process.cwd(), "public/uploads")));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/wallet", walletRoutes);
app.use("/api/transfer", transferRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/savings-jars", savingsJarRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/notifications", notificationRoutes);
app.get("/", (req, res) => {
  res.send("API đang chạy ngon lành!");
});


connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Server start on PORT ${PORT}`);
  });
});