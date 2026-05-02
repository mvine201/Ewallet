import Transaction from "../models/Transaction.js";
import VnpayTransaction from "../models/VNPayTransaction.js";

export const DAILY_TRANSACTION_LIMIT = 50000000;

const VN_UTC_OFFSET_HOURS = 7;

export const getVietnamDayRange = (date = new Date()) => {
  const utcMillis = date.getTime();
  const vnMillis = utcMillis + VN_UTC_OFFSET_HOURS * 60 * 60 * 1000;
  const vnDate = new Date(vnMillis);

  const startOfDayInVietnam = Date.UTC(
    vnDate.getUTCFullYear(),
    vnDate.getUTCMonth(),
    vnDate.getUTCDate(),
    0,
    0,
    0,
    0
  ) - VN_UTC_OFFSET_HOURS * 60 * 60 * 1000;

  return {
    start: new Date(startOfDayInVietnam),
    end: new Date(startOfDayInVietnam + 24 * 60 * 60 * 1000),
  };
};

const withSession = (query, session) => (session ? query.session(session) : query);

export const getSuccessfulTransactionTotalForWallet = async (walletId, session) => {
  const { start, end } = getVietnamDayRange();
  const result = await withSession(
    Transaction.aggregate([
      {
        $match: {
          walletId,
          status: "success",
          createdAt: { $gte: start, $lt: end },
        },
      },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: "$amount" },
        },
      },
    ]),
    session
  );

  return result[0]?.totalAmount || 0;
};

export const getPendingTopupTotalForWallet = async (walletId, session) => {
  const { start, end } = getVietnamDayRange();
  const result = await withSession(
    VnpayTransaction.aggregate([
      {
        $match: {
          walletId,
          status: "pending",
          createdAt: { $gte: start, $lt: end },
        },
      },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: "$amount" },
        },
      },
    ]),
    session
  );

  return result[0]?.totalAmount || 0;
};

export const ensureWithinDailyTransactionLimit = async ({
  walletId,
  amount,
  session,
  includePendingTopups = false,
}) => {
  const normalizedAmount = Number(amount) || 0;
  const successfulTotal = await getSuccessfulTransactionTotalForWallet(walletId, session);
  const pendingTopupTotal = includePendingTopups
    ? await getPendingTopupTotalForWallet(walletId, session)
    : 0;

  const currentTotal = successfulTotal + pendingTopupTotal;
  const projectedTotal = currentTotal + normalizedAmount;

  if (projectedTotal > DAILY_TRANSACTION_LIMIT) {
    const remaining = Math.max(0, DAILY_TRANSACTION_LIMIT - currentTotal);
    const error = new Error("DAILY_TRANSACTION_LIMIT_EXCEEDED");
    error.code = "DAILY_TRANSACTION_LIMIT_EXCEEDED";
    error.currentTotal = currentTotal;
    error.remaining = remaining;
    error.limit = DAILY_TRANSACTION_LIMIT;
    throw error;
  }

  return {
    currentTotal,
    remaining: DAILY_TRANSACTION_LIMIT - currentTotal,
    limit: DAILY_TRANSACTION_LIMIT,
  };
};
