//
//  SplashScreenViewController.swift
//  WitVPN
//
//  Created by thongvm on 14/01/2022.
//

import Foundation
import Lottie
import PureLayout
class SplashScreenViewController: BaseViewController {
    let animationViewLayer = LottieAnimationView()
    @IBOutlet weak var animationView: UIView!
 
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let animation = LottieAnimation.named("ic_logo_splash", subdirectory: "lottie")
            self.animationViewLayer.animation = animation
            self.animationViewLayer.contentMode = .scaleAspectFit
            self.animationView.addSubview(self.animationViewLayer)
            self.animationViewLayer.autoPinEdgesToSuperviewEdges()
            
            self.animationViewLayer.play(fromProgress: 0,
                               toProgress: 1,
                               loopMode: LottieLoopMode.playOnce,
                               completion: { (finished) in
                                if finished {
                                    debugPrint("Animation Complete")
                                } else {
                                    debugPrint("Animation cancelled")
                                }
                self.openHome()
            })
        }
    }
    
    func openHome() {
        let loginView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController")
        self.navigationController?.pushViewController(loginView, animated: true)
    }
    
}
