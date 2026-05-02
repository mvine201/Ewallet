import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    // Nếu userId null thì đây là thông báo chung cho toàn hệ thống
    default: null
  },
  title: String,
  message: String,
  link: {
    type: String,
    default: null
  },
  fileUrl: {
    type: String,
    default: null
  },
  type: {
    type: String,
    enum: ["transaction", "payment_due", "low_balance", "system", "promotion", "custom"],
  },
  relatedId: {
    type: mongoose.Schema.Types.ObjectId,
    default: null
  },
  isRead: {
    type: Boolean,
    default: false
  }
}, { timestamps: { createdAt: true, updatedAt: false } });

export default mongoose.model("Notification", notificationSchema);