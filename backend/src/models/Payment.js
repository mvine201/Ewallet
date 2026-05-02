import mongoose from "mongoose";

const paymentSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  serviceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Service"
  },
  transactionId: {
  type: mongoose.Schema.Types.ObjectId,
  ref: "Transaction",
  default: null
  },
  amount: Number,
  content: String,
  studentSnapshot: {
    studentId: String,
    fullName: String,
    cohort: String,
    faculty: String,
    phone: String,
    email: String
  },
  serviceSnapshot: {
    name: String,
    type: { type: String },
    category: String,
    semester: String,
    academicYear: String
  },
  paymentMode: {
    type: String,
    enum: ["single", "monthly"],
    default: "single"
  },
  status: {
    type: String,
    enum: ["unpaid", "paid", "overdue", "cancelled"],
    default: "unpaid"
  },
  dueDate: Date,
  paidAt: Date
}, { timestamps: { createdAt: true, updatedAt: false } });

export default mongoose.model("Payment", paymentSchema);
