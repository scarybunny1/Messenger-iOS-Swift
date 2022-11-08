//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Ayush Bhatt on 21/10/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    let registerFormView = RegisterFormView()
    let spinner = JGProgressHUD(style: .dark)
    let scrollView = UIScrollView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style()
        layout()
        
        registerFormView.selectProfilePicture = presentPhotoActionSheet
        
        registerFormView.onSignupButtonPressed = {[weak self] firstname, lastname, email, password, profilePicture in
            
            guard let self = self else{return}
            
            guard !firstname.isEmpty else{
                self.showAlertDialogForInvalidDetails(title: "First name required", message: "First name cannot be empty.")
                return
            }
            guard !lastname.isEmpty else{
                self.showAlertDialogForInvalidDetails(title: "Last name required", message: "Last name cannot be empty.")
                return
            }
            
            guard !email.isEmpty else{
                self.showAlertDialogForInvalidDetails(title: "Email required", message: "Email cannot be empty.")
                return
            }
            guard !password.isEmpty else{
                self.showAlertDialogForInvalidDetails(title: "Password required", message: "Password cannot be empty.")
                return
            }
            guard password.count >= 6 else{
                self.showAlertDialogForInvalidDetails(title: "Weak Password", message: "Password should be atleast 6 characters long.")
                return
            }
            self.spinner.show(in: self.view)
            //TODO:  Firebase User signup
            DatabaseManager.shared.userExists(emailAddress: email, completion: { [weak self] exists in
                guard let self = self else{return}
                guard !exists else{
                    self.showAlertDialogForInvalidDetails(title: "User Exists", message: "\(email) already exists.")
                    return
                }
                FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { data, error in
                    
                    guard let authResult = data, error == nil else{
                        print("Error creating user \(error)")
                        DispatchQueue.main.async {
                            self.spinner.dismiss()
                        }
                        return
                    }
                    let user = authResult.user
                    print("New User: \(user)")
                    UserDefaults.standard.set(email, forKey: "email")
                    let fullName = firstname + " " + lastname
                    UserDefaults.standard.set(fullName, forKey: "current-user-name")
                    
                    let chatUser = ChatAppUser(firstName: firstname, lastName: lastname, emailAddress: email)
                    DatabaseManager.shared.insertUser(user: chatUser){isSuccess in
                        if isSuccess{
                            //Upload image
                            guard let image = profilePicture.pngData() else{
                                DispatchQueue.main.async {
                                    self.spinner.dismiss()
                                }
                                return
                            }
                            StorageManager.shared.uploadProfilePicture(with: image, fileName: chatUser.profilePicture) { result in
                                switch result{
                                case .success(let downloadURL):
                                    UserDefaults.standard.set(downloadURL, forKey: "profile-picture-url")
                                    
                                    UserDefaults.standard.set(true, forKey: "user-logged-in")
                                    DispatchQueue.main.async {
                                        self.spinner.dismiss()
                                    }
                                    (UIApplication.shared.delegate as! AppDelegate).setUpRootVC()
                                case .failure(let error):
                                    print(error.localizedDescription)
                                    DispatchQueue.main.async {
                                        self.spinner.dismiss()
                                    }
                                }
                            }
                        }
                    }
                    
                }
            })
        }
    }
    
    private func showAlertDialogForInvalidDetails(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel))
        present(alert, animated: true)
    }
    
}

extension RegisterViewController{
    func style(){
        title = "Create Account"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        registerFormView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func layout(){
        
        view.addSubview(scrollView)
        scrollView.addSubview(registerFormView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            registerFormView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            registerFormView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            registerFormView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            registerFormView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            registerFormView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    private func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture", message: "Select a method to upload profile picture", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Choose from Gallery", style: .default, handler: {[weak self] _ in
            self?.presentPhotoPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Take a Picture", style: .default, handler: {[weak self] _ in
            self?.presentCamera()
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .camera
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        self.registerFormView.imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
