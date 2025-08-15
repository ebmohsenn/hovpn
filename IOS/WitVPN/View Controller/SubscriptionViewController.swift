//
//  SubscriptionViewController.swift
//  WitVPN
//
//  Created by thongvm on 20/01/2022.
//

import Foundation
import SideMenu
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
class SubscriptionViewController: BaseViewController {
    @IBOutlet weak var listView: UICollectionView!
    @IBOutlet weak var lbPopup: UILabel!
    @IBOutlet weak var popup: UIView!
    
    let main = UIStoryboard(name: "Main", bundle: nil)
    lazy var db = Firestore.firestore()
    var cell:SubscriptionCell? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupData()
        self.leftMenu()
    }
    
    func setupUI() {
        self.listView.register(SubscriptionCell.self, forCellWithReuseIdentifier: "SubscriptionCell")
        self.listView.register(UINib(nibName: "SubscriptionCell", bundle: nil), forCellWithReuseIdentifier: "SubscriptionCell")
        self.listView.delegate = self
        self.listView.dataSource = self
        self.popup.isHidden = true
    }
    
    func setupData() {
        self.showHUD()
        db.collection("configs").getDocuments { query, error in
            
            if let error = error {
                print("error: \(error.localizedDescription)")
                self.hideHUD()
            }else {
                guard let document = query?.documents.first else {return}
                let data = document.data()
                print("data: \(data)")
                guard let iap = data["iap-ios"] as? [String: Any],
                let monthly = iap["monthly"] as? String,
                let yearly = iap["yearly"] as? String else {return}
                print("monthly: \(monthly), yearly: \(yearly)")
                StoreKit.shared.retriveProduct(products: [monthly, yearly]).done { skProducts in
                    self.hideHUD()
                    self.cell?.updatePrice(skProducts: skProducts)
                }.catch { error in
                    
                }.finally {
                    
                }
            }
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
    
    func updatePremium(_ productId: String) {
        let uuid = WitWork.shared.uuid ?? NSUUID().uuidString.lowercased()
        let ref = self.db.collection("anonymous").document(uuid)
        let data:[String: Any] = [
            "deviceInfo": WitWork.shared.getDeviceInfo(),
            "premium": [
                "autoRenewing": true,
                "packageName": Bundle.main.bundleIdentifier ?? "",
                "productId": productId,
                "purchaseTime": NSDate()
            ]
        ]
        ref.setData(data) { updateError in
            if let error = updateError {
                debugPrint(error)
            }else {
                debugPrint(data)
            }
        }
    }
}

extension SubscriptionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.listView.deselectItem(at: indexPath, animated: false)
    }
}

extension SubscriptionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubscriptionCell", for: indexPath) as! SubscriptionCell
        self.cell = cell
        cell.delegate = self
        cell.reloadUI()
        return cell
    }
}

extension SubscriptionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let active = StoreKit.shared.isActivePaidSubscription()
        return .init(width: self.view.frame.size.width, height: active ? self.view.frame.self.height : 945)
    }
}

extension SubscriptionViewController: SubscriptionCellProtocol {
    func subscriptionCellPurchaseStart() {
        self.showHUD()
    }
    
    func subscriptionCellPurchaseSuccessMonthly(_ productId: String) {
        self.updatePremium(productId)
        self.lbPopup.text = "You subscribed monthly VIP package successfully"
        self.popup.isHidden = false
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            UIView.animate(withDuration: 0.5, delay: 0, options: .allowAnimatedContent) {
                self.popup.isHidden = true
            } completion: { finished in
            }
        }
    }
    
    func subscriptionCellPurchaseSuccessYearly(_ productId: String) {
        self.lbPopup.text = "You subscribed yearly VIP package successfully"
        self.popup.isHidden = false
        self.updatePremium(productId)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            UIView.animate(withDuration: 0.5, delay: 0, options: .allowAnimatedContent) {
                self.popup.isHidden = true
            } completion: { finished in
            }
        }
    }
    
    func subscriptionCellPurchaseEnd() {
        self.hideHUD()
        self.listView.reloadData()
    }
    
    func subscriptionCellPurchaseFailed(err: Error) {
        self.show(msg: err.localizedDescription, title: "Error")
    }
    
    func subscriptionCellDidTapLeftMenu() {
        guard let sideMenu = SideMenuManager.default.leftMenuNavigationController else {return}
        self.present(sideMenu, animated: true, completion: nil)
    }
    
    func subscriptionCellDidTapTerms() {
        guard let termsVC = self.storyboard?.instantiateViewController(withIdentifier: "TermsViewController") else {return}
        self.navigationController?.show(termsVC, sender: nil)
    }
    
    func subscriptionCellDidTapPolicy() {
        guard let privacyVC = self.storyboard?.instantiateViewController(withIdentifier: "PrivacyViewController") else {return}
        self.navigationController?.show(privacyVC, sender: nil)
    }
}

extension SubscriptionViewController: LeftMenuViewControllerDelegate {
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

extension SubscriptionViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        guard let leftVC = menu.viewControllers.first as? LeftMenuViewController else {return}
        leftVC.highlightVIP()
    }
}
