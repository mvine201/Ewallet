import json
import random
import sys

try:
    from sklearn.ensemble import RandomForestRegressor  # type: ignore
except Exception:
    RandomForestRegressor = None


NEEDS_KEYS = {"tuition", "parking", "dormitory", "insurance", "union_fee", "library"}
WANTS_KEYS = {"canteen", "other", "transfer"}
SAVINGS_KEYS = {"savings"}


def safe_ratio(value, total):
    if not total:
        return 0.0
    return float(value) / float(total)


def build_feature_map(stats):
    categories = stats.get("categories", [])
    total_expense = float(stats.get("totalExpense", 0) or 0)
    total_inflow = float(stats.get("totalInflow", 0) or 0)

    amounts = {item.get("key"): float(item.get("amount", 0) or 0) for item in categories}
    needs_amount = sum(amount for key, amount in amounts.items() if key in NEEDS_KEYS)
    wants_amount = sum(amount for key, amount in amounts.items() if key in WANTS_KEYS)
    savings_amount = sum(amount for key, amount in amounts.items() if key in SAVINGS_KEYS)
    transfer_amount = float(amounts.get("transfer", 0) or 0)

    features = {
        "total_expense": total_expense,
        "total_inflow": total_inflow,
        "expense_to_inflow": safe_ratio(total_expense, total_inflow),
        "needs_ratio": safe_ratio(needs_amount, total_expense),
        "wants_ratio": safe_ratio(wants_amount, total_expense),
        "savings_ratio": safe_ratio(savings_amount, total_expense),
        "transfer_ratio": safe_ratio(transfer_amount, total_expense),
        "top_category": categories[0] if categories else None,
        "top_want_category": next((item for item in categories if item.get("key") in WANTS_KEYS), None),
        "category_count": len(categories),
    }
    return features


def rule_based_risk(features):
    risk = 22.0
    risk += max(0.0, features["expense_to_inflow"] - 0.8) * 110.0
    risk += max(0.0, features["wants_ratio"] - 0.3) * 70.0
    risk += max(0.0, features["transfer_ratio"] - 0.2) * 55.0
    risk += max(0.0, 0.15 - features["savings_ratio"]) * 80.0
    if features["total_inflow"] <= 0 and features["total_expense"] > 0:
        risk = 78.0
    return max(0.0, min(100.0, risk))


def random_forest_risk(features):
    if RandomForestRegressor is None:
        return rule_based_risk(features), "rules"

    random.seed(42)
    samples = []
    labels = []
    for _ in range(240):
        expense_to_inflow = random.uniform(0.2, 1.35)
        needs_ratio = random.uniform(0.2, 0.75)
        wants_ratio = random.uniform(0.05, 0.6)
        savings_ratio = random.uniform(0.0, 0.4)
        transfer_ratio = random.uniform(0.0, 0.35)

        raw_risk = 18.0
        raw_risk += max(0.0, expense_to_inflow - 0.8) * 110.0
        raw_risk += max(0.0, wants_ratio - 0.3) * 70.0
        raw_risk += max(0.0, transfer_ratio - 0.2) * 55.0
        raw_risk += max(0.0, 0.15 - savings_ratio) * 80.0
        raw_risk = max(0.0, min(100.0, raw_risk))

        samples.append([expense_to_inflow, needs_ratio, wants_ratio, savings_ratio, transfer_ratio])
        labels.append(raw_risk)

    model = RandomForestRegressor(n_estimators=80, random_state=42)
    model.fit(samples, labels)

    current = [[
        features["expense_to_inflow"],
        features["needs_ratio"],
        features["wants_ratio"],
        features["savings_ratio"],
        features["transfer_ratio"],
    ]]
    predicted = float(model.predict(current)[0])
    return max(0.0, min(100.0, predicted)), "random_forest"


def build_status(risk):
    if risk >= 70:
        return "alert"
    if risk >= 45:
        return "watch"
    return "healthy"


def build_headline(status, period_label):
    if status == "alert":
        return f"Chi tiêu {period_label} đang vượt ngưỡng an toàn"
    if status == "watch":
        return f"Chi tiêu {period_label} cần theo dõi sát hơn"
    return f"Chi tiêu {period_label} đang ở mức ổn định"


def build_summary(features, status):
    top_category = features["top_category"]
    if features["total_expense"] <= 0:
        return "Chưa có khoản chi tiêu nào trong kỳ này, chưa đủ dữ liệu để đánh giá xu hướng."

    top_text = ""
    if top_category:
        top_text = f"Danh mục lớn nhất hiện là {top_category.get('title', 'Khác')}."

    if status == "alert":
        return f"{top_text} Tỷ lệ chi ra đang ăn sâu vào dòng tiền vào, nên cần giảm các khoản ít ưu tiên ngay trong kỳ tới.".strip()
    if status == "watch":
        return f"{top_text} Mức chi đang tăng nhanh hơn vùng an toàn, nên theo dõi sát các khoản linh hoạt.".strip()
    return f"{top_text} Phân bổ hiện khá cân đối, có thể duy trì và tăng thêm phần dành cho tích luỹ.".strip()


def build_focus(features):
    top_category = features["top_category"]
    if not top_category:
        return ("Ưu tiên kỳ này", "Bắt đầu ghi nhận chi tiêu để AI có đủ dữ liệu phân tích.")

    if features["savings_ratio"] < 0.15:
        return ("Ưu tiên kỳ này", "Tăng phần dành cho tiết kiệm lên ít nhất 15% tổng chi.")

    if features["wants_ratio"] > 0.3:
        target = features["top_want_category"] or top_category
        return ("Ưu tiên kỳ này", f"Siết nhóm {target.get('title', 'chi tiêu lớn')} để giảm áp lực ngân sách.")

    return ("Điểm sáng", f"Nhóm {top_category.get('title', 'chi tiêu chính')} đang là khoản lớn nhất cần theo dõi.")


def build_actions(features):
    actions = []
    top_category = features["top_category"]

    if features["savings_ratio"] < 0.15:
        actions.append({
            "title": "Tăng phần tích luỹ",
            "detail": "Mỗi lần nạp ví hoặc nhận tiền, tách ngay một phần nhỏ sang quỹ tiết kiệm.",
            "tag": "Ưu tiên",
            "emphasis": "save",
        })

    if features["wants_ratio"] > 0.3:
        target = features["top_want_category"]
        title = target.get("title", "nhóm chi linh hoạt") if target else "nhóm chi linh hoạt"
        actions.append({
            "title": "Giảm chi linh hoạt",
            "detail": f"Đặt giới hạn cho {title.lower()} trong kỳ tới để kéo tỷ trọng về dưới 30%.",
            "tag": "Cắt giảm",
            "emphasis": "cut",
        })

    if features["transfer_ratio"] > 0.2:
        actions.append({
            "title": "Rà soát chuyển khoản",
            "detail": "Các khoản chuyển tiền đi đang khá cao, nên gắn nội dung rõ mục đích để dễ kiểm soát.",
            "tag": "Theo dõi",
            "emphasis": "watch",
        })

    if not actions:
        actions.append({
            "title": "Giữ nhịp hiện tại",
            "detail": "Cấu trúc chi tiêu đang ổn, chỉ cần tiếp tục theo dõi nhóm chi lớn nhất mỗi tuần.",
            "tag": "Ổn định",
            "emphasis": "keep",
        })

    if len(actions) < 3:
        actions.append({
            "title": "So sánh theo chu kỳ",
            "detail": "Đổi giữa Tuần và Tháng để nhận ra nhóm nào tăng đột biến.",
            "tag": "Mẹo dùng nhanh",
            "emphasis": "watch",
        })

    return actions[:3]


def build_badges(features):
    badges = []
    inflow = features["total_inflow"]
    expense = features["total_expense"]
    if inflow > 0:
        badges.append(f"Chi ra {round(safe_ratio(expense, inflow) * 100)}% dòng tiền vào")
    badges.append(f"Tiết kiệm {round(features['savings_ratio'] * 100)}% tổng chi")
    if features["top_category"]:
        badges.append(f"Lớn nhất: {features['top_category'].get('title', 'Khác')}")
    return badges[:3]


def main():
    raw = sys.stdin.read().strip()
    payload = json.loads(raw) if raw else {}
    stats = payload.get("stats", payload)
    period = stats.get("period", "month")
    period_label = "tuần này" if period == "week" else "tháng này"

    features = build_feature_map(stats)
    risk, source = random_forest_risk(features)
    status = build_status(risk)
    focus_label, focus_value = build_focus(features)

    output = {
        "status": status,
        "headline": build_headline(status, period_label),
        "summary": build_summary(features, status),
        "focusLabel": focus_label,
        "focusValue": focus_value,
        "actions": build_actions(features),
        "badges": build_badges(features),
        "metrics": {
            "stabilityScore": max(0, min(100, int(round(100 - risk)))),
            "needsRate": int(round(features["needs_ratio"] * 100)),
            "wantsRate": int(round(features["wants_ratio"] * 100)),
            "savingsRate": int(round(features["savings_ratio"] * 100)),
        },
        "source": source,
    }

    sys.stdout.write(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
