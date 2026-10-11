import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  private let controller = ProbeViewController()

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = UINavigationController(rootViewController: controller)
    window.makeKeyAndVisible()
    self.window = window
    return true
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    controller.refresh()
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    controller.refresh()
    return url.scheme == Bundle.main.object(forInfoDictionaryKey: "MainAppScheme") as? String
  }
}
