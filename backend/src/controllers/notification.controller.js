import Notification from "../models/Notification.js";

// Lấy danh sách thông báo của user hiện tại
// GET /api/notifications
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    // Lấy thông báo riêng của user HOẶC thông báo chung (userId = null)
    const notifications = await Notification.find({
      $or: [{ userId }, { userId: null }]
    }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: notifications
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

    // Tìm thông báo (nếu là thông báo chung, ta không cập nhật isRead vì nó sẽ cập nhật cho mọi người)
    // Tạm thời để đơn giản, nếu là thông báo riêng của user thì cập nhật isRead: true
    // Nếu là thông báo chung, do đang dùng model chung, ta có thể bỏ qua hoặc tạo 1 schema ReadStatus (phức tạp)
    // Trong giới hạn project, Admin sẽ gửi thông báo vào thẳng các User (tạo nhiều document)
    // -> Nên Notification luôn có userId.
    
    const notification = await Notification.findOne({ _id: notificationId, userId });
    
    if (!notification) {
      // Có thể là thông báo chung userId = null, ta không đánh dấu isRead được trên schema này.
      // Nhưng nếu yêu cầu bắt buộc, chúng ta có thể bỏ qua.
      const globalNotif = await Notification.findOne({ _id: notificationId, userId: null });
      if (globalNotif) {
         return res.status(200).json({ success: true, message: "Đã đọc (thông báo chung)" });
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
