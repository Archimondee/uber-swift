//
//  HomeController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 13/05/23.
//

import Firebase
import MapKit
import UIKit

private let reuseIdentifier = "LocationCell"
private let annotationIdentifer = "DriverAnnotation"

private enum ActionButtonConfiguration {
  case showMenu
  case dismissActionView

  init() {
    self = .showMenu
  }
}

class HomeController: UIViewController {
  // MARK: - Properties

  private let mapView = MKMapView()
  private let locationManager = LocationHandler.shared.locationManager
  private let inputActionView = LocationInputActionView()
  private let locationInputView = LocationInputView()
  private let tableView = UITableView()
  private var searchResults = [MKPlacemark]()
  private final let locationInputViewHeight: CGFloat = 200
  private final let rideActionViewHeight: CGFloat = 300
  private var user: User? {
    didSet {
      locationInputView.user = user
      if user?.accountType == .passenger {
        fetchDrivers()
        configureLocationInputActivationView()
      }
    }
  }

  private let rideActionView = RideActionView()
  private var actionButtonConfig = ActionButtonConfiguration()
  private var route: MKRoute?

  private lazy var actionButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(named: "burger-menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
    button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
    return button
  }()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    checkIfUserIsLoggedIn()
    view.backgroundColor = .backgroundColor
    enableLocationServices()
    // signOut()
  }

  override func viewDidAppear(_: Bool) {
    checkIfUserIsLoggedIn()
    view.backgroundColor = .backgroundColor
    enableLocationServices()
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
      fetchUserData()
    }
  }

  fileprivate func configureActionButton(config: ActionButtonConfiguration) {
    switch config {
    case .showMenu:
      actionButton.setImage(UIImage(named: "burger-menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
      actionButtonConfig = .showMenu
    case .dismissActionView:
      actionButton.setImage(UIImage(named: "back-button")?.withRenderingMode(.alwaysOriginal), for: .normal)
      actionButtonConfig = .dismissActionView
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

  // MARK: - API

  func fetchUserData() {
    guard let currentUid = Auth.auth().currentUser?.uid else { return }
    Service.shared.fetchUserData(uid: currentUid) { user in
      self.user = user
    }
  }

  func fetchDrivers() {
    guard let location = locationManager?.location else { return }
    Service.shared.fetchDriver(location: location) { driver in
      guard let coordinate = driver.location?.coordinate else { return }
      let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
      var driverIsVisible: Bool {
        return self.mapView.annotations.contains(where: { annotation -> Bool in
          guard let driverAnno = annotation as? DriverAnnotation else { return false }
          if driverAnno.uid == driver.uid {
            driverAnno.updateAnnotationPosition(withCoordinate: coordinate)

            return true
          }
          return false
        })
      }

      if !driverIsVisible {
        self.mapView.addAnnotation(annotation)
      }
    }
  }

  // MARK: - Helpers

  func configureUI() {
    configureMapView()
    configureRideActionView()

    view.addSubview(actionButton)
    actionButton.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 75, paddingLeft: 20, width: 38, height: 38)

    configureTableView()
  }

  func configureLocationInputActivationView() {
    view.addSubview(inputActionView)
    inputActionView.centerX(inView: view)
    inputActionView.setDimensions(height: 50, width: view.frame.width - 64)
    inputActionView.anchor(top: actionButton.bottomAnchor, paddingTop: 20)
    inputActionView.addShadow()
    inputActionView.alpha = 0
    inputActionView.delegate = self
    locationInputView.delegate = self

    UIView.animate(withDuration: 2) {
      self.inputActionView.alpha = 1
    }
  }

  func configureMapView() {
    view.addSubview(mapView)
    mapView.frame = view.frame

    mapView.showsUserLocation = true
    mapView.userTrackingMode = .follow
    mapView.delegate = self
  }

  func configureRideActionView() {
    view.addSubview(rideActionView)
    rideActionView.delegate = self
    rideActionView.frame = CGRect(x: 0, y: view.frame.height,
                                  width: view.frame.width, height: rideActionViewHeight)
  }

  func configureTableView() {
    tableView.delegate = self
    tableView.dataSource = self

    tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
    tableView.rowHeight = 60
    tableView.tableFooterView = UIView()

    let height = view.frame.height - locationInputViewHeight
    tableView.frame = CGRect(x: 0, y: view.frame.height,
                             width: view.frame.width, height: height)

    view.addSubview(tableView)
  }

  func configureLocationView() {
    view.addSubview(locationInputView)
    locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
    inputActionView.alpha = 0
    UIView.animate(withDuration: 0.5, animations: {
      self.locationInputView.alpha = 1

    }) { _ in

      UIView.animate(withDuration: 0.3) {
        self.tableView.frame.origin.y = self.locationInputViewHeight
      }
    }
  }

  func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
    UIView.animate(withDuration: 0.3, animations: {
      self.locationInputView.alpha = 0
      self.tableView.frame.origin.y = self.view.frame.height
      self.locationInputView.removeFromSuperview()

    }, completion: completion)
  }

  @objc func actionButtonPressed() {
    switch actionButtonConfig {
    case .showMenu:
      print("Debug")
    case .dismissActionView:
      removeAnnotationsAndOverlays()
      mapView.showAnnotations(mapView.annotations, animated: true)
      mapView.setCenter(mapView.userLocation.coordinate, animated: true)
      mapView.region.span.longitudeDelta = 0.03
      mapView.region.span.latitudeDelta = 0.03
      // mapView.zoomToFit(annotations: mapView.annotations)
      UIView.animate(withDuration: 0.3) {
        self.inputActionView.alpha = 1
        self.configureActionButton(config: .showMenu)
        self.animateRideActionView(shouldShow: false)
      }
    }
  }

  func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil) {
    let yOrigin = shouldShow ? view.frame.height - rideActionViewHeight : view.frame.height

    UIView.animate(withDuration: 0.3) {
      self.rideActionView.frame.origin.y = yOrigin
    }

    if shouldShow {
      guard let destination = destination else { return }
      rideActionView.destination = destination
    }
  }
}

// MARK: - LocationServices

extension HomeController {
  func enableLocationServices() {
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      locationManager?.requestWhenInUseAuthorization()
    case .restricted, .denied:
      print("Debug : ")
    case .authorizedAlways:
      locationManager?.startUpdatingLocation()
      locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    case .authorizedWhenInUse:

      locationManager?.requestAlwaysAuthorization()

    @unknown default:
      break
    }
  }
}

extension HomeController: LocationInputActionViewDelegate {
  func presentLocationInputView() {
    inputActionView.alpha = 0
    configureLocationView()
  }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
  func executeSearch(query: String) {
    searchBy(naturalLanguageQuery: query) { placemarks in
      self.searchResults = placemarks
      self.tableView.reloadData()
    }
  }

  func dismissLocationInputView() {
    dismissLocationView { _ in
      UIView.animate(withDuration: 0.3) {
        self.inputActionView.alpha = 1
      }
    }
  }
}

extension HomeController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
    return "Testing"
  }

  func numberOfSections(in _: UITableView) -> Int {
    return 2
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? 2 : searchResults.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
    if indexPath.section == 1 {
      cell.placemark = searchResults[indexPath.row]
    }

    return cell
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedPlacemark = searchResults[indexPath.row]

    configureActionButton(config: .dismissActionView)
    let destination = MKMapItem(placemark: selectedPlacemark)
    generatePolyline(toDestination: destination)
    dismissLocationView { _ in
      let annotation = MKPointAnnotation()
      annotation.coordinate = selectedPlacemark.coordinate
      self.mapView.addAnnotation(annotation)
      self.mapView.selectAnnotation(annotation, animated: true)

//      self.mapView.annotations.forEach { annotation in
//        if let anno = annotation as? MKUserLocation {
//          annotations.append(anno)
//        }
//
//        if let anno = annotation as? MKPointAnnotation {
//          annotations.append(anno)
//        }
//      }

      let annotations = self.mapView.annotations.filter { !$0.isKind(of: DriverAnnotation.self) }
      self.mapView.zoomToFit(annotations: annotations)
      self.animateRideActionView(shouldShow: true, destination: selectedPlacemark)
    }
  }
}

// MARK: - Map Helper Function

private extension HomeController {
  func searchBy(naturalLanguageQuery: String, completion: @escaping ([MKPlacemark]) -> Void) {
    var results = [MKPlacemark]()

    let request = MKLocalSearch.Request()
    request.region = mapView.region
    request.naturalLanguageQuery = naturalLanguageQuery

    let search = MKLocalSearch(request: request)
    search.start { response, _ in
      guard let response = response else { return }

      response.mapItems.forEach { item in
        results.append(item.placemark)
      }

      completion(results)
    }
  }

  func generatePolyline(toDestination destination: MKMapItem) {
    let request = MKDirections.Request()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = destination
    request.transportType = .automobile
    let directionRequest = MKDirections(request: request)
    directionRequest.calculate { response, _ in
      guard let response = response else { return }
      self.route = response.routes[0]
      guard let polyline = self.route?.polyline else { return }
      self.mapView.addOverlay(polyline)
    }
  }

  func removeAnnotationsAndOverlays() {
    mapView.annotations.forEach { annotation in
      if let anno = annotation as? MKPointAnnotation {
        mapView.removeAnnotation(anno)
      }
    }

    if mapView.overlays.count > 0 {
      mapView.removeOverlay(mapView.overlays[0])
    }
  }
}

// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
  func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? DriverAnnotation {
      let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifer)
      view.image = UIImage(named: "driver")

      return view
    }

    return nil
  }

  func mapView(_: MKMapView, rendererFor _: MKOverlay) -> MKOverlayRenderer {
    if let route = route {
      let polyline = route.polyline
      let lineRenderer = MKPolylineRenderer(polyline: polyline)
      lineRenderer.strokeColor = .mainBlueTint
      lineRenderer.lineWidth = 3
      return lineRenderer
    }
    return MKOverlayRenderer()
  }
}

extension HomeController: RideActionViewDelegate {
  func uploadTrip(_ view: RideActionView) {
    guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
    guard let destinationCoordinates = view.destination?.coordinate else { return }
    Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates, completion: { err, _ in
      if let error = err {
        print("Failed to upload \(error)")
      }

      print("Debug : did upload trips")
    })
  }
}
