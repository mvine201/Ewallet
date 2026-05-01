import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  studentId: {
    type: String,
    unique: true,
    sparse: true
  },
  studentFullName: String,
  dateOfBirth: String,
  fullName: String,
  password: String,
  phone: {
    type: String,
    unique: true,
    required: true
  },
  email: {
    type: String,
    unique: true,
    sparse: true  
  },
  avatar: String,
  role: {
    type: String,
    default: "user"
  },
  isActive: {
  type: Boolean,
  default: true
  },
  isVerified: {
    type: Boolean,
    default: false
  }
}, { timestamps: true });

export default mongoose.model("User", userSchema);
