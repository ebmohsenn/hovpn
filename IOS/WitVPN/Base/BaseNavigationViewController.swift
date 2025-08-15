//
//  BaseNavigationViewController.swift
//  WitVPN
//
//  Created by thongvm on 31/01/2022.
//

import Foundation
class BaseNavigationViewController: UINavigationController {
    
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
