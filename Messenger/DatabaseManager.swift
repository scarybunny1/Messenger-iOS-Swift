//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ayush Bhatt on 22/10/22.
//

import Foundation
import FirebaseDatabase
import MessageKit

public final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    public static func getSafeEntry(entry: String) -> String{
        let safeEmail = entry.replacingOccurrences(of: ".", with: "-")
        return safeEmail
    }
}

extension DatabaseManager{
    
    public func getUserFullName(from email: String, completion: @escaping (Result<String, Error>) -> Void){
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard let user = snapshot.value as? [String: Any],
                    let firstName = user["firstName"] as? String,
                    let lastName = user["lastName"] as? String else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let fullName = firstName + " " + lastName
            completion(.success(fullName))
        })
    }
    
    public func userExists(emailAddress: String, completion: @escaping (Bool) -> Void){
        
        let safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else{
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    public func insertUser(user: ChatAppUser, completion: @escaping (Bool) -> Void){
        
        database.child(user.safeEmail).setValue(["firstName": user.firstName, "lastName": user.lastName]) { [weak self] error, _ in
            
            guard error == nil else{
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self?.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]]{
                    let newElement: [String: String] = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    self?.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }else{
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self?.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            }
        }
    }
    
    public func getUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let userCollection = snapshot.value as? [[String: String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(userCollection))
        }
    }
}

//MARK:  Handling conversations

extension DatabaseManager{
    
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (String?) -> Void){
        guard let email = UserDefaults.standard.string(forKey: "email"), let senderName = UserDefaults.standard.string(forKey: "current-user-name") else{return}
        
        let safeEmail = DatabaseManager.getSafeEntry(entry: email)
        
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userCollection = snapshot.value as? [String: Any], let message = self?.getMessageContent(mmessage: firstMessage) else{
                completion(nil)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let stringDate = ConversationViewController.dateFormatter.string(from: messageDate)
            
            var emailArray = [safeEmail, otherUserEmail]
            emailArray.sort(by: <)
            let conversationId = "conversation_\(emailArray[0])_\(emailArray[1])"
            let latest_message: [String: Any] = [
                "date": stringDate,
                "message": message,
                "is_read": false
            ]
            let newConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": latest_message
            ]
            
            let recipient_newConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": senderName,
                "latest_message": latest_message
            ]
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append to existing conversation
                    conversations.append(recipient_newConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }else{
                    //create new conversation
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversation])
                }
                
            })
            
            if var conversations = userCollection["conversations"] as? [[String: Any]]{
                //append to the existing conversation
                conversations.append(newConversation)
                userCollection["conversations"] = conversations
            }else{
                userCollection["conversations"] = [newConversation]
            }
            
            ref.setValue(userCollection) { [weak self] error, _ in
                guard error == nil else{
                    completion(nil)
                    return
                }
                self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
            }
        }
    }
    
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: Message, completion: @escaping (String?) -> Void){
        
        guard let email = UserDefaults.standard.string(forKey: "email"), let messageContent = self.getMessageContent(mmessage: firstMessage) as? String else{
            completion(nil)
            return
        }
        
        let stringDate = ConversationViewController.dateFormatter.string(from: firstMessage.sentDate)
         
        
        let message: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": messageContent,
            "date": stringDate,
            "sender_email": email,
            "name": name,
            "is_read": false
        ]
        
        let value = ["messages": [message]]
        
        database.child(conversationId).setValue(value) { error, _ in
            guard error == nil else{
                completion(nil)
                print("error saving conversations")
                return
            }
            completion(conversationId)
        }
    }
    
    private func getMessageContent(mmessage: Message) -> Any{
        
        switch mmessage.kind{
            
        case .text(let messageText):
            return messageText
        case .attributedText(_):
            break
        case .photo(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString{
                return targetUrlString
            }
            break
        case .video(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString{
                return targetUrlString
            }
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        return ""
    }
    
    public func getConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        print("\(email)/conversations")
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let result = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = result.compactMap {
                guard let conversationId = $0["id"] as? String,
                      let name = $0["name"] as? String,
                      let otherUserEmail = $0["other_user_email"] as? String,
                      let l = $0["latest_message"] as? [String: Any],
                      let message = l["message"] as? String,
                      let date = l["date"] as? String,
                      let isRead = l["is_read"] as? Bool else{
                    completion(.failure(DatabaseError.failedToFetch))
                    return nil
                }
                let latest_message = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latest_message)
            }
            completion(.success(conversations))
        })
    }
    
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let result = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = result.compactMap {
                if let messageId = $0["id"] as? String,
                      let name = $0["name"] as? String,
                      let senderEmail = $0["sender_email"] as? String,
                      let type = $0["type"] as? String,
                      let content = $0["content"] as? String,
                      let dateString = $0["date"] as? String,
                      let isRead = $0["is_read"] as? Bool,
                      let date = ConversationViewController.dateFormatter.date(from: dateString){
                    
                    return Message(sender: Sender(photoURL: "", senderId: senderEmail, displayName: name), messageId: messageId, sentDate: date, kind: self.getKind(content: content, type: type)!)
                }
                
                completion(.failure(DatabaseError.failedToFetch))
                return nil
            }
            
            completion(.success(messages))
        })
    }
    
    private func getKind(content: String, type: String) -> MessageKind?{
        var kind: MessageKind?
        if type == "text"{
            kind = .text(content)
        }else if type == "photo"{
            guard let imageUrl = URL(string: content), let placeholder = UIImage(systemName: "plus") else{
                print("Failed to get imageurl from string")
                return nil
            }
            kind = .photo(Media(url: imageUrl, placeholderImage: placeholder, size: CGSize(width: 300, height: 300)))
        }else if type == "video"{
            guard let videoUrl = URL(string: content), let placeholder = UIImage(systemName: "plus") else{
                print("Failed to get videoUrl from string")
                return nil
            }
            kind = .video(Media(url: videoUrl, placeholderImage: placeholder, size: CGSize(width: 300, height: 300)))
        }

        guard let finalKind = kind else{return nil}
        return finalKind
    }
    
    public func sendMessage(to conversationId: String, name: String, otherUserEmail: String, message: Message, completion: @escaping (Bool) -> Void){
        print(conversationId)
        let ref = database.child("\(conversationId)/messages")
        ref.observeSingleEvent(of: .value, with: {snapshot in
            guard var conversation = snapshot.value as? [[String: Any]],
                  let email = UserDefaults.standard.string(forKey: "email"),
                  let messageContent = self.getMessageContent(mmessage: message) as? String
            else{
                
                completion(false)
                return
            }
            let stringDate = ConversationViewController.dateFormatter.string(from: message.sentDate)
            
            let newMessage: [String: Any] = [
                "id": message.messageId,
                "type": message.kind.messageKindString,
                "content": messageContent,
                "date": stringDate,
                "sender_email": email,
                "name": name,
                "is_read": false
            ]
            
            conversation.append(newMessage)
            ref.setValue(conversation) { error, _ in
                guard error == nil else{
                    completion(false)
                    print("Failed to append new message to existing conversation")
                    return
                }
                
                let mySafeEmail = DatabaseManager.getSafeEntry(entry: email)
                let recipientSafeEmail = DatabaseManager.getSafeEntry(entry: otherUserEmail)
                
                let latestMessage: [String: Any] = [
                    "date": stringDate,
                    "is_read": false,
                    "message": messageContent
                ]
                
                self.database.child("\(mySafeEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var conversations = snapshot.value as? [[String: Any]] else{
                        completion(false)
                        return
                    }
                    for (i, conversation) in conversations.enumerated(){
                        if let id = conversation["id"] as? String, id == conversationId{
                            conversations[i]["latest_message"] = latestMessage
                            break
                        }
                    }
                    self.database.child("\(mySafeEmail)/conversations").setValue(conversations) { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        //Update latest message for recipient
                        self.database.child("\(recipientSafeEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var conversations = snapshot.value as? [[String: Any]] else{
                                completion(false)
                                return
                            }
                            for (i, conversation) in conversations.enumerated(){
                                if let id = conversation["id"] as? String, id == conversationId{
                                    conversations[i]["latest_message"] = latestMessage
                                    break
                                }
                            }
                            self.database.child("\(recipientSafeEmail)/conversations").setValue(conversations) { error, _ in
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        })
                    }
                    
                })
            }
        })
    }
    
    public func deleteConversation(for conversationId: String, completion: @escaping (Bool) -> Void){
        guard let userEmail = UserDefaults.standard.string(forKey: "email") else{
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.getSafeEntry(entry: userEmail)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard let userObject = snapshot.value as? [String: Any], var conversations = userObject["conversations"] as? [[String: Any]] else{
                print("Failed to get user")
                completion(false)
                return
            }
            
            for i in 0..<conversations.count{
                if let id = conversations[i]["id"] as? String{
                    if id == conversationId{
                        conversations.remove(at: i)
                        break
                    }
                }
            }
            
            self.database.child("\(safeEmail)/conversations").setValue(conversations) { error, _ in
                guard error == nil else{
                    print("Failed to delete conversation")
                    completion(false)
                    return
                }
                completion(true)
            }
        })
    }
    
    public func conversationExists(with otherUserEmail: String, completion: @escaping (Result<String, Error>) -> Void){
        guard let email = UserDefaults.standard.string(forKey: "email") else{
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
        
        let safeEmail = DatabaseManager.getSafeEntry(entry: email)
        let safeOtherUserEmail = DatabaseManager.getSafeEntry(entry: otherUserEmail)
        var emailArray = [safeEmail, safeOtherUserEmail]
        emailArray.sort(by: <)
        let conversationId = "conversation_\(emailArray[0])_\(emailArray[1])"
        
        database.child(conversationId).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(conversationId))
            
        }
        
    }
}

public enum DatabaseError: Error{
    case failedToFetch
}


public struct ChatAppUser{
    var firstName: String
    var lastName: String
    var emailAddress: String
    
    var safeEmail: String{
        let safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        return safeEmail
    }
    
    var profilePicture: String{
        return safeEmail + "_profile_picture.png"
    }
}
