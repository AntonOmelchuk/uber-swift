//
//  MenuController.swift
//  Uber
//
//  Created by Anton Omelchuk on 09.10.2021.
//

import UIKit

class MenuController: UIViewController {
    
    // MARK: - Properties
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            menuHeader.user = user
        }
    }
    
    private lazy var menuHeader: MenuHeader = {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 80, height: 140)
        
        let view = MenuHeader(frame: frame)
        return view
    }()
    
    private let menuItem1: UILabel = {
        let label = UILabel()
        label.text = "Menu item 1"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        
        return label
    }()
    
    private let menuItem2: UILabel = {
        let label = UILabel()
        label.text = "Menu item 2"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        
        return label
    }()
    
    private let menuItem3: UILabel = {
        let label = UILabel()
        label.text = "Menu item 3"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    // MARK: - Selectors
    
    // MARK: - Helper Functions
    
    func configureUI() {
        view.backgroundColor = .white
        view.addSubview(menuHeader)
        view.addSubview(menuItem1)
        menuItem1.anchor(top: menuHeader.bottomAnchor, left: view.leftAnchor, paddingTop: 21, paddingLeft: 15)
        view.addSubview(menuItem2)
        menuItem2.anchor(top: menuItem1.bottomAnchor, left: view.leftAnchor, paddingTop: 21, paddingLeft: 15)
        view.addSubview(menuItem3)
        menuItem3.anchor(top: menuItem2.bottomAnchor, left: view.leftAnchor, paddingTop: 21, paddingLeft: 15)
    }
}

