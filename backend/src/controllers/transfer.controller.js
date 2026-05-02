import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import Transaction from "../models/Transaction.js";
import Notification from "../models/Notification.js";

// ==================== THIẾT LẬP / ĐỔI PIN ====================
// POST /api/transfer/pin
export const setPin = async (req, res) => {
  try {
    const { currentPin, pin } = req.body;

    if (!pin || !/^\d{6}$/.test(pin)) {
      return res.status(400).json({
        success: false,
        message: "PIN phải là 6 chữ số",
      });
    }

    const wallet = await Wallet.findOne({ userId: req.user.id });
    if (!wallet) {
      return res.status(404).json({ success: false, message: "Không tìm thấy ví" });
    }

    if (wallet.status !== "active") {
      return res.status(403).json({
        success: false,
        message: "Ví của bạn đã bị khoá",
      });
    }

    const hadPin = Boolean(wallet.pin);

    if (hadPin) {
      if (!currentPin || !/^\d{6}$/.test(currentPin)) {
        return res.status(400).json({
          success: false,
          message: "Vui lòng nhập PIN hiện tại gồm 6 chữ số",
        });
      }

      const isCurrentPinValid = await bcrypt.compare(currentPin, wallet.pin);
      if (!isCurrentPinValid) {
        return res.status(401).json({
          success: false,
          message: "PIN hiện tại không đúng",
        });
      }

      const isSamePin = await bcrypt.compare(pin, wallet.pin);
      if (isSamePin) {
        return res.status(400).json({
          success: false,
          message: "PIN mới không được trùng PIN hiện tại",
        });
      }
    }

    const hashedPin = await bcrypt.hash(pin, 10);
    wallet.pin = hashedPin;
    await wallet.save();

    return res.status(200).json({
      success: true,
      message: hadPin ? "Đổi PIN thành công" : "Thiết lập PIN thành công",
    });
  } catch (error) {
    console.error("setPin error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== TÌM NGƯỜI NHẬN ====================
// GET /api/transfer/lookup?q=phone_hoặc_studentId
export const lookupReceiver = async (req, res) => {
  try {
    const q = req.query.q?.trim();

    if (!q) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập số điện thoại hoặc mã số sinh viên",
      });
    }

    const phoneUser = await User.findOne({
      phone: q,
      isActive: true,
    }).select("fullName phone studentId avatar isVerified");

    const verifiedStudentUser = await User.findOne({
      studentId: q,
      isActive: true,
      isVerified: true,
    }).select("fullName phone studentId avatar isVerified");

    const user = phoneUser || verifiedStudentUser;

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy người dùng",
      });
    }

    // Không cho tự chuyển cho chính mình
    if (user._id.toString() === req.user.id) {
      return res.status(400).json({
        success: false,
        message: "Không thể chuyển tiền cho chính mình",
      });
    }

    const receiverWallet = await Wallet.findOne({ userId: user._id });
    if (!receiverWallet || receiverWallet.status !== "active") {
      return res.status(404).json({
        success: false,
        message: "Ví người nhận không tồn tại hoặc đã bị khoá",
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        id:        user._id,
        fullName:  user.fullName,
        phone:     user.phone,
        studentId: user.studentId,
        isVerified: user.isVerified,
        avatar:    user.avatar,
      },
    });
  } catch (error) {
    console.error("lookupReceiver error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== CHUYỂN TIỀN ====================
// POST /api/transfer
export const transfer = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { receiverId, amount, description, pin } = req.body;

    // --- Validate input ---
    if (!receiverId || !amount || !pin) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng điền đầy đủ thông tin: người nhận, số tiền, PIN",
      });
    }

    if (isNaN(amount) || amount < 1000) {
      return res.status(400).json({
        success: false,
        message: "Số tiền chuyển tối thiểu là 1,000 VND",
      });
    }

    if (receiverId === req.user.id) {
      return res.status(400).json({
        success: false,
        message: "Không thể chuyển tiền cho chính mình",
      });
    }

    // --- Lấy ví người gửi ---
    const senderWallet = await Wallet.findOne({ userId: req.user.id }).session(session);
    if (!senderWallet || senderWallet.status !== "active") {
      await session.abortTransaction();
      return res.status(403).json({
        success: false,
        message: "Ví của bạn không tồn tại hoặc đã bị khoá",
      });
    }

    // --- Kiểm tra PIN ---
    if (!senderWallet.pin) {
      await session.abortTransaction();
      return res.status(403).json({
        success: false,
        message: "Bạn chưa thiết lập PIN. Vui lòng tạo PIN trước khi chuyển tiền",
      });
    }

    const isPinValid = await bcrypt.compare(pin, senderWallet.pin);
    if (!isPinValid) {
      await session.abortTransaction();
      return res.status(401).json({
        success: false,
        message: "PIN không đúng",
      });
    }

    // --- Kiểm tra số dư ---
    if (senderWallet.balance < amount) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: `Số dư không đủ. Số dư hiện tại: ${senderWallet.balance.toLocaleString("vi-VN")}₫`,
      });
    }

    // --- Lấy ví người nhận ---
    const receiverWallet = await Wallet.findOne({ userId: receiverId }).session(session);
    if (!receiverWallet || receiverWallet.status !== "active") {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: "Ví người nhận không tồn tại hoặc đã bị khoá",
      });
    }

    // --- Trừ tiền người gửi ---
    await Wallet.findByIdAndUpdate(
      senderWallet._id,
      { $inc: { balance: -amount } },
      { session }
    );

    // --- Cộng tiền người nhận ---
    await Wallet.findByIdAndUpdate(
      receiverWallet._id,
      { $inc: { balance: amount } },
      { session }
    );

    const transferDesc = description?.trim() || "Chuyển tiền";

    // --- Tạo transaction cho người gửi ---
    const [senderTxn] = await Transaction.create(
      [{
        walletId:         senderWallet._id,
        type:             "transfer",
        status:           "success",
        method:           "internal",
        amount,
        receiverWalletId: receiverWallet._id,
        description:      `${transferDesc} → ${receiverId}`,
      }],
      { session }
    );

    // --- Tạo transaction cho người nhận ---
    await Transaction.create(
      [{
        walletId:         receiverWallet._id,
        type:             "transfer",
        status:           "success",
        method:           "internal",
        amount,
        receiverWalletId: receiverWallet._id,
        description:      `Nhận tiền từ ${req.user.id} - ${transferDesc}`,
      }],
      { session }
    );

    // --- Thông báo người gửi ---
    const receiver = await User.findById(receiverId).select("fullName");
    const sender   = await User.findById(req.user.id).select("fullName");

    await Notification.create(
      [{
        userId:    req.user.id,
        title:     "Chuyển tiền thành công",
        message:   `Bạn đã chuyển ${amount.toLocaleString("vi-VN")}₫ đến ${receiver?.fullName}`,
        type:      "transaction",
        relatedId: senderTxn._id,
      }],
      { session }
    );

    // --- Thông báo người nhận ---
    await Notification.create(
      [{
        userId:    receiverId,
        title:     "Nhận tiền",
        message:   `Bạn vừa nhận ${amount.toLocaleString("vi-VN")}₫ từ ${sender?.fullName}`,
        type:      "transaction",
        relatedId: senderTxn._id,
      }],
      { session }
    );

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message: "Chuyển tiền thành công",
      data: {
        transactionId: senderTxn._id,
        amount,
        receiver: {
          id:       receiverId,
          fullName: receiver?.fullName,
        },
        description: transferDesc,
        newBalance: senderWallet.balance - amount,
      },
    });
  } catch (error) {
    await session.abortTransaction();
    console.error("transfer error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  } finally {
    session.endSession();
  }
};
