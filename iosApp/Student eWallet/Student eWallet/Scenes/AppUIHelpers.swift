import UIKit

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
