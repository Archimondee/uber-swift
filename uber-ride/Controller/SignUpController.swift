//
//  SignUpController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 12/05/23.
//

import Firebase
import GeoFire
import UIKit

class SignUpController: UIViewController {
  // MARK: - Properties

  private var location = LocationHandler.shared.locationManager.location

  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "UBER"
    label.font = UIFont(name: "Avenir-Light", size: 36)
    label.textColor = UIColor(white: 1, alpha: 0.8)
    return label
  }()

  private lazy var emailContainerView: UIView = UIView().inputContainerView(image: UIImage(named: "email")!, textField: emailTextField, segmentedControl: nil)

  private lazy var fullnameContainerView: UIView = UIView().inputContainerView(image: UIImage(named: "person")!, textField: fullnameTextField, segmentedControl: nil)

  private lazy var passwordContainerView: UIView = UIView().inputContainerView(image: UIImage(named: "lock")!, textField: passwordTextField, segmentedControl: nil)

  private lazy var accountTypeContainerView: UIView = UIView().inputContainerView(image: UIImage(named: "account")!, segmentedControl: accountTypeSegmentedControl)

  private let emailTextField: UITextField = UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)

  private let fullnameTextField: UITextField = UITextField().textField(withPlaceholder: "Fullname", isSecureTextEntry: false)

  private let passwordTextField: UITextField = UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)

  private let accountTypeSegmentedControl: UISegmentedControl = {
    let sc = UISegmentedControl(items: ["Rider", "Driver"])
    sc.backgroundColor = .backgroundColor
    sc.tintColor = UIColor.white
    sc.selectedSegmentIndex = 0
    let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    let attributesSelected = [NSAttributedString.Key.foregroundColor: UIColor.backgroundColor]

    sc.setTitleTextAttributes(attributes, for: UIControl.State.normal)
    sc.setTitleTextAttributes(attributesSelected, for: UIControl.State.selected)

    return sc
  }()

  private lazy var signUpButton: AuthButton = {
    let button = AuthButton(type: .system)
    button.setTitle("Signup", for: .normal)
    button.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
    return button
  }()

  private lazy var alreadyHaveAccountButton: UIButton = {
    let button = UIButton(type: .system)
    let attributedTitle = NSMutableAttributedString(string: "Already have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.lightGray])

    attributedTitle.append(NSAttributedString(string: "Login", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint]))
    button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
    button.setAttributedTitle(attributedTitle, for: .normal)
    return button
  }()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    configureUI()
  }

  // MARK: - Selectors

  @objc func handleShowLogin() {
    navigationController?.popViewController(animated: true)
  }

  @objc func handleSignup() {
    guard let email = emailTextField.text?.lowercased() else { return }
    guard let password = passwordTextField.text else { return }
    guard let fullname = fullnameTextField.text else { return }
    let accountTypeIndex = accountTypeSegmentedControl.selectedSegmentIndex

    Auth.auth().createUser(withEmail: email, password: password) { result, error in
      if let error = error {
        print("Failed to register user with error \(error)")
      }

      guard let uid = result?.user.uid else { return }
      let values = ["email": email, "fullname": fullname, "accountType": accountTypeIndex] as [String: Any]

      if accountTypeIndex == 1 {
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        guard let location = self.location else { return }
        geofire.setLocation(location, forKey: uid) { _ in
          self.uploadUserDataAndNavigate(uid: uid, values: values)
        }
      }
      self.uploadUserDataAndNavigate(uid: uid, values: values)
    }
  }

  // MARK: - Helpers

  func configureUI() {
    view.backgroundColor = .backgroundColor
    configureNavigationBar()

    view.addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true

    titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
    titleLabel.centerX(inView: view)

    let stack = UIStackView(arrangedSubviews: [emailContainerView, fullnameContainerView, passwordContainerView, accountTypeContainerView, signUpButton])
    stack.axis = .vertical
    stack.distribution = .fillEqually
    stack.spacing = 24

    view.addSubview(stack)
    stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)

    view.addSubview(alreadyHaveAccountButton)
    alreadyHaveAccountButton.centerX(inView: view)
    alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
  }

  func configureNavigationBar() {
    navigationController?.navigationBar.isHidden = true
    navigationController?.navigationBar.barStyle = .black
  }

  func uploadUserDataAndNavigate(uid: String, values: [String: Any]) {
    REF_USERS.child(uid).updateChildValues(values) { _, _ in
      self.dismiss(animated: true)
    }
  }
}
