//
//  ForgotPasswordViewController.swift
//  WitVPN
//
//  Created by thongvm on 25/01/2022.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit
class ForgotPasswordViewController: BaseViewController {
    @IBOutlet weak var emailBox: UIView!
    @IBOutlet weak var errorBox: UIView!

    @IBOutlet weak var lbError: UILabel!
    @IBOutlet weak var txtEmail: UITextField!
    
    @IBOutlet weak var btnResetPassword: UIButton!
    @IBOutlet weak var csBottomButton: NSLayoutConstraint!
    
    @IBOutlet weak var gradientView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        self.txtEmail.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.csBottomButton.constant = keyboardHeight - 10

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                self.btnResetPassword.layoutIfNeeded()
            } completion: { (finished) in
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.csBottomButton.constant = 20

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.btnResetPassword.layoutIfNeeded()
        } completion: { (finished) in
        }
    }

    
    func setupUI() {
        self.emailBox.layer.cornerRadius = 8
        self.emailBox.clipsToBounds = true
        
        self.errorBox.layer.cornerRadius = 8
        self.errorBox.clipsToBounds = true
        
        self.btnResetPassword.layer.cornerRadius = 8
        self.btnResetPassword.clipsToBounds = true
        
        self.errorBox.isHidden = true
        self.txtEmail.placeholder = "Email address"
        self.txtEmail.keyboardType = .emailAddress
        self.txtEmail.attributedPlaceholder = NSAttributedString(string: "Email address",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)])
    }
    
    @IBAction func didTapSendResetPassword() {
        self.view.endEditing(true)
        self.errorBox.isHidden = true
        self.showHUD()
        self.gradientView.alpha = 0
        self.gradientView.isHidden = false
        Auth.auth().sendPasswordReset(withEmail: self.txtEmail.text!) { err in
            self.hideHUD()
            if let error = err {
                self.lbError.text = error.localizedDescription
                self.errorBox.isHidden = false
            }else {
                UIView.animate(withDuration: 0.8) {
                    self.gradientView.alpha = 1
                } completion: { finished in
                }
            }
        }
    }
    
    @IBAction func didTapClosePopup() {
        UIView.animate(withDuration: 0.8) {
            self.gradientView.alpha = 0
        } completion: { finished in
        }
    }
    
    @IBAction func didTapClose() {
        self.navigationController?.popViewController(animated: true)
    }
}
