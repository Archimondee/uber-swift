//
//  UserInfoHeader.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 04/07/23.
//

import UIKit

class UserInfoHeader: UIView {
  // MARK: - Properties

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
    // label.text = "test@gmail.com"
    label.text = user.email
    return label
  }()

  // MARK: - Lifecycle

//  override init(frame: CGRect) {
//    super.init(frame: frame)
//  }

  init(user: User, frame: CGRect) {
    self.user = user
    super.init(frame: frame)

    backgroundColor = .black

    addSubview(profileImageView)
    profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
    profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 20, paddingLeft: 20)
    profileImageView.setDimensions(height: 64, width: 64)
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

  // MARK:
}
