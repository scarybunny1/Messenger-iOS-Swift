//
//  ChatTableViewCell.swift
//  Messenger
//
//  Created by Ayush Bhatt on 27/10/22.
//

import UIKit
import SDWebImage

class ChatTableViewCell: UITableViewCell {
    
    static let identifier = "ChatTableViewCell"
    
    let userImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.borderColor = UIColor.label.cgColor
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 2
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.contentMode = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        return label
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 5
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        styleView()
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.layer.cornerRadius = userImageView.frame.width / 2.0
    }
    
    func configure(with conversation: Conversation){
        userNameLabel.text = conversation.name
        userMessageLabel.text = conversation.latestMessage.text
        
        let fileName = conversation.otherUserEmail + "_profile_picture.png"
        
        let path = "images/\(fileName)"
        
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async{
                    self?.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        }
    }
}

extension ChatTableViewCell{
    private func styleView(){
        
    }
    
    private func layout(){
        stackView.addArrangedSubview(userNameLabel)
        stackView.addArrangedSubview(userMessageLabel)
        addSubview(userImageView)
        addSubview(stackView)
        NSLayoutConstraint.activate([
            userImageView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
            userImageView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(equalToSystemSpacingBelow: userImageView.bottomAnchor, multiplier: 2),
            userImageView.widthAnchor.constraint(equalToConstant: 100),
//            userImageView.heightAnchor.constraint(equalToConstant: 100),
            
            stackView.centerYAnchor.constraint(equalTo: userImageView.centerYAnchor),
            trailingAnchor.constraint(equalToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 2),
            stackView.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 8)
        ])
    }
}
