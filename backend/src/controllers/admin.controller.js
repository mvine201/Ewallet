import bcrypt from "bcryptjs";
import crypto from "crypto";
import xlsx from "xlsx";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import Student from "../models/Student.js";
import Service from "../models/Service.js";
import Payment from "../models/Payment.js";
import Transaction from "../models/Transaction.js";

const deriveCohortFromStudentId = (studentId) => {
  const match = String(studentId || "").trim().match(/^(\d{2})/);
  return match ? `K${match[1]}` : "";
};

const cohortToStudentIdPrefix = (cohort) => {
  const match = String(cohort || "").trim().match(/^K?(\d{2})$/i);
  return match ? match[1] : "";
};

const normalizeList = (value) => {
  if (Array.isArray(value)) {
    return value.map((item) => String(item).trim()).filter(Boolean);
  }
  if (typeof value === "string") {
    return value.split(",").map((item) => item.trim()).filter(Boolean);
  }
  return [];
};

const parseDateOrNull = (value) => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};

const buildServicePayload = (body, existingService = null) => {
  const category = body.category || existingService?.category || "internal";
  const type = body.type || existingService?.type;
  const scopeType = body.scopeType || existingService?.scopeType || "school";
  const price = Number(body.price ?? existingService?.price ?? 0);
  const startValue = body.paymentWindow?.startAt ?? body.paymentStartAt;
  const endValue = body.paymentWindow?.endAt ?? body.paymentEndAt;
  const startAt = startValue !== undefined
    ? parseDateOrNull(startValue)
    : existingService?.paymentWindow?.startAt || null;
  const endAt = endValue !== undefined
    ? parseDateOrNull(endValue)
    : existingService?.paymentWindow?.endAt || null;
  const reminderDaysBeforeDue =
    Array.isArray(body.paymentWindow?.reminderDaysBeforeDue)
      ? body.paymentWindow.reminderDaysBeforeDue
      : existingService?.paymentWindow?.reminderDaysBeforeDue || [5, 3, 1];

  const parkingConfig = {
    perUsePrice: Number(body.parkingConfig?.perUsePrice ?? body.parkingPerUsePrice ?? existingService?.parkingConfig?.perUsePrice ?? 0),
    monthlyPassEnabled: Boolean(body.parkingConfig?.monthlyPassEnabled ?? body.parkingMonthlyPassEnabled ?? existingService?.parkingConfig?.monthlyPassEnabled),
    monthlyPassPrice: Number(body.parkingConfig?.monthlyPassPrice ?? body.parkingMonthlyPassPrice ?? existingService?.parkingConfig?.monthlyPassPrice ?? 0),
    monthlyPassOpenDayFrom: Number(body.parkingConfig?.monthlyPassOpenDayFrom ?? body.parkingMonthlyOpenDayFrom ?? existingService?.parkingConfig?.monthlyPassOpenDayFrom ?? 1),
    monthlyPassOpenDayTo: Number(body.parkingConfig?.monthlyPassOpenDayTo ?? body.parkingMonthlyOpenDayTo ?? existingService?.parkingConfig?.monthlyPassOpenDayTo ?? 5),
  };

  return {
    name: body.name !== undefined ? body.name.trim() : existingService?.name,
    price: type === "parking" && price === 0 ? parkingConfig.perUsePrice : price,
    description: body.description !== undefined ? body.description : existingService?.description,
    category,
    type,
    scopeType,
    applicableCohorts: body.applicableCohorts !== undefined
      ? normalizeList(body.applicableCohorts)
      : existingService?.applicableCohorts || [],
    applicableFaculties: body.applicableFaculties !== undefined
      ? normalizeList(body.applicableFaculties)
      : existingService?.applicableFaculties || [],
    requireVerification: body.requireVerification !== undefined
      ? body.requireVerification !== false
      : existingService?.requireVerification !== false,
    requireActiveStudent: category === "internal" && (
      body.requireActiveStudent !== undefined
        ? body.requireActiveStudent !== false
        : existingService?.requireActiveStudent !== false
    ),
    icon: body.icon || existingService?.icon || "💳",
    paymentWindow: {
      startAt,
      endAt,
      semester: body.paymentWindow?.semester ?? body.semester ?? existingService?.paymentWindow?.semester,
      academicYear: body.paymentWindow?.academicYear ?? body.academicYear ?? existingService?.paymentWindow?.academicYear,
      reminderDaysBeforeDue,
    },
    parkingConfig,
    isActive: body.isActive,
  };
};

const validateServicePayload = (payload) => {
  if (!payload.name || !payload.type) {
    return "Vui lòng nhập tên và loại dịch vụ";
  }

  if (payload.category === "external") {
    return null;
  }

  if (["cohort", "cohort_faculty"].includes(payload.scopeType) && !payload.applicableCohorts.length) {
    return "Vui lòng chọn ít nhất một khoá áp dụng";
  }

  if (["faculty", "cohort_faculty"].includes(payload.scopeType) && !payload.applicableFaculties.length) {
    return "Vui lòng nhập ít nhất một khoa áp dụng";
  }

  if (payload.type === "tuition") {
    if (!payload.paymentWindow.startAt || !payload.paymentWindow.endAt) {
      return "Vui lòng nhập thời hạn nộp học phí";
    }

    if (!payload.paymentWindow.semester || !payload.paymentWindow.academicYear) {
      return "Vui lòng nhập học kỳ và năm học";
    }

    if (payload.paymentWindow.startAt >= payload.paymentWindow.endAt) {
      return "Ngày bắt đầu nộp học phí phải trước ngày kết thúc";
    }
  }

  if (payload.type === "parking") {
    if (payload.parkingConfig.perUsePrice <= 0) {
      return "Vui lòng nhập giá giữ xe theo lượt";
    }

    if (payload.parkingConfig.monthlyPassEnabled) {
      const { monthlyPassPrice, monthlyPassOpenDayFrom, monthlyPassOpenDayTo } = payload.parkingConfig;
      if (monthlyPassPrice <= 0) return "Vui lòng nhập giá gói giữ xe theo tháng";
      if (monthlyPassOpenDayFrom < 1 || monthlyPassOpenDayTo > 31 || monthlyPassOpenDayFrom > monthlyPassOpenDayTo) {
        return "Khoảng ngày mở bán gói tháng không hợp lệ";
      }
    }
  }

  return null;
};

// ==================== DASHBOARD THỐNG KÊ ====================
// GET /api/admin/dashboard
export const getDashboard = async (req, res) => {
  try {
    const [
      totalUsers,
      totalWallets,
      activeWallets,
      lockedWallets,
      verifiedUsers,
      unverifiedUsers,
      lockedUsers,
      totalStudents,
      totalServices,
      activeServices,
      totalTransactions,
    ] = await Promise.all([
      User.countDocuments({ role: "user" }),
      Wallet.countDocuments(),
      Wallet.countDocuments({ status: "active" }),
      Wallet.countDocuments({ status: "locked" }),
      User.countDocuments({ isVerified: true, role: "user" }),
      User.countDocuments({ isVerified: false, role: "user" }),
      User.countDocuments({ isActive: false, role: "user" }),
      Student.countDocuments(),
      Service.countDocuments(),
      Service.countDocuments({ isActive: true }),
      Transaction.countDocuments(),
    ]);

    // Tổng số dư toàn hệ thống
    const balanceResult = await Wallet.aggregate([
      { $group: { _id: null, totalBalance: { $sum: "$balance" } } },
    ]);
    const totalBalance = balanceResult[0]?.totalBalance || 0;

    // Giao dịch gần đây (5 giao dịch mới nhất)
    const recentTransactions = await Transaction.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate({
        path: "walletId",
        select: "userId",
        populate: { path: "userId", select: "fullName phone" },
      });

    return res.status(200).json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          verified: verifiedUsers,
          unverified: unverifiedUsers,
          locked: lockedUsers,
        },
        wallets: {
          total: totalWallets,
          active: activeWallets,
          locked: lockedWallets,
          totalBalance,
        },
        students: { total: totalStudents },
        services: { total: totalServices, active: activeServices },
        transactions: { total: totalTransactions },
        recentTransactions: recentTransactions.map((t) => ({
          id: t._id,
          type: t.type,
          amount: t.amount,
          status: t.status,
          description: t.description,
          user: t.walletId?.userId
            ? {
                fullName: t.walletId.userId.fullName,
                phone: t.walletId.userId.phone,
              }
            : null,
          createdAt: t.createdAt,
        })),
      },
    });
  } catch (error) {
    console.error("getDashboard error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== DANH SÁCH NGƯỜI DÙNG ====================
// GET /api/admin/users?page=1&limit=20&search=keyword
export const getUsers = async (req, res) => {
  try {
    const { page = 1, limit = 20, search = "" } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const filter = { role: "user" };
    if (search) {
      filter.$or = [
        { fullName: { $regex: search, $options: "i" } },
        { phone: { $regex: search, $options: "i" } },
        { studentId: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .select("-password")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      User.countDocuments(filter),
    ]);

    // Lấy ví cho từng user
    const userIds = users.map((u) => u._id);
    const wallets = await Wallet.find({ userId: { $in: userIds } }).select(
      "userId balance status"
    );
    const walletMap = {};
    wallets.forEach((w) => {
      walletMap[w.userId.toString()] = w;
    });

    const usersWithWallet = users.map((u) => {
      const user = u.toObject();
      const wallet = walletMap[u._id.toString()];
      user.wallet = wallet
        ? { balance: wallet.balance, status: wallet.status, id: wallet._id }
        : null;
      return user;
    });

    return res.status(200).json({
      success: true,
      data: {
        users: usersWithWallet,
        pagination: {
          total,
          page: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error("getUsers error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== CHI TIẾT NGƯỜI DÙNG ====================
// GET /api/admin/users/:id
export const getUserDetail = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy người dùng" });
    }

    const wallet = await Wallet.findOne({ userId: user._id });

    // Lấy 10 giao dịch gần nhất
    let recentTransactions = [];
    if (wallet) {
      recentTransactions = await Transaction.find({ walletId: wallet._id })
        .sort({ createdAt: -1 })
        .limit(10);
    }

    return res.status(200).json({
      success: true,
      data: {
        user: user.toObject(),
        wallet: wallet
          ? {
              id: wallet._id,
              balance: wallet.balance,
              status: wallet.status,
              hasPin: Boolean(wallet.pin),
              createdAt: wallet.createdAt,
            }
          : null,
        recentTransactions,
      },
    });
  } catch (error) {
    console.error("getUserDetail error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== KHOÁ TÀI KHOẢN ====================
// PATCH /api/admin/users/:id/lock
export const lockUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy người dùng" });
    }

    if (user.role === "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Không thể khoá tài khoản admin" });
    }

    if (!user.isActive) {
      return res
        .status(400)
        .json({ success: false, message: "Tài khoản đã bị khoá trước đó" });
    }

    user.isActive = false;
    await user.save();

    return res.status(200).json({
      success: true,
      message: `Đã khoá tài khoản "${user.fullName}"`,
    });
  } catch (error) {
    console.error("lockUser error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== MỞ KHOÁ TÀI KHOẢN ====================
// PATCH /api/admin/users/:id/unlock
export const unlockUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy người dùng" });
    }

    if (user.isActive) {
      return res
        .status(400)
        .json({ success: false, message: "Tài khoản đang hoạt động bình thường" });
    }

    user.isActive = true;
    await user.save();

    return res.status(200).json({
      success: true,
      message: `Đã mở khoá tài khoản "${user.fullName}"`,
    });
  } catch (error) {
    console.error("unlockUser error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== KHOÁ VÍ ====================
// PATCH /api/admin/users/:id/lock-wallet
export const lockWallet = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.params.id });
    if (!wallet) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy ví" });
    }

    if (wallet.status === "locked") {
      return res
        .status(400)
        .json({ success: false, message: "Ví đã bị khoá trước đó" });
    }

    wallet.status = "locked";
    await wallet.save();

    return res.status(200).json({
      success: true,
      message: "Đã khoá ví thành công",
    });
  } catch (error) {
    console.error("lockWallet error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== MỞ KHOÁ VÍ ====================
// PATCH /api/admin/users/:id/unlock-wallet
export const unlockWallet = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.params.id });
    if (!wallet) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy ví" });
    }

    if (wallet.status === "active") {
      return res
        .status(400)
        .json({ success: false, message: "Ví đang hoạt động bình thường" });
    }

    wallet.status = "active";
    await wallet.save();

    return res.status(200).json({
      success: true,
      message: "Đã mở khoá ví thành công",
    });
  } catch (error) {
    console.error("unlockWallet error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== RESET MẬT KHẨU ====================
// PATCH /api/admin/users/:id/reset-password
export const resetPassword = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy người dùng" });
    }

    if (user.role === "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Không thể reset mật khẩu admin" });
    }

    // Tạo mật khẩu ngẫu nhiên 8 ký tự
    const newPassword = crypto.randomBytes(4).toString("hex"); // 8 ký tự hex
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    user.password = hashedPassword;
    await user.save();

    return res.status(200).json({
      success: true,
      message: `Đã reset mật khẩu cho "${user.fullName}"`,
      data: {
        newPassword,
        phone: user.phone,
        fullName: user.fullName,
      },
    });
  } catch (error) {
    console.error("resetPassword error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== DANH SÁCH SINH VIÊN ====================
// GET /api/admin/students?page=1&limit=20&search=keyword&cohort=K28&faculty=...&academicStatus=studying
export const getStudents = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      search = "",
      cohort = "",
      faculty = "",
      academicStatus = "",
    } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const andFilters = [];
    if (cohort) {
      const cohortPrefix = cohortToStudentIdPrefix(cohort);
      andFilters.push({
        $or: [
          { cohort },
          ...(cohortPrefix ? [{ studentId: { $regex: `^${cohortPrefix}`, $options: "i" } }] : []),
        ],
      });
    }
    if (faculty) andFilters.push({ faculty });
    if (academicStatus === "studying") {
      andFilters.push({
        $or: [
          { academicStatus: "studying" },
          { academicStatus: { $exists: false } },
          { academicStatus: null },
          { academicStatus: "" },
        ],
      });
    } else if (academicStatus) {
      andFilters.push({ academicStatus });
    }

    if (search) {
      const searchRegex = { $regex: search, $options: "i" };
      const searchCohortPrefix = cohortToStudentIdPrefix(search);
      andFilters.push({ $or: [
        { studentId: searchRegex },
        { fullName: searchRegex },
        { email: searchRegex },
        { faculty: searchRegex },
        { cohort: searchRegex },
        ...(searchCohortPrefix ? [{ studentId: { $regex: `^${searchCohortPrefix}`, $options: "i" } }] : []),
      ] });
    }

    const filter = andFilters.length ? { $and: andFilters } : {};

    const [students, total, cohorts, faculties, cohortSourceStudents] = await Promise.all([
      Student.find(filter)
        .sort({ cohort: -1, faculty: 1, studentId: 1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Student.countDocuments(filter),
      Student.distinct("cohort", { cohort: { $nin: [null, ""] } }),
      Student.distinct("faculty", { faculty: { $nin: [null, ""] } }),
      Student.find({}, "studentId cohort").lean(),
    ]);

    const derivedCohorts = cohortSourceStudents
      .map((student) => student.cohort || deriveCohortFromStudentId(student.studentId))
      .filter(Boolean);
    const cohortOptions = [...new Set([...cohorts, ...derivedCohorts])];

    return res.status(200).json({
      success: true,
      data: {
        students,
        pagination: {
          total,
          page: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
        },
        filterOptions: {
          cohorts: cohortOptions.sort((a, b) => b.localeCompare(a, "vi")),
          faculties: faculties.sort((a, b) => a.localeCompare(b, "vi")),
        },
      },
    });
  } catch (error) {
    console.error("getStudents error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== IMPORT SINH VIÊN TỪ EXCEL ====================
// POST /api/admin/students/import
export const importStudents = async (req, res) => {
  try {
    if (!req.file) {
      return res
        .status(400)
        .json({ success: false, message: "Vui lòng upload file Excel (.xlsx)" });
    }

    const workbook = xlsx.read(req.file.buffer, { type: "buffer" });
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const rawData = xlsx.utils.sheet_to_json(sheet, { defval: "" });

    if (!rawData.length) {
      return res
        .status(400)
        .json({ success: false, message: "File Excel trống" });
    }

    // Map tên cột tiếng Việt → field name
    const columnMap = {
      mssv: "studentId",
      "mã số sinh viên": "studentId",
      "ma so sinh vien": "studentId",
      studentid: "studentId",
      "họ tên": "fullName",
      "ho ten": "fullName",
      fullname: "fullName",
      "ngày sinh": "dateOfBirth",
      "ngay sinh": "dateOfBirth",
      dateofbirth: "dateOfBirth",
      email: "email",
      khoa: "faculty",
      faculty: "faculty",
      facultyname: "faculty",
      lớp: "className",
      lop: "className",
      class: "className",
      classname: "className",
    };

    const normalizeKey = (key) =>
      key
        .trim()
        .toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/\s+/g, " ");

    const students = rawData.map((row) => {
      const mapped = {};
      Object.keys(row).forEach((key) => {
        const normalizedKey = normalizeKey(key);
        const fieldName = columnMap[normalizedKey];
        if (fieldName) {
          mapped[fieldName] = String(row[key]).trim();
        }
      });
      return {
        ...mapped,
        cohort: deriveCohortFromStudentId(mapped.studentId),
        academicStatus: mapped.academicStatus || "studying",
      };
    });

    // Validate
    const errors = [];
    const validStudents = [];

    students.forEach((s, idx) => {
      if (!s.studentId || !s.fullName || !s.dateOfBirth) {
        errors.push(
          `Dòng ${idx + 2}: Thiếu thông tin bắt buộc (MSSV, Họ tên, Ngày sinh)`
        );
      } else {
        validStudents.push(s);
      }
    });

    if (!validStudents.length) {
      return res.status(400).json({
        success: false,
        message: "Không có dữ liệu hợp lệ",
        data: { errors },
      });
    }

    // Upsert: nếu studentId trùng thì update, không thì insert
    let imported = 0;
    let updated = 0;
    const importErrors = [];

    for (const student of validStudents) {
      try {
        const result = await Student.findOneAndUpdate(
          { studentId: student.studentId },
          { $set: student },
          { upsert: true, new: true, runValidators: true }
        );
        if (result.createdAt.getTime() === result.updatedAt.getTime()) {
          imported++;
        } else {
          updated++;
        }
      } catch (err) {
        importErrors.push(`MSSV ${student.studentId}: ${err.message}`);
      }
    }

    return res.status(200).json({
      success: true,
      message: `Import thành công: ${imported} sinh viên mới, ${updated} cập nhật`,
      data: {
        imported,
        updated,
        totalProcessed: validStudents.length,
        errors: [...errors, ...importErrors],
      },
    });
  } catch (error) {
    console.error("importStudents error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== CẬP NHẬT TRẠNG THÁI THEO KHOÁ / KHOA ====================
// PATCH /api/admin/students/cohort-status
export const updateCohortStatus = async (req, res) => {
  try {
    const { cohort, faculty, academicStatus } = req.body;

    if (!cohort || !["studying", "graduated"].includes(academicStatus)) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng chọn khoá và trạng thái hợp lệ",
      });
    }

    const cohortPrefix = cohortToStudentIdPrefix(cohort);
    const filter = {
      $or: [
        { cohort },
        ...(cohortPrefix ? [{ studentId: { $regex: `^${cohortPrefix}`, $options: "i" } }] : []),
      ],
    };
    if (faculty) filter.faculty = faculty;

    const result = await Student.updateMany(filter, { $set: { academicStatus } });
    const statusText = academicStatus === "graduated" ? "đã tốt nghiệp" : "đang học";
    const scopeText = faculty ? `${cohort} - ${faculty}` : cohort;

    return res.status(200).json({
      success: true,
      message: `Đã cập nhật ${result.modifiedCount} sinh viên thuộc ${scopeText} sang trạng thái ${statusText}`,
      data: {
        matched: result.matchedCount,
        modified: result.modifiedCount,
      },
    });
  } catch (error) {
    console.error("updateCohortStatus error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== XOÁ SINH VIÊN ====================
// DELETE /api/admin/students/:id
export const deleteStudent = async (req, res) => {
  try {
    const student = await Student.findByIdAndDelete(req.params.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy sinh viên" });
    }

    return res.status(200).json({
      success: true,
      message: `Đã xoá sinh viên "${student.fullName}" (${student.studentId})`,
    });
  } catch (error) {
    console.error("deleteStudent error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== XOÁ NHIỀU SINH VIÊN ====================
// DELETE /api/admin/students/bulk
export const deleteStudentsBulk = async (req, res) => {
  try {
    const { ids } = req.body;

    if (!Array.isArray(ids) || !ids.length) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng chọn ít nhất một sinh viên để xoá",
      });
    }

    const result = await Student.deleteMany({ _id: { $in: ids } });

    return res.status(200).json({
      success: true,
      message: `Đã xoá ${result.deletedCount} sinh viên`,
      data: { deleted: result.deletedCount },
    });
  } catch (error) {
    console.error("deleteStudentsBulk error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== DANH SÁCH DỊCH VỤ ====================
// GET /api/admin/services
export const getServices = async (req, res) => {
  try {
    const services = await Service.find().sort({ createdAt: -1 });
    return res.status(200).json({ success: true, data: services });
  } catch (error) {
    console.error("getServices error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== THÊM DỊCH VỤ ====================
// POST /api/admin/services
export const createService = async (req, res) => {
  try {
    const payload = buildServicePayload(req.body);
    const validationError = validateServicePayload(payload);
    if (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError,
      });
    }

    delete payload.isActive;
    const service = await Service.create(payload);

    return res.status(201).json({
      success: true,
      message: `Đã thêm dịch vụ "${service.name}"`,
      data: service,
    });
  } catch (error) {
    console.error("createService error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== CẬP NHẬT DỊCH VỤ ====================
// PUT /api/admin/services/:id
export const updateService = async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy dịch vụ" });
    }

    const payload = buildServicePayload(req.body, service);
    const validationError = validateServicePayload(payload);
    if (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError,
      });
    }

    Object.entries(payload).forEach(([key, value]) => {
      if (value !== undefined) service[key] = value;
    });

    await service.save();

    return res.status(200).json({
      success: true,
      message: `Đã cập nhật dịch vụ "${service.name}"`,
      data: service,
    });
  } catch (error) {
    console.error("updateService error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== XOÁ DỊCH VỤ ====================
// DELETE /api/admin/services/:id
export const deleteService = async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy dịch vụ" });
    }

    // Soft delete: deactivate thay vì xoá
    service.isActive = false;
    await service.save();

    return res.status(200).json({
      success: true,
      message: `Đã vô hiệu hoá dịch vụ "${service.name}"`,
    });
  } catch (error) {
    console.error("deleteService error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== XUẤT DANH SÁCH THANH TOÁN DỊCH VỤ ====================
// GET /api/admin/services/:id/payments/export
export const exportServicePayments = async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) {
      return res
        .status(404)
        .json({ success: false, message: "Không tìm thấy dịch vụ" });
    }

    const payments = await Payment.find({
      serviceId: service._id,
      status: "paid",
    })
      .populate("transactionId", "createdAt amount description")
      .sort({ paidAt: 1 });

    const rows = payments.map((payment, index) => ({
      STT: index + 1,
      "Mã sinh viên": payment.studentSnapshot?.studentId || "",
      "Họ tên": payment.studentSnapshot?.fullName || "",
      "Số điện thoại": payment.studentSnapshot?.phone || "",
      "Email": payment.studentSnapshot?.email || "",
      "Khoá": payment.studentSnapshot?.cohort || "",
      "Khoa": payment.studentSnapshot?.faculty || "",
      "Dịch vụ": payment.serviceSnapshot?.name || service.name,
      "Loại dịch vụ": payment.serviceSnapshot?.type || service.type,
      "Học kỳ": payment.serviceSnapshot?.semester || service.paymentWindow?.semester || "",
      "Năm học": payment.serviceSnapshot?.academicYear || service.paymentWindow?.academicYear || "",
      "Nội dung thanh toán": payment.content || payment.transactionId?.description || "",
      "Số tiền": payment.amount,
      "Hình thức": payment.paymentMode === "monthly" ? "Theo tháng" : "Một lần",
      "Thời gian thanh toán": payment.paidAt
        ? new Date(payment.paidAt).toLocaleString("vi-VN")
        : "",
      "Mã giao dịch": payment.transactionId?._id?.toString() || "",
    }));

    const worksheet = xlsx.utils.json_to_sheet(rows);
    const workbook = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(workbook, worksheet, "Thanh toan");
    const buffer = xlsx.write(workbook, { type: "buffer", bookType: "xlsx" });
    const safeName = service.name.replace(/[^\p{L}\p{N}]+/gu, "-").replace(/^-|-$/g, "");

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="payments-${safeName || service._id}.xlsx"`
    );
    return res.send(buffer);
  } catch (error) {
    console.error("exportServicePayments error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};
