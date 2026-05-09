import Notification from "../models/Notification.js";
import NotificationRead from "../models/NotificationRead.js";
import Payment from "../models/Payment.js";
import Service from "../models/Service.js";
import Student from "../models/Student.js";
import User from "../models/User.js";

const ONE_DAY_MS = 24 * 60 * 60 * 1000;

const escapeRegExp = (value) =>
  String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const deriveCohort = (studentId) => {
  const match = String(studentId || "").trim().match(/^(\d{2})/);
  return match ? `K${match[1]}` : "";
};

const getStudentInfo = async (userId) => {
  const user = await User.findById(userId);
  if (!user?.isVerified || !user.studentId) return null;

  const student = await Student.findOne({
    studentId: { $regex: new RegExp(`^${escapeRegExp(user.studentId.trim())}$`, "i") },
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

const buildTuitionServiceFilter = (student, now) => {
  const scopeConditions = [
    { category: "internal", scopeType: "school" },
  ];

  if (student.cohort) {
    scopeConditions.push({
      category: "internal",
      scopeType: "cohort",
      applicableCohorts: student.cohort,
    });
  }

  if (student.faculty) {
    scopeConditions.push({
      category: "internal",
      scopeType: "faculty",
      applicableFaculties: student.faculty,
    });
  }

  if (student.cohort && student.faculty) {
    scopeConditions.push({
      category: "internal",
      scopeType: "cohort_faculty",
      applicableCohorts: student.cohort,
      applicableFaculties: student.faculty,
    });
  }

  const filter = {
    isActive: true,
    type: "tuition",
    "paymentWindow.endAt": { $gte: now },
    $and: [
      { $or: scopeConditions },
      {
        $or: [
          { "paymentWindow.startAt": { $exists: false } },
          { "paymentWindow.startAt": null },
          { "paymentWindow.startAt": { $lte: now } },
        ],
      },
    ],
  };

  if (student.academicStatus === "graduated") {
    filter.requireActiveStudent = { $ne: true };
  }

  return filter;
};

const normalizeReminderDays = (value) => {
  const days = Array.isArray(value) ? value : [5, 3, 1];
  return [...new Set(days.map(Number).filter((day) => Number.isInteger(day) && day > 0))];
};

const getDaysRemaining = (dueDate, now) => {
  const endAt = new Date(dueDate);
  if (Number.isNaN(endAt.getTime()) || endAt <= now) return null;
  return Math.ceil((endAt.getTime() - now.getTime()) / ONE_DAY_MS);
};

const syncTuitionPaymentDueNotifications = async (userId) => {
  const student = await getStudentInfo(userId);
  if (!student) {
    await Notification.deleteMany({ userId, type: "payment_due" });
    return;
  }

  const now = new Date();
  const services = await Service.find(buildTuitionServiceFilter(student, now)).select(
    "name paymentWindow"
  );
  if (!services.length) {
    await Notification.deleteMany({ userId, type: "payment_due" });
    return;
  }

  const serviceIds = services.map((service) => service._id);
  const paidPayments = await Payment.find({
    userId,
    serviceId: { $in: serviceIds },
    status: "paid",
  }).select("serviceId");

  const paidServiceIds = new Set(
    paidPayments.map((payment) => payment.serviceId.toString())
  );

  const currentReminders = new Map();
  services.forEach((service) => {
    if (paidServiceIds.has(service._id.toString())) return;

    const daysRemaining = getDaysRemaining(service.paymentWindow?.endAt, now);
    const reminderDays = normalizeReminderDays(
      service.paymentWindow?.reminderDaysBeforeDue
    );
    if (!daysRemaining || !reminderDays.includes(daysRemaining)) return;

    currentReminders.set(
      service._id.toString(),
      `chỉ còn ${daysRemaining} ngày thì cổng học phí sẽ đóng cửa. Vui lòng thanh toán khoản học phí của bạn!`
    );
  });

  const existingReminders = await Notification.find({
    userId,
    type: "payment_due",
  }).select("_id relatedId message");

  const keptReminderKeys = new Set();
  const staleReminderIds = existingReminders
    .filter((notification) => {
      const serviceId = notification.relatedId?.toString();
      const currentMessage = serviceId ? currentReminders.get(serviceId) : null;
      const reminderKey = `${serviceId}:${notification.message}`;
      const shouldKeep =
        currentMessage === notification.message && !keptReminderKeys.has(reminderKey);
      if (shouldKeep) keptReminderKeys.add(reminderKey);
      return !shouldKeep;
    })
    .map((notification) => notification._id);

  if (staleReminderIds.length) {
    await Notification.deleteMany({ _id: { $in: staleReminderIds } });
  }

  await Promise.all(
    [...currentReminders.entries()].map(async ([serviceId, message]) => {
      await Notification.findOneAndUpdate(
        {
          userId,
          type: "payment_due",
          relatedId: serviceId,
          message,
        },
        {
          $setOnInsert: {
            userId,
            title: "Nhắc nộp học phí",
            message,
            type: "payment_due",
            relatedId: serviceId,
            link: null,
            fileUrl: null,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
    })
  );
};

// Lấy danh sách thông báo của user hiện tại
// GET /api/notifications
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    await syncTuitionPaymentDueNotifications(userId);

    // Lấy thông báo riêng của user HOẶC thông báo chung (userId = null)
    const notifications = await Notification.find({
      $or: [{ userId }, { userId: null }],
      type: { $ne: "transaction" },
    }).sort({ createdAt: -1 });

    const globalNotificationIds = notifications
      .filter((notification) => notification.userId == null)
      .map((notification) => notification._id);

    const globalReadStates = globalNotificationIds.length
      ? await NotificationRead.find({
          userId,
          notificationId: { $in: globalNotificationIds },
        }).select("notificationId")
      : [];

    const globalReadSet = new Set(
      globalReadStates.map((state) => state.notificationId.toString())
    );

    const normalizedNotifications = notifications.map((notification) => {
      const item = notification.toObject();
      if (item.userId == null) {
        item.isRead = globalReadSet.has(item._id.toString());
      }
      return item;
    });

    return res.status(200).json({
      success: true,
      data: normalizedNotifications
    });
  } catch (error) {
    console.error("getNotifications error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// Đánh dấu 1 thông báo đã đọc
// PUT /api/notifications/:id/read
export const markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const notificationId = req.params.id;

    const notification = await Notification.findOne({ _id: notificationId, userId });

    if (!notification) {
      const globalNotif = await Notification.findOne({ _id: notificationId, userId: null });
      if (globalNotif) {
        await NotificationRead.findOneAndUpdate(
          { notificationId, userId },
          { $set: { readAt: new Date() } },
          { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        return res.status(200).json({ success: true, message: "Đã đánh dấu đọc" });
      }
      return res.status(404).json({ success: false, message: "Không tìm thấy thông báo" });
    }

    notification.isRead = true;
    await notification.save();

    return res.status(200).json({
      success: true,
      message: "Đã đánh dấu đọc"
    });
  } catch (error) {
    console.error("markAsRead error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};
