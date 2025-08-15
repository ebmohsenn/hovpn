//
//  SignupViewController.swift
//  WitVPN
//
//  Created by thongvm on 18/01/2022.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import TTTAttributedLabel
class SignupViewController: BaseViewController {
    @IBOutlet weak var emailBox: UIView!
    @IBOutlet weak var passwdBox: UIView!
    @IBOutlet weak var confirmPasswdBox: UIView!
    @IBOutlet weak var signinBox: UIView!
    @IBOutlet weak var errorBox: UIView!
    
    @IBOutlet weak var lbError: UILabel!
    @IBOutlet weak var lbPrivacy: TTTAttributedLabel!

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    @IBOutlet weak var btnSignin: UIButton!
    @IBOutlet weak var csBottomLogin: NSLayoutConstraint!
    
    lazy var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)        
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
    
    func setupUI() {
        let corner: CGFloat = 8
        self.emailBox.layer.cornerRadius = corner
        self.emailBox.clipsToBounds = true
        self.passwdBox.layer.cornerRadius = corner
        self.passwdBox.clipsToBounds = true
        self.btnSignin.layer.cornerRadius = corner
        self.btnSignin.clipsToBounds = true
        self.errorBox.layer.cornerRadius = corner
        self.errorBox.clipsToBounds = true
        self.confirmPasswdBox.layer.cornerRadius = corner
        self.confirmPasswdBox.clipsToBounds = true
        self.signinBox.layer.cornerRadius = corner
        self.signinBox.clipsToBounds = true
        
        self.txtEmail.delegate = self
        self.txtPassword.delegate = self
        self.txtConfirmPassword.delegate = self
        
        self.txtEmail.keyboardType = .emailAddress
        self.txtEmail.autocorrectionType = .no
        self.txtPassword.isSecureTextEntry = true
        self.txtConfirmPassword.isSecureTextEntry = true
        
        self.txtPassword.placeholder = "Password"
        self.txtConfirmPassword.placeholder = "Confirm password"
        self.txtEmail.placeholder = "Email"
        self.txtPassword.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)])
        self.txtConfirmPassword.attributedPlaceholder = NSAttributedString(string: "Confirm password",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)])
        self.txtEmail.attributedPlaceholder = NSAttributedString(string: "Email address",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)])
        
        self.errorBox.isHidden = true
        let fulltext = "By signing up, I agree to the Private Policy and Terms of Use"
        //"To continue, please select the options below. By signing up, I agree to the private policy and terms of conditions"
        
        let rangePrivacy = (fulltext as NSString).range(of: "Private Policy")
        let rangeTerms = (fulltext as NSString).range(of: "Terms of Use")

        let urlTC = URL(string: "action://TC")!
        let urlPP = URL(string: "action://PP")!
        let ppLinkAttributes: [String: Any] = [
                NSAttributedString.Key.foregroundColor.rawValue: UIColor(named: "cl_accent")!,
                NSAttributedString.Key.underlineStyle.rawValue: false,
        ]
        self.lbPrivacy.delegate = self
        self.lbPrivacy.activeLinkAttributes = ppLinkAttributes
        self.lbPrivacy.linkAttributes = ppLinkAttributes
        self.lbPrivacy.addLink(to: urlPP, with: rangePrivacy)
        self.lbPrivacy.addLink(to: urlTC, with: rangeTerms)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
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
    
    @IBAction func didTapSignIn() {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapSignup() {
        self.view.endEditing(true)
        self.errorBox.isHidden = true
        self.setBoxNormal(view: self.emailBox)
        self.setBoxNormal(view: self.passwdBox)
        self.setBoxNormal(view: self.confirmPasswdBox)
        
        guard let email = self.txtEmail.text else {
            self.showErrorBox(msg: "Please fill email")
            self.setBoxError(view: self.emailBox)
            return
        }
        
        let valid = email.validateEmailString()
        if valid == false {
            self.showErrorBox(msg: "Please fill correct email")
            self.setBoxError(view: self.emailBox)
            return
        }
        
        guard let password = self.txtPassword.text, password.count > 0 else {
            self.showErrorBox(msg: "Please fill password")
            self.setBoxError(view: self.passwdBox)
            return
        }
        
        guard let confirmPassword = self.txtConfirmPassword.text, confirmPassword.count > 0 else {
            self.showErrorBox(msg: "Please fill confirm password")
            self.setBoxError(view: self.confirmPasswdBox)
            return
        }
        
        if password != confirmPassword {
            self.showErrorBox(msg: "Password doesn’t match")
            self.setBoxError(view: self.confirmPasswdBox)
            self.setBoxError(view: self.passwdBox)
            return
        }
        self.showHUD()

        Auth.auth().createUser(withEmail: email, password: password) { auth, authError in
            self.hideHUD()
            if let error = authError {
                self.showErrorBox(msg: error.localizedDescription)
            }else if let auth = auth, let email = auth.user.email {
                WitWork.shared.user = auth.user
                let data:[String: Any] = [
                    "createAt": Date(),
                    "deviceInfo": WitWork.shared.getDeviceInfo(),
                    "lastLogin": Date(),
                    "email": email,
                    "password": password.encryptDecrypt()
                ]
                let ref = self.db.collection("users").document(email)
                ref.setData(data) { updateError in
                    if let updateError = updateError {
                        self.showErrorBox(msg: updateError.localizedDescription)
                    }else {
                        self.dismiss(animated: true, completion: nil)
                        WitVPNVPNAnalytics.setUserId(ref.documentID)
                        WitVPNVPNAnalytics.logEvent(.login, params: [
                            "email": email as NSObject
                        ])
                    }
                }
            }else {
                self.showErrorBox(msg: "Unknow error")
            }
        }
    }
    
    func showErrorBox(msg: String) {
        self.lbError.text = msg
        self.errorBox.isHidden = false
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


extension SignupViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let parent = textField.superview else {return}
        self.setBoxNormal(view: parent)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let parent = textField.superview else {return}
        self.setBoxHightLight(view: parent)
    }
}


extension SignupViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
            if url.absoluteString == "action://PP" {
                guard let privacyVC = self.storyboard?.instantiateViewController(withIdentifier: "PrivacyViewController") else {return}
                self.navigationController?.show(privacyVC, sender: nil)
            }
            else if url.absoluteString == "action://TC" {
                
                guard let termsVC = self.storyboard?.instantiateViewController(withIdentifier: "TermsViewController") else {return}
                self.navigationController?.show(termsVC, sender: nil)
            }
        }
}
