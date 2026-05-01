import mongoose from "mongoose";
import SavingsJar from "../models/SavingsJar.js";
import Wallet from "../models/Wallet.js";
import Transaction from "../models/Transaction.js";
import Notification from "../models/Notification.js";

const MAX_ACTIVE_JARS = 10;

// ==================== TÍNH NGÀY NẠP TIẾP THEO ====================
const calcNextDepositAt = (autoDeposit) => {
  if (!autoDeposit?.enabled) return null;

  const now = new Date();

  if (autoDeposit.frequency === "weekly") {
    const target = autoDeposit.dayOfWeek ?? 1; // Thứ Hai
    const current = now.getDay();
    let daysUntil = target - current;
    if (daysUntil <= 0) daysUntil += 7;
    const next = new Date(now);
    next.setDate(next.getDate() + daysUntil);
    next.setHours(8, 0, 0, 0); // Nhắc lúc 8h sáng
    return next;
  }

  if (autoDeposit.frequency === "monthly") {
    const target = autoDeposit.dayOfMonth ?? 1;
    const next = new Date(now.getFullYear(), now.getMonth(), target, 8, 0, 0, 0);
    if (next <= now) {
      next.setMonth(next.getMonth() + 1);
    }
    return next;
  }

  return null;
};

// ==================== DANH SÁCH HŨ TIẾT KIỆM ====================
// GET /api/savings-jars
export const getSavingsJars = async (req, res) => {
  try {
    const { status } = req.query;
    const filter = { userId: req.user.id };
    if (status) filter.status = status;

    const jars = await SavingsJar.find(filter).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: jars,
    });
  } catch (error) {
    console.error("getSavingsJars error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== CHI TIẾT HŨ TIẾT KIỆM ====================
// GET /api/savings-jars/:id
export const getSavingsJarDetail = async (req, res) => {
  try {
    const jar = await SavingsJar.findOne({
      _id: req.params.id,
      userId: req.user.id,
    });

    if (!jar) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy hũ tiết kiệm",
      });
    }

    // Lấy lịch sử giao dịch liên quan
    const wallet = await Wallet.findOne({ userId: req.user.id });
    const transactions = wallet
      ? await Transaction.find({
          walletId: wallet._id,
          savingsJarId: jar._id,
        }).sort({ createdAt: -1 }).limit(20)
      : [];

    return res.status(200).json({
      success: true,
      data: {
        jar,
        transactions,
      },
    });
  } catch (error) {
    console.error("getSavingsJarDetail error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== TẠO HŨ TIẾT KIỆM ====================
// POST /api/savings-jars
export const createSavingsJar = async (req, res) => {
  try {
    const { name, targetAmount, deadline, icon, autoDeposit } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập tên hũ tiết kiệm",
      });
    }

    if (!targetAmount || targetAmount < 10000) {
      return res.status(400).json({
        success: false,
        message: "Số tiền mục tiêu tối thiểu là 10,000₫",
      });
    }

    // Kiểm tra giới hạn số hũ active
    const activeCount = await SavingsJar.countDocuments({
      userId: req.user.id,
      status: "active",
    });

    if (activeCount >= MAX_ACTIVE_JARS) {
      return res.status(400).json({
        success: false,
        message: `Bạn đã có ${MAX_ACTIVE_JARS} hũ tiết kiệm đang hoạt động. Vui lòng hoàn thành hoặc huỷ bớt để tạo thêm`,
      });
    }

    // Validate deadline
    let parsedDeadline = null;
    if (deadline) {
      parsedDeadline = new Date(deadline);
      if (Number.isNaN(parsedDeadline.getTime()) || parsedDeadline <= new Date()) {
        return res.status(400).json({
          success: false,
          message: "Thời hạn tiết kiệm phải là ngày trong tương lai",
        });
      }
    }

    // Validate autoDeposit
    let autoDepositConfig = { enabled: false };
    if (autoDeposit?.enabled) {
      if (!autoDeposit.amount || autoDeposit.amount < 1000) {
        return res.status(400).json({
          success: false,
          message: "Số tiền nạp tự động tối thiểu là 1,000₫",
        });
      }

      if (!["weekly", "monthly"].includes(autoDeposit.frequency)) {
        return res.status(400).json({
          success: false,
          message: "Tần suất nạp phải là hàng tuần (weekly) hoặc hàng tháng (monthly)",
        });
      }

      autoDepositConfig = {
        enabled: true,
        amount: autoDeposit.amount,
        frequency: autoDeposit.frequency,
        dayOfWeek: autoDeposit.frequency === "weekly"
          ? Math.min(6, Math.max(0, Number(autoDeposit.dayOfWeek) || 1))
          : 1,
        dayOfMonth: autoDeposit.frequency === "monthly"
          ? Math.min(28, Math.max(1, Number(autoDeposit.dayOfMonth) || 1))
          : 1,
      };

      autoDepositConfig.nextDepositAt = calcNextDepositAt(autoDepositConfig);
    }

    const jar = await SavingsJar.create({
      userId: req.user.id,
      name: name.trim(),
      targetAmount,
      icon: icon || "🐷",
      deadline: parsedDeadline,
      autoDeposit: autoDepositConfig,
    });

    return res.status(201).json({
      success: true,
      message: `Đã tạo hũ tiết kiệm "${jar.name}"`,
      data: jar,
    });
  } catch (error) {
    console.error("createSavingsJar error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== CẬP NHẬT HŨ TIẾT KIỆM ====================
// PUT /api/savings-jars/:id
export const updateSavingsJar = async (req, res) => {
  try {
    const jar = await SavingsJar.findOne({
      _id: req.params.id,
      userId: req.user.id,
    });

    if (!jar) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy hũ tiết kiệm",
      });
    }

    if (jar.status !== "active") {
      return res.status(400).json({
        success: false,
        message: "Chỉ có thể chỉnh sửa hũ đang hoạt động",
      });
    }

    const { name, icon, targetAmount, deadline, autoDeposit } = req.body;

    if (name !== undefined) {
      if (!name.trim()) {
        return res.status(400).json({
          success: false,
          message: "Tên hũ không được để trống",
        });
      }
      jar.name = name.trim();
    }

    if (icon !== undefined) jar.icon = icon;

    if (targetAmount !== undefined) {
      if (targetAmount < 10000) {
        return res.status(400).json({
          success: false,
          message: "Số tiền mục tiêu tối thiểu là 10,000₫",
        });
      }
      if (targetAmount < jar.currentAmount) {
        return res.status(400).json({
          success: false,
          message: "Số tiền mục tiêu không thể thấp hơn số tiền hiện có trong hũ",
        });
      }
      jar.targetAmount = targetAmount;
    }

    if (deadline !== undefined) {
      if (deadline === null || deadline === "") {
        jar.deadline = null;
      } else {
        const parsed = new Date(deadline);
        if (Number.isNaN(parsed.getTime()) || parsed <= new Date()) {
          return res.status(400).json({
            success: false,
            message: "Thời hạn tiết kiệm phải là ngày trong tương lai",
          });
        }
        jar.deadline = parsed;
      }
    }

    if (autoDeposit !== undefined) {
      if (!autoDeposit?.enabled) {
        jar.autoDeposit = { ...jar.autoDeposit.toObject(), enabled: false, nextDepositAt: null };
      } else {
        if (!autoDeposit.amount || autoDeposit.amount < 1000) {
          return res.status(400).json({
            success: false,
            message: "Số tiền nạp tự động tối thiểu là 1,000₫",
          });
        }
        jar.autoDeposit = {
          enabled: true,
          amount: autoDeposit.amount,
          frequency: autoDeposit.frequency || jar.autoDeposit.frequency || "weekly",
          dayOfWeek: autoDeposit.dayOfWeek ?? jar.autoDeposit.dayOfWeek ?? 1,
          dayOfMonth: autoDeposit.dayOfMonth ?? jar.autoDeposit.dayOfMonth ?? 1,
          lastDepositAt: jar.autoDeposit.lastDepositAt,
        };
        jar.autoDeposit.nextDepositAt = calcNextDepositAt(jar.autoDeposit);
      }
    }

    // Kiểm tra nếu đã đạt mục tiêu
    if (jar.currentAmount >= jar.targetAmount) {
      jar.status = "completed";
      jar.completedAt = new Date();
    }

    await jar.save();

    return res.status(200).json({
      success: true,
      message: `Đã cập nhật hũ "${jar.name}"`,
      data: jar,
    });
  } catch (error) {
    console.error("updateSavingsJar error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== NẠP TIỀN VÀO HŨ ====================
// POST /api/savings-jars/:id/deposit
export const depositToJar = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { amount } = req.body;

    if (!amount || amount < 1000) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Số tiền nạp tối thiểu là 1,000₫",
      });
    }

    const jar = await SavingsJar.findOne({
      _id: req.params.id,
      userId: req.user.id,
    }).session(session);

    if (!jar) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy hũ tiết kiệm",
      });
    }

    if (jar.status !== "active") {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Hũ tiết kiệm không còn hoạt động",
      });
    }

    // Kiểm tra ví
    const wallet = await Wallet.findOne({ userId: req.user.id }).session(session);
    if (!wallet || wallet.status !== "active") {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Ví không tồn tại hoặc đã bị khoá",
      });
    }

    if (wallet.balance < amount) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: `Số dư ví không đủ. Hiện có: ${wallet.balance.toLocaleString("vi-VN")}₫`,
      });
    }

    // Giới hạn nạp không vượt quá mục tiêu
    const maxDeposit = jar.targetAmount - jar.currentAmount;
    const depositAmount = Math.min(amount, maxDeposit);

    if (depositAmount <= 0) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Hũ đã đạt mục tiêu, không thể nạp thêm",
      });
    }

    // Trừ ví, cộng hũ
    wallet.balance -= depositAmount;
    jar.currentAmount += depositAmount;

    // Kiểm tra đạt mục tiêu
    if (jar.currentAmount >= jar.targetAmount) {
      jar.status = "completed";
      jar.completedAt = new Date();
    }

    // Cập nhật autoDeposit nếu là nạp theo lịch
    if (jar.autoDeposit?.enabled) {
      jar.autoDeposit.lastDepositAt = new Date();
      jar.autoDeposit.nextDepositAt = jar.status === "completed"
        ? null
        : calcNextDepositAt(jar.autoDeposit);
    }

    await wallet.save({ session });
    await jar.save({ session });

    // Tạo transaction
    const [transaction] = await Transaction.create(
      [{
        walletId: wallet._id,
        type: "savings_deposit",
        status: "success",
        amount: depositAmount,
        savingsJarId: jar._id,
        description: `Nạp tiền vào hũ "${jar.name}"`,
      }],
      { session }
    );

    // Notification
    await Notification.create(
      [{
        userId: req.user.id,
        title: "Nạp hũ tiết kiệm",
        message: `Đã nạp ${depositAmount.toLocaleString("vi-VN")}₫ vào hũ "${jar.name}". ${
          jar.status === "completed"
            ? "🎉 Chúc mừng! Bạn đã đạt mục tiêu!"
            : `Tiến độ: ${jar.currentAmount.toLocaleString("vi-VN")}₫ / ${jar.targetAmount.toLocaleString("vi-VN")}₫`
        }`,
        type: "transaction",
        relatedId: transaction._id,
      }],
      { session }
    );

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message: jar.status === "completed"
        ? `🎉 Chúc mừng! Hũ "${jar.name}" đã đạt mục tiêu!`
        : `Đã nạp ${depositAmount.toLocaleString("vi-VN")}₫ vào hũ`,
      data: {
        jar,
        walletBalance: wallet.balance,
        depositAmount,
      },
    });
  } catch (error) {
    await session.abortTransaction();
    console.error("depositToJar error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  } finally {
    session.endSession();
  }
};

// ==================== RÚT TIỀN TỪ HŨ ====================
// POST /api/savings-jars/:id/withdraw
export const withdrawFromJar = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { amount } = req.body;

    const jar = await SavingsJar.findOne({
      _id: req.params.id,
      userId: req.user.id,
    }).session(session);

    if (!jar) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy hũ tiết kiệm",
      });
    }

    if (jar.currentAmount <= 0) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Hũ tiết kiệm không có tiền để rút",
      });
    }

    // Nếu không truyền amount → rút hết
    const withdrawAmount = amount
      ? Math.min(Number(amount), jar.currentAmount)
      : jar.currentAmount;

    if (withdrawAmount <= 0) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Số tiền rút không hợp lệ",
      });
    }

    const wallet = await Wallet.findOne({ userId: req.user.id }).session(session);
    if (!wallet) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Không tìm thấy ví",
      });
    }

    // Cộng ví, trừ hũ
    wallet.balance += withdrawAmount;
    jar.currentAmount -= withdrawAmount;

    // Nếu hũ đã completed và rút hết → chuyển về cancelled
    if (jar.currentAmount <= 0 && jar.status === "completed") {
      jar.status = "cancelled";
    }

    await wallet.save({ session });
    await jar.save({ session });

    const [transaction] = await Transaction.create(
      [{
        walletId: wallet._id,
        type: "savings_withdraw",
        status: "success",
        amount: withdrawAmount,
        savingsJarId: jar._id,
        description: `Rút tiền từ hũ "${jar.name}"`,
      }],
      { session }
    );

    await Notification.create(
      [{
        userId: req.user.id,
        title: "Rút tiền hũ tiết kiệm",
        message: `Đã rút ${withdrawAmount.toLocaleString("vi-VN")}₫ từ hũ "${jar.name}" về ví`,
        type: "transaction",
        relatedId: transaction._id,
      }],
      { session }
    );

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message: `Đã rút ${withdrawAmount.toLocaleString("vi-VN")}₫ về ví`,
      data: {
        jar,
        walletBalance: wallet.balance,
        withdrawAmount,
      },
    });
  } catch (error) {
    await session.abortTransaction();
    console.error("withdrawFromJar error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  } finally {
    session.endSession();
  }
};

// ==================== HUỶ HŨ TIẾT KIỆM ====================
// DELETE /api/savings-jars/:id
export const deleteSavingsJar = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const jar = await SavingsJar.findOne({
      _id: req.params.id,
      userId: req.user.id,
    }).session(session);

    if (!jar) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy hũ tiết kiệm",
      });
    }

    if (jar.status === "cancelled") {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Hũ đã bị huỷ trước đó",
      });
    }

    // Trả tiền còn lại về ví
    if (jar.currentAmount > 0) {
      const wallet = await Wallet.findOne({ userId: req.user.id }).session(session);
      if (!wallet) {
        await session.abortTransaction();
        return res.status(400).json({
          success: false,
          message: "Không tìm thấy ví",
        });
      }

      wallet.balance += jar.currentAmount;
      await wallet.save({ session });

      const [transaction] = await Transaction.create(
        [{
          walletId: wallet._id,
          type: "savings_withdraw",
          status: "success",
          amount: jar.currentAmount,
          savingsJarId: jar._id,
          description: `Huỷ hũ "${jar.name}" — hoàn tiền về ví`,
        }],
        { session }
      );

      await Notification.create(
        [{
          userId: req.user.id,
          title: "Huỷ hũ tiết kiệm",
          message: `Đã huỷ hũ "${jar.name}" và hoàn ${jar.currentAmount.toLocaleString("vi-VN")}₫ về ví`,
          type: "transaction",
          relatedId: transaction._id,
        }],
        { session }
      );
    }

    jar.currentAmount = 0;
    jar.status = "cancelled";
    jar.autoDeposit.enabled = false;
    jar.autoDeposit.nextDepositAt = null;
    await jar.save({ session });

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message: `Đã huỷ hũ "${jar.name}"${jar.currentAmount > 0 ? " và hoàn tiền về ví" : ""}`,
      data: jar,
    });
  } catch (error) {
    await session.abortTransaction();
    console.error("deleteSavingsJar error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  } finally {
    session.endSession();
  }
};
