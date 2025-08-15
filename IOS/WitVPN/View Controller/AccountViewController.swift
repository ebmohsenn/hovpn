//
//  AccountViewController.swift
//  WitVPN
//
//  Created by thongvm on 18/01/2022.
//

import Foundation
import UIKit
import FirebaseAuth
import SideMenu
class AccountViewController: BaseViewController {
    @IBOutlet weak var lbEmail: UILabel!
    @IBOutlet weak var lbPremiumStatus: UILabel!
    @IBOutlet weak var bg: UIView!
    @IBOutlet weak var banner: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorBox: UIView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var topConstraints: NSLayoutConstraint!
    
    let main = UIStoryboard(name: "Main", bundle: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupData()
        self.leftMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let active = StoreKit.shared.isActivePaidSubscription()
        if active {
            guard let paidSubscription = WitWork.shared.getSubscription() else {return}
            let date = paidSubscription.expiresDate
            print("expired at: \(date)")
            let dateStr = date.toFormat("YYYY/MM/dd", locale: nil)
            self.lbPremiumStatus.text = "VIP package until \(dateStr)"
        }else {
            self.lbPremiumStatus.text = "Free"
        }
        
        self.errorBox.isHidden = true
    }
    
    func setupUI() {
        self.bg.layer.cornerRadius = 8
        self.bg.clipsToBounds = true
        self.banner.isHidden = StoreKit.shared.isActivePaidSubscription()
        self.errorBox.isHidden = true
        self.deleteView.isHidden = true
        if UIDevice.current.checkIfHasDynamicIsland() {
            self.topConstraints.constant = -8
        }
    }
    
    func leftMenu() {
        guard let sideMenu: SideMenuNavigationController = main.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideMenuNavigationController,
        let leftVC = sideMenu.viewControllers.first as? LeftMenuViewController else {return}
        leftVC.delegate = self
        SideMenuManager.default.leftMenuNavigationController = sideMenu
        SideMenuManager.default.addPanGestureToPresent(toView: self.navigationController?.navigationBar ?? self.view)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: self.view)
        
        let style: SideMenuPresentationStyle = .menuSlideIn
        style.backgroundColor = UIColor.black
        style.presentingEndAlpha = 0.7
        var settings = SideMenuSettings()
        settings.presentationStyle = style
        settings.menuWidth = UIScreen.main.bounds.width * 0.75
        SideMenuManager.default.leftMenuNavigationController?.settings = settings
    }
    
    func setupData() {
        guard let user = WitWork.shared.user else {
            return
        }
        self.lbEmail.text = user.email
    }
    
    @IBAction func didTapLogout() {
        do { try Auth.auth().signOut() }
        catch { print("already logged out") }
        WitWork.shared.logout()
        guard let vc = self.main.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {return}
        self.navigationController?.setViewControllers([vc], animated: true)
        WitVPNVPNAnalytics.logEvent(.logout)
    }
    
    @IBAction func didTapLeftMenu() {
        guard let sideMenu = SideMenuManager.default.leftMenuNavigationController else {return}
        self.present(sideMenu, animated: true, completion: nil)
    }
    
    @IBAction func tapDelete() {
        UIView.animate(withDuration: 0.8) { [weak self] in
            guard let self = self else { return }
            self.deleteView.isHidden = false
        } completion: { finished in
        }
    }
    
    @IBAction func tapConfirmDelete() {
        self.errorBox.isHidden = true
        self.closeDeleteView()
        let user = Auth.auth().currentUser
        self.showHUD()
        user?.delete(completion: { [weak self] error in
            guard let self = self else { return }
            self.hideHUD()
            if let error = error {
                let errorInfor = (error as NSError).userInfo
                if let key = errorInfor["FIRAuthErrorUserInfoNameKey"] as? String {
                    switch key {
                    case "ERROR_USER_NOT_FOUND":
                        self.deleteAccount()
                        return
                    default:
                        break
                    }
                }
                self.track(error.localizedDescription)
                self.errorBox.isHidden = false
                self.errorLabel.text = error.localizedDescription
            } else {
                self.deleteAccount()
            }
        })
    }
    
    func deleteAccount() {
        WitVPNVPNAnalytics.logEvent(.delete)
        WitWork.shared.deleteAccount()
        self.didTapLogout()
    }
    
    @IBAction func tapCancel() {
        self.closeDeleteView()
    }
    
    func closeDeleteView() {
        UIView.animate(withDuration: 0.8) { [weak self] in
            guard let self = self else { return }
            self.deleteView.isHidden = true
        } completion: { finished in
            
        }
    }
}

extension AccountViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        guard let leftVC = menu.viewControllers.first as? LeftMenuViewController else {return}
        leftVC.highlightUser()
    }
}

extension AccountViewController: LeftMenuViewControllerDelegate {
    func leftMenuDidTapAccount() {
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
            
        })
    }
    
    func leftMenuDidTapUpgrade() {
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
            SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
                guard let vc = self.main.instantiateViewController(withIdentifier: "SubscriptionViewController") as? SubscriptionViewController else {return}
                self.navigationController?.setViewControllers([vc], animated: true)
            })
        })
    }
    
    func leftMenuDidTapHome() {
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
            guard let vc = self.main.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {return}
            self.navigationController?.setViewControllers([vc], animated: true)
        })
    }
}
