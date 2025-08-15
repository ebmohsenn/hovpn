//
//  BaseViewController.swift
//  WitVPN
//
//  Created by thongvm on 14/01/2022.
//

import Foundation
import UIKit
import SVProgressHUD
import GoogleMobileAds
import FirebaseAnalytics
class BaseViewController: UIViewController {
    
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
        
        if #available(iOS 13.0, *) {
                // Always adopt a light interface style.
                overrideUserInterfaceStyle = .light
        }
        self.track("Init: \(self.description)")
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: self.description,
                                       AnalyticsParameterScreenClass: self])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        self.track("Deinit: \(self.description)")
    }
    
    func showHUD() {
        SVProgressHUD.show()
    }
    
    func hideHUD() {
        SVProgressHUD.dismiss()
    }
    
    func show(msg: String, title: String? = nil,
              any: [Any] = [],
              destructiveTitle: String? = nil,
              tap: UIAlertControllerCompletionBlock?) {
        UIAlertController.showAlert(in: self, withTitle: title, message: msg, cancelButtonTitle: "Cancel", destructiveButtonTitle: destructiveTitle, otherButtonTitles: any, tap: tap)
    }
    
    func show(msg: String, title: String? = nil, tap: UIAlertControllerCompletionBlock?) {
        self.show(msg: msg, title: title, any: ["Ok"], tap: tap)
    }
    
    func show(msg: String,title: String? = nil) {
        self.show(msg: msg,title: title, tap: nil)
    }

}

extension BaseViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.track("Banner View Did Received")
    }
    
    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        self.track("Banner View Did Click")
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        self.track("Banner View Failed To Received Ad Error: \(error.localizedDescription)")
    }
}
