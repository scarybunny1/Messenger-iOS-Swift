//
//  RegisterFormView.swift
//  Messenger
//
//  Created by Ayush Bhatt on 22/10/22.
//

import UIKit

class RegisterFormView: UIView {
    
    var onSignupButtonPressed: (String, String, String, String, UIImage) -> Void = {_, _, _, _, _ in }
    
    var selectProfilePicture: () -> Void = {}
    
    let stackView = UIStackView()
    
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.circle")
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor.black.cgColor
        return iv
    }()
    
    let firstnameTF : UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.placeholder = "First Name"
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
    let lastnameTF : UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.placeholder = "Last Name"
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
    
    let emailTF : UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.placeholder = "Email Address"
        tf.returnKeyType = .continue
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.backgroundColor = UIColor.white
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let i = UIImageView(image: UIImage(systemName: "email"))
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
    
    let signupButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 3
        button.backgroundColor = UIColor.lightGray
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
    
    override func layoutSubviews() {
        print(imageView.frame)
        imageView.layer.cornerRadius = imageView.frame.width / 2.0
    }
}

extension RegisterFormView {
    func style(){
        translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        
        firstnameTF.delegate = self
        lastnameTF.delegate = self
        emailTF.delegate = self
        passwordTF.delegate = self
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePicture))
        imageView.addGestureRecognizer(gesture)
        signupButton.addTarget(self, action: #selector(performSignupAction), for: .touchUpInside)
        
        imageView.isUserInteractionEnabled = true
        stackView.isUserInteractionEnabled = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
    }
    
    func layout(){
        let wrapperView = UIView()
        wrapperView.addSubview(imageView)
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(wrapperView)
        stackView.addArrangedSubview(firstnameTF)
        stackView.addArrangedSubview(lastnameTF)
        stackView.addArrangedSubview(emailTF)
        stackView.addArrangedSubview(passwordTF)
        
        stackView.addArrangedSubview(signupButton)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            emailTF.heightAnchor.constraint(equalToConstant: 45),
            passwordTF.heightAnchor.constraint(equalToConstant: 45),
            firstnameTF.heightAnchor.constraint(equalToConstant: 45),
            lastnameTF.heightAnchor.constraint(equalToConstant: 45),
            signupButton.heightAnchor.constraint(equalToConstant: 45),
            imageView.centerXAnchor.constraint(equalTo: wrapperView.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: CGFloat(100)),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])
        
    }
    
    @objc
    private func didTapChangeProfilePicture(){
        print("Profile picture tapped")
        selectProfilePicture()
    }
    
    @objc
    private func performSignupAction(){
        dismissKeyboard()
        
        guard let email = emailTF.text, let password = passwordTF.text, let firstname = firstnameTF.text, let lastname = lastnameTF.text else{
            return
        }
        onSignupButtonPressed(firstname, lastname, email, password, imageView.image!)
    }
    
    private func dismissKeyboard(){
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        firstnameTF.resignFirstResponder()
        lastnameTF.resignFirstResponder()
    }
    
}

extension RegisterFormView: UITextFieldDelegate{
    func textFieldDidEndEditing(_ textField: UITextField) {
        endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstnameTF{
            lastnameTF.becomeFirstResponder()
        }
        else if textField == lastnameTF{
            emailTF.becomeFirstResponder()
        }
        else if textField == emailTF{
            passwordTF.becomeFirstResponder()
        }
        else if textField == passwordTF{
            performSignupAction()
        }
        return true
    }
}

