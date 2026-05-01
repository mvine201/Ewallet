import mongoose from "mongoose";

const savingsJarSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  targetAmount: {
    type: Number,
    required: true,
    min: 10000
  },
  currentAmount: {
    type: Number,
    default: 0
  },
  deadline: {
    type: Date,
    default: null
  },
  icon: {
    type: String,
    default: "🐷"
  },
  status: {
    type: String,
    enum: ["active", "completed", "cancelled"],
    default: "active",
    index: true
  },
  autoDeposit: {
    enabled: {
      type: Boolean,
      default: false
    },
    amount: {
      type: Number,
      default: 0
    },
    frequency: {
      type: String,
      enum: ["weekly", "monthly"],
      default: "weekly"
    },
    dayOfWeek: {
      type: Number,
      min: 0,
      max: 6,
      default: 1 // Thứ Hai
    },
    dayOfMonth: {
      type: Number,
      min: 1,
      max: 28,
      default: 1
    },
    nextDepositAt: {
      type: Date,
      default: null
    },
    lastDepositAt: {
      type: Date,
      default: null
    }
  },
  completedAt: {
    type: Date,
    default: null
  }
}, { timestamps: true });

// Giới hạn tối đa 10 hũ active mỗi user (validate ở controller)
savingsJarSchema.index({ userId: 1, status: 1 });

export default mongoose.model("SavingsJar", savingsJarSchema);
