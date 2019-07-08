
import UIKit
//import CHKLineChartKit

public let BM_SCREEN_W: CGFloat = UIScreen.main.bounds.size.width
public let BM_SCREEN_H: CGFloat = UIScreen.main.bounds.size.height

class ViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let demos: [Int: (String, String, Bool)] = [
        0: ("最佳例子", "ChartCustomViewController", false),
        1: ("简单例子", "ChartFullViewController", true),
        2: ("图片例子", "ChartImageViewController", true),
        3: ("列表例子", "ChartInTableViewController", true),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.demos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "DemoCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "DemoCell")
        }
        cell?.textLabel?.text = self.demos[indexPath.row]!.0
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let demoObject = self.demos[indexPath.row] {
            var vc: UIViewController
            let className = demoObject.1
            let isNIB = demoObject.2
            if isNIB {
                guard let storyboard = self.storyboard else {
                    return
                }
                vc = storyboard.instantiateViewController(withIdentifier: className)
            } else {
                guard let nameSpage = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else {
                    return
                }
                guard let Type = NSClassFromString(nameSpage + "." + className) as? UIViewController.Type else {
                    return
                }
                vc = Type.init()
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
}
