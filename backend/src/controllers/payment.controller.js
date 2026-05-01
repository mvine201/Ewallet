import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import Student from "../models/Student.js";
import Service from "../models/Service.js";
import Payment from "../models/Payment.js";
import Transaction from "../models/Transaction.js";
import Notification from "../models/Notification.js";

// Loại dịch vụ cho phép thanh toán nhiều lần
const REPEATABLE_TYPES = ["parking", "canteen"];

// ==================== LẤY THÔNG TIN SINH VIÊN HIỆN TẠI ====================
const getStudentInfo = async (userId) => {
  const user = await User.findById(userId);
  if (!user?.isVerified || !user.studentId) return null;

  const student = await Student.findOne({
    studentId: { $regex: new RegExp(`^${user.studentId.trim()}$`, "i") },
    isActive: true,
  });

  if (!student) return null;

  return {
    studentId: student.studentId,
    cohort: student.cohort || deriveCohort(student.studentId),
    faculty: student.faculty,
    academicStatus: student.academicStatus || "studying",
  };
};

const deriveCohort = (studentId) => {
  const match = String(studentId || "").trim().match(/^(\d{2})/);
  return match ? `K${match[1]}` : "";
};

// ==================== XÂY DỰNG BỘ LỌC DỊCH VỤ THEO SINH VIÊN ====================
const buildServiceFilter = (student) => {
  const baseFilter = { isActive: true };

  // Người dùng chưa xác thực → chỉ thấy dịch vụ external không yêu cầu xác thực
  if (!student) {
    return {
      ...baseFilter,
      category: "external",
      requireVerification: { $ne: true },
    };
  }

  // Sinh viên đã tốt nghiệp → loại bỏ dịch vụ yêu cầu đang học
  if (student.academicStatus === "graduated") {
    baseFilter.requireActiveStudent = { $ne: true };
  }

  // Xây dựng điều kiện phạm vi
  const scopeConditions = [];

  // Dịch vụ external → ai cũng thấy
  scopeConditions.push({ category: "external" });

  // Dịch vụ internal, phạm vi toàn trường
  scopeConditions.push({ category: "internal", scopeType: "school" });

  // Phạm vi theo khoá
  if (student.cohort) {
    scopeConditions.push({
      category: "internal",
      scopeType: "cohort",
      applicableCohorts: student.cohort,
    });
  }

  // Phạm vi theo khoa
  if (student.faculty) {
    scopeConditions.push({
      category: "internal",
      scopeType: "faculty",
      applicableFaculties: student.faculty,
    });
  }

  // Phạm vi theo khoá + khoa (phải khớp CẢ HAI)
  if (student.cohort && student.faculty) {
    scopeConditions.push({
      category: "internal",
      scopeType: "cohort_faculty",
      applicableCohorts: student.cohort,
      applicableFaculties: student.faculty,
    });
  }

  return {
    ...baseFilter,
    $or: scopeConditions,
  };
};

// ==================== DANH SÁCH DỊCH VỤ KHẢ DỤNG ====================
// GET /api/payments/services
export const getAvailableServices = async (req, res) => {
  try {
    const student = await getStudentInfo(req.user.id);
    const filter = buildServiceFilter(student);

    const services = await Service.find(filter).sort({ type: 1, name: 1 });

    // Lấy trạng thái thanh toán cho từng dịch vụ (nếu có)
    const serviceIds = services.map((s) => s._id);
    const existingPayments = await Payment.find({
      userId: req.user.id,
      serviceId: { $in: serviceIds },
      status: { $in: ["paid", "unpaid", "overdue"] },
    }).select("serviceId status paidAt dueDate amount");

    // Map payment status cho từng dịch vụ
    const paymentMap = {};
    existingPayments.forEach((p) => {
      const key = p.serviceId.toString();
      if (!paymentMap[key]) paymentMap[key] = [];
      paymentMap[key].push(p);
    });

    const servicesWithStatus = services.map((svc) => {
      const s = svc.toObject();
      const payments = paymentMap[s._id.toString()] || [];
      const paidPayment = payments.find((p) => p.status === "paid");
      const unpaidPayment = payments.find((p) => ["unpaid", "overdue"].includes(p.status));

      s.paymentStatus = {
        hasPaid: Boolean(paidPayment),
        hasUnpaid: Boolean(unpaidPayment),
        canPay: REPEATABLE_TYPES.includes(s.type) || !paidPayment,
        unpaidPayment: unpaidPayment || null,
        paidPayment: paidPayment
          ? { paidAt: paidPayment.paidAt, amount: paidPayment.amount }
          : null,
      };

      return s;
    });

    return res.status(200).json({
      success: true,
      data: {
        services: servicesWithStatus,
        studentInfo: student
          ? {
              studentId: student.studentId,
              cohort: student.cohort,
              faculty: student.faculty,
              academicStatus: student.academicStatus,
            }
          : null,
      },
    });
  } catch (error) {
    console.error("getAvailableServices error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== DANH SÁCH CÁC KHOẢN THANH TOÁN CỦA TÔI ====================
// GET /api/payments?status=unpaid&page=1
export const getMyPayments = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const filter = { userId: req.user.id };
    if (status) filter.status = status;

    const [payments, total] = await Promise.all([
      Payment.find(filter)
        .populate("serviceId", "name icon type category")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Payment.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      data: {
        payments,
        pagination: {
          total,
          page: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error("getMyPayments error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== CHI TIẾT MỘT KHOẢN THANH TOÁN ====================
// GET /api/payments/:id
export const getPaymentDetail = async (req, res) => {
  try {
    const payment = await Payment.findOne({
      _id: req.params.id,
      userId: req.user.id,
    }).populate("serviceId");

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy khoản thanh toán",
      });
    }

    // Lấy giao dịch liên quan
    let transaction = null;
    if (payment.transactionId) {
      transaction = await Transaction.findById(payment.transactionId);
    }

    return res.status(200).json({
      success: true,
      data: { payment, transaction },
    });
  } catch (error) {
    console.error("getPaymentDetail error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== THANH TOÁN DỊCH VỤ ====================
// POST /api/payments/pay
export const payService = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { serviceId, pin, amount: customAmount } = req.body;

    // --- Validate input ---
    if (!serviceId) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Vui lòng chọn dịch vụ cần thanh toán",
      });
    }

    if (!pin || !/^\d{6}$/.test(pin)) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập PIN gồm 6 chữ số",
      });
    }

    // --- Kiểm tra dịch vụ ---
    const service = await Service.findById(serviceId).session(session);
    if (!service || !service.isActive) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: "Dịch vụ không tồn tại hoặc đã bị vô hiệu hoá",
      });
    }

    // --- Kiểm tra quyền truy cập dịch vụ ---
    const user = await User.findById(req.user.id).session(session);

    // Dịch vụ yêu cầu xác thực sinh viên
    if (service.requireVerification && !user.isVerified) {
      await session.abortTransaction();
      return res.status(403).json({
        success: false,
        message: "Bạn cần xác thực sinh viên để sử dụng dịch vụ này",
      });
    }

    // Kiểm tra scope nếu là dịch vụ internal
    if (service.category === "internal" && user.isVerified) {
      const student = await getStudentInfo(req.user.id);

      if (!student) {
        await session.abortTransaction();
        return res.status(403).json({
          success: false,
          message: "Không tìm thấy thông tin sinh viên",
        });
      }

      // Kiểm tra yêu cầu đang học
      if (service.requireActiveStudent && student.academicStatus === "graduated") {
        await session.abortTransaction();
        return res.status(403).json({
          success: false,
          message: "Dịch vụ này chỉ dành cho sinh viên đang học. Bạn đã tốt nghiệp",
        });
      }

      // Kiểm tra phạm vi
      const scopeError = checkScope(service, student);
      if (scopeError) {
        await session.abortTransaction();
        return res.status(403).json({
          success: false,
          message: scopeError,
        });
      }
    }

    // --- Kiểm tra đã thanh toán chưa (cho dịch vụ không lặp lại) ---
    if (!REPEATABLE_TYPES.includes(service.type)) {
      const existingPaid = await Payment.findOne({
        userId: req.user.id,
        serviceId: service._id,
        status: "paid",
      }).session(session);

      if (existingPaid) {
        await session.abortTransaction();
        return res.status(400).json({
          success: false,
          message: `Bạn đã thanh toán "${service.name}" rồi`,
          data: { paidAt: existingPaid.paidAt },
        });
      }
    }

    // --- Tính số tiền thanh toán ---
    let payAmount;
    if (service.type === "parking") {
      // Gửi xe: dùng giá lượt hoặc giá tháng
      payAmount = customAmount || service.parkingConfig?.perUsePrice || service.price;
    } else {
      payAmount = service.price;
    }

    if (!payAmount || payAmount <= 0) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: "Số tiền thanh toán không hợp lệ",
      });
    }

    // --- Kiểm tra thời hạn nộp (cho học phí) ---
    if (service.type === "tuition" && service.paymentWindow) {
      const now = new Date();
      if (service.paymentWindow.startAt && now < service.paymentWindow.startAt) {
        await session.abortTransaction();
        return res.status(400).json({
          success: false,
          message: `Chưa đến thời hạn nộp. Bắt đầu từ: ${new Date(service.paymentWindow.startAt).toLocaleString("vi-VN")}`,
        });
      }
      if (service.paymentWindow.endAt && now > service.paymentWindow.endAt) {
        await session.abortTransaction();
        return res.status(400).json({
          success: false,
          message: "Đã quá hạn nộp",
        });
      }
    }

    // --- Kiểm tra ví và PIN ---
    const wallet = await Wallet.findOne({ userId: req.user.id }).session(session);
    if (!wallet || wallet.status !== "active") {
      await session.abortTransaction();
      return res.status(403).json({
        success: false,
        message: "Ví không tồn tại hoặc đã bị khoá",
      });
    }

    if (!wallet.pin) {
      await session.abortTransaction();
      return res.status(403).json({
        success: false,
        message: "Bạn chưa thiết lập PIN. Vui lòng tạo PIN trước khi thanh toán",
      });
    }

    const isPinValid = await bcrypt.compare(pin, wallet.pin);
    if (!isPinValid) {
      await session.abortTransaction();
      return res.status(401).json({
        success: false,
        message: "PIN không đúng",
      });
    }

    if (wallet.balance < payAmount) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: `Số dư không đủ. Hiện có: ${wallet.balance.toLocaleString("vi-VN")}₫, cần: ${payAmount.toLocaleString("vi-VN")}₫`,
      });
    }

    // --- Thực hiện thanh toán ---
    // Trừ ví
    wallet.balance -= payAmount;
    await wallet.save({ session });

    // Tạo transaction
    const [transaction] = await Transaction.create(
      [{
        walletId: wallet._id,
        type: "payment",
        status: "success",
        method: "wallet",
        amount: payAmount,
        description: `Thanh toán ${service.name}`,
      }],
      { session }
    );

    // Tạo hoặc cập nhật Payment record
    // Kiểm tra có khoản unpaid đang chờ không
    let payment = await Payment.findOne({
      userId: req.user.id,
      serviceId: service._id,
      status: { $in: ["unpaid", "overdue"] },
    }).session(session);

    if (payment) {
      // Cập nhật payment đang chờ → paid
      payment.status = "paid";
      payment.paidAt = new Date();
      payment.amount = payAmount;
      payment.transactionId = transaction._id;
      await payment.save({ session });
    } else {
      // Tạo payment mới
      [payment] = await Payment.create(
        [{
          userId: req.user.id,
          serviceId: service._id,
          transactionId: transaction._id,
          amount: payAmount,
          status: "paid",
          paidAt: new Date(),
          dueDate: service.paymentWindow?.endAt || null,
        }],
        { session }
      );
    }

    // Notification
    await Notification.create(
      [{
        userId: req.user.id,
        title: "Thanh toán thành công",
        message: `Đã thanh toán ${payAmount.toLocaleString("vi-VN")}₫ cho "${service.name}"`,
        type: "transaction",
        relatedId: transaction._id,
      }],
      { session }
    );

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message: `Thanh toán "${service.name}" thành công`,
      data: {
        payment: {
          id: payment._id,
          service: {
            id: service._id,
            name: service.name,
            icon: service.icon,
            type: service.type,
          },
          amount: payAmount,
          paidAt: payment.paidAt,
          transactionId: transaction._id,
        },
        walletBalance: wallet.balance,
      },
    });
  } catch (error) {
    await session.abortTransaction();
    console.error("payService error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  } finally {
    session.endSession();
  }
};

// ==================== KIỂM TRA PHẠM VI DỊCH VỤ ====================
function checkScope(service, student) {
  const scope = service.scopeType || "school";

  if (scope === "school") return null; // Toàn trường → OK

  if (scope === "cohort") {
    if (!service.applicableCohorts?.length) return null;
    if (!student.cohort || !service.applicableCohorts.includes(student.cohort)) {
      return `Dịch vụ này chỉ dành cho sinh viên ${service.applicableCohorts.join(", ")}`;
    }
    return null;
  }

  if (scope === "faculty") {
    if (!service.applicableFaculties?.length) return null;
    if (!student.faculty || !service.applicableFaculties.includes(student.faculty)) {
      return `Dịch vụ này chỉ dành cho sinh viên khoa ${service.applicableFaculties.join(", ")}`;
    }
    return null;
  }

  if (scope === "cohort_faculty") {
    const cohortOk = !service.applicableCohorts?.length ||
      (student.cohort && service.applicableCohorts.includes(student.cohort));
    const facultyOk = !service.applicableFaculties?.length ||
      (student.faculty && service.applicableFaculties.includes(student.faculty));

    if (!cohortOk || !facultyOk) {
      return `Dịch vụ này chỉ dành cho sinh viên ${service.applicableCohorts?.join(", ") || ""} - ${service.applicableFaculties?.join(", ") || ""}`;
    }
    return null;
  }

  return null;
}
