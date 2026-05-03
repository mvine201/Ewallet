import mongoose from "mongoose";
import Transaction from "../models/Transaction.js";
import Wallet from "../models/Wallet.js";
import { generateAnalyticsAIPlan } from "../libs/analyticsAiBridge.js";

const PERIODS = new Set(["week", "month"]);

const CATEGORY_META = {
  tuition: { title: "Học phí", colorHex: "#2563EB", bucket: "needs" },
  parking: { title: "Giữ xe", colorHex: "#F59E0B", bucket: "needs" },
  dormitory: { title: "Ký túc xá", colorHex: "#7C3AED", bucket: "needs" },
  insurance: { title: "Bảo hiểm", colorHex: "#0EA5E9", bucket: "needs" },
  union_fee: { title: "Đoàn phí", colorHex: "#DC2626", bucket: "needs" },
  library: { title: "Thư viện", colorHex: "#4F46E5", bucket: "needs" },
  canteen: { title: "Ăn uống", colorHex: "#10B981", bucket: "wants" },
  transfer: { title: "Chuyển khoản", colorHex: "#6B7280", bucket: "wants" },
  savings: { title: "Tiết kiệm", colorHex: "#059669", bucket: "savings" },
  other: { title: "Khác", colorHex: "#94A3B8", bucket: "wants" },
};

const normalizePeriod = (value) => (PERIODS.has(value) ? value : "month");

const getPeriodRange = (period) => {
  const now = new Date();
  const start = new Date(now);

  if (period === "week") {
    const day = start.getDay();
    const diff = day === 0 ? 6 : day - 1;
    start.setDate(start.getDate() - diff);
  } else {
    start.setDate(1);
  }

  start.setHours(0, 0, 0, 0);
  return { start, end: now };
};

const dateOnly = (value) => {
  const date = new Date(value);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
};

const fillDailySeries = (start, end, rawItems) => {
  const amountByDate = new Map(rawItems.map((item) => [item._id, item.amount]));
  const result = [];
  const cursor = new Date(start);
  const finalDay = new Date(end);
  cursor.setHours(0, 0, 0, 0);
  finalDay.setHours(0, 0, 0, 0);

  while (cursor <= finalDay) {
    const key = dateOnly(cursor);
    result.push({
      date: key,
      amount: amountByDate.get(key) || 0,
    });
    cursor.setDate(cursor.getDate() + 1);
  }

  return result;
};

const buildFallbackPlan = (stats) => {
  const topCategory = stats.categories[0];
  const savingsCategory = stats.categories.find((item) => item.key === "savings");
  const transferCategory = stats.categories.find((item) => item.key === "transfer");
  const savingsRate = Math.round((savingsCategory?.percentage || 0));
  const totalInflow = stats.totalInflow || 0;
  const expenseToInflow = totalInflow > 0 ? stats.totalExpense / totalInflow : 1;

  let status = "healthy";
  if (expenseToInflow > 0.85) {
    status = "alert";
  } else if (expenseToInflow > 0.65) {
    status = "watch";
  }

  return {
    status,
    headline:
      status === "alert"
        ? "Chi tiêu đang vượt vùng an toàn"
        : status === "watch"
          ? "Chi tiêu cần theo dõi thêm"
          : "Chi tiêu hiện đang ổn định",
    summary: topCategory
      ? `Nhóm chi lớn nhất hiện là ${topCategory.title}.`
      : "Chưa đủ dữ liệu chi tiêu để phân tích.",
    focusLabel: "Ưu tiên kỳ này",
    focusValue: savingsRate < 15
      ? "Tăng tỷ trọng tiết kiệm lên ít nhất 15% tổng chi."
      : topCategory
        ? `Theo dõi sát nhóm ${topCategory.title.toLowerCase()}.`
        : "Bắt đầu ghi nhận thêm giao dịch.",
    actions: [
      {
        title: savingsRate < 15 ? "Tăng tích luỹ" : "Giữ nhịp hiện tại",
        detail: savingsRate < 15
          ? "Mỗi lần có tiền vào ví, chuyển một phần nhỏ sang quỹ tiết kiệm."
          : "Tiếp tục theo dõi nhóm chi lớn nhất để tránh tăng đột biến.",
        tag: savingsRate < 15 ? "Ưu tiên" : "Ổn định",
        emphasis: savingsRate < 15 ? "save" : "keep",
      },
      {
        title: "So sánh theo chu kỳ",
        detail: "Đổi giữa Tuần và Tháng để nhận ra danh mục tăng mạnh.",
        tag: "Mẹo dùng nhanh",
        emphasis: "watch",
      },
      {
        title: "Rà soát chuyển khoản",
        detail: transferCategory
          ? "Các khoản chuyển tiền đi nên có nội dung rõ mục đích để dễ kiểm soát."
          : "Giữ nội dung giao dịch đầy đủ để báo cáo chi tiêu rõ hơn.",
        tag: "Theo dõi",
        emphasis: "watch",
      },
    ],
    badges: [
      totalInflow > 0 ? `Chi ra ${Math.round(expenseToInflow * 100)}% dòng tiền vào` : "Chưa có dữ liệu tiền vào",
      `Tiết kiệm ${savingsRate}% tổng chi`,
      topCategory ? `Lớn nhất: ${topCategory.title}` : "Đang chờ thêm dữ liệu",
    ],
    metrics: {
      stabilityScore: status === "alert" ? 38 : status === "watch" ? 62 : 84,
      needsRate: Math.round(
        stats.categories
          .filter((item) => CATEGORY_META[item.key]?.bucket === "needs")
          .reduce((sum, item) => sum + item.percentage, 0)
      ),
      wantsRate: Math.round(
        stats.categories
          .filter((item) => CATEGORY_META[item.key]?.bucket === "wants")
          .reduce((sum, item) => sum + item.percentage, 0)
      ),
      savingsRate,
    },
    source: "node-fallback",
  };
};

const buildAnalyticsStats = async (userId, period) => {
  const wallet = await Wallet.findOne({ userId }).select("_id");
  if (!wallet) {
    return null;
  }

  const { start, end } = getPeriodRange(period);
  const walletObjectId = new mongoose.Types.ObjectId(wallet._id);

  const [aggregate] = await Transaction.aggregate([
    {
      $match: {
        walletId: walletObjectId,
        status: "success",
        createdAt: { $gte: start, $lte: end },
      },
    },
    {
      $lookup: {
        from: "payments",
        localField: "_id",
        foreignField: "transactionId",
        as: "paymentDocs",
      },
    },
    {
      $addFields: {
        paymentDoc: { $first: "$paymentDocs" },
        isTransferIn: {
          $and: [
            { $eq: ["$type", "transfer"] },
            { $eq: ["$receiverWalletId", walletObjectId] },
          ],
        },
      },
    },
    {
      $addFields: {
        flow: {
          $switch: {
            branches: [
              { case: "$isTransferIn", then: "in" },
              {
                case: { $in: ["$type", ["topup", "refund", "savings_withdraw"]] },
                then: "in",
              },
            ],
            default: "out",
          },
        },
        categoryKey: {
          $switch: {
            branches: [
              { case: { $eq: ["$type", "savings_deposit"] }, then: "savings" },
              { case: { $eq: ["$type", "transfer"] }, then: "transfer" },
              { case: { $eq: ["$paymentDoc.serviceSnapshot.type", "tuition"] }, then: "tuition" },
              { case: { $eq: ["$paymentDoc.serviceSnapshot.type", "parking"] }, then: "parking" },
              { case: { $eq: ["$paymentDoc.serviceSnapshot.type", "dormitory"] }, then: "dormitory" },
              { case: { $eq: ["$paymentDoc.serviceSnapshot.type", "insurance"] }, then: "insurance" },
              { case: { $eq: ["$paymentDoc.serviceSnapshot.type", "union_fee"] }, then: "union_fee" },
              { case: { $eq: ["$paymentDoc.serviceSnapshot.type", "library"] }, then: "library" },
              { case: { $eq: ["$paymentDoc.serviceSnapshot.type", "canteen"] }, then: "canteen" },
            ],
            default: "other",
          },
        },
      },
    },
    {
      $facet: {
        categories: [
          { $match: { flow: "out" } },
          {
            $group: {
              _id: "$categoryKey",
              amount: { $sum: "$amount" },
              transactionCount: { $sum: 1 },
            },
          },
          { $sort: { amount: -1 } },
        ],
        daily: [
          { $match: { flow: "out" } },
          {
            $group: {
              _id: {
                $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
              },
              amount: { $sum: "$amount" },
            },
          },
          { $sort: { _id: 1 } },
        ],
        totals: [
          { $match: { flow: "out" } },
          {
            $group: {
              _id: null,
              totalExpense: { $sum: "$amount" },
              transactionCount: { $sum: 1 },
            },
          },
        ],
        inflow: [
          { $match: { flow: "in" } },
          {
            $group: {
              _id: null,
              totalInflow: { $sum: "$amount" },
            },
          },
        ],
      },
    },
  ]);

  const totalExpense = aggregate?.totals?.[0]?.totalExpense || 0;
  const totalInflow = aggregate?.inflow?.[0]?.totalInflow || 0;
  const transactionCount = aggregate?.totals?.[0]?.transactionCount || 0;

  const categories = (aggregate?.categories || []).map((item) => {
    const meta = CATEGORY_META[item._id] || CATEGORY_META.other;
    const percentage = totalExpense > 0 ? (item.amount / totalExpense) * 100 : 0;

    return {
      key: item._id,
      title: meta.title,
      colorHex: meta.colorHex,
      bucket: meta.bucket,
      amount: item.amount,
      percentage: Number(percentage.toFixed(1)),
      transactionCount: item.transactionCount,
    };
  });

  const topCategory = categories[0] || null;

  return {
    period,
    startDate: dateOnly(start),
    endDate: dateOnly(end),
    totalExpense,
    totalInflow,
    netCashFlow: totalInflow - totalExpense,
    categories,
    daily: fillDailySeries(start, end, aggregate?.daily || []),
    summary: {
      topCategoryTitle: topCategory?.title || null,
      topCategoryAmount: topCategory?.amount || 0,
      topCategoryPercentage: topCategory?.percentage || 0,
      transactionCount,
    },
  };
};

export const getAnalyticsStats = async (req, res) => {
  try {
    const period = normalizePeriod(req.query.period);
    const stats = await buildAnalyticsStats(req.user.id, period);

    if (!stats) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy ví để thống kê",
      });
    }

    return res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("getAnalyticsStats error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

export const getAnalyticsAIPlan = async (req, res) => {
  try {
    const period = normalizePeriod(req.query.period);
    const stats = await buildAnalyticsStats(req.user.id, period);

    if (!stats) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy ví để phân tích",
      });
    }

    let plan;
    try {
      plan = await generateAnalyticsAIPlan({ stats });
    } catch (error) {
      console.error("analytics AI bridge error:", error);
      plan = buildFallbackPlan(stats);
    }

    return res.status(200).json({
      success: true,
      data: {
        period,
        generatedAt: new Date().toISOString(),
        ...plan,
      },
    });
  } catch (error) {
    console.error("getAnalyticsAIPlan error:", error);
    return res.status(500).json({ success: false, message: "Lỗi server" });
  }
};
