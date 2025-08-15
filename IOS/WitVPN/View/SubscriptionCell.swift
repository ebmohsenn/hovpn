//
//  SubscriptionCell.swift
//  WitVPN
//
//  Created by thongvm on 22/01/2022.
//

import Foundation
import UIKit
import StoreKit
protocol SubscriptionCellProtocol {
    func subscriptionCellDidTapLeftMenu()
    func subscriptionCellPurchaseStart()
    func subscriptionCellPurchaseSuccessMonthly(_ productId: String)
    func subscriptionCellPurchaseSuccessYearly(_ productId: String)
    func subscriptionCellPurchaseFailed(err: Error)
    func subscriptionCellPurchaseEnd()
    func subscriptionCellDidTapTerms()
    func subscriptionCellDidTapPolicy()
}
class SubscriptionCell: UICollectionViewCell {
    var delegate: SubscriptionCellProtocol?
    @IBOutlet weak var lbPriceOfMonthly: UILabel!
    @IBOutlet weak var lbPriceOfYearly: UILabel!
    @IBOutlet weak var lbPriceDiscount: UILabel!
    @IBOutlet weak var yearlyBox: UIView!
    @IBOutlet weak var monthlyBox: UIView!
    @IBOutlet weak var monthlyTick: UIImageView!
    @IBOutlet weak var yearlyTick: UIImageView!
    
    @IBOutlet weak var premimumBox: UIView!
    @IBOutlet weak var expiredBox: UIView!
    @IBOutlet weak var lbExpired: UILabel!
    
    @IBOutlet weak var premiumLb: UILabel!
    @IBOutlet weak var btnPolicy: UIButton!
    @IBOutlet weak var btnTerms: UIButton!
    
    var skYearly: SKProduct? = nil
    var skMonthly: SKProduct? = nil
    var skProduct: SKProduct? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func reloadUI() {
        let active = StoreKit.shared.isActivePaidSubscription()
        self.premimumBox.isHidden = active
        self.premiumLb.isHidden = active
        self.btnPolicy.isHidden = active
        self.btnTerms.isHidden = active
        
        self.expiredBox.isHidden = !active
        if active {
            guard let paidSubscription = WitWork.shared.getSubscription() else {return}
            let date = paidSubscription.expiresDate
            print("expired at: \(date)")
            let dateStr = date.toFormat("YYYY/MM/dd", locale: nil)
            self.lbExpired.text = "You current monthly VIP package is valid until \(dateStr). If you want to cancel or change, please go to your subscription account"
        }
    }
    
    @IBAction func didTapLeftMenu() {
        self.delegate?.subscriptionCellDidTapLeftMenu()
    }
    
    func updatePrice(skProducts: [SKProduct]) {
        let sortSKproducts = skProducts.sorted {
            $0.price.compare($1.price) == .orderedAscending
        }
        if sortSKproducts.count < 2 {return}
        // yearly
        skMonthly = sortSKproducts[0]
        self.lbPriceOfMonthly.text = skMonthly?.priceStringForProduct()
        
        // monthly
        skYearly = sortSKproducts[1]
        self.lbPriceOfYearly.text = skYearly?.priceStringForProduct()
        
        // show discount
        guard let skPriceYearly = skYearly?.price, let skPriceMonthly = skMonthly?.price else {
            return
        }
        let discount =  (skPriceMonthly.floatValue * 12) - skPriceYearly.floatValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        self.lbPriceDiscount.text = "SAVE: \(formatter.string(from: NSNumber(value: discount)) ?? "")"
        skProduct = skMonthly
    }
    
    @IBAction func didTapMonthly() {
        self.yearlyBox.backgroundColor = UIColor(named: "cl_bg_text_box")
        self.monthlyBox.backgroundColor = UIColor(named: "cl_selected_item")
        self.monthlyTick.isHidden = false
        self.yearlyTick.isHidden = true
        skProduct = skMonthly
    }
    
    @IBAction func didTapYearly() {
        self.yearlyBox.backgroundColor = UIColor(named: "cl_selected_item")
        self.monthlyBox.backgroundColor = UIColor(named: "cl_bg_text_box")
        self.monthlyTick.isHidden = true
        self.yearlyTick.isHidden = false
        skProduct = skYearly
    }
    
    @IBAction func didTapPurchase() {
        guard let skProduct = skProduct else {
            return
        }
        self.delegate?.subscriptionCellPurchaseStart()
        StoreKit
            .shared
            .purchase(skProduct: skProduct)
            .done { (purchaseDetail) in
                if self.skMonthly == self.skProduct {
                    self.delegate?.subscriptionCellPurchaseSuccessMonthly(skProduct.productIdentifier)
                }else {
                    self.delegate?.subscriptionCellPurchaseSuccessYearly(skProduct.productIdentifier)
                }
        }.catch { (error) in
            self.delegate?.subscriptionCellPurchaseFailed(err: error)
        }.finally {
            self.delegate?.subscriptionCellPurchaseEnd()
        }
    }
    
    @IBAction func didTapRestore() {
        self.delegate?.subscriptionCellPurchaseStart()
        StoreKit.shared.restore().done { sessionId in
            if StoreKit.shared.isActivePaidSubscription() == false {
                self.delegate?.subscriptionCellPurchaseFailed(err: WP_Error(msg: "You have no subscriptions to restore"))
            }else {
                let restoreProductId = sessionId.currentSubscription?.productId ?? ""
                let monthlyProductId = self.skMonthly?.productIdentifier ?? ""
                if restoreProductId == monthlyProductId {
                    self.delegate?.subscriptionCellPurchaseSuccessMonthly(monthlyProductId)
                }else {
                    self.delegate?.subscriptionCellPurchaseSuccessYearly(self.skYearly?.productIdentifier ?? "")
                }
            }
           
        }.catch { err in
            self.delegate?.subscriptionCellPurchaseFailed(err: err)
        }.finally {
            self.delegate?.subscriptionCellPurchaseEnd()
        }
    }
    
    @IBAction func didTapTerms() {
        self.delegate?.subscriptionCellDidTapTerms()
    }
    
    @IBAction func didTapPolicy() {
        self.delegate?.subscriptionCellDidTapPolicy()
    }
    
}
