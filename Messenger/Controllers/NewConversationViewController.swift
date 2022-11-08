//
//  NewChatViewController.swift
//  Messenger
//
//  Created by Ayush Bhatt on 21/10/22.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: ((SearchResults) -> Void)?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users: [SearchResults] = []
    private var results: [SearchResults] = []
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search for users"
        
        return sb
    }()
    
    private let tableView: UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let l = UILabel()
        l.text = "No Results Found"
        l.textAlignment = .center
        l.textColor = .gray
        l.font = .systemFont(ofSize: 21, weight: .bold)
        l.isHidden = true
        return l
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        self.navigationItem.standardAppearance = appearance
        self.navigationItem.scrollEdgeAppearance = appearance
        style()
        layout()
        
        searchBar.becomeFirstResponder()
    }
}

extension NewConversationViewController{
    func style(){
        searchBar.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
    }
    
    func layout(){
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            noResultsLabel.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 2),
            noResultsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noResultsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            
        ])
    }
    
    @objc
    private func dismissSelf(){
        dismiss(animated: true)
    }
}

extension NewConversationViewController: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        results.removeAll()
        tableView.isHidden = true
        noResultsLabel.isHidden = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            return
        }
        searchBar.resignFirstResponder()
        self.showUsers(query: text)
    }
    
    func showUsers(query: String){
        if !hasFetched{
            spinner.show(in: view)
            DatabaseManager.shared.getUsers { [weak self] result in
                DispatchQueue.main.async {
                    self?.spinner.dismiss()
                }
                switch result{
                case .success(let userCollection):
                    
                    self?.users = userCollection.compactMap({
                        guard let name = $0["name"], let email = $0["email"] else{return nil}
                        return SearchResults(name: name, email: email)
                    })
                    self?.filterUsers(query: query)
                case .failure(let error):
                    print("Failed to fetch users: \(error)")
                }
            }
            hasFetched = true
        }else{
            filterUsers(query: query)
        }
    }
    
    private func filterUsers(query: String){
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else{return}
        let safeEmail = DatabaseManager.getSafeEntry(entry: currentUserEmail)
        self.results = users.filter {
            guard $0.email != safeEmail else{
                return false
            }
            return $0.name.lowercased().hasPrefix(query.lowercased())
        }
        updateUI()
    }
    
    private func updateUI(){
        if results.isEmpty{
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        }else{
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}


extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: results[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let targetUser = results[indexPath.row]
        dismiss(animated: true) {[weak self] in
            self?.completion?(targetUser)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
}

public struct SearchResults{
    let name: String
    let email: String
}
