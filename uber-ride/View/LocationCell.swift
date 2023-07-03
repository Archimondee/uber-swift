//
//  LocationCell.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 20/05/23.
//

import MapKit
import UIKit

class LocationCell: UITableViewCell {
  var placemark: MKPlacemark? {
    didSet {
      titleLabel.text = placemark?.name
      addressLabel.text = placemark?.address
    }
  }
  
  var type: LocationType? {
    didSet {
      titleLabel.text = type?.description
      addressLabel.text = type?.subtitle
    }
  }

  let titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.text = "123 Main Street"
    return label
  }()

  private let addressLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = .lightGray
    label.text = "123 Main Street, Washington DC"
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
    stack.axis = .vertical
    stack.distribution = .fillEqually
    stack.spacing = 4

    addSubview(stack)
    stack.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
