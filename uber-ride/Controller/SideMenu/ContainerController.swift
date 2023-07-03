//
//  ContainerController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 30/06/23.
//

import Firebase
import UIKit

class ContainerController: UIViewController {
  // MARK: - Properties

  private let homeController = HomeController()
  private var menuController: MenuController!
  private var isExpanded = false
  private let blackView = UIView()

  private var user: User? {
    didSet {
      guard let user = user else { return }
      homeController.user = user
      configureMenuController(withUser: user)
    }
  }

  // MARK: - API

  func fetchUserData() {
    guard let currentUid = Auth.auth().currentUser?.uid else { return }
    Service.shared.fetchUserData(uid: currentUid) { user in
      self.user = user
    }
  }

  func signOut() {
    do {
      try Auth.auth().signOut()
      DispatchQueue.main.async {
        let nav = UINavigationController(rootViewController: LoginController())
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
      }
    } catch {
      print("Signing out \(error.localizedDescription)")
    }
  }

  func checkIfUserIsLoggedIn() {
    if Auth.auth().currentUser?.uid == nil {
      DispatchQueue.main.async {
        let nav = UINavigationController(rootViewController: LoginController())
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
      }
    } else {
      configure()
    }
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    checkIfUserIsLoggedIn()
  }

  override var prefersStatusBarHidden: Bool {
    return isExpanded
  }

  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    return .slide
  }

  // MARK: - Selectors

  @objc func dismissMenu() {
    isExpanded = false
    animateMenu(shouldExpand: false)
  }

  // MARK: - Helper Functions

  func configure() {
    view.backgroundColor = .backgroundColor
    fetchUserData()
    configureHomeController()
  }

  func configureHomeController() {
    addChild(homeController)
    homeController.didMove(toParent: self)
    view.addSubview(homeController.view)
    homeController.delegate = self
  }

  func configureMenuController(withUser user: User) {
    menuController = MenuController(user: user)
    addChild(menuController)
    menuController.didMove(toParent: self)
    menuController.view.frame = CGRect(x: 0, y: 40, width: view.frame.width, height: view.frame.height - 40)
    view.insertSubview(menuController.view, at: 0)
    menuController.delegate = self
    configureBlackView()
  }

  func configureBlackView() {
    blackView.frame = view.bounds
    blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
    blackView.alpha = 0
    view.addSubview(blackView)

    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
    blackView.addGestureRecognizer(tap)
  }

  func animateMenu(shouldExpand: Bool, completion: ((Bool) -> Void)? = nil) {
    let xOrigin = view.frame.width - 80
    if shouldExpand {
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
        self.homeController.view.frame.origin.x = xOrigin

      } completion: { _ in
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
          self.blackView.alpha = 1
          self.blackView.frame = CGRect(x: xOrigin, y: 0, width: 80, height: self.view.frame.height)
        }
      }

    } else {
      blackView.alpha = 0
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
        self.homeController.view.frame.origin.x = 0
      }, completion: completion)
    }

    animateStatusBar()
  }

  func animateStatusBar() {
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
      self.setNeedsStatusBarAppearanceUpdate()
    }
  }
}

// MARK: - HomeControllerDelegate

extension ContainerController: HomeControllerDelegate {
  func handleMenuToggle() {
    isExpanded.toggle()
    animateMenu(shouldExpand: isExpanded)
  }
}

// MARK: - MenuControllerDelegate

extension ContainerController: MenuControllerDelegate {
  func didSelect(option: MenuOptions) {
    isExpanded.toggle()
    animateMenu(shouldExpand: false) { _ in
      switch option {
      case .yourTrips:
        break
      case .settings:
        guard let user = self.user else { return }
        let controller = SettingsController(user: user)
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
      case .logout:
        let alert = UIAlertController(title: nil, message: "Are you sure you want to log out? ", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
          self.signOut()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
      }
    }
  }
}
