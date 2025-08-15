//
//  LeftMenuViewController.swift
//  WitVPN
//
//  Created by thongvm on 14/01/2022.
//

import Foundation
import Macaw
import UIKit
import SideMenu
protocol LeftMenuViewControllerDelegate {
    func leftMenuDidTapAccount()
    func leftMenuDidTapUpgrade()
    func leftMenuDidTapHome()
}
class LeftMenuViewController: BaseViewController {
    @IBOutlet weak var homeView: UIView!
    @IBOutlet weak var vipView: UIView!
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var banner: UIImageView!
    var delegate: LeftMenuViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.banner.isHidden = StoreKit.shared.isActivePaidSubscription()
    }
    func setupUI() {
        self.homeView.layer.cornerRadius = 8
        self.vipView.layer.cornerRadius = 8
        self.userView.layer.cornerRadius = 8
        self.homeView.clipsToBounds = true
        self.vipView.clipsToBounds = true
        self.userView.clipsToBounds = true
    }
    
    @IBAction func didTapClose() {
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
        })
    }
    
    @IBAction func didTapHomeView() {
        self.highlightHome()
        self.delegate?.leftMenuDidTapHome()
    }
    
    func highlightHome() {
        self.homeView.backgroundColor = UIColor(named: "cl_selected_item")
        self.vipView.backgroundColor = UIColor(named: "cl_default_item")
        self.userView.backgroundColor = UIColor(named: "cl_default_item")
    }
    
    @IBAction func didTapVipView() {
        self.highlightVIP()
        self.delegate?.leftMenuDidTapUpgrade()
    }
    func highlightVIP() {
        self.vipView.backgroundColor = UIColor(named: "cl_selected_item")
        self.homeView.backgroundColor = UIColor(named: "cl_default_item")
        self.userView.backgroundColor = UIColor(named: "cl_default_item")
    }
    
    @IBAction func didTapUserView() {
        self.highlightUser()
        self.delegate?.leftMenuDidTapAccount()
    }
    func highlightUser() {
        self.userView.backgroundColor = UIColor(named: "cl_selected_item")
        self.homeView.backgroundColor = UIColor(named: "cl_default_item")
        self.vipView.backgroundColor = UIColor(named: "cl_default_item")
    }
    
    @IBAction func didTapBanner() {
        if StoreKit.shared.isActivePaidSubscription() == false {
            self.highlightVIP()
            self.delegate?.leftMenuDidTapUpgrade()
        }
    }
}
