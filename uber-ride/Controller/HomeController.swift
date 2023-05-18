//
//  HomeController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 13/05/23.
//

import Firebase
import MapKit
import UIKit

class HomeController: UIViewController {
  private let mapView = MKMapView()
  override func viewDidLoad() {
    super.viewDidLoad()
    checkIfUserIsLoggedIn()
    view.backgroundColor = .backgroundColor
    //signOut()
  }

  override func viewDidAppear(_ animated: Bool) {
    checkIfUserIsLoggedIn()
  }

  func checkIfUserIsLoggedIn() {
    if Auth.auth().currentUser?.uid == nil {
      DispatchQueue.main.async {
        let nav = UINavigationController(rootViewController: LoginController())
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
      }
    } else {
      configureUI()
    }
  }

  func signOut() {
    do {
      try Auth.auth().signOut()
    } catch {
      print("Signing out \(error.localizedDescription)")
    }
  }

  // MARK: - Helpers

  func configureUI() {
    view.addSubview(mapView)
    mapView.frame = view.frame
  }
}
