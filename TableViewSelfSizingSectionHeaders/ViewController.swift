//
//  ViewController.swift
//  TableViewSelfSizingHeaders
//
//  Created by Tom Kraina on 24.6.2019.
//  Copyright © 2019 Tom Kraina. All rights reserved.
//

import UIKit

class TableViewController: UIViewController { //UITableViewController {

    @IBOutlet weak var tableView: UITableView!

    let rows = ["First", "Second", "Third"]
    let sections = ["UITableView.automaticDimension", "UITableViewHeaderFooterView", "SubclassOfTableViewHeaderFooterView1", "SubclassOfTableViewHeaderFooterView2", "SubclassOfUIView"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.reuseIdentifier)
        tableView.register(SubclassOfTableViewHeaderFooterView1.self, forHeaderFooterViewReuseIdentifier: SubclassOfTableViewHeaderFooterView1.reuseIdentifier)
        tableView.register(SubclassOfTableViewHeaderFooterView2.self, forHeaderFooterViewReuseIdentifier: SubclassOfTableViewHeaderFooterView2.reuseIdentifier)
    }
}

// MARK: - UITableViewDataSource

extension TableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = rows[indexPath.row]
        return cell
    }

    // Implementing this method will make the SubclassOfTableViewHeaderFooterView
    // show the default textLabel over the custom one, so we end up with two labels displayed.
    // Moreover, it will make self-sizing header views not work if UITableView.Style.plain is used.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(repeating: sections[section], count: 3) // Make a long string
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = String(repeating: sections[section], count: 3) // Make a long, multiline string

        switch section {
        case 0...1:
            let header = makeDefaultHeader()
            // No need to set the text of the textLabel, UIKit does that if tableView(_:, titleForHeaderInSection:) is implemented
//            header.textLabel?.text = title
            return header
        case 2:
            let header = makeSubclassHeader1()
            // No need to set header.directionalLayoutMargins here, they are set by UIKit for UITableViewHeaderFooterView subclasses
            header.customLabel.text = title
            return header
        case 3:
            let header = makeSubclassHeader2()
            // No need to set header.directionalLayoutMargins here, they are set by UIKit for UITableViewHeaderFooterView subclasses
            // We still need to set the text (not sure why tho)
            header.customLabel.text = title
            return header
        case 4:
            let header = makeCustomHeader()
            header.directionalLayoutMargins.leading = tableView.separatorInset.left
            header.customLabel.text = title
            return header
        default:
            fatalError("Should not happen")
        }
    }

    private func makeDefaultHeader() -> UITableViewHeaderFooterView {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: UITableViewHeaderFooterView.reuseIdentifier)!
    }

    private func makeSubclassHeader1() -> SubclassOfTableViewHeaderFooterView1 {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SubclassOfTableViewHeaderFooterView1.reuseIdentifier) as! SubclassOfTableViewHeaderFooterView1
    }

    private func makeSubclassHeader2() -> SubclassOfTableViewHeaderFooterView2 {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SubclassOfTableViewHeaderFooterView2.reuseIdentifier) as! SubclassOfTableViewHeaderFooterView2
    }

    private func makeCustomHeader() -> MultilinePlainStyleTableViewHeaderFooterView {
        return MultilinePlainStyleTableViewHeaderFooterView()
    }
}

extension TableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        switch section {
        case 0:
            // If UITableView.Style.plain is used, tableView(_, titleForHeaderInSection:) is not implemented,
            // and this method returns UITableView.automaticDimension, the header won't displayed at all.
            return UITableView.automaticDimension
        case 1:
            // If UITableView.Style.plain is used, tableView(_, titleForHeaderInSection:) is not implemented,
            // and this method returns UITableView.automaticDimension, the header won't displayed at all.
            return 28.0
        case 2...4:
            // Returning UITableView.automaticDimension does not work for custom views
            // as UIKit does not call sizeThatFits: on the custom views.
            // Moreover, calling tableView.headerView(forSection:) returns nil so we need to call the delegate method directly.
            let view = self.tableView(tableView, viewForHeaderInSection: section)
            let size = view?.sizeThatFits(CGSize(width: tableView.bounds.width, height: 0.0)) ?? .zero
            return size.height
        default:
            fatalError()
        }
    }
}


extension UITableViewHeaderFooterView {
    class var reuseIdentifier: String {
        return String(describing: self)
    }
}

// A UITableViewHeaderFooterView subclass that will show 2 overlaying labels if tableView(_:titleForHeaderInSection:) is implemented
class SubclassOfTableViewHeaderFooterView1: UITableViewHeaderFooterView {

    lazy var customLabel: UILabel = self.makeCustomLabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.customLabel)

        NSLayoutConstraint.activate([
            self.customLabel.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.customLabel.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.customLabel.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.customLabel.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // This method is not called by UIKit when UITableView.automaticDimension is returned from
        // the particular UITableViewDelegate method. This is in contrast to how self-sizing cells work.
        return self.systemLayoutSizeFitting(size, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }

    private func makeCustomLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.init(white: 0.1, alpha: 1.0) // Same as _UITableViewHeaderFooterViewLabel
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}


class SubclassOfTableViewHeaderFooterView2: UITableViewHeaderFooterView {

    // Override textLabel to prevent UIKit creating one, so we won't end up with two labels displayed
    override var textLabel: UILabel? {
        get { return customLabel }
    }

    lazy var customLabel: UILabel = self.makeCustomLabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.customLabel)

        NSLayoutConstraint.activate([
            self.customLabel.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.customLabel.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.customLabel.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.customLabel.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // This method is not called by UIKit when UITableView.automaticDimension is returned from
        // the particular UITableViewDelegate method. This is in contrast to how self-sizing cells work.
        return self.systemLayoutSizeFitting(size, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }

    private func makeCustomLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.init(white: 0.1, alpha: 1.0) // Same as _UITableViewHeaderFooterViewLabel
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}

class MultilinePlainStyleTableViewHeaderFooterView: UIView {

    lazy var customLabel: UILabel = self.makeTitleLabel()
    lazy var contentView: UIView = self.makeContentView()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.contentView)
        NSLayoutConstraint.activate([
            self.contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.contentView.topAnchor.constraint(equalTo: self.topAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        self.contentView.directionalLayoutMargins = NSDirectionalEdgeInsets.init(top: 4, leading: 15, bottom: 4, trailing: 15)
        self.contentView.addSubview(self.customLabel)

        NSLayoutConstraint.activate([
            self.customLabel.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.customLabel.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.customLabel.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.customLabel.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // This method is not called by UIKit when UITableView.automaticDimension is returned from
        // the particular UITableViewDelegate method. This is in contrast to how self-sizing cells work.
        return self.systemLayoutSizeFitting(size, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }

    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.init(white: 0.1, alpha: 1.0) // Same as _UITableViewHeaderFooterViewLabel
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeContentView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0) // Same as _UITableViewHeaderFooterViewBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}
