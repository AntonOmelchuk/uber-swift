//
//  MenuHeader.swift
//  Uber
//
//  Created by Anton Omelchuk on 09.10.2021.
//

import UIKit

class MenuHeader: UIView {
    
    // MARK: - Properties
    
    private let user: User
    
    private let profileImageView: UIImageView = {
       let image = UIImageView()
        image.backgroundColor = .lightGray
        
        return image
    }()
    
    private lazy var fullName: UILabel = {
        let label = UILabel()
        label.textColor = .white 
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = user.fullName
        
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.text = user.email
        
        return label
    }()
    
    // MARK: - Lifecycle
    
    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)
        
        backgroundColor = .backgroundColor
        
        addSubview(profileImageView)
        profileImageView.anchor(top: self.safeAreaLayoutGuide.topAnchor, left: leftAnchor, paddingTop: 4, paddingLeft: 12, width: 64, height: 64)
        profileImageView.layer.cornerRadius = 32
        
        let stack = UIStackView(arrangedSubviews: [fullName, emailLabel])
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.axis = .vertical
        
        addSubview(stack)
        
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 12)
    } 
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
    // MARK: - Selectors
}
