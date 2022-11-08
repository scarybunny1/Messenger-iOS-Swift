////
////  AppDelegate.swift
////  Messenger
////
////  Created by Ayush Bhatt on 21/10/22.
////
//
import UIKit
import Firebase

class MessengerViewController: UIViewController{
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func commonInit(){
        
    }
    
    func setTabBarItem(title: String, image: String){
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: image, withConfiguration: configuration), tag: 0)
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.backgroundColor = .systemBackground
        FirebaseApp.configure()
        
        setUpRootVC()
        
        
        return true
    }
    
    func setUpRootVC() {
        let isLoggedin = UserDefaults.standard.bool(forKey: "user-logged-in")
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = .gray
        
        if (isLoggedin){
            let profileVC = ProfileViewController()
            let profileNC = UINavigationController(rootViewController: profileVC)
            
            let chatsVC = ChatsViewController()
            let chatsNC = UINavigationController(rootViewController: chatsVC)
            
            let tabBarController = UITabBarController()
            tabBarController.viewControllers = [chatsNC, profileNC]
            
            tabBarController.tabBar.isTranslucent = false
            tabBarController.tabBar.tintColor = .black
            
            window?.rootViewController = tabBarController
        }else{
            let loginVC = LoginViewController()
            let authNC = UINavigationController(rootViewController: loginVC)
            
            window?.rootViewController = authNC
        }
    }
    
}
