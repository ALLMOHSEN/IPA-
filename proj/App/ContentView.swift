import SwiftUI
import WebKit

let siteURL = URL(string: "https://allmohsen.github.io/Alrubeiy-libry/")!

struct ContentView: View {
    @State private var reloadToken = 0
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.18, blue: 0.31).ignoresSafeArea()
            WebView(url: siteURL, reloadToken: reloadToken)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    let reloadToken: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // يحفظ بيانات المكتبة (localStorage) بين مرات التشغيل
        config.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true
        web.scrollView.contentInsetAdjustmentBehavior = .automatic
        web.isOpaque = false
        web.backgroundColor = .clear
        context.coordinator.webView = web

        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.pullToRefresh(_:)), for: .valueChanged)
        web.scrollView.refreshControl = refresh

        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
        weak var webView: WKWebView?
        private var downloadDestination: URL?

        @objc func pullToRefresh(_ sender: UIRefreshControl) {
            webView?.reload()
            sender.endRefreshing()
        }

        // MARK: التنقل
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.shouldPerformDownload {          // زر "تحميل النسخة الاحتياطية"
                decisionHandler(.download)
                return
            }
            // الروابط الخارجية تُفتح في المتصفح
            if navigationAction.navigationType == .linkActivated,
               let target = navigationAction.request.url,
               let host = target.host, host != siteURL.host,
               ["http", "https"].contains(target.scheme ?? "") {
                UIApplication.shared.open(target)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
        }

        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            download.delegate = self
        }
        func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            download.delegate = self
        }

        // MARK: صفحة عدم الاتصال
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            showOffline(webView)
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            showOffline(webView)
        }
        private func showOffline(_ webView: WKWebView) {
            let html = """
            <html dir="rtl" lang="ar"><head><meta name="viewport" content="width=device-width, initial-scale=1">
            <style>body{font-family:-apple-system;background:#0B2E4F;color:#fff;display:flex;flex-direction:column;
            align-items:center;justify-content:center;height:100vh;margin:0;text-align:center;padding:24px}
            a{background:#F6D27A;color:#0B2E4F;padding:12px 28px;border-radius:12px;text-decoration:none;font-weight:700;margin-top:16px}</style></head>
            <body><h2>لا يوجد اتصال بالإنترنت</h2><p>تحقق من الاتصال ثم أعد المحاولة.</p>
            <a href="\(siteURL.absoluteString)">إعادة المحاولة</a></body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }

        // MARK: نوافذ JavaScript (alert / confirm)
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            present(UIAlertController(title: nil, message: message, preferredStyle: .alert)) { ac in
                ac.addAction(UIAlertAction(title: "حسناً", style: .default) { _ in completionHandler() })
            }
        }
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            present(UIAlertController(title: nil, message: message, preferredStyle: .alert)) { ac in
                ac.addAction(UIAlertAction(title: "إلغاء", style: .cancel) { _ in completionHandler(false) })
                ac.addAction(UIAlertAction(title: "موافق", style: .default) { _ in completionHandler(true) })
            }
        }
        private func present(_ ac: UIAlertController, configure: (UIAlertController) -> Void) {
            configure(ac)
            topViewController()?.present(ac, animated: true)
        }

        // MARK: التحميل (النسخة الاحتياطية JSON) ثم مشاركة/حفظ الملف
        func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                      suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
            let name = suggestedFilename.isEmpty ? "library-backup.json" : suggestedFilename
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: dest)
            downloadDestination = dest
            completionHandler(dest)
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let file = downloadDestination, let top = topViewController() else { return }
            let sheet = UIActivityViewController(activityItems: [file], applicationActivities: nil)
            sheet.popoverPresentationController?.sourceView = top.view
            sheet.popoverPresentationController?.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            top.present(sheet, animated: true)
        }

        private func topViewController() -> UIViewController? {
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            var vc = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
            while let presented = vc?.presentedViewController { vc = presented }
            return vc
        }
    }
}
