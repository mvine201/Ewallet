import mongoose from "mongoose";
import User from "./src/models/User.js";
import 'dotenv/config';

async function run() {
  await mongoose.connect(process.env.MONGODB_CONNECTIONSTRING);
  const users = await User.find();
  console.log("Users:", users.length);
  if (users.length > 0) {
     console.log("Sample user:", users[0]);
  }
  process.exit(0);
}
run();
