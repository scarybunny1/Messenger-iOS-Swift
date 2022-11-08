//
//  ConversationViewController.swift
//  Messenger
//
//  Created by Ayush Bhatt on 25/10/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

public struct Message: MessageType{
    public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

public struct Media: MediaItem{
    public var url: URL?
    public var image: UIImage?
    public var placeholderImage: UIImage
    public var size: CGSize
}

public extension MessageKind{
    var messageKindString: String{
        switch self{
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

public struct Sender: SenderType{
    var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ConversationViewController: MessagesViewController {
    
    private let otherPersonEmail: String
    private var conversationId: String? = nil
    var isNewConversation = false
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    var selfSender: Sender?{
        guard let email = UserDefaults.standard.string(forKey: "email") else{
            return nil
        }
        return Sender(photoURL: "", senderId: email, displayName: "Me")
    }
    var messages: [Message] = []
    
    init(with email: String, id: String?){
        otherPersonEmail = email
        conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        layout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let id = conversationId{
            listenForMessages(id: id, shouldScrollToBottom: true)
        }
        messageInputBar.becomeFirstResponder()
    }
}

extension ConversationViewController{
    func style(){
        view.backgroundColor = .red
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        setUpInputButton()
    }
    
    func layout(){
        
    }
    
    private func setUpInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Select a method to upload media", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Choose from Gallery", style: .default, handler: {[weak self] _ in
            self?.presentPhotoPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Take a Picture", style: .default, handler: {[weak self] _ in
            self?.presentCamera()
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Video", message: "Select a method to upload media", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: {[weak self] _ in
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .photoLibrary
            vc.allowsEditing = true
            vc.mediaTypes = ["public.movie"]
            vc.videoQuality = .typeMedium
            self?.present(vc, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Record a Video", style: .default, handler: {[weak self] _ in
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .camera
            vc.mediaTypes = ["public.movie"]
            vc.videoQuality = .typeMedium
            vc.allowsEditing = true
            self?.present(vc, animated: true)
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
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: id) {[weak self] result in
            switch result{
            case .success(let messages):
                guard !messages.isEmpty else{
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom{
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(_):
                print("Failed to get messages")
            }
        }
    }
}

extension ConversationViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender{
            return sender
        }
        
        fatalError("Sender is not defined")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
}

extension ConversationViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let sender = selfSender, let messageId = createMessageId(), let name = title else{
            return
        }
        let message = Message(sender: sender, messageId: messageId, sentDate: Date(), kind: .text(text))
        
        if isNewConversation{
            //create new conversation to database
            DatabaseManager.shared.createNewConversation(with: otherPersonEmail, name: name, firstMessage: message) { conversationId in
                if let id = conversationId{
                    print("Successfully sent message")
                    self.listenForMessages(id: id, shouldScrollToBottom: true)
                    self.conversationId = conversationId
                    self.isNewConversation = false
                }
            }
        }else{
            //append to existing conversation
            guard let conversationId = conversationId else{
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: otherPersonEmail, message: message) { success in
                print("Successfully continued the conversation")
            }
        }
    }
    
    private func createMessageId() -> String?{
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else{return nil}
        let timestamp = NSDate().timeIntervalSince1970
        
        return DatabaseManager.getSafeEntry(entry: "\(otherPersonEmail)_\(currentUserEmail)_\(timestamp)")
    }
}

extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let conversationId = conversationId, let messageID = createMessageId(), let otherName = title, let selfSender = selfSender else{
            return
        }
        
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let imageData = selectedImage.pngData(){
            let fileName = "photo_message_" + messageID + ".png"
            
            //Upload images to storage bucket
            StorageManager.shared.uploadPicture(with: imageData, fileName: fileName) { result in
                switch result{
                case .success(let urlString):
                    //Update the conversations
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else{
                        return
                    }
                    
                    let media = Media(url: url,image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, name: otherName, otherUserEmail: self.otherPersonEmail, message: message) { success in
                        if success{
                            print("Successfully sent a photo message")
                        }
                        else{
                            print("Failed to send a photo message")
                        }
                    }
                case .failure(let error):
                    print("Failed to upload picture: \(error)")
                }
            }
        }
        else if let videoUrl = info[.mediaURL] as? URL{
            let fileName = "video_message_" + messageID + ".mov"
            print(videoUrl)
            StorageManager.shared.uploadVideo(with: videoUrl, fileName: fileName) { result in
                switch result{
                case .success(let urlString):
                    //Update the conversations
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else{
                        return
                    }
                    
                    let media = Media(url: url,image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, name: otherName, otherUserEmail: self.otherPersonEmail, message: message) { success in
                        if success{
                            print("Successfully sent a photo message")
                        }
                        else{
                            print("Failed to send a photo message")
                        }
                    }
                case .failure(let error):
                    print("Failed to upload picture: \(error)")
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else{
            return
        }
        
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            imageView.sd_setImage(with: imageUrl)
        case .video(let media):
            guard let imageUrl = media.url else{
                return
            }
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }
}

extension ConversationViewController: MessageCellDelegate{
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{return}
        let message = messages[indexPath.section]
        
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            let vc = PhotoViewerViewController()
            vc.imageView.sd_setImage(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else{
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.player?.play()
            present(vc, animated: true)
            break
            
        default:
            break
        }
    }
    
}
