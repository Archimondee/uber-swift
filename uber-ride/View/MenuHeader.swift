//
//  MenuHeader.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 30/06/23.
//

import UIKit

class MenuHeader: UIView {
  // MARK: - Properties

//  var user: User? {
//    didSet {
//      fullnameLabel.text = user?.fullname
//      emailLabel.text = user?.email
//    }
//  }

  private let user: User

  private let profileImageView: UIImageView = {
    let iv = UIImageView()
    iv.backgroundColor = .lightGray
    return iv
  }()

  private lazy var fullnameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    // label.text = "Driver Name"
    label.text = user.fullname
    label.textColor = .white
    return label
  }()

  private lazy var emailLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = .lightGray
//    label.text = "test@gmail.com"
    label.text = user.email
    return label
  }()

  // MARK: - Lifecycle

  init(user: User, frame: CGRect) {
    self.user = user
    super.init(frame: frame)

    backgroundColor = .backgroundColor

    addSubview(profileImageView)
    profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 20, paddingLeft: -60, width: 64, height: 64)
    profileImageView.layer.cornerRadius = 64 / 2

    let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
    stack.distribution = .fillEqually
    stack.spacing = 4
    stack.axis = .vertical
    addSubview(stack)
    stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 12)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Selectors

  // MARK: - Helper Functions
}
