import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import { findStudentById } from "../data/mockStudents.js";

const signToken = (user) =>
  jwt.sign(
    { id: user._id, role: user.role, isVerified: user.isVerified },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );

const normalizeText = (value) =>
  value
    ?.trim()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ")
    .toLowerCase();

const normalizeDate = (dateString) => {
  if (!dateString) return "";
  const str = dateString.trim();
  // match format: DD/MM/YYYY or DD-MM-YYYY
  const dmMatch = str.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})$/);
  if (dmMatch) {
    return `${dmMatch[3]}-${dmMatch[2].padStart(2, "0")}-${dmMatch[1].padStart(2, "0")}`;
  }
  // match format: YYYY-MM-DD or YYYY/MM/DD
  const ymMatch = str.match(/^(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})$/);
  if (ymMatch) {
    return `${ymMatch[1]}-${ymMatch[2].padStart(2, "0")}-${ymMatch[3].padStart(2, "0")}`;
  }
  return str;
};

// ==================== ĐĂNG KÝ ====================
export const register = async (req, res) => {
  try {
    const { phone, password, fullName, email } = req.body;

    // Validate input
    if (!phone || !password || !fullName) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng điền đầy đủ họ tên, số điện thoại và mật khẩu",
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu phải có ít nhất 6 ký tự",
      });
    }

    // Kiểm tra phone trùng
    const existingPhone = await User.findOne({ phone });
    if (existingPhone) {
      return res.status(409).json({
        success: false,
        message: "Số điện thoại đã được đăng ký",
      });
    }

    // Kiểm tra email trùng (nếu có nhập)
    if (email) {
      const existingEmail = await User.findOne({ email });
      if (existingEmail) {
        return res.status(409).json({
          success: false,
          message: "Email đã được đăng ký",
        });
      }
    }

    // Tạo user
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({
      phone,
      password: hashedPassword,
      fullName,
      email: email || null,
      isVerified: false, // chưa xác thực sinh viên
    });

    // Tự động tạo ví
    await Wallet.create({ userId: user._id });

    const token = signToken(user);

    return res.status(201).json({
      success: true,
      message: "Đăng ký thành công",
      data: {
        token,
        user: {
          id: user._id,
          fullName: user.fullName,
          phone: user.phone,
          email: user.email,
          role: user.role,
          isVerified: user.isVerified,
        },
      },
    });
  } catch (error) {
    console.error("register error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== ĐĂNG NHẬP ====================
export const login = async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập số điện thoại và mật khẩu",
      });
    }

    // Tìm user
    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Số điện thoại hoặc mật khẩu không đúng",
      });
    }

    // Kiểm tra tài khoản bị khoá
    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: "Tài khoản của bạn đã bị khoá. Vui lòng liên hệ nhà trường",
      });
    }

    // Kiểm tra mật khẩu
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Số điện thoại hoặc mật khẩu không đúng",
      });
    }

    const token = signToken(user);

    return res.status(200).json({
      success: true,
      message: "Đăng nhập thành công",
      data: {
        token,
        user: {
          id: user._id,
          fullName: user.fullName,
          phone: user.phone,
          email: user.email,
          studentId: user.studentId,
          role: user.role,
          isVerified: user.isVerified,
          avatar: user.avatar,
        },
      },
    });
  } catch (error) {
    console.error("login error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== XÁC THỰC SINH VIÊN ====================
export const verifyStudent = async (req, res) => {
  try {
    const { studentId, fullName, dateOfBirth } = req.body;

    if (!studentId || !fullName || !dateOfBirth) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập mã số sinh viên, họ tên và ngày sinh",
      });
    }

    const normalizedStudentId = studentId.trim();
    const normalizedFullName = fullName.trim().replace(/\s+/g, " ");
    const normalizedDateOfBirth = dateOfBirth.trim();
    const matchedStudent = await findStudentById(normalizedStudentId);

    if (!matchedStudent) {
      return res.status(404).json({
        success: false,
        message: "Mã số sinh viên không tồn tại trong danh sách xác thực",
      });
    }

    const isStudentInfoMatched =
      normalizeText(matchedStudent.fullName) === normalizeText(normalizedFullName) &&
      normalizeDate(matchedStudent.dateOfBirth) === normalizeDate(normalizedDateOfBirth);

    if (!isStudentInfoMatched) {
      return res.status(400).json({
        success: false,
        message: "Thông tin sinh viên không khớp với dữ liệu xác thực",
      });
    }

    const currentUser = await User.findById(req.user.id);
    if (!currentUser) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản",
      });
    }

    if (currentUser.isVerified) {
      return res.status(409).json({
        success: false,
        message: "Tài khoản đã được xác thực sinh viên",
      });
    }

    // Kiểm tra MSSV đã được dùng bởi tài khoản khác chưa
    const existingStudent = await User.findOne({ studentId: normalizedStudentId });
    if (existingStudent && existingStudent._id.toString() !== req.user.id) {
      return res.status(409).json({
        success: false,
        message: "Mã số sinh viên đã được liên kết với tài khoản khác",
      });
    }

    // Cập nhật user
    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        studentId: normalizedStudentId,
        studentFullName: matchedStudent.fullName,
        dateOfBirth: matchedStudent.dateOfBirth,
        isVerified: true,
        email: currentUser.email || matchedStudent.email,
      },
      { new: true }
    ).select("-password");

    return res.status(200).json({
      success: true,
      message: "Xác thực sinh viên thành công",
      data: {
        id: user._id,
        fullName: user.fullName,
        studentId: user.studentId,
        studentFullName: user.studentFullName,
        dateOfBirth: user.dateOfBirth,
        isVerified: user.isVerified,
        cohort: matchedStudent.cohort,
        faculty: matchedStudent.faculty,
        academicStatus: matchedStudent.academicStatus,
      },
    });
  } catch (error) {
    console.error("verifyStudent error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== ĐỔI MẬT KHẨU ====================
export const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập mật khẩu hiện tại và mật khẩu mới",
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu mới phải có ít nhất 6 ký tự",
      });
    }

    if (currentPassword === newPassword) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu mới không được trùng mật khẩu hiện tại",
      });
    }

    const user = await User.findById(req.user.id);
    if (!user || !user.isActive) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản",
      });
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Mật khẩu hiện tại không đúng",
      });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    return res.status(200).json({
      success: true,
      message: "Đổi mật khẩu thành công",
    });
  } catch (error) {
    console.error("changePassword error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ==================== LẤY THÔNG TIN BẢN THÂN ====================
export const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");
    if (!user) {
      return res.status(404).json({ success: false, message: "Không tìm thấy tài khoản" });
    }

    const userData = user.toObject();
    const matchedStudent = user.isVerified
      ? await findStudentById(user.studentId)
      : null;

    userData.studentInfo = matchedStudent
      ? {
          studentId: matchedStudent.studentId,
          fullName: matchedStudent.fullName,
          dateOfBirth: matchedStudent.dateOfBirth,
          email: matchedStudent.email,
          cohort: matchedStudent.cohort,
          faculty: matchedStudent.faculty,
          academicStatus: matchedStudent.academicStatus,
        }
      : null;

    return res.status(200).json({ success: true, data: userData });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};
