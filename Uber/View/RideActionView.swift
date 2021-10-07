//
//  RideActionView.swift
//  Uber
//
//  Created by Anton Omelchuk on 02.10.2021.
//

import UIKit
import MapKit

protocol RideActionViewDelegate: AnyObject {
    func uploadTrip(_ view: RideActionView)
    func cancelTrip()
}

enum RideActionViewConfiguration {
    case requestRide
    case tripAccepted
    case driverArrived
    case pickupPassenger
    case tripInProgress
    case endTrip
    
    init() {
        self = .requestRide
    }
}

enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    
    var description: String {
        switch self {
        case .requestRide: return "CONFIRM UBERX"
        case .cancel: return "CANCEL RIDE"
        case .getDirections: return "GET DIRECTIONS"
        case .pickup: return "PICKUP PASSENGER"
        case .dropOff: return "DROP OF PASSENGER"
        }
    }
    
    init() {
        self = .requestRide
    }
}

class RideActionView: UIView {

    // MARK: - Properties
    
    var destination: MKPlacemark? {
        didSet {
            titleLabel.text = destination?.name
            addressLabel.text = destination?.address
        }
    }
    
    var buttonAction = ButtonAction()
    var user: User?
    
    var config = RideActionViewConfiguration() {
        didSet {
            configureUI(withConfig: config)
        }
    }
    
    weak var delegate: RideActionViewDelegate?
    
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
    
    private lazy var iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        
        view.addSubview(infoViewLabel)
        infoViewLabel.centerX(inView: view)
        infoViewLabel.centerY(inView: view)
        
        return view
    }()
    
    private let infoViewLabel: UILabel = {
        let label = UILabel()
        label.text = "X"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30)
        
        return label
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
        switch buttonAction {
        case .requestRide:
            delegate?.uploadTrip(self)
        case .cancel:
            delegate?.cancelTrip()
        case .getDirections:
            print("get")
        case .pickup:
            print("pickup")
        case .dropOff:
            print("dropoff")
        }
    }
    
    // MARK: - Helper Fucntions
    
    private func configureUI(withConfig config: RideActionViewConfiguration) {
        switch config {
        case .requestRide:
            buttonAction = .requestRide
            actionButton.setTitle(buttonAction.description, for: .normal)
        case .tripAccepted:
            guard let user = user else { return }
            
            if user.accountType == .passenger {
                titleLabel.text = "En Route To Passenger"
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            } else {
                titleLabel.text = "Driver En Route"
                buttonAction = .cancel
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
            infoViewLabel.text = String(user.fullName.first ?? "X")
            uberLabel.text = user.fullName
        case .driverArrived:
            guard let user = user else { return }
            
            if user.accountType == .driver {
                titleLabel.text = "Driver Has Arrived"
                addressLabel.text = "Please meet driver at pickup location"
            }
        case .pickupPassenger:
            titleLabel.text = "Arrived At Passenger Location"
            buttonAction = .pickup
            actionButton.setTitle(buttonAction.description, for: .normal)
        case .tripInProgress:
            guard let user = user else { return }
            
            if user.accountType == .driver {
                actionButton.setTitle("TRIP IN PROGRESS", for: .normal)
                actionButton.isEnabled = false
            } else {
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
            titleLabel.text = "En Route To Destination"
        case .endTrip:
            guard let user = user else { return }
            
            if user.accountType == .driver {
                actionButton.setTitle("ARRIVED AT DESTINATION", for: .normal)
                actionButton.isEnabled = false
            } else {
                buttonAction = .dropOff
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
        }
    }
}
