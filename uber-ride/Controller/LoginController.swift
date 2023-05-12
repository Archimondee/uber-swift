//
//  LoginController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 10/05/23.
//

import UIKit

class LoginController: UIViewController {
  // MARK: - Properties

  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "UBER"
    label.font = UIFont(name: "Avenir-Light", size: 36)
    label.textColor = UIColor(white: 1, alpha: 0.8)
    return label
  }()

  private lazy var emailContainerView: UIView = UIView().inputContainerView(image: UIImage(named: "email")!, textField: emailTextField, segmentedControl: nil)

  private lazy var passwordContainerView: UIView = UIView().inputContainerView(image: UIImage(named: "lock")!, textField: passwordTextField, segmentedControl: nil)

  private let emailTextField: UITextField = UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)

  private let passwordTextField: UITextField = UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)

  private let loginButton: AuthButton = {
    let button = AuthButton(type: .system)
    button.setTitle("Login", for: .normal)
    return button
  }()

  private lazy var dontHaveAccountButton: UIButton = {
    let button = UIButton(type: .system)
    let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.lightGray])

    attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint]))
    button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
    button.setAttributedTitle(attributedTitle, for: .normal)
    return button
  }()

  // MARK: - Selector

  @objc func handleShowSignUp() {
    let controller = SignUpController()
    navigationController?.pushViewController(controller, animated: true)
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    configureUI()
  }

//  override var preferredStatusBarStyle: UIStatusBarStyle {
//    return .lightContent
//  }

  // MARK: - Helper

  func configureUI() {
    view.backgroundColor = .backgroundColor
    configureNavigationBar()

    view.addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true

    titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
    titleLabel.centerX(inView: view)

    let stack = UIStackView(arrangedSubviews: [emailContainerView, passwordContainerView, loginButton])
    stack.axis = .vertical
    stack.distribution = .fillProportionally
    stack.spacing = 24

    view.addSubview(stack)
    stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)

    view.addSubview(dontHaveAccountButton)
    dontHaveAccountButton.centerX(inView: view)
    dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
  }

  func configureNavigationBar() {
    navigationController?.navigationBar.isHidden = true
    navigationController?.navigationBar.barStyle = .black
  }
}
