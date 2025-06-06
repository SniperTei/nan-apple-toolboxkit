import UIKit
import Alamofire

class NetworkTestViewController: UIViewController {
    
    private let urlTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let resultTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "网络测试"
        view.backgroundColor = .white
        
        // 配置URL输入框
        urlTextField.borderStyle = .roundedRect
        urlTextField.placeholder = "请输入请求URL"
        urlTextField.text = "https://api.github.com"  // 默认URL
        view.addSubview(urlTextField)
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置发送按钮
        sendButton.setTitle("发送请求", for: .normal)
        sendButton.addTarget(self, action: #selector(sendRequestButtonTapped), for: .touchUpInside)
        view.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置结果显示区域
        resultTextView.isEditable = false
        resultTextView.font = .systemFont(ofSize: 14)
        resultTextView.layer.borderWidth = 1
        resultTextView.layer.borderColor = UIColor.lightGray.cgColor
        resultTextView.layer.cornerRadius = 5
        view.addSubview(resultTextView)
        resultTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置约束
        NSLayoutConstraint.activate([
            urlTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            urlTextField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 20),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 40),
            
            resultTextView.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 20),
            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func sendRequestButtonTapped() {
        guard let urlString = urlTextField.text, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            showAlert(message: "请输入有效的URL")
            return
        }
        
        // 显示加载状态
        sendButton.isEnabled = false
        resultTextView.text = "正在请求..."
        
        // 发送网络请求
        AF.request(url).responseString { [weak self] response in
            guard let self = self else { return }
            
            // 恢复按钮状态
            self.sendButton.isEnabled = true
            
            switch response.result {
            case .success(let value):
                // 格式化JSON显示
                if let data = value.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    self.resultTextView.text = prettyString
                } else {
                    self.resultTextView.text = value
                }
                
            case .failure(let error):
                self.resultTextView.text = "请求失败：\(error.localizedDescription)"
            }
        }
        
        // 收起键盘
        urlTextField.resignFirstResponder()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
} 