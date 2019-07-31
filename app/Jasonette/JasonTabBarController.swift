//
//  JasonTabBarController.swift
//  Finalsite
//
//  Created by Gregory Ecklund on 10/29/18.
//  Copyright © 2018 Finalsite. All rights reserved.
//

import Foundation
import UIKit

@objc class JasonTabBarController:UITabBarController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    @objc func reset() {
        DispatchQueue.main.async { [weak self] in
            let homeTab = self?.viewControllers?.remove(at: 0)
            self?.viewControllers?.removeAll()
            self?.viewControllers?.append(homeTab!)
        }
    }

}
