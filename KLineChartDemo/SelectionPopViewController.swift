
import UIKit
import MZFormSheetPresentationController

class SelectionPopViewController: UIViewController {
    
    typealias SelectedItemClosure = (_ vc: SelectionPopViewController, _ indexPath: IndexPath) -> Void
    
    var sections: [String] = [String]()
    
    var items: [String: [String]] = [String: [String]]()
    
    var selectedIndexPaths: [IndexPath] = [IndexPath]()
    
    var selectedItemClosure: SelectedItemClosure?
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        return table
    }()
    
    convenience init(selectedItemClosure: SelectedItemClosure? = nil) {
        self.init()
        
        self.selectedItemClosure = selectedItemClosure
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.bottom.right.left.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    public func addItems(section: String, items: [String], selectedIndex: Int? = nil) {
        self.sections.append(section)
        self.items[section] = items
        if let i = selectedIndex {
            self.selectedIndexPaths.append(IndexPath(row: i, section: self.sections.count - 1))
        }
    }
    
    public func clear() {
        self.sections.removeAll()
        self.items.removeAll()
        self.selectedIndexPaths.removeAll()
    }
    
    public func show(from: UIViewController) {
        let sheetController = MZFormSheetPresentationViewController(contentViewController: self)
        sheetController.contentViewCornerRadius = 5
        sheetController.presentationController?.backgroundColor = UIColor(white: 0, alpha: 0.5)
        sheetController.dismiss(animated: false, completion: nil)
        sheetController.presentationController?.shouldDismissOnBackgroundViewTap = true
        sheetController.contentViewControllerTransitionStyle = .fade
        sheetController.presentationController?.shouldCenterVertically = true
        from.present(sheetController, animated: true, completion: nil)
    }
}

extension SelectionPopViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = self.sections[section]
        return self.items[s]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let SelectionPopViewCell = "SelectionPopViewCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: SelectionPopViewCell)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: SelectionPopViewCell)
        }
        
        let section = self.sections[indexPath.section]
        let rows = self.items[section]!
        let item = rows[indexPath.row]
        cell?.textLabel?.text = item.isEmpty ? "N/A" : item
        
        if self.selectedIndexPaths.contains(indexPath) {
            cell?.accessoryType = .checkmark
        } else {
            cell?.accessoryType = .none
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        self.dismiss(animated: true) {
            self.selectedItemClosure?(self, indexPath)
        }
    }
}
