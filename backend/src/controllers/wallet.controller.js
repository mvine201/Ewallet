import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import { v4 as uuidv4 } from "uuid";
import vnpay from "../libs/vnpay.js";
import Wallet from "../models/Wallet.js";
import Transaction from "../models/Transaction.js";
import VnpayTransaction from "../models/VNPayTransaction.js";
import Notification from "../models/Notification.js";
import { ProductCode, VnpLocale, dateFormat } from "vnpay";
import { ensureWithinDailyTransactionLimit } from "../libs/dailyTransactionLimit.js";

const confirmVnpayTransaction = async (verify, session) => {
  const withSession = (query) => (session ? query.session(session) : query);
  const saveOptions = session ? { session } : undefined;
  const writeOptions = session ? { session } : undefined;

  const vnpTxn = await withSession(VnpayTransaction.findOne({
    orderId: verify.vnp_TxnRef,
  }));

  if (!vnpTxn) {
    return { code: "01", message: "Order not found" };
  }

  const paidAmount = Number(verify.vnp_Amount);

  if (Number(vnpTxn.amount) !== paidAmount) {
    return { code: "04", message: "Invalid amount" };
  }

  if (vnpTxn.status !== "pending") {
    return {
      code: "00",
      message: "Order already confirmed",
      vnpTxn,
      isSuccess: vnpTxn.status === "success",
      alreadyConfirmed: true,
    };
  }

  const isSuccess = verify.isSuccess;

  vnpTxn.status = isSuccess ? "success" : "failed";
  vnpTxn.responseCode = verify.vnp_ResponseCode;
  vnpTxn.bankCode = verify.vnp_BankCode;
  vnpTxn.vnpTransactionNo = verify.vnp_TransactionNo;
  vnpTxn.payDate = verify.vnp_PayDate;
  await vnpTxn.save(saveOptions);

  const [transaction] = await Transaction.create(
    [{
      walletId: vnpTxn.walletId,
      type: "topup",
      status: isSuccess ? "success" : "failed",
      method: "vnpay",
      amount: paidAmount,
      vnpayTransactionId: vnpTxn._id,
      description: `Nạp tiền qua VNPay - ${verify.vnp_TxnRef}`,
    }],
    writeOptions
  );

  if (isSuccess) {
    await Wallet.findByIdAndUpdate(
      vnpTxn.walletId,
      { $inc: { balance: paidAmount } },
      writeOptions
    );

    await Notification.create(
      [{
        userId: vnpTxn.userId,
        title: "Nạp tiền thành công",
        message: `Bạn vừa nạp ${paidAmount.toLocaleString("vi-VN")}₫ vào ví qua VNPay`,
        type: "transaction",
        relatedId: transaction._id,
      }],
      writeOptions
    );
  }

  return { code: "00", message: "Confirm success", vnpTxn, isSuccess };
};

// ==================== TẠO URL NẠP TIỀN ====================
// POST /api/wallet/topup
export const createTopup = async (req, res) => {
  try {
    const { amount, pin } = req.body;

    if (!amount || isNaN(amount) || amount < 10000) {
      return res.status(400).json({
        success: false,
        message: "Số tiền nạp tối thiểu là 10,000 VND",
      });
    }

    if (amount > 50000000) {
      return res.status(400).json({
        success: false,
        message: "Số tiền nạp tối đa là 50,000,000 VND",
      });
    }

    if (!pin || !/^\d{6}$/.test(pin)) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập PIN gồm 6 chữ số",
      });
    }

    const wallet = await Wallet.findOne({ userId: req.user.id });
    if (!wallet || wallet.status !== "active") {
      return res.status(404).json({
        success: false,
        message: "Ví không tồn tại hoặc đã bị khoá",
      });
    }

    if (!wallet.pin) {
      return res.status(403).json({
        success: false,
        message: "Bạn chưa thiết lập PIN. Vui lòng tạo PIN trước khi nạp tiền",
      });
    }

    const isPinValid = await bcrypt.compare(pin, wallet.pin);
    if (!isPinValid) {
      return res.status(401).json({
        success: false,
        message: "PIN không đúng",
      });
    }

    try {
      await ensureWithinDailyTransactionLimit({
        walletId: wallet._id,
        amount,
        includePendingTopups: true,
      });
    } catch (error) {
      if (error.code === "DAILY_TRANSACTION_LIMIT_EXCEEDED") {
        return res.status(400).json({
          success: false,
          message: `Bạn đã vượt giới hạn giao dịch 50,000,000₫ mỗi ngày. Hạn mức còn lại hôm nay: ${error.remaining.toLocaleString("vi-VN")}₫`,
        });
      }
      throw error;
    }

    const orderId = `${Date.now()}${uuidv4().slice(0, 6).toUpperCase()}`;

    // Lưu pending transaction
    await VnpayTransaction.create({
      userId: req.user.id,
      walletId: wallet._id,
      amount,
      orderId,
      status: "pending",
    });

    // Tạo URL thanh toán bằng thư viện vnpay
    const paymentUrl = vnpay.buildPaymentUrl({
      vnp_Amount: amount,
      vnp_IpAddr:
        req.headers["x-forwarded-for"]?.split(",")[0].trim() ||
        req.socket.remoteAddress ||
        "127.0.0.1",
      vnp_TxnRef: orderId,
      vnp_OrderInfo: `Nap tien vi SV ${orderId}`,
      vnp_OrderType: ProductCode.Other,
      vnp_Locale: VnpLocale.VN,
      vnp_ReturnUrl: process.env.VNP_RETURN_URL,
    });

    return res.status(200).json({
      success: true,
      message: "Tạo link thanh toán thành công",
      data: { paymentUrl, orderId },
    });
  } catch (error) {
    console.error("createTopup error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== RETURN URL ====================
// GET /api/wallet/topup/vnpay-return
export const vnpayReturn = async (req, res) => {
  try {
    const verify = vnpay.verifyReturnUrl(req.query);

    if (!verify.isVerified) {
      return res.redirect("studentewallet://topup-result?success=false&message=invalid-signature");
    }

    const result = await confirmVnpayTransaction(verify);

    if (!result.vnpTxn) {
      return res.redirect(`studentewallet://topup-result?success=false&orderId=${encodeURIComponent(verify.vnp_TxnRef)}&message=${encodeURIComponent(result.message)}`);
    }

    const params = new URLSearchParams({
      success: String(Boolean(result.isSuccess)),
      orderId: verify.vnp_TxnRef,
      amount: String(verify.vnp_Amount || result.vnpTxn.amount || ""),
      bankCode: verify.vnp_BankCode || "",
      responseCode: verify.vnp_ResponseCode || "",
    });
    return res.redirect(`studentewallet://topup-result?${params.toString()}`);
  } catch (error) {
    console.error("vnpayReturn error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== IPN ====================
// GET /api/wallet/topup/vnpay-ipn
export const vnpayIPN = async (req, res) => {
  try {
    const verify = vnpay.verifyIpnCall(req.query);

    if (!verify.isVerified) {
      return res.status(200).json({ RspCode: "97", Message: "Invalid signature" });
    }

    const result = await confirmVnpayTransaction(verify);

    if (!result.vnpTxn) {
      return res.status(200).json({ RspCode: result.code, Message: result.message });
    }

    return res.status(200).json({ RspCode: result.code, Message: result.message });
  } catch (error) {
    console.error("vnpayIPN error:", error);
    return res.status(200).json({ RspCode: "99", Message: "Unknown error" });
  }
};

// ==================== KIỂM TRA TRẠNG THÁI NẠP TIỀN ====================
export const getTopupStatus = async (req, res) => {
  try {
    const { orderId } = req.params;

    const vnpTxn = await VnpayTransaction.findOne({
      orderId,
      userId: req.user.id,
    });

    if (!vnpTxn) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy giao dịch nạp tiền",
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        orderId: vnpTxn.orderId,
        amount: vnpTxn.amount,
        status: vnpTxn.status,
        responseCode: vnpTxn.responseCode,
        bankCode: vnpTxn.bankCode,
        payDate: vnpTxn.payDate,
      },
    });
  } catch (error) {
    console.error("getTopupStatus error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== XEM SỐ DƯ VÍ ====================
export const getMyWallet = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.user.id });
    if (!wallet) {
      return res.status(404).json({ success: false, message: "Không tìm thấy ví" });
    }

    const walletData = wallet.toObject();
    walletData.hasPin = Boolean(wallet.pin);
    delete walletData.pin;

    return res.status(200).json({ success: true, data: walletData });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== LỊCH SỬ GIAO DỊCH ====================
export const getTransactions = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.user.id });
    if (!wallet) {
      return res.status(404).json({ success: false, message: "Không tìm thấy ví" });
    }

    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const transactions = await Transaction.find({ walletId: wallet._id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const formattedTransactions = transactions.map((transaction) => {
      const item = transaction.toObject();
      const isReceiverWallet =
        item.receiverWalletId?.toString() === wallet._id.toString();
      const isTransferIn =
        item.type === "transfer" &&
        (isReceiverWallet || item.description?.toLowerCase().startsWith("nhận tiền"));

      let direction = "out";
      let displayType = "Giao dịch";

      if (item.type === "topup" || item.type === "refund" || isTransferIn) {
        direction = "in";
      }

      switch (item.type) {
        case "topup":
          displayType = "Nạp tiền";
          break;
        case "transfer":
          displayType = isTransferIn ? "Nhận tiền vào" : "Chuyển tiền đi";
          break;
        case "payment":
          displayType = "Thanh toán dịch vụ";
          break;
        case "refund":
          displayType = "Hoàn tiền";
          break;
        default:
          displayType = item.type;
      }

      return {
        ...item,
        direction,
        displayType,
      };
    });

    const total = await Transaction.countDocuments({ walletId: wallet._id });

    return res.status(200).json({
      success: true,
      data: {
        transactions: formattedTransactions,
        pagination: {
          total,
          page: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};
