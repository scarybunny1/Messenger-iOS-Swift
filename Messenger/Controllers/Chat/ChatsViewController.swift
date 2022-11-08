//
//  ChatsViewController.swift
//  Messenger
//
//  Created by Ayush Bhatt on 21/10/22.
//

import UIKit

public struct Conversation{
    public let id: String
    public let name: String
    public let otherUserEmail: String
    public let latestMessage: LatestMessage
}

public struct LatestMessage{
    public let date: String
    public let text: String
    public let isRead: Bool
}

class ChatsViewController: MessengerViewController {
    
    var conversations: [Conversation] = []
    
    var tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.isHidden = true
        table.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.identifier)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchChats()
        startListeningForConversations()
        style()
        layout()
    }
    
    override func commonInit() {
        setTabBarItem(title: "Chats", image: "message")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .done, target: self, action: #selector(didTapNewConversationBarButton))
    }

}

extension ChatsViewController{
    private func style(){
        title = "Chats"
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        setUpTableView()
    }
    
    private func layout(){
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setUpTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchChats(){
        tableView.isHidden = false
    }
    
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.string(forKey: "email") else{return}
        let safeEmail = DatabaseManager.getSafeEntry(entry: email)
        print(safeEmail)
        DatabaseManager.shared.getConversations(for: safeEmail) { [weak self] result in
            switch(result){
            case .success(let conversations):
                guard !conversations.isEmpty else{
                    return
                }
                self?.conversations = conversations
                DispatchQueue.main.async{
                    self?.tableView.reloadData()
                }
            case .failure(let e):
                print("Error fetching all conversations: \(e)")
            }
        }
    }
    
    @objc
    private func didTapNewConversationBarButton(){
        let vc = NewConversationViewController()
        let nc = UINavigationController(rootViewController: vc)
        vc.completion = {[weak self] result in
            guard let self = self else{return}
            print(result)
            //If conversation is already present, push the chat view on stack and continue the conversation
            let currentConversations = self.conversations
            if let targetConversation = currentConversations.first(where: {$0.otherUserEmail == result.email}){
                let vc = ConversationViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                self.startNewConversation(with: result)
            }
        }
        vc.title = "New Conversation"
        present(nc, animated: true, completion: nil)
    }
    
    private func startNewConversation(with user: SearchResults){
        DatabaseManager.shared.conversationExists(with: user.email) { idResult in
            switch idResult{
            case .success(let conversationId):
                let vc = ConversationViewController(with: user.email, id: conversationId)
                vc.isNewConversation = false
                vc.title = user.name
                self.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                //Else create a new conversation
                let vc = ConversationViewController(with: user.email, id: nil)
                vc.isNewConversation = true
                vc.title = user.name
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
}

extension ChatsViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.identifier, for: indexPath) as! ChatTableViewCell
        cell.configure(with: conversations[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        
        let vc = ConversationViewController(with: conversation.otherUserEmail, id: conversation.id)
        vc.title = conversation.name
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 136
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(for: conversations[indexPath.row].id){success in
                if success{
                    self.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            }
            tableView.endUpdates()
        }
    }
}
