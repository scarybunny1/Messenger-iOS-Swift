//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Ayush Bhatt on 21/10/22.
//

import UIKit
import Firebase

class ProfileViewController: MessengerViewController {
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .blue
        
        style()
        layout()
    }
    
    override func commonInit() {
        setTabBarItem(title: "Profile", image: "person.circle")
        title = "Profile"
        
    }

}


extension ProfileViewController{
    private func style(){
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(logoutUser))
        setUpTableView()
        
    }
    
    private func layout(){
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setUpTableView(){
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = createTableHeader()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func createTableHeader() -> UIView?{
        
        guard let email = UserDefaults.standard.string(forKey: "email"), !email.isEmpty else{
            return nil
        }
        let safeEmail = DatabaseManager.getSafeEntry(entry: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/\(fileName)"
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.frame.width - 150) / 2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 75
        imageView.backgroundColor = .white
        headerView.addSubview(imageView)
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result{
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        }
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else{
                return
            }
            DispatchQueue.main.async{
                let image = UIImage(data: data)
                imageView.image = image
            }
        }.resume()
    }
    
    @objc
    private func logoutUser(){
        let email = UserDefaults.standard.string(forKey: "email")
        let alert = UIAlertController(title: nil, message: "Signed in as \(email ?? "")", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive){_ in
            do{
                try FirebaseAuth.Auth.auth().signOut()
                
                
                UserDefaults.standard.set(false, forKey: "user-logged-in")
                (UIApplication.shared.delegate as! AppDelegate).setUpRootVC()
                
            }catch{
                print("Error logging out user \(error)")
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Hello"
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
}
