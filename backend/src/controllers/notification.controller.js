import Notification from "../models/Notification.js";
import NotificationRead from "../models/NotificationRead.js";

// Lấy danh sách thông báo của user hiện tại
// GET /api/notifications
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
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
