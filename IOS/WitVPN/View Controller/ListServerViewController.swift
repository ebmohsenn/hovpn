//
//  ListServerViewController.swift
//  WitVPN
//
//  Created by thongvm on 16/01/2022.
//

import Foundation
import FirebaseFirestore
import UIKit
import SVPullToRefresh
import GoogleMobileAds

protocol ListServerViewControllerDelegate {
    func listServerDidSelect(server: ServerModel)
}
class ListServerViewController: BaseViewController {
    @IBOutlet weak var listView: UICollectionView!
    @IBOutlet weak var circle: UIImageView!
    
    /// ADS
    @IBOutlet weak var adsView: UIView!
    @IBOutlet weak var heightOfAdsViewConstraint: NSLayoutConstraint!
    private var bannerView: GADBannerView!
    private var interstitial: GADInterstitialAd?
    
    lazy var db = Firestore.firestore()
    var data: [ServerModel] = []
    var selectedIndex: Int = -1
    var delegate: ListServerViewControllerDelegate?
    var selectedServer: ServerModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideAdsBanner()
        if let banner = WitWork.shared.adsBanner {
            self.loadAdsBanner(banner: banner)
        }
    }
    
    func setupUI() {
        self.listView.register(ServerCell.self, forCellWithReuseIdentifier: "ServerCell")
        self.listView.register(UINib(nibName: "ServerCell", bundle: nil), forCellWithReuseIdentifier: "ServerCell")
        self.listView.dataSource = self
        self.listView.delegate = self
    }
    
    func setupData() {
        if let data = UserDefaults.standard.dictionary(forKey: "selectedServer")  {
            let server = ServerModel()
            server.initWith(data: data)
            self.selectedServer = server
        }
        
        if WitWork.shared.serversData.count > 0 {
            self.data = WitWork.shared.serversData
            self.listView.reloadData()
        }else {
            self.showHUD()
        }
        
        db.collection("Servers").getDocuments() { [weak self](querySnapshot, err) in
            guard let wSelf = self else {return}
            wSelf.hideHUD()
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                wSelf.data.removeAll()
                for document in querySnapshot!.documents {
                    let server = ServerModel()
                    server.initWith(data: document.data())
                    wSelf.data.append(server)
                    print("\(document.documentID))")
                }
                
                wSelf.data.sort { $0.premium == false && !$1.premium == false}
                
                var i: Int = 0
                wSelf.data.forEach { server in
                    if let selectedServer = wSelf.selectedServer {
                        if selectedServer.ipAddress == server.ipAddress {
                            wSelf.selectedIndex = i
                        }
                        i+=1
                    }
                }
                WitWork.shared.serversData = wSelf.data

                wSelf.listView.reloadData()
            }
        }
    }
    
    @IBAction func didTapClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSelectedPremium() {
        self.circle.isHighlighted = !self.circle.isHighlighted
        if self.circle.isHighlighted == true {
            self.data = WitWork.shared.serversData.filter {$0.premium == self.circle.isHighlighted}
        }else {
            self.data = WitWork.shared.serversData
        }
        var i: Int = 0
        self.selectedIndex = -1
        self.data.forEach { server in
            if let selectedServer = self.selectedServer {
                if selectedServer.ipAddress == server.ipAddress {
                    self.selectedIndex = i
                }
                i+=1
            }
        }
        self.listView.reloadData()
    }
}

extension ListServerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        self.listView.reloadData()
        
        self.dismiss(animated: true, completion: {
            let server = self.data[indexPath.row]
            self.delegate?.listServerDidSelect(server: server)
        })

    }
}

extension ListServerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServerCell", for: indexPath) as! ServerCell
        let server = self.data[indexPath.row]
        cell.lbCountry.text = server.country
        cell.flag.fileName = server.countryCode.lowercased()
        cell.bg.backgroundColor = self.selectedIndex == indexPath.row ? .init(named: "cl_selected_item") : .init(named: "cl_default_item")
        cell.leftIcon.image = server.premium ? .init(named: "ic_premium") : nil
        cell.leftIcon.isHighlighted = self.selectedIndex == indexPath.row
        cell.lbState.text = server.state.uppercased()
        
        return cell
    }
}

extension ListServerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: self.view.frame.width - 32, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
}

extension ListServerViewController { // Google Admob
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
}
