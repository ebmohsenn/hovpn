//
//  PrivacyViewController.swift
//  WitVPN
//
//  Created by thongvm on 25/01/2022.
//

import Foundation
import UIKit

class PrivacyViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapClose() {
        self.navigationController?.popViewController(animated: true)
    }

}
