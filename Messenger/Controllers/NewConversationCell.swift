//
//  FindUserTableViewCell.swift
//  Messenger
//
//  Created by Ayush Bhatt on 01/11/22.
//

import UIKit

class NewConversationCell: UITableViewCell {
    
    static let identifier = "NewConversationCell"
    
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
    
    func configure(with user: SearchResults){
        userNameLabel.text = user.name
        
        let fileName = user.email + "_profile_picture.png"
        
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

extension NewConversationCell{
    private func styleView(){
        
    }
    
    private func layout(){
        addSubview(userNameLabel)
        addSubview(userImageView)
        NSLayoutConstraint.activate([
            userImageView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
            userImageView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(equalToSystemSpacingBelow: userImageView.bottomAnchor, multiplier: 2),
            userImageView.widthAnchor.constraint(equalToConstant: 60),
//            userImageView.heightAnchor.constraint(equalToConstant: 100),
            
            userNameLabel.centerYAnchor.constraint(equalTo: userImageView.centerYAnchor),
            trailingAnchor.constraint(equalToSystemSpacingAfter: userNameLabel.trailingAnchor, multiplier: 2),
            userNameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 8)
        ])
    }
}

