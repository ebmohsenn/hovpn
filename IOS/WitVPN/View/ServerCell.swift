//
//  ServerCell.swift
//  WitVPN
//
//  Created by thongvm on 16/01/2022.
//

import Foundation
import Macaw
class ServerCell: UICollectionViewCell {
    @IBOutlet weak var flag: SVGView!
    @IBOutlet weak var lbCountry: UILabel!
    @IBOutlet weak var lbState: UILabel!
    @IBOutlet weak var bg: UIView!
    @IBOutlet weak var leftIcon: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
    }
}
