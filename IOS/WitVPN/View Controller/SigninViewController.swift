//
//  SigninViewController.swift
//  WitVPN
//
//  Created by thongvm on 18/01/2022.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import Localize_Swift
import TTTAttributedLabel
class SigninViewController: BaseViewController {
    @IBOutlet weak var emailBox: UIView!
    @IBOutlet weak var passwdBox: UIView!
    @IBOutlet weak var signupBox: UIView!
    @IBOutlet weak var errorBox: UIView!

    @IBOutlet weak var lbError: UILabel!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnSignin: UIButton!
    
    @IBOutlet weak var csBottomLogin: NSLayoutConstraint!
    let main = UIStoryboard(name: "Main", bundle: nil)
    lazy var db = Firestore.firestore()

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
        self.view.endEditing(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI() {
        self.emailBox.layer.cornerRadius = 8
        self.emailBox.clipsToBounds = true
        self.passwdBox.layer.cornerRadius = 8
        self.passwdBox.clipsToBounds = true
        self.signupBox.layer.cornerRadius = 8
        self.signupBox.clipsToBounds = true
        self.btnSignin.layer.cornerRadius = 8
        self.btnSignin.clipsToBounds = true
        self.errorBox.layer.cornerRadius = 8
        self.errorBox.clipsToBounds = true
        
        self.txtEmail.delegate = self
        self.txtPassword.delegate = self
        
        self.txtEmail.keyboardType = .emailAddress
        self.txtEmail.autocorrectionType = .no
        self.txtPassword.isSecureTextEntry = true
        
        self.txtPassword.placeholder = "Password"
        self.txtEmail.placeholder = "Email address"
        self.errorBox.isHidden = true
        self.txtPassword.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)])
        self.txtEmail.attributedPlaceholder = NSAttributedString(string: "Email address",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)])
    }

    
    func setBoxHightLight(view: UIView) {
        view.layer.borderColor = (UIColor(named: "cl_selected_box") ?? UIColor.clear).cgColor
        view.layer.borderWidth = 1
    }
    
    func setBoxError(view: UIView) {
        view.layer.borderColor = (UIColor(named: "cl_error") ?? UIColor.clear).cgColor
        view.layer.borderWidth = 1
    }
    
    func setBoxNormal(view: UIView) {
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.borderWidth = 1
    }
    
    @IBAction func didTapClose() {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSignup() {
        self.view.endEditing(true)
        guard let vc = self.main.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController else {return}
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapSignin() {
        self.login()
    }
    
    @IBAction func didTapResetPassword() {
        guard let termsVC = self.storyboard?.instantiateViewController(withIdentifier: "ForgotPasswordViewController") else {return}
        self.navigationController?.show(termsVC, sender: nil)
        
    }
    
    func login() {
        guard let email = self.txtEmail.text else {return}
        let bool = email.validateEmailString()
        self.errorBox.isHidden = true
        if bool == false {
            self.errorBox.isHidden = false
            self.lbError.text = "error_email_format".localized()
            self.setBoxError(view: self.emailBox)
            return
        }
        
        guard let password = self.txtPassword.text, password.count > 0 else {
            self.setBoxError(view: self.passwdBox)
            return
        }
        self.showHUD()
        Auth.auth().signIn(withEmail: email, password: password) { authData, authErro in
            if let authErro = authErro {
                self.lbError.text = authErro.localizedDescription
                self.errorBox.isHidden = false
                self.hideHUD()
            }else {
                self.track("===== login =====")
                let email = authData?.user.email ?? ""
                self.track("auth email: \(email)")
                self.track("auth user id: \(authData?.user.uid ?? "")")
                let ref = self.db.collection("users").document(email)
                ref.getDocument { [weak self] snapshot, error in
                    guard let self = self else { return }
                    self.track(snapshot?.data() ?? "")
                    WitWork.shared.udpateTraffic(snapshot: snapshot)
                    
                    if let error = error {
                        self.lbError.text = error.localizedDescription
                        self.errorBox.isHidden = false
                        self.hideHUD()
                    }else {
                        WitVPNVPNAnalytics.setUserId(ref.documentID)
                        WitVPNVPNAnalytics.logEvent(.login, params: [
                            "email": email as NSObject
                        ])
                        let deviceInfo = WitWork.shared.getDeviceInfo()
                        ref.updateData(["lastLogin": Date(),
                                        "deviceInfo": deviceInfo,
                                        "password": password.encryptDecrypt()]) { err in
                            
                            self.hideHUD()
                            if let err = err {
                                self.lbError.text = err.localizedDescription
                                self.errorBox.isHidden = false
                                self.track("update error snap Id: \(err.localizedDescription)")
                            }else {
                                // reauthen
                                WitWork.shared.user = Auth.auth().currentUser
                                self.dismiss(animated: true, completion: {
                                    NotificationCenter.default.post(name: NSNotification.Name("reauthen"), object: nil)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.csBottomLogin.constant = keyboardHeight - 10

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                self.btnSignin.layoutIfNeeded()
            } completion: { (finished) in
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.csBottomLogin.constant = 20

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.btnSignin.layoutIfNeeded()
        } completion: { (finished) in
        }
    }
}

extension SigninViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let parent = textField.superview else {return}
        self.setBoxNormal(view: parent)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let parent = textField.superview else {return}
        self.setBoxHightLight(view: parent)
    }
}
