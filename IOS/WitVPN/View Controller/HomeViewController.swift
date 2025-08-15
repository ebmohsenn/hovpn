//
//  HomeViewController.swift
//  WitVPN
//
//  Created by thongvm on 14/01/2022.
//

import Foundation
import Lottie
import NetworkExtension
import SideMenu
import Macaw
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import GoogleMobileAds

class HomeViewController: BaseViewController {
    
    /// ANOTHER VIEW
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var selectedLocationView: UIView!
    @IBOutlet weak var boxUploadView: UIView!
    @IBOutlet weak var boxDownloadView: UIView!
    @IBOutlet weak var lbCountry: UILabel!
    @IBOutlet weak var flag: SVGView!
    @IBOutlet weak var lbUpload: UILabel!
    @IBOutlet weak var lbDownload: UILabel!

    /// ADS
    @IBOutlet weak var adsView: UIView!
    @IBOutlet weak var heightOfAdsViewConstraint: NSLayoutConstraint!
    private var bannerView: GADBannerView!
    private var interstitial: GADInterstitialAd?

    /// VPN CONNECT NOW VIEW
    @IBOutlet weak var lbConnectVPNNow: UILabel!
    @IBOutlet weak var connectVPNView: UIView!
    @IBOutlet weak var csWidthOfProcess: NSLayoutConstraint!
    @IBOutlet weak var topConstraints: NSLayoutConstraint!

    lazy var db = Firestore.firestore()
    fileprivate var timer: Timer?
    private var p_download: UInt64 = 0
    private var p_upload: UInt64 = 0
    private var downloadInfo: [String: [String: UInt64]] = [:]
    
    let animationViewLayer = LottieAnimationView()
    let main = UIStoryboard(name: "Main", bundle: nil)
    
    var currentServer: ServerModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        fetchToken()
        fetchAds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideAdsBanner()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set delete for side menu
        self.leftMenu()
        self.vpnDidChange(status: VPNManager.shared().status)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    ///MARK: - FIREBASE FIRESTORE
    func fetchAds() {
        db.collection("configs").getDocuments { [weak self] query, error in
            guard let self = self else { return }
            if let error = error {
                print("error: \(error.localizedDescription)")
                self.hideHUD()
            }else {
                guard let document = query?.documents.first else {return}
                let data = document.data()
                self.track("data: \(data)")
                
                guard let iap = data["ads-ios"] as? [String: Any] else { return }
                if let banner = iap["banner"] as? String {
                    WitWork.shared.adsBanner = banner
                    self.loadAdsBanner(banner: banner)
                }
                
                if let show = iap["show"] as? String {
                    WitWork.shared.adsShow = show
                    self.loadInterstitial()
                }
            }
        }
    }

    func fetchToken() {
        if let user = WitWork.shared.user, let email = user.email {

            let ref = self.db.collection("users").document(email)
            ref.getDocument { [weak self] snapshot, error in
                guard let _ = snapshot?.documentID,
                      let data = snapshot?.data(),
                      let self = self else { return }
                if let password = data["password"] as? String {
                    let credential = EmailAuthProvider.credential(withEmail: email, password: password.encryptDecrypt() as String)
                    Auth.auth().currentUser?.reauthenticate(with: credential, completion: { auth, error in
                        if let error = error {
                            self.track(error.localizedDescription)
                            self.refreshAuthen()
                        }else {
                            WitVPNVPNAnalytics.logEvent(.reAuthen, params: [
                                "email": email as NSObject
                            ])
                            WitVPNVPNAnalytics.setUserId(auth?.user.uid)
                            self.track(snapshot?.data() ?? "")
                            WitWork.shared.udpateTraffic(snapshot: snapshot)
                            WitWork.shared.user = Auth.auth().currentUser

                            let deviceInfo = WitWork.shared.getDeviceInfo()
                            ref.updateData(["lastLogin": Date(),
                                            "deviceInfo": deviceInfo]) { err in
                                self.hideHUD()
                            }
                            self.track(auth ?? "")
                        }
                    })
                }else { // refresh
                    self.refreshAuthen()
                }
            }
        }else {
            self.loginAnnonymous()
        }
    }
    
    func refreshAuthen() {
        VPNManager.shared().stopConnection {}
        WitWork.shared.logout()
        self.p_upload = 0
        self.p_download = 0
        self.loginAnnonymous()
    }
    
    func loginAnnonymous() {
        let uuid = WitWork.shared.getUUID()
        let ref = self.db.collection("anonymous").document(uuid)
        var data:[String: Any] = [:]
        ref.getDocument { [weak self] snapshot, error in
            guard let self = self, let documentId = snapshot?.documentID else { return }
            WitVPNVPNAnalytics.setUserId(documentId)
            WitVPNVPNAnalytics.logEvent(.loginAnonymous, params: [
                "uuid": uuid as NSObject
            ])
            if let _ = snapshot?.data() {
                self.track(snapshot?.data() ?? "")
                data = ["deviceInfo": WitWork.shared.getDeviceInfo(),
                        "lastLogin": Date()]
                ref.updateData(data) { updateError in
                    if let error = updateError {
                        self.track(error)
                    }
                }
            }else {
                data = ["createAt": Date(),
                        "deviceInfo": WitWork.shared.getDeviceInfo(),
                        "lastLogin": Date()]
                ref.setData(data) { updateError in
                    if let error = updateError {
                        self.track(error)
                    }
                }
            }
            WitWork.shared.udpateTraffic(snapshot: snapshot)
        }
    }
    
    /// MARK: - SETUP UI
    func setupUI() {
        self.selectedLocationView.layer.cornerRadius = 8
        self.selectedLocationView.clipsToBounds = true
        self.connectVPNView.layer.cornerRadius = 8
        self.connectVPNView.clipsToBounds = true
        self.boxUploadView.layer.cornerRadius = 8
        self.boxUploadView.clipsToBounds = true
        self.boxDownloadView.layer.cornerRadius = 8
        self.boxDownloadView.clipsToBounds = true
        self.flag.contentMode = .scaleToFill
        if UIDevice.current.checkIfHasDynamicIsland() {
            self.topConstraints.constant = -8
        }
    }
    
    func setupData() {
        if let data = UserDefaults.standard.dictionary(forKey: "selectedServer")  {
            let server = ServerModel()
            server.initWith(data: data)
            self.lbCountry.text = server.country
            self.flag.fileName = server.countryCode.lowercased()
            self.currentServer = server
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("reauthen"),
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.p_upload = 0
            self.p_download = 0
            
        }
        NotificationCenter
            .default
            .addObserver(self, selector: #selector(self.VPNStatusDidChange(noti:)),
                         name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    @objc func VPNStatusDidChange(noti: Notification) {
        guard let session = noti.object as? NETunnelProviderSession else {return}
        self.vpnDidChange(status: session.status)
    }
    
    func vpnDidChange(status: NEVPNStatus) {
        switch status {
        case .connected:
            self.track("NEVPNStatusConnected")
            /// PLAY LOTTIE
            self.play(animation: "ic_logo_connected")
            self.lbConnectVPNNow.text = "DISCONNECT"
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                self.getDataUsage()
            }
            self.timer?.fire()
            break
        case .connecting:
            self.track("NEVPNStatusConnecting")
            /// ANIMATION BUTTON
            self.connectVPNView.layoutIfNeeded()
            self.csWidthOfProcess.constant = self.connectVPNView.frame.self.width
            UIView.animate(withDuration: 5) {
                self.connectVPNView.layoutIfNeeded()
            } completion: { finished in
                
            }
            self.lbConnectVPNNow.text = "CONNECTING"
            break
        case .disconnected:
            self.track("NEVPNStatusDisconnected")
            self.play(animation: "ic_logo_connect")
            self.lbConnectVPNNow.text = "CONNECT VPN NOW"
            self.csWidthOfProcess.constant = 0;
            self.lbUpload.text = "0 MB"
            self.lbDownload.text = "0 MB"
            self.timer?.invalidate()
            self.timer = nil
            break
        default:
            self.track("NEVPNStatusDefault")
            self.lbConnectVPNNow.text = "CONNECT VPN NOW"
            self.play(animation: "ic_logo_connect")
            break
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
    
    func play(animation: String) {
        let animation = LottieAnimation.named(animation, subdirectory: "lottie")
        self.animationViewLayer.animation = animation
        self.animationViewLayer.layer.masksToBounds = true
        self.animationViewLayer.contentMode = .scaleAspectFill
        self.animationView.addSubview(self.animationViewLayer)
        self.animationViewLayer.autoPinEdgesToSuperviewEdges()
        self.animationView.backgroundColor = .clear
        self.animationViewLayer.play()
        self.animationViewLayer.loopMode = .loop
        self.animationViewLayer.backgroundBehavior = .pauseAndRestore
    }
    
    func getDataUsage() {
        let p_upload = UserDefaults.standard.value(forKey: "p_upload") as? UInt64 ?? 0
        let p_download = UserDefaults.standard.value    (forKey: "p_download") as? UInt64 ?? 0
        let upload =  SystemDataUsage.upload - p_upload
        let download =  SystemDataUsage.download - p_download
        self.p_upload = upload
        self.p_download = download
        self.lbUpload.text = Units(bytes: upload).getReadableUnit()
        self.lbDownload.text = Units(bytes: download).getReadableUnit()
    }
    
    
    @IBAction func didTapLeftMenu() {
        guard let sideMenu = SideMenuManager.default.leftMenuNavigationController else {return}
        self.present(sideMenu, animated: true, completion: nil)
    }
    
    @IBAction func didTapListServer() {
        guard let vc = main.instantiateViewController(withIdentifier: "ListServerViewController") as? ListServerViewController else {return}
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func didTapConnect() {
        if VPNManager.shared().status == .connected {
            let uuid = WitWork.shared.getUUID()
            var ref = self.db.collection("anonymous").document(uuid)
            let p_upload = WitWork.shared.upload + self.p_upload
            let p_download = WitWork.shared.download + self.p_download
            self.track("Upload/ Download in this section: \(self.p_upload)/\(self.p_download)")
            self.track("Total Upload/ Download: \(p_upload)/\(p_download)")
           
            if let user = WitWork.shared.user, let email = user.email {
                ref = self.db.collection("users").document(email)
            }
            let data: [String : Any] = ["traffic": ["download": p_download,
                                                    "upload": p_upload],
                                        "lastLogin": Date()]
            WitWork.shared.upload = p_upload
            WitWork.shared.download = p_download
            WitVPNVPNAnalytics.logEvent(.disConnect)
            ref.updateData(data) { [weak self] err in
                guard let self = self else { return }
                self.track(data)
                VPNManager.shared().stopConnection {}
            }
            self.vpnDidChange(status: .disconnected)
            return
        }
        
        UserDefaults.standard.setValue(SystemDataUsage.upload, forKey: "p_upload")
        UserDefaults.standard.setValue(SystemDataUsage.download, forKey: "p_download")
        guard let currentServer = self.currentServer,
              let ovpn = self.currentServer?.ovpn,
              let decodedData = Data(base64Encoded: ovpn)
        else {return}
        WitVPNVPNAnalytics.logEvent(.connect, params: [
            "ip_address": currentServer.ipAddress
        ])
        VPNManager.shared().openVPNconfigure(currentServer.ipAddress, data: decodedData)
    }
}

extension HomeViewController: ListServerViewControllerDelegate {
    func listServerDidSelect(server: ServerModel) {
        let active = StoreKit.shared.isActivePaidSubscription()
        let premium = server.premium
        if premium == true && active == false {
            guard let vc = self.main.instantiateViewController(withIdentifier: "SubscriptionViewController") as? SubscriptionViewController else {return}
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
        self.lbCountry.text = server.country
        self.flag.fileName = server.countryCode.lowercased()
        let data = server.dictionary()
        UserDefaults.standard.set(data, forKey: "selectedServer")
        UserDefaults.standard.synchronize()
        
        self.currentServer = server
        
        if premium == false {
            interstitial?.present(fromRootViewController: self)
        }
    }
}

extension HomeViewController: LeftMenuViewControllerDelegate {
    func leftMenuDidTapAccount() {
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
            if let _ = WitWork.shared.user {
                guard let vc = self.main.instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else {return}
                self.navigationController?.pushViewController(vc, animated: true)
            }else {
                guard let vc = self.main.instantiateViewController(withIdentifier: "AuthNavigation") as? UINavigationController else {return}
                vc.modalPresentationStyle = .formSheet
                self.present(vc, animated: true, completion: nil)
            }
            
        })
    }
    
    func leftMenuDidTapUpgrade() {
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
            guard let vc = self.main.instantiateViewController(withIdentifier: "SubscriptionViewController") as? SubscriptionViewController else {return}
            self.navigationController?.pushViewController(vc, animated: true)
        })
    }
    
    func leftMenuDidTapHome() {
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: {
            
        })
    }
}

extension HomeViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        guard let leftVC = menu.viewControllers.first as? LeftMenuViewController else {return}
        leftVC.highlightHome()
    }
}

extension HomeViewController { // Google Admob
    func loadAdsBanner(banner: String) {
        if self.bannerView != nil || StoreKit.shared.isActivePaidSubscription() == true {
            return
        }
        let adUnitID = banner
        let adSize = GADAdSizeFromCGSize(CGSize(width: 300, height: 50))
        heightOfAdsViewConstraint.constant = adSize.size.height
        bannerView = GADBannerView(adSize: adSize)
        bannerView.delegate = self
        self.adsView.addSubview(self.bannerView)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self
        bannerView.autoAlignAxis(toSuperviewAxis: .horizontal)
        bannerView.autoAlignAxis(toSuperviewAxis: .vertical)
        bannerView.autoSetDimensions(to: adSize.size)
        bannerView.load(GADRequest())
    }
    
    func hideAdsBanner() {
        let premium = StoreKit.shared.isActivePaidSubscription()
        heightOfAdsViewConstraint.constant = premium ? 0 : 50
    }
    
    func loadInterstitial() {
        guard let show = WitWork.shared.adsShow, show.count > 0 else { return }
        if StoreKit.shared.isActivePaidSubscription() { return }
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: show,
                               request: request,
                               completionHandler: { [self] ad, error in
            if let error = error {
                self.track("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            interstitial = ad
            interstitial?.fullScreenContentDelegate = self
        })
    }
}

extension HomeViewController: GADFullScreenContentDelegate {
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.track("Ad did fail to present full screen content.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadInterstitial()
        }
    }
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.track("Ad will present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadInterstitial()
        }
        self.track("interstitialDidDismissScreen")
    }
}


