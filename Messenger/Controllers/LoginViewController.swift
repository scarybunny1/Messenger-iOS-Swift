//
//  LoginViewController.swift
//  Messenger
//
//  Created by Ayush Bhatt on 21/10/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class LoginViewController: UIViewController {
    
    let loginFormView = LoginFormView()
    let scrollView = UIScrollView()
    let spinner = JGProgressHUD(style: .dark)

    override func viewDidLoad() {
        super.viewDidLoad()

        style()
        layout()
        
        loginFormView.onLoginButtonPressed = {[weak self] email, password in
            guard let self = self else{return}
            guard !email.isEmpty else{
                self.showAlertDialogForInvalidDetails(title: "Email required", message: "Email cannot be empty.")
                return
            }
            guard !password.isEmpty else{
                self.showAlertDialogForInvalidDetails(title: "Password required", message: "Password cannot be empty.")
                return
            }
            self.spinner.show(in: self.view)
            //Firebase User login using email and password
            
            FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                
                guard let _ = authResult, error == nil else{
                    print("Error logging in user")
                    self.showAlertDialogForInvalidDetails(title: "Error", message: error?.localizedDescription ?? "Something went wrong")
                    return
                }
                let safeEmail = DatabaseManager.getSafeEntry(entry: email)
                DatabaseManager.shared.getUserFullName(from: safeEmail) { result in
                    switch(result){
                    case .success(let fullName):
                        UserDefaults.standard.set(email, forKey: "email")
                        UserDefaults.standard.set(fullName, forKey: "current-user-name")
                        UserDefaults.standard.set(true, forKey: "user-logged-in")
                        DispatchQueue.main.async {
                            self.spinner.dismiss()
                        }
                        (UIApplication.shared.delegate as! AppDelegate).setUpRootVC()
                        
                    case .failure(let error):
                        print("Failed to get user's fullname: \(error)")
                        DispatchQueue.main.async {
                            self.spinner.dismiss()
                        }
                    }
                }
                
            }
        }
        
        loginFormView.onSignupButtonPressed = {[weak self] in
            let registerVC = RegisterViewController()
            self?.navigationController?.pushViewController(registerVC, animated: false)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        loginFormView.passwordTF.text = ""
        loginFormView.emailTF.text = ""
    }
    
    private func showAlertDialogForInvalidDetails(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel))
        present(alert, animated: true)
    }

}

extension LoginViewController{
    func style(){
        title = "Login"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        loginFormView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func layout(){
        
        
        view.addSubview(scrollView)
        scrollView.addSubview(loginFormView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            loginFormView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            loginFormView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            loginFormView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            loginFormView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            loginFormView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }
}
