//
//  TermsViewController.swift
//  WitVPN
//
//  Created by thongvm on 25/01/2022.
//

import Foundation

class TermsViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapClose() {
        self.navigationController?.popViewController(animated: true)
    }
}
