//
//  SceneDelegate.swift
//  Student eWallet
//
//  Created by Mạc Văn Vinh on 10/4/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)

        // Always require login on cold launch: TokenStore is empty by design
        let rootVC: UIViewController
        if let _ = TokenStore.shared.token {
            rootVC = MainTabBarController()
        } else {
            let login = LoginViewController()
            let nav = UINavigationController(rootViewController: login)
            // On successful login, switch to main tab bar
            login.onLoginSuccess = { [weak window] in
                let main = MainTabBarController()
                window?.rootViewController = main
                window?.makeKeyAndVisible()
            }
            rootVC = nav
        }

        window.rootViewController = rootVC
        self.window = window
        window.makeKeyAndVisible()

        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "studentewallet" else { return }
        if url.host == "topup-result" {
            NotificationCenter.default.post(name: .topupDeepLinkReceived, object: url)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

extension Notification.Name {
    static let topupDeepLinkReceived = Notification.Name("topupDeepLinkReceived")
    static let notificationsDidChange = Notification.Name("notificationsDidChange")
}
