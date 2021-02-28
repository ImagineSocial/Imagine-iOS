//
//  Reachability.swift
//  Imagine
//
//  Created by Malte Schoppe on 15.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Reachability

//Reachability
//declare this property where it won't go out of scope relative to your listener
fileprivate var reachability: Reachability!

protocol ReachabilityActionDelegate {
    func reachabilityChanged(_ isReachable: Bool)
}
protocol ReachabilityObserverDelegate: class, ReachabilityActionDelegate {
    func addReachabilityObserver()
    func removeReachabilityObserver()
}
// Declaring default implementation of adding/removing observer
extension ReachabilityObserverDelegate {
    /** Subscribe on reachability changing */
    func addReachabilityObserver() {
        reachability = try? Reachability()
        reachability.whenReachable = { [weak self] reachability in
            self?.reachabilityChanged(true)
        }
        reachability.whenUnreachable = { [weak self] reachability in
            self?.reachabilityChanged(false)
        }
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func isConnected() -> Bool {
        
        if reachability.connection != .unavailable {
            return true
        } else {
            return false
        }
        
    }
    
    /** Unsubscribe */
    func removeReachabilityObserver() {
        reachability.stopNotifier()
        reachability = nil
//        EventsManager.shared.removeListener(self)
    }
}
