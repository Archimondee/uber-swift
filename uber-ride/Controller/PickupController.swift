//
//  PickupController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 15/06/23.
//

import MapKit
import UIKit

protocol PickupControllerDelegate: AnyObject {
  func didAcceptTrip(_ trip: Trip)
}

class PickupController: UIViewController {
  // MARK: - Properties
  weak var delegate: PickupControllerDelegate?
  private let mapView = MKMapView()
  let trip: Trip

  private lazy var cancelButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(named: "close")?.withRenderingMode(.alwaysOriginal), for: .normal)
    button.addTarget(self, action: #selector(handleDismissal), for: .touchUpInside)
    return button
  }()

  private let pickupLabel: UILabel = {
    let label = UILabel()
    label.text = "Would you like to pickup this passenger"
    label.font = UIFont.systemFont(ofSize: 16)
    label.textColor = .white
    return label
  }()

  private lazy var acceptTripButton: UIButton = {
    let button = UIButton(type: .system)
    button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
    button.backgroundColor = .white
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
    button.setTitleColor(.black, for: .normal)
    button.setTitle("Accept Trip", for: .normal)
    return button
  }()

  init(trip: Trip) {
    self.trip = trip
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    configureUI()
    configureMapView()
  }

  // MARK: - Selectors

  @objc func handleDismissal() {
    dismiss(animated: true)
  }

  @objc func handleAcceptTrip() {
    Service.shared.acceptTrip(trip: trip) { _, _ in
      self.delegate?.didAcceptTrip(self.trip)
    }
  }

  // MARK: - API

  // MARK: - Helpers

  func configureUI() {
    view.backgroundColor = .backgroundColor
    view.addSubview(cancelButton)
    cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 10, paddingLeft: 16)

    view.addSubview(mapView)
    mapView.setDimensions(height: 270, width: 270)
    mapView.layer.cornerRadius = 270 / 2
    mapView.layer.masksToBounds = true
    mapView.centerX(inView: view)
    mapView.centerY(inView: view, constant: -180)

    view.addSubview(pickupLabel)
    pickupLabel.centerX(inView: view)
    pickupLabel.anchor(top: mapView.bottomAnchor, paddingTop: 16)

    view.addSubview(acceptTripButton)
    acceptTripButton.anchor(top: pickupLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 16,
                            paddingLeft: 32, paddingRight: 32, height: 50)
  }

  func configureMapView() {
    let region = MKCoordinateRegion(center: trip.pickupCoordinates!, latitudinalMeters: 1000, longitudinalMeters: 1000)
    mapView.setRegion(region, animated: false)
    let anno = MKPointAnnotation()
    anno.coordinate = trip.pickupCoordinates!
    mapView.addAnnotation(anno)
    mapView.selectAnnotation(anno, animated: true)
  }
}
