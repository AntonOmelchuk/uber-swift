//
//  LocationInputView.swift
//  Uber
//
//  Created by Anton Omelchuk on 27.09.2021.
//

import UIKit

protocol LocationInputViewDelegate: AnyObject {
    func dismissLocationInputView()
    func executeSearch(query: String)
}

class LocationInputView: UIView {

    // MARK: - Properties
    
    weak var delegate: LocationInputViewDelegate?
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
        
        return button
    }()
    
    let titleLabel: UILabel = {
       let label = UILabel()
        label.text = "Stephan Dowless"
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 16)
        
        return label
    }()
    
    private let startLocationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        
        return view
    }()
    
    private let linkingView: UIView = {
        let view = UIView()
        view.backgroundColor = .darkGray
        
        return view
    }()
    
    private let destinationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        
        return view
    }()
    
    private lazy var startingLocationTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Current location"
        textField.backgroundColor = .systemGroupedBackground
        textField.isEnabled = false
        textField.layer.cornerRadius = 3
        
        let paddingView = UIView()
        paddingView.setDemensions(height: 30, width: 8)
        
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private lazy var destinationLocationTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter a destination..."
        textField.backgroundColor = .lightGray
        textField.returnKeyType = .search
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.layer.cornerRadius = 3
        textField.delegate = self
        
        let paddingView = UIView()
        paddingView.setDemensions(height: 30, width: 8)
        
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addShadow()
        
        backgroundColor = .white
        
        addSubview(backButton)
        backButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: 44, paddingLeft: 12, width: 24, height: 25)
        
        addSubview(titleLabel)
        titleLabel.centerY(inView: backButton)
        titleLabel.centerX(inView: self)
        
        addSubview(startingLocationTextField)
        startingLocationTextField.anchor(top: backButton.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 4, paddingLeft: 40, height: 36)
        
        addSubview(destinationLocationTextField)
        destinationLocationTextField.anchor(top: startingLocationTextField.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 40, height: 36)
        
        addSubview(startLocationIndicatorView)
        startLocationIndicatorView.centerY(inView: startingLocationTextField)
        startLocationIndicatorView.anchor(left: leftAnchor, paddingLeft: 20, width: 6, height: 6)
        startLocationIndicatorView.layer.cornerRadius = 3
        
        addSubview(destinationIndicatorView)
        destinationIndicatorView.centerY(inView: destinationLocationTextField)
        destinationIndicatorView.anchor(left: leftAnchor, paddingLeft: 20, width: 6, height: 6)
        
        addSubview(linkingView)
        linkingView.centerX(inView: startLocationIndicatorView)
        linkingView.anchor(top: startLocationIndicatorView.bottomAnchor, bottom: destinationIndicatorView.topAnchor, paddingTop: 4, paddingBottom: 4, width: 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selectors
    
    @objc func handleBackTapped() {
        delegate?.dismissLocationInputView()
    }
}

// MARK: - UITextFieldDelegate

extension LocationInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text else { return false }
        delegate?.executeSearch(query: query)
        self.endEditing(true)
        
        return true
    }
}
