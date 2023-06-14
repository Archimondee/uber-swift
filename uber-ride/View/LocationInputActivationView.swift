//
//  LocationInputActivationView.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 19/05/23.
//

import UIKit

protocol LocationInputActionViewDelegate: AnyObject {
  func presentLocationInputView()
}

class LocationInputActionView: UIView {
  weak var delegate: LocationInputActionViewDelegate?

  private let indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    return view
  }()

  private let placeholderLabel: UILabel = {
    let label = UILabel()
    label.text = "Where to?"
    label.font = UIFont.systemFont(ofSize: 18)
    label.textColor = .darkGray
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .white
    addSubview(indicatorView)
    indicatorView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
    indicatorView.setDimensions(height: 6, width: 6)

    addSubview(placeholderLabel)
    placeholderLabel.centerY(inView: self, leftAnchor: indicatorView.rightAnchor, paddingLeft: 20)

    let tap = UITapGestureRecognizer(target: self, action: #selector(presentLocationInputView))
    addGestureRecognizer(tap)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func presentLocationInputView() {
    delegate?.presentLocationInputView()
  }
}
