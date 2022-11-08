//
//  LoginFormView.swift
//  Messenger
//
//  Created by Ayush Bhatt on 22/10/22.
//

import UIKit

class LoginFormView : UIView{
    
    var onSignupButtonPressed: () -> Void = {}
    var onLoginButtonPressed: (String, String) -> Void = {_, _ in }
    
    let stackView = UIStackView()
    
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "logo")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    let emailTF : UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.placeholder = "Email"
        tf.returnKeyType = .continue
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.backgroundColor = UIColor.white
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let i = UIImageView(image: UIImage(systemName: "person"))
        i.frame = CGRect(x: 5, y: 5, width: 20, height: 20)
        v.addSubview(i)
        tf.leftView = v
        tf.leftViewMode = .always
        return tf
        
    }()
    let passwordTF : UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.backgroundColor = UIColor.white
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let i = UIImageView(image: UIImage(systemName: "key"))
        i.frame = CGRect(x: 5, y: 5, width: 20, height: 20)
        v.addSubview(i)
        tf.leftView = v
        tf.leftViewMode = .always
        return tf
        
    }()
    
    let loginButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 3
        button.backgroundColor = UIColor.lightGray
        return button
    }()
    
    let signupButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 3
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.backgroundColor = UIColor.white
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        commoninit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commoninit(){
        style()
        layout()
    }
}

extension LoginFormView {
    func style(){
        translatesAutoresizingMaskIntoConstraints = false
        
        emailTF.delegate = self
        passwordTF.delegate = self
        
        signupButton.addTarget(self, action: #selector(goToRegisterScreen), for: .touchUpInside)
        
        loginButton.addTarget(self, action: #selector(performLoginAction), for: .touchUpInside)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
    }
    
    func layout(){
        stackView.addArrangedSubview(imageView)
        
        stackView.addArrangedSubview(emailTF)
        stackView.addArrangedSubview(passwordTF)
        
        stackView.addArrangedSubview(loginButton)
        stackView.addArrangedSubview(signupButton)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            emailTF.heightAnchor.constraint(equalToConstant: 45),
            passwordTF.heightAnchor.constraint(equalToConstant: 45),
            loginButton.heightAnchor.constraint(equalToConstant: 45),
            signupButton.heightAnchor.constraint(equalToConstant: 45),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
        ])
    }
    
    @objc
    private func goToRegisterScreen(){
        dismissKeyboard()
        onSignupButtonPressed()
    }
    
    @objc
    private func performLoginAction(){
        dismissKeyboard()
        
        guard let email = emailTF.text, let password = passwordTF.text else{
            return
        }
        onLoginButtonPressed(email, password)
    }
    
    private func dismissKeyboard(){
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
    }
}

extension LoginFormView: UITextFieldDelegate{
    func textFieldDidEndEditing(_ textField: UITextField) {
        dismissKeyboard()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTF{
            passwordTF.becomeFirstResponder()
        }
        else if textField == passwordTF{
            performLoginAction()
        }
        return true
    }
}
