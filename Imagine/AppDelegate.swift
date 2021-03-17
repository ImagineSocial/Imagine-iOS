//
//  AppDelegate.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    

    // Only portrait mode
    var myOrientation: UIInterfaceOrientationMask = .portrait
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return myOrientation
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //Init Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        
        // To have the textViews and textFields always above the keyboard
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        // Change Color of navigationItem and Barbutton
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.imagineColor, NSAttributedString.Key.font : UIFont(name: "IBMPlexSans", size: 18)], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.imagineColor
//        UINavigationBar.appearance().isTranslucent = true Too many other views with different options
        
        // Initiate rootviewcontroller here because otherwise the app would crash because a child of TabBarViewController would call Firebase before FirebaseApp.configure would be called here in AppDelegate
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "initialTabBarVC")
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        
        if let _ = Auth.auth().currentUser {    // Already signed up but before integration of notifications. Will ask after sign Up. Can delete this after everybody has set it (maybe 3 Users left)
            registerForPushNoticications(application: application)
        }
        
        do{ // If i want to play full screen: https://stackoverflow.com/questions/31828654/turn-off-audio-playback-of-avplayer
          try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [AVAudioSession.CategoryOptions.mixWithOthers])
          try AVAudioSession.sharedInstance().setActive(true)
        }catch{//some meaningful exception handling
            
        }
        
        deleteApplicationBadgeNumber(application: application)
        
        return true
    }
    
    func registerForPushNoticications(application: UIApplication) {
        // Set FirebaseCloudMessaging for Apple Notification Center
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {granted, _ in
                    let defaults = UserDefaults.standard
                    if granted {
                        defaults.set(true, forKey: "allowNotifications")
                    } else {
                        defaults.set(false, forKey: "allowNotifications")
                    }
            })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error, failed to register to remote Notifications: ", error.localizedDescription)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        deleteApplicationBadgeNumber(application: application)
    }
    
    func deleteApplicationBadgeNumber(application: UIApplication) {
        if application.applicationIconBadgeNumber != 0 {
            application.applicationIconBadgeNumber = 0
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                if let currentToken = UserDefaults.standard.value(forKey: "fcmToken") as? String {
                    if currentToken == result.token {
                        print("The fcm token hasnt changed")
                    } else {
                        //save Token in Database
                        HandyHelper().saveFCMToken(token: result.token)
                    }
                } else {    // Not a token set in userdefaults yet
                    HandyHelper().saveFCMToken(token: result.token)
                    print("Set fcm token in userdefaults")
                }
                
            }
        }
    }


}

extension AppDelegate : MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        print("Your Firebase FCM Registration Token: \(fcmToken)")
    }
}

