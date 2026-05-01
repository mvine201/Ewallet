import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema({
  walletId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Wallet",
    required: true
  },
  type: {
    type: String,
    enum: ["topup", "payment", "transfer", "refund", "savings_deposit", "savings_withdraw"],
    required: true
  },
  status: {
    type: String,
    enum: ["pending", "success", "failed"],
    default: "pending"
  },
  receiverWalletId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Wallet",
    default: null
  },
  method: String,
  amount: Number,
  vnpayTransactionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "VnpayTransaction"
  },
  savingsJarId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "SavingsJar",
    default: null
  },
  description: String
}, { timestamps: { createdAt: true, updatedAt: false } });

export default mongoose.model("Transaction", transactionSchema);