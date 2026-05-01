// Script tạo tài khoản admin mặc định
// Chạy: node src/scripts/seedAdmin.js

import "dotenv/config";
import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";

const ADMIN_PHONE = "admin";
const ADMIN_PASSWORD = "admin123";
const ADMIN_FULLNAME = "Administrator";

async function seedAdmin() {
  try {
    await mongoose.connect(process.env.MONGODB_CONNECTIONSTRING);
    console.log("✅ Connected to MongoDB");

    // Kiểm tra admin đã tồn tại chưa
    const existingAdmin = await User.findOne({ phone: ADMIN_PHONE });
    if (existingAdmin) {
      console.log("⚠️  Admin account already exists:");
      console.log(`   Phone: ${ADMIN_PHONE}`);
      console.log(`   Role: ${existingAdmin.role}`);
      process.exit(0);
    }

    // Tạo admin
    const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 10);
    const admin = await User.create({
      phone: ADMIN_PHONE,
      password: hashedPassword,
      fullName: ADMIN_FULLNAME,
      role: "admin",
      isActive: true,
      isVerified: true,
    });

    // Tạo ví cho admin
    await Wallet.create({ userId: admin._id });

    console.log("🎉 Admin account created successfully!");
    console.log(`   Phone: ${ADMIN_PHONE}`);
    console.log(`   Password: ${ADMIN_PASSWORD}`);
    console.log(`   Role: admin`);
    console.log("");
    console.log("⚠️  Hãy đổi mật khẩu sau khi đăng nhập lần đầu!");

    process.exit(0);
  } catch (error) {
    console.error("❌ Seed error:", error);
    process.exit(1);
  }
}

seedAdmin();
