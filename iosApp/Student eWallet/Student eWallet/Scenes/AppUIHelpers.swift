import UIKit

enum AppMoneyFormatter {
    static func digits(from text: String?) -> String {
        String((text ?? "").filter { $0.isNumber })
    }

    static func amount(from text: String?) -> Double? {
        let digits = digits(from: text)
        guard !digits.isEmpty else { return nil }
        return Double(digits)
    }

    static func groupedText(from text: String?) -> String {
        let digits = digits(from: text)
        guard !digits.isEmpty else { return "" }

        let normalizedDigits = String(digits.drop(while: { $0 == "0" }))
        let displayDigits = normalizedDigits.isEmpty ? "0" : normalizedDigits
        let reversed = displayDigits.reversed()
        let chunks = stride(from: 0, to: displayDigits.count, by: 3).map { start -> String in
            let chunkStart = reversed.index(reversed.startIndex, offsetBy: start)
            let chunkEnd = reversed.index(chunkStart, offsetBy: min(3, displayDigits.count - start))
            return String(reversed[chunkStart..<chunkEnd].reversed())
        }
        return chunks.reversed().joined(separator: ".")
    }
}

extension UIColor {
    static var appSurfaceBackground: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1.0)
            }
            return UIColor(red: 0.97, green: 0.975, blue: 0.985, alpha: 1.0)
        }
    }

    static var appElevatedSurfaceBackground: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.18, green: 0.19, blue: 0.22, alpha: 1.0)
            }
            return .white
        }
    }

    static var appSurfaceBorder: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.08)
            }
            return UIColor.black.withAlphaComponent(0.06)
        }
    }
}

extension UIViewController {
    func redirectToHomeTab() {
        if let tabBarController = tabBarController ?? navigationController?.tabBarController {
            let navigations = tabBarController.viewControllers?.compactMap { $0 as? UINavigationController } ?? []
            navigations.forEach { $0.popToRootViewController(animated: false) }
            tabBarController.selectedIndex = 0
            return
        }

        navigationController?.setViewControllers([HomeViewController()], animated: true)
    }

    func showInvalidConfirmationAndReturn(message: String) {
        let alert = UIAlertController(title: "Thông tin chưa đúng", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Nhập lại", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    func enableKeyboardDismissOnTap() {
        let gestureName = "AppKeyboardDismissTapGesture"
        let alreadyInstalled = view.gestureRecognizers?.contains { $0.name == gestureName } == true
        if !alreadyInstalled {
            let tap = UITapGestureRecognizer(target: self, action: #selector(appDismissKeyboardFromTap(_:)))
            tap.name = gestureName
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }

        configureKeyboardDismissal(in: view)
    }

    @objc func appDismissKeyboardFromTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if let touchedView = view.hitTest(location, with: nil), isKeyboardInputView(touchedView) {
            return
        }

        view.endEditing(true)
    }

    private func configureKeyboardDismissal(in rootView: UIView) {
        if let scrollView = rootView as? UIScrollView {
            scrollView.keyboardDismissMode = .interactive
        }

        rootView.subviews.forEach { configureKeyboardDismissal(in: $0) }
    }

    private func isKeyboardInputView(_ view: UIView) -> Bool {
        var currentView: UIView? = view
        while let inspectedView = currentView {
            if inspectedView is UITextField || inspectedView is UITextView {
                return true
            }
            currentView = inspectedView.superview
        }
        return false
    }
}

extension UITextField {
    func applyMoneyInputStyle(target: Any?, action: Selector) {
        keyboardType = .numberPad
        addTarget(target, action: action, for: .editingChanged)
    }

    func applyPinInputStyle() {
        keyboardType = .numberPad
        isSecureTextEntry = true
        addTarget(self, action: #selector(limitToSixPinDigits), for: .editingChanged)
    }

    @objc private func limitToSixPinDigits() {
        let pinDigits = String((text ?? "").unicodeScalars.filter {
            CharacterSet(charactersIn: "0123456789").contains($0)
        }.prefix(6))
        if text != pinDigits {
            text = pinDigits
        }
    }

    func formatMoneyInputKeepingCursorAtEnd() {
        text = AppMoneyFormatter.groupedText(from: text)
        let endPosition = endOfDocument
        selectedTextRange = textRange(from: endPosition, to: endPosition)
    }
}

extension UIView {
    func applyAppCardStyle(cornerRadius: CGFloat = 24) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .appSurfaceBackground
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.appSurfaceBorder.resolvedColor(with: traitCollection).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.masksToBounds = false
    }

    func applyInsetSurfaceStyle(cornerRadius: CGFloat = 18) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .appElevatedSurfaceBackground
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.appSurfaceBorder.resolvedColor(with: traitCollection).cgColor
        layer.masksToBounds = true
    }

    func applyInfoCardStyle() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .appElevatedSurfaceBackground
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.appSurfaceBorder.resolvedColor(with: traitCollection).cgColor
    }
}

extension UIButton {
    func applyPrimaryAppStyle() {
        let color = UIColor(red: 0.88, green: 0.07, blue: 0.07, alpha: 1) // Slightly deeper red
        backgroundColor = color
        tintColor = .white
        titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.shadowColor = color.withAlphaComponent(0.35).cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 15
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    func applySecondaryAppStyle() {
        let color = UIColor(red: 0.88, green: 0.07, blue: 0.07, alpha: 1)
        tintColor = color
        backgroundColor = .appElevatedSurfaceBackground
        titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.appSurfaceBorder.resolvedColor(with: traitCollection).cgColor
    }

    func applyNeutralSurfaceButtonStyle(cornerRadius: CGFloat = 14) {
        if var configuration {
            configuration.baseBackgroundColor = .appElevatedSurfaceBackground
            self.configuration = configuration
        } else {
            backgroundColor = .appElevatedSurfaceBackground
        }
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.appSurfaceBorder.resolvedColor(with: traitCollection).cgColor
        layer.masksToBounds = true
    }
}
