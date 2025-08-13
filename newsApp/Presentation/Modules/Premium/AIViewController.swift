import UIKit
import WebKit

class AIViewController: UIViewController {
    
    // MARK: - Properties
    private var webView: WKWebView!
    
    // 여기서 URL 직접 설정
    private let urlString = "https://markup.hankyung.com/app/ai/index.html" // 원하는 URL로 변경
    
    // MARK: - Initializer
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadURL()
    }
    
    // MARK: - Setup
    private func setupWebView() {
        // WKWebView 설정
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Auto Layout 설정
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // 제약 조건 설정 (탭바를 고려한 safe area 사용)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) // 변경: safeArea 사용
        ])
    }
    
    private func loadURL() {
        guard let url = URL(string: urlString) else {
            showAlert(message: "올바르지 않은 URL입니다.")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension AIViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // 로딩 시작
        print("웹뷰 로딩 시작")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 로딩 완료
        print("웹뷰 로딩 완료")
        
        // 타이틀 설정 제거 (탭바 아이템 이름 유지를 위해)
        // if let title = webView.title, !title.isEmpty {
        //     self.title = title
        // }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 로딩 실패
        print("웹뷰 로딩 실패: \(error.localizedDescription)")
        showAlert(message: "페이지를 불러올 수 없습니다.")
    }
}

// MARK: - WKUIDelegate
extension AIViewController: WKUIDelegate {
    
    // alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    // confirm 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
}

// MARK: - 사용 예시
/*
// 간단한 사용 방법:
let aiViewController = AIViewController()
navigationController?.pushViewController(aiViewController, animated: true)

// 또는 modal로 띄우기:
let aiViewController = AIViewController()
let navController = UINavigationController(rootViewController: aiViewController)
present(navController, animated: true)

// Storyboard에서도 바로 사용 가능
*/
