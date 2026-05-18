import jwt from "jsonwebtoken";
import User from "../models/User.js";

export const STUDENT_VERIFICATION_REQUIRED_MESSAGE =
  "Hãy xác thực sinh viên để sử dụng các dịch vụ của Uni Ewallet";

// Kiểm tra đăng nhập
export const protect = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      success: false,
      message: "Bạn cần đăng nhập để thực hiện thao tác này",
    });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, role, isVerified }
    next();
  } catch {
    return res.status(401).json({
      success: false,
      message: "Token không hợp lệ hoặc đã hết hạn",
    });
  }
};

// Kiểm tra đã xác thực sinh viên (dùng cho thanh toán nội bộ)
export const studentOnly = (req, res, next) => {
  if (!req.user.isVerified) {
    return res.status(403).json({
      success: false,
      message: STUDENT_VERIFICATION_REQUIRED_MESSAGE,
    });
  }
  next();
};

// Kiểm tra trạng thái xác thực sinh viên từ DB để tránh token cũ giữ sai trạng thái
export const requireStudentVerification = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select("isVerified isActive role");

    if (!user || user.isActive === false) {
      return res.status(403).json({
        success: false,
        message: "Tài khoản của bạn đã bị khoá hoặc không tồn tại",
      });
    }

    if (user.role === "admin") {
      return res.status(403).json({
        success: false,
        message: "Tài khoản admin không được sử dụng dịch vụ ví trên ứng dụng sinh viên",
      });
    }

    if (!user.isVerified) {
      return res.status(403).json({
        success: false,
        message: STUDENT_VERIFICATION_REQUIRED_MESSAGE,
      });
    }

    req.user.isVerified = true;
    next();
  } catch (error) {
    console.error("requireStudentVerification error:", error);
    return res.status(500).json({
      success: false,
      message: "Lỗi server",
    });
  }
};

// Kiểm tra quyền admin
export const adminOnly = (req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({
      success: false,
      message: "Bạn không có quyền thực hiện thao tác này",
    });
  }
  next();
};
