import UIKit
import PrismUI

@main
@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private let store = ShowcaseCounterStore()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("-showcaseReset") {
            store.reset()
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let store = ShowcaseCounterStore()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let host = HostUIView(element: store.rootElement(), theme: store.activeTheme)
        host.accessibilityIdentifier = "showcase.host"
        store.setContainerWidth(windowScene.screen.bounds.width)
        host.onBoundsChange = { [weak store] bounds in
            store?.setContainerWidth(bounds.width)
        }
        store.onChange = { [weak host] element in host?.setRootElement(element) }
        store.onThemeChange = { [weak host] theme in host?.setTheme(theme) }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = ShowcaseViewController(host: host)
        self.window = window
        window.makeKeyAndVisible()
    }
}

private final class ShowcaseViewController: UIViewController {
    private let host: HostUIView

    init(host: HostUIView) {
        self.host = host
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() { view = host }
}
