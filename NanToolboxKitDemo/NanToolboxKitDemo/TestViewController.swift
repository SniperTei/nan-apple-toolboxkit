import UIKit
import NanToolboxKit

class TestViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // 测试项数据
    private let testItems = [
        "测试日志",
        "测试崩溃",
        "测试埋点",
        "测试性能",
        "测试网络",
        "测试旋转"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "功能测试"
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = testItems[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0: // 测试日志
            let logVC = TestLogController()
            navigationController?.pushViewController(logVC, animated: true)
        case 1: // 测试崩溃
            // TODO: 实现崩溃测试控制器
            break
        case 2: // 测试埋点
            // TODO: 实现埋点测试控制器
            break
        case 3: // 测试性能
            // TODO: 实现性能测试控制器
            break
        case 4: // 测试网络
            // TODO: 实现网络测试控制器
            break
        case 5: // 测试旋转
            // TODO: 实现旋转测试控制器
            let rotateVC = TestViewRotateController()
            navigationController?.pushViewController(rotateVC, animated: true)
            break
        default:
            break
        }
    }
} 
