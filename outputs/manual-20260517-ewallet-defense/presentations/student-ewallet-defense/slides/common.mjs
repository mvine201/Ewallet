const C = {
  coral: "#f45b63",
  coral2: "#ef1d1d",
  navy: "#18202c",
  navy2: "#111827",
  ink: "#202631",
  gray: "#6b7280",
  light: "#eef1f5",
  paper: "#fbfbfa",
  white: "#ffffff",
  mint: "#14b88a",
  blue: "#2f80ed",
  amber: "#f59e0b",
};

const media = (ctx, name) => `${ctx.workspaceDir}/assets/report-media/${name}`;
const repo = (ctx, path) => `/Users/macvanvinh/MyProject/Student_eWallet/${path}`;

function bg(slide, ctx, opts = {}) {
  ctx.addShape(slide, { x: 0, y: 0, w: ctx.W, h: ctx.H, fill: C.paper, line: ctx.line() });
  ctx.addShape(slide, { x: 0, y: 0, w: ctx.W, h: 7, fill: C.navy, line: ctx.line() });
  if (opts.band !== false) ctx.addShape(slide, { x: 0, y: 650, w: ctx.W, h: 10, fill: C.coral, line: ctx.line() });
  ctx.addText(slide, {
    text: `Slide ${String(ctx.slideNumber).padStart(2, "0")}`,
    x: 18,
    y: 675,
    w: 100,
    h: 18,
    fontSize: 8,
    color: "#9aa1aa",
  });
}

function text(slide, ctx, value, x, y, w, h, opt = {}) {
  return ctx.addText(slide, {
    text: value,
    x,
    y,
    w,
    h,
    fontSize: opt.size ?? 24,
    color: opt.color ?? C.ink,
    bold: opt.bold ?? false,
    typeface: opt.face ?? (opt.title ? ctx.fonts.title : ctx.fonts.body),
    align: opt.align ?? "left",
    valign: opt.valign ?? "top",
    fill: opt.fill ?? "#00000000",
    line: opt.line ?? ctx.line(),
    insets: opt.insets ?? { left: 0, right: 0, top: 0, bottom: 0 },
  });
}

function kicker(slide, ctx, label, x = 72, y = 42) {
  ctx.addShape(slide, { x, y: y + 5, w: 16, h: 16, fill: C.coral, line: ctx.line() });
  text(slide, ctx, label.toUpperCase(), x + 26, y, 330, 28, { size: 13, color: C.gray, bold: true, valign: "middle" });
}

function title(slide, ctx, label, claim, opt = {}) {
  bg(slide, ctx);
  kicker(slide, ctx, label);
  text(slide, ctx, claim, 72, 72, 980, 76, { size: opt.size ?? 34, color: C.coral, bold: true, title: true });
  if (opt.rule !== false) ctx.addShape(slide, { x: 72, y: 156, w: 1130, h: 2, fill: C.light, line: ctx.line() });
}

function bandTitle(slide, ctx, label, claim) {
  bg(slide, ctx);
  ctx.addShape(slide, { x: 0, y: 54, w: ctx.W, h: 56, fill: C.coral, line: ctx.line() });
  text(slide, ctx, label.toUpperCase(), 72, 38, 320, 22, { size: 12, color: C.gray, bold: true });
  text(slide, ctx, claim, 72, 66, 1080, 32, { size: 24, color: C.white, bold: true, align: "center", valign: "middle" });
}

function bulletBlock(slide, ctx, items, x, y, w, h, opt = {}) {
  const content = items.map((item) => `- ${item}`).join("\n");
  return text(slide, ctx, content, x, y, w, h, {
    size: opt.size ?? 18,
    color: opt.color ?? C.ink,
    fill: opt.fill ?? "#00000000",
    line: opt.line ?? ctx.line(),
    insets: opt.insets ?? { left: 16, right: 14, top: 12, bottom: 10 },
  });
}

function labelCard(slide, ctx, label, body, x, y, w, h, opt = {}) {
  ctx.addShape(slide, {
    x,
    y,
    w,
    h,
    fill: opt.fill ?? C.white,
    line: opt.line ?? { style: "solid", fill: opt.border ?? C.light, width: 1 },
  });
  text(slide, ctx, label, x + 18, y + 14, w - 36, 24, { size: opt.labelSize ?? 16, color: opt.labelColor ?? C.coral, bold: true });
  text(slide, ctx, body, x + 18, y + 46, w - 36, h - 58, { size: opt.bodySize ?? 16, color: opt.bodyColor ?? C.ink });
}

function metric(slide, ctx, value, label, x, y, w, h, opt = {}) {
  ctx.addShape(slide, { x, y, w, h, fill: opt.fill ?? C.navy, line: ctx.line() });
  const valueH = Math.min(38, Math.max(26, h * 0.42));
  text(slide, ctx, value, x + 16, y + 12, w - 32, valueH, { size: opt.valueSize ?? 30, color: opt.valueColor ?? C.white, bold: true, align: "center", valign: "middle" });
  text(slide, ctx, label, x + 16, y + 18 + valueH, w - 32, Math.max(18, h - valueH - 26), { size: opt.labelSize ?? 13, color: opt.labelColor ?? "#dbe1ea", align: "center" });
}

function node(slide, ctx, label, x, y, w, h, opt = {}) {
  ctx.addShape(slide, { x, y, w, h, fill: opt.fill ?? C.navy, line: ctx.line() });
  text(slide, ctx, label, x + 10, y + 10, w - 20, h - 20, {
    size: opt.size ?? 16,
    color: opt.color ?? C.white,
    bold: opt.bold ?? true,
    align: "center",
    valign: "middle",
  });
}

function hline(slide, ctx, x1, y, x2, color = "#cfd4db", h = 2) {
  ctx.addShape(slide, { x: x1, y, w: x2 - x1, h, fill: color, line: ctx.line() });
}

function vline(slide, ctx, x, y1, y2, color = "#cfd4db", w = 2) {
  ctx.addShape(slide, { x, y: y1, w, h: y2 - y1, fill: color, line: ctx.line() });
}

function smallBar(slide, ctx, x, y, w, label, color = C.coral) {
  ctx.addShape(slide, { x, y, w, h: 10, fill: color, line: ctx.line() });
  text(slide, ctx, label, x, y + 15, 150, 18, { size: 11, color: C.gray });
}

async function phoneShot(slide, ctx, img, x, y, w, h, caption) {
  ctx.addShape(slide, { x, y, w, h, fill: C.white, line: { style: "solid", fill: "#e5e7eb", width: 1 } });
  await ctx.addImage(slide, { path: media(ctx, img), x: x + 4, y: y + 4, w: w - 8, h: h - 34, fit: "contain", alt: caption });
  text(slide, ctx, caption, x + 8, y + h - 24, w - 16, 18, { size: 11, color: C.gray, align: "center" });
}

async function slide01(presentation, ctx) {
  const slide = presentation.slides.add();
  bg(slide, ctx, { band: false });
  ctx.addShape(slide, { x: 0, y: 0, w: 24, h: 720, fill: C.coral, line: ctx.line() });
  ctx.addShape(slide, { x: 38, y: 54, w: 645, h: 372, fill: C.coral, line: ctx.line() });
  ctx.addShape(slide, { x: 86, y: 34, w: 645, h: 372, fill: "#00000000", line: { style: "solid", fill: C.navy, width: 1 } });
  ctx.addShape(slide, { x: 1068, y: 42, w: 92, h: 32, fill: C.coral, line: ctx.line() });
  text(slide, ctx, "UNI EWALLET", 1078, 49, 72, 18, { size: 11, color: C.white, bold: true, align: "center" });
  await ctx.addImage(slide, { path: repo(ctx, "iosApp/Student eWallet/Student eWallet/Assets.xcassets/LogoUniEwallet_xoanen.imageset/LogoUniEwallet_xoanen.png"), x: 200, y: 122, w: 320, h: 220, fit: "contain", alt: "Uni Ewallet logo" });
  text(slide, ctx, "KHÓA LUẬN TỐT NGHIỆP", 760, 138, 360, 24, { size: 15, color: C.coral, bold: true });
  text(slide, ctx, "Xây dựng ứng dụng ví điện tử sinh viên", 760, 176, 410, 92, { size: 34, color: C.ink, bold: true, title: true });
  text(slide, ctx, "Hỗ trợ thanh toán phí nội bộ trường học và tích hợp AI quản lý chi tiêu", 760, 286, 410, 72, { size: 19, color: C.gray });
  ctx.addShape(slide, { x: 760, y: 395, w: 322, h: 4, fill: C.navy, line: ctx.line() });
  text(slide, ctx, "SVTH: Mạc Văn Vinh - 28211152394\nGVHD: Th.S Nguyễn Mạnh Đức\nĐà Nẵng, 06/2026", 760, 420, 420, 86, { size: 17, color: C.ink });
  ctx.addShape(slide, { x: 940, y: 612, w: 270, h: 14, fill: C.coral, line: ctx.line() });
  return slide;
}

function slide02(presentation, ctx) {
  const slide = presentation.slides.add();
  bg(slide, ctx, { band: false });
  ctx.addShape(slide, { x: 665, y: 66, w: 220, h: 92, fill: C.navy, line: ctx.line() });
  ctx.addShape(slide, { x: 641, y: 52, w: 220, h: 92, fill: "#00000000", line: { style: "solid", fill: "#aab0b8", width: 1 } });
  text(slide, ctx, "NỘI DUNG", 690, 96, 150, 26, { size: 23, color: C.white, bold: true, align: "center" });
  const items = [
    "Bối cảnh & lý do chọn đề tài",
    "Mục tiêu, phạm vi, đối tượng",
    "Phân tích use case & giải pháp",
    "Kiến trúc, CSDL, triển khai",
    "Kết quả, hạn chế, hướng phát triển",
  ];
  items.forEach((it, i) => {
    const y = 210 + i * 70;
    ctx.addShape(slide, { x: 292, y, w: 42, h: 42, fill: i % 2 === 0 ? C.coral : C.navy, line: ctx.line() });
    text(slide, ctx, String(i + 1), 300, y + 7, 26, 24, { size: 20, color: C.white, bold: true, align: "center", valign: "middle" });
    ctx.addShape(slide, { x: 354, y: y + 8, w: 450, h: 26, fill: i % 2 === 0 ? C.coral : C.navy, line: ctx.line() });
    text(slide, ctx, it.toUpperCase(), 374, y + 13, 400, 16, { size: 13, color: C.white, bold: true });
  });
  return slide;
}

function slide03(presentation, ctx) {
  const slide = presentation.slides.add();
  title(slide, ctx, "Bối cảnh", "Thanh toán nội bộ trường học cần một ví sinh viên chuyên biệt.");
  labelCard(slide, ctx, "Vấn đề 01", "Sinh viên khó theo dõi số dư và dễ phát sinh tình huống không đủ tiền khi cần thanh toán dịch vụ.", 72, 208, 335, 176);
  labelCard(slide, ctx, "Vấn đề 02", "Thông báo học phí, dịch vụ và nhắc hạn còn phân tán; sinh viên có thể bỏ lỡ mốc quan trọng.", 472, 208, 335, 176, { fill: C.navy, labelColor: C.coral, bodyColor: C.white, border: C.navy });
  labelCard(slide, ctx, "Vấn đề 03", "Ví điện tử phổ biến chưa được thiết kế riêng cho nghiệp vụ và dữ liệu trong môi trường giáo dục.", 872, 208, 335, 176);
  metric(slide, ctx, "85%", "người dùng Internet tại Việt Nam sở hữu ít nhất một ví điện tử theo báo cáo trích dẫn trong luận văn.", 115, 454, 260, 126);
  metric(slide, ctx, "71%", "sử dụng ví điện tử hàng tuần, cho thấy hành vi thanh toán số đã đủ quen thuộc.", 510, 454, 260, 126, { fill: C.coral });
  metric(slide, ctx, "1 hệ sinh thái", "đề tài hướng đến ví + dịch vụ trường + phân tích chi tiêu + quản trị.", 905, 454, 260, 126);
  return slide;
}

function slide04(presentation, ctx) {
  const slide = presentation.slides.add();
  bandTitle(slide, ctx, "Mục tiêu", "Đề tài tập trung vào ví iOS cho sinh viên và cổng quản trị cho nhà trường.");
  const cols = [
    ["Mục đích", ["Nghiên cứu kiến trúc hệ thống ví điện tử.", "Ứng dụng UIKit và Express để xây dựng sản phẩm.", "Hỗ trợ thanh toán không tiền mặt trong trường học."]],
    ["Đối tượng", ["Học sinh, sinh viên cần chuyển tiền và thanh toán dịch vụ.", "Trường học cần quản lý phí, dịch vụ và thông báo.", "Quản trị viên theo dõi vận hành hệ thống."]],
    ["Phạm vi", ["Phân tích yêu cầu và thiết kế giao diện.", "Phát triển iOS app, backend và admin web.", "Kiểm thử các chức năng người dùng chính."]],
  ];
  cols.forEach(([head, items], i) => {
    const x = 80 + i * 390;
    ctx.addShape(slide, { x, y: 170, w: 320, h: 70, fill: i === 1 ? C.navy : C.coral, line: ctx.line() });
    text(slide, ctx, head.toUpperCase(), x + 18, 192, 280, 24, { size: 20, color: C.white, bold: true, align: "center" });
    bulletBlock(slide, ctx, items, x, 260, 320, 230, { size: 17, fill: C.white, line: { style: "solid", fill: "#e5e7eb", width: 1 } });
  });
  text(slide, ctx, "Kết quả kỳ vọng: hoàn thành các chức năng cơ bản của hệ thống trong thời gian triển khai khóa luận.", 160, 545, 960, 36, { size: 20, color: C.ink, align: "center", bold: true });
  return slide;
}

function slide05(presentation, ctx) {
  const slide = presentation.slides.add();
  title(slide, ctx, "Giải pháp", "Ba nhóm người dùng cùng vận hành trên một hệ sinh thái ví.");
  node(slide, ctx, "Người dùng chưa đăng ký\nĐăng ký - Đăng nhập", 82, 252, 230, 92, { fill: C.coral });
  node(slide, ctx, "Sinh viên\nVí - Dịch vụ - AI - Tiết kiệm", 510, 232, 260, 132, { fill: C.navy });
  node(slide, ctx, "Quản trị\nDữ liệu - Dịch vụ - Thông báo", 958, 252, 230, 92, { fill: C.coral });
  hline(slide, ctx, 312, 298, 510, C.gray, 3);
  hline(slide, ctx, 770, 298, 958, C.gray, 3);
  const usecases = ["Xác thực sinh viên", "Xem số dư", "Nạp tiền", "Chuyển tiền", "Thanh toán dịch vụ", "Lịch sử giao dịch", "Thống kê & AI", "Hũ tiết kiệm"];
  usecases.forEach((u, i) => {
    const x = 172 + (i % 4) * 235;
    const y = 440 + Math.floor(i / 4) * 58;
    ctx.addShape(slide, { x, y, w: 190, h: 36, fill: i % 2 ? C.white : C.light, line: { style: "solid", fill: "#dde2e8", width: 1 } });
    text(slide, ctx, u, x + 10, y + 9, 170, 16, { size: 14, color: C.ink, bold: true, align: "center" });
  });
  return slide;
}

function slide06(presentation, ctx) {
  const slide = presentation.slides.add();
  bandTitle(slide, ctx, "Kiến trúc", "REST API liên kết app iOS, admin web, cơ sở dữ liệu và các dịch vụ xử lý.");
  node(slide, ctx, "iOS App\nSwift + UIKit", 110, 190, 190, 86, { fill: C.coral });
  node(slide, ctx, "Admin Web\nVite + JS", 110, 385, 190, 86, { fill: C.navy });
  node(slide, ctx, "Express API Server\nAuth / Wallet / Transfer / Payment / Analytics", 472, 270, 340, 126, { fill: C.white, color: C.ink, line: { style: "solid", fill: C.navy, width: 2 } });
  node(slide, ctx, "MongoDB\nCollections nghiệp vụ", 970, 190, 190, 86, { fill: C.navy });
  node(slide, ctx, "VNPay + AI Engine\nTop-up callback / gợi ý chi tiêu", 938, 385, 254, 86, { fill: C.coral });
  hline(slide, ctx, 300, 233, 472, C.gray, 3);
  hline(slide, ctx, 300, 428, 472, C.gray, 3);
  hline(slide, ctx, 812, 313, 970, C.gray, 3);
  vline(slide, ctx, 874, 250, 428, C.gray, 3);
  hline(slide, ctx, 812, 428, 938, C.gray, 3);
  text(slide, ctx, "Node.js/Express định tuyến API; middleware JWT bảo vệ tài nguyên; MongoDB lưu user, wallet, transaction, payment, service, notification và savings jar.", 166, 548, 940, 52, { size: 18, color: C.gray, align: "center" });
  return slide;
}

function slide07(presentation, ctx) {
  const slide = presentation.slides.add();
  title(slide, ctx, "Cơ sở dữ liệu", "Thiết kế MongoDB tách rõ danh tính, tiền, dịch vụ và tương tác.");
  const collections = [
    ["users", "tài khoản, vai trò, xác thực"],
    ["students", "danh sách sinh viên đối chiếu"],
    ["wallets", "số dư, tiền tệ, PIN, trạng thái"],
    ["transactions", "topup, payment, transfer, savings"],
    ["services", "dịch vụ nội bộ và thương mại"],
    ["payments", "ghi nhận thanh toán dịch vụ"],
    ["vnpay_transactions", "phiên nạp tiền qua VNPay"],
    ["notifications", "thông báo hệ thống"],
    ["notification_reads", "trạng thái đã đọc"],
    ["savings_jars", "hũ tiết kiệm cá nhân"],
  ];
  collections.forEach(([name, desc], i) => {
    const x = 78 + (i % 5) * 232;
    const y = 210 + Math.floor(i / 5) * 142;
    ctx.addShape(slide, { x, y, w: 185, h: 88, fill: i % 2 === 0 ? C.navy : C.coral, line: ctx.line() });
    text(slide, ctx, name, x + 12, y + 15, 160, 22, { size: 17, color: C.white, bold: true, align: "center" });
    text(slide, ctx, desc, x + 14, y + 43, 157, 34, { size: 12, color: "#f3f4f6", align: "center" });
  });
  ctx.addShape(slide, { x: 202, y: 515, w: 876, h: 2, fill: C.light, line: ctx.line() });
  text(slide, ctx, "Trọng tâm dữ liệu: mỗi ví gắn với một người dùng; mọi nghiệp vụ tiền tạo transaction để phục vụ lịch sử, thống kê và kiểm soát.", 210, 545, 860, 42, { size: 18, color: C.ink, align: "center", bold: true });
  return slide;
}

async function slide08(presentation, ctx) {
  const slide = presentation.slides.add();
  bandTitle(slide, ctx, "Triển khai iOS", "Ứng dụng sinh viên đã có các màn hình cốt lõi từ đăng nhập đến thanh toán.");
  await phoneShot(slide, ctx, "image51.jpeg", 64, 140, 154, 360, "Đăng nhập");
  await phoneShot(slide, ctx, "image53.jpeg", 236, 140, 154, 360, "Trang chủ ví");
  await phoneShot(slide, ctx, "image58.jpeg", 408, 140, 154, 360, "Chuyển tiền");
  await phoneShot(slide, ctx, "image61.jpeg", 580, 140, 154, 360, "Lịch sử");
  await phoneShot(slide, ctx, "image69.jpeg", 752, 140, 154, 360, "Thanh toán dịch vụ");
  await phoneShot(slide, ctx, "image62.jpeg", 924, 140, 154, 360, "Hũ tiết kiệm");
  metric(slide, ctx, "14+", "màn hình người dùng trong báo cáo", 110, 536, 270, 78, { valueSize: 24, labelSize: 12 });
  metric(slide, ctx, "REST", "endpoint tập trung trong APIEndpoint.swift", 505, 536, 270, 78, { fill: C.coral, valueSize: 24, labelSize: 12 });
  metric(slide, ctx, "JWT + PIN", "xác thực phiên và xác nhận giao dịch", 900, 536, 270, 78, { valueSize: 24, labelSize: 12 });
  return slide;
}

function slide09(presentation, ctx) {
  const slide = presentation.slides.add();
  title(slide, ctx, "Giao dịch", "Mỗi thao tác tiền đi qua xác thực PIN, kiểm tra số dư và ghi nhận lịch sử.");
  const steps = [
    ["1", "Nhập thông tin\nngười nhận/dịch vụ/số tiền"],
    ["2", "Xác nhận\nthông tin giao dịch"],
    ["3", "Nhập PIN\nbảo mật ví"],
    ["4", "API kiểm tra\nPIN + số dư + trạng thái"],
    ["5", "Cập nhật ví\nvà tạo transaction"],
  ];
  steps.forEach(([num, label], i) => {
    const x = 86 + i * 226;
    ctx.addShape(slide, { x, y: 230, w: 150, h: 88, fill: i % 2 === 0 ? C.coral : C.navy, line: ctx.line() });
    ctx.addShape(slide, { x: x + 58, y: 342, w: 34, h: 34, fill: C.white, line: { style: "solid", fill: i % 2 === 0 ? C.coral : C.navy, width: 3 } });
    text(slide, ctx, num, x + 64, 350, 22, 16, { size: 16, color: i % 2 === 0 ? C.coral : C.navy, bold: true, align: "center" });
    text(slide, ctx, label, x + 12, 250, 126, 46, { size: 14, color: C.white, bold: true, align: "center", valign: "middle" });
    if (i < steps.length - 1) hline(slide, ctx, x + 150, 274, x + 226, C.gray, 3);
  });
  labelCard(slide, ctx, "Các loại giao dịch", "topup, payment, transfer, refund, savings_deposit, savings_withdraw", 135, 468, 360, 104, { bodySize: 18 });
  labelCard(slide, ctx, "Ràng buộc chính", "Ví có balance, currency, PIN và status; transaction có type, status, receiverWalletId, amount, description.", 548, 468, 585, 104, { fill: C.navy, labelColor: C.coral, bodyColor: C.white, border: C.navy, bodySize: 16 });
  return slide;
}

async function slide10(presentation, ctx) {
  const slide = presentation.slides.add();
  bandTitle(slide, ctx, "Thống kê & AI", "Chi tiêu không chỉ được ghi nhận, mà còn được diễn giải thành gợi ý hành động.");
  await phoneShot(slide, ctx, "image67.jpeg", 96, 150, 245, 390, "Biểu đồ chi tiêu");
  await phoneShot(slide, ctx, "image68.jpeg", 378, 150, 245, 390, "AI gợi ý quản lý tiền");
  ctx.addShape(slide, { x: 724, y: 174, w: 210, h: 210, fill: C.light, line: ctx.line() });
  ctx.addShape(slide, { x: 760, y: 210, w: 138, h: 138, fill: C.coral, line: ctx.line() });
  ctx.addShape(slide, { x: 794, y: 244, w: 70, h: 70, fill: C.paper, line: ctx.line() });
  text(slide, ctx, "AI", 800, 258, 58, 34, { size: 34, color: C.navy, bold: true, align: "center" });
  smallBar(slide, ctx, 982, 210, 128, "Theo tuần/tháng", C.coral);
  smallBar(slide, ctx, 982, 278, 92, "Cơ cấu chi tiêu", C.navy);
  smallBar(slide, ctx, 982, 346, 150, "Gợi ý tiết kiệm", C.mint);
  bulletBlock(slide, ctx, ["Thống kê giao dịch theo kỳ để người dùng nhìn được thói quen chi tiêu.", "AI engine tạo nhận xét và gợi ý dựa trên lịch sử chi tiêu.", "Thông tin được đưa về giao diện iOS qua endpoint analytics."], 705, 444, 445, 126, { size: 16, fill: C.white, line: { style: "solid", fill: "#e5e7eb", width: 1 } });
  return slide;
}

async function slide11(presentation, ctx) {
  const slide = presentation.slides.add();
  title(slide, ctx, "Quản trị", "Admin web giúp nhà trường theo dõi vận hành và quản lý dữ liệu nghiệp vụ.");
  await ctx.addImage(slide, { path: media(ctx, "image70.png"), x: 74, y: 198, w: 360, h: 190, fit: "contain", alt: "Dashboard admin" });
  await ctx.addImage(slide, { path: media(ctx, "image71.png"), x: 466, y: 198, w: 360, h: 190, fit: "contain", alt: "Quản lý người dùng" });
  await ctx.addImage(slide, { path: media(ctx, "image73.png"), x: 858, y: 198, w: 360, h: 190, fit: "contain", alt: "Quản lý dịch vụ" });
  const cards = [
    ["Dashboard", "Theo dõi người dùng, sinh viên, dịch vụ, giao dịch và số dư hệ thống."],
    ["Người dùng & sinh viên", "Tra cứu, lọc, cập nhật trạng thái, hỗ trợ dữ liệu xác thực sinh viên."],
    ["Dịch vụ & thông báo", "Quản lý khoản cần thanh toán và gửi thông báo đến sinh viên."],
  ];
  cards.forEach(([a, b], i) => labelCard(slide, ctx, a, b, 88 + i * 392, 445, 310, 100, { bodySize: 14 }));
  return slide;
}

function slide12(presentation, ctx) {
  const slide = presentation.slides.add();
  bandTitle(slide, ctx, "Kết quả", "Hệ thống đã hoàn thành lõi nghiệp vụ, còn các tích hợp thật là hướng mở rộng.");
  const cols = [
    ["Đã đạt được", ["Phân tích tổng quát chức năng hệ thống.", "Xây dựng cơ sở dữ liệu.", "Hoàn thiện các luồng nạp tiền, chuyển tiền, thanh toán dịch vụ ở mức mô phỏng."]],
    ["Hạn chế", ["Chưa rút tiền về ngân hàng.", "Chưa liên kết ngân hàng.", "OTP số điện thoại và xác thực sinh viên chưa kết nối hệ thống thật."]],
    ["Hướng phát triển", ["Liên kết ngân hàng và quy trình thanh toán thật.", "Kết nối API trường học để xác thực sinh viên.", "Tối ưu CSDL và mở rộng dịch vụ."]],
  ];
  cols.forEach(([head, items], i) => {
    const x = 82 + i * 390;
    ctx.addShape(slide, { x, y: 170, w: 310, h: 54, fill: i === 0 ? C.coral : i === 1 ? C.navy : C.mint, line: ctx.line() });
    text(slide, ctx, head.toUpperCase(), x + 18, 188, 274, 18, { size: 18, color: C.white, bold: true, align: "center" });
    bulletBlock(slide, ctx, items, x, 250, 310, 230, { size: 16, fill: C.white, line: { style: "solid", fill: "#e5e7eb", width: 1 } });
  });
  text(slide, ctx, "Thông điệp kết luận: Student eWallet chứng minh được quy trình ví điện tử sinh viên từ thiết kế đến triển khai prototype, tạo nền tảng để phát triển thành hệ thống thanh toán trường học thực tế.", 150, 548, 980, 56, { size: 19, color: C.ink, bold: true, align: "center" });
  return slide;
}

async function slide13(presentation, ctx) {
  const slide = presentation.slides.add();
  bg(slide, ctx);
  ctx.addShape(slide, { x: 696, y: 102, w: 402, h: 284, fill: C.coral, line: ctx.line() });
  ctx.addShape(slide, { x: 650, y: 72, w: 402, h: 284, fill: "#00000000", line: { style: "solid", fill: C.navy, width: 1 } });
  await ctx.addImage(slide, { path: repo(ctx, "iosApp/Student eWallet/Student eWallet/Assets.xcassets/LogoUniEwallet_xoanen.imageset/LogoUniEwallet_xoanen.png"), x: 750, y: 132, w: 235, h: 180, fit: "contain", alt: "Uni Ewallet logo" });
  ctx.addShape(slide, { x: 1080, y: 505, w: 92, h: 32, fill: C.coral, line: ctx.line() });
  text(slide, ctx, "Q&A", 1101, 512, 48, 18, { size: 14, color: C.white, bold: true, align: "center" });
  text(slide, ctx, "CẢM ƠN HỘI ĐỒNG ĐÃ LẮNG NGHE", 650, 428, 480, 36, { size: 26, color: C.coral, bold: true, title: true });
  text(slide, ctx, "Mạc Văn Vinh - 28211152394", 650, 474, 360, 24, { size: 18, color: C.gray });
  text(slide, ctx, "Student eWallet | Khóa luận tốt nghiệp CNTT", 650, 504, 390, 22, { size: 15, color: C.ink });
  return slide;
}

export const slides = [slide01, slide02, slide03, slide04, slide05, slide06, slide07, slide08, slide09, slide10, slide11, slide12, slide13];
