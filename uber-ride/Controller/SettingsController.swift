//
//  SettingsController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 04/07/23.
//

import UIKit

private let reuseIdentifier = "LocationCell"

enum LocationType: Int, CaseIterable, CustomStringConvertible {
  case home
  case work

  var description: String {
    switch self {
    case .home: return "Home"
    case .work: return "Work"
    }
  }

  var subtitle: String {
    switch self {
    case .home: return "Add Home"
    case .work: return "Add Work"
    }
  }
}

class SettingsController: UITableViewController {
  // MARK: - Properties

  private let user: User
  private lazy var infoHeader: UserInfoHeader = {
    let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 100)
    let view = UserInfoHeader(user: user, frame: frame)

    return view
  }()

  // MARK: - Lifecycle

  init(user: User) {
    self.user = user
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureTableView()
    configureNavigationBar()
  }

  // MARK: - Selectors

  @objc func handleDismissal() {
    dismiss(animated: true)
  }

  // MARK: - Helper Functions

  func configureTableView() {
    tableView.rowHeight = 60
    tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
    tableView.backgroundColor = .white
    tableView.tableHeaderView = infoHeader
    tableView.separatorStyle = .none
  }

  func configureNavigationBar() {
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationController?.navigationBar.isTranslucent = false
    navigationController?.navigationBar.barStyle = .black
    navigationItem.title = "Settings"
    navigationController?.navigationBar.barTintColor = .backgroundColor
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
  }
}

// MARK: UITableViewDelegate/Datasource

extension SettingsController {
  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return LocationType.allCases.count
  }

  override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
    let view = UIView()
    view.backgroundColor = .black

    let title = UILabel()
    title.font = UIFont.systemFont(ofSize: 16)
    title.textColor = .white
    title.text = "Favorites"
    view.addSubview(title)
    title.centerY(inView: view, leftAnchor: view.leftAnchor, paddingLeft: 16)

    return view
  }

  override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
    return 40
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
    guard let type = LocationType(rawValue: indexPath.row) else { return cell }
    cell.type = type
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let type = LocationType(rawValue: indexPath.row) else { return }
  }
}
