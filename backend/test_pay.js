import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import User from "./src/models/User.js";
import Wallet from "./src/models/Wallet.js";
import Service from "./src/models/Service.js";
import { payService } from "./src/controllers/payment.controller.js";
import 'dotenv/config';

async function run() {
  await mongoose.connect(process.env.MONGODB_CONNECTIONSTRING);
  
  const user = await User.findOne({ studentId: "SV2024003" });
  if (!user) return console.log("No user found");
  
  const wallet = await Wallet.findOne({ userId: user._id });
  if (!wallet) return console.log("No wallet found");
  
  // mock pin just in case
  wallet.pin = await bcrypt.hash("123456", 10);
  wallet.balance += 100000;
  await wallet.save();
  
  const service = await Service.findOne({ type: "parking", isActive: true });
  if (!service) return console.log("No service found");
  
  const req = {
    user: { id: user._id.toString() },
    body: {
      serviceId: service._id.toString(),
      pin: "123456",
      paymentMode: "monthly"
    }
  };
  
  const res = {
    status: function(code) {
      console.log("STATUS:", code);
      return this;
    },
    json: function(data) {
      console.log("JSON:", JSON.stringify(data, null, 2));
    }
  };
  
  console.log("Testing payService with user:", req.user.id, "and service:", req.body.serviceId);
  
  try {
    await payService(req, res);
  } catch (e) {
    console.error("Uncaught error:", e);
  }
  
  process.exit(0);
}

run();
