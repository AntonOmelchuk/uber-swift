//
//  RideActionView.swift
//  Uber
//
//  Created by Anton Omelchuk on 02.10.2021.
//

import UIKit
import MapKit

class RideActionView: UIView {

    // MARK: - Properties
    
    var destination: MKPlacemark? {
        didSet {
            titleLabel.text = destination?.name
            addressLabel.text = destination?.address
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        
        return label
    }()
    
    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        
        let label = UILabel()
        label.text = "X"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30)
        
        view.addSubview(label)
        label.centerX(inView: view)
        label.centerY(inView: view)
        
        return view
    }()
    
    private let uberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "Uber X"
        label.textAlignment = .center
        
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        
        return view
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.setTitle("CONFIRM UBERX", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        button.layer.cornerRadius = 3
        
        return button
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerX(inView: self)
        stack.anchor(top: topAnchor, paddingTop: 12)
        
        addSubview(iconView)
        iconView.centerX(inView: self)
        iconView.anchor(top: stack.bottomAnchor, paddingTop: 16)
        iconView.setDemensions(height: 60, width: 60)
        iconView.layer.cornerRadius = 30
        
        addSubview(uberLabel)
        uberLabel.centerX(inView: self)
        uberLabel.anchor(top: iconView.bottomAnchor, paddingTop: 8)
        
        addSubview(separatorView)
        separatorView.anchor(top: uberLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 4, height: 0.75)
        
        addSubview(actionButton)
        actionButton.centerX(inView: self)
        actionButton.anchor(left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor, paddingLeft: 12, paddingBottom: 12, paddingRight: 12, height: 48)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selectores
    
    @objc func actionButtonPressed() {
        
    }
}
