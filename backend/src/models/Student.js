import mongoose from "mongoose";

const studentSchema = new mongoose.Schema({
  studentId: {
    type: String,
    unique: true,
    required: true
  },
  fullName: {
    type: String,
    required: true
  },
  dateOfBirth: {
    type: String,
    required: true
  },
  email: String,
  cohort: {
    type: String,
    index: true
  },
  faculty: String,
  className: String,
  academicStatus: {
    type: String,
    enum: ["studying", "graduated"],
    default: "studying",
    index: true
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, { timestamps: true });

export default mongoose.model("Student", studentSchema);
