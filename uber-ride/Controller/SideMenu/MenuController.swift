//
//  MenuController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 30/06/23.
//

import UIKit

private let reuseIdentifier = "MenuCell"
enum MenuOptions: Int, CaseIterable, CustomStringConvertible {
  case yourTrips
  case settings
  case logout

  var description: String {
    switch self {
    case .yourTrips:
      return "Your Trips"
    case .settings:
      return "Settings"
    case .logout:
      return "Logout"
    }
  }
}

protocol MenuControllerDelegate: AnyObject {
  func didSelect(option: MenuOptions)
}

class MenuController: UITableViewController {
  // MARK: - Properties

  var user: User

  private lazy var menuHeader: MenuHeader = {
    let frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 80, height: 140)
    let view = MenuHeader(user: user, frame: frame)
    return view
  }()

  weak var delegate: MenuControllerDelegate?

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
    view.backgroundColor = .white
    configureTableView()
  }

  // MARK: - Selectors

  // MARK: - Helper Functions

  func configureTableView() {
    tableView.backgroundColor = .white
    tableView.separatorStyle = .none
    tableView.isScrollEnabled = false
    tableView.rowHeight = 60
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    tableView.tableHeaderView = menuHeader
  }
}

// MARK: - MenuController

extension MenuController {
  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return MenuOptions.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    guard let option = MenuOptions(rawValue: indexPath.row) else { return UITableViewCell() }
    cell.textLabel?.text = option.description
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let option = MenuOptions(rawValue: indexPath.row) else { return }
    delegate?.didSelect(option: option)
  }
}
