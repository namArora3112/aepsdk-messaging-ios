/*
Copyright 2024 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import AEPAssurance
import AEPCore
import AEPEdge
//import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle
import AEPSignal
import AEPMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("========================================")
        print("🚀 [APP LAUNCH] App launched")
        print("========================================")
        MobileCore.setLogLevel(.trace)

        let extensions = [
            Identity.self,
            Lifecycle.self,
            Signal.self,
            Edge.self,
//            Consent.self,
            Messaging.self,
            Assurance.self
        ]
        
        MobileCore.registerExtensions(extensions) {
            MobileCore.configureWith(appId: Constants.APPID)
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                let iMap = IdentityMap()
                iMap.add(item: IdentityItem(id: "namantest@adobetest.com"), withNamespace: "Email")
                Identity.updateIdentities(with:iMap)
                print("naman nunu")
            }
            if Constants.isStage {
                MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])
            }
                
            #if DEBUG
                MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
            #endif
            
            if !Constants.assuranceURL.isEmpty {
                Assurance.startSession(url: URL(string: Constants.assuranceURL)!)
            }
            
            self.registerForPushNotifications(application)
            let cardSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
            let cbeSurface1 = Surface(path: Constants.SurfaceName.CBE_HTML)
            let cbeSurface2 = Surface(path: Constants.SurfaceName.CBE_JSON)
            Messaging.updatePropositionsForSurfaces([cardSurface,cbeSurface1, cbeSurface2])
        }
        
        return true
    }
        
    // MARK: - Notification Categories Setup
    private func registerNotificationCategories() {
        print("========================================")
        print("📋 [NOTIFICATION CATEGORIES] Registering notification categories...")
        print("========================================")
        
        // Define actions for notifications
        
        // Accept Action - Opens the app (foreground)
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_ACTION",
            title: "Accept",
            options: [.foreground] // Opens the app
        )
        
        // Decline Action - Opens the app (foreground)
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_ACTION",
            title: "Decline",
            options: [.foreground] // Opens the app
        )
        
        // Dismiss Action - Does NOT open the app
        let dismissAction = UNNotificationAction(
            identifier: "Dismiss",
            title: "Dismiss",
            options: [] // No options = doesn't open app
        )
        
        // TRACKABLE_CATEGORY - Basic tracking with Accept and Dismiss
        let trackableCategory = UNNotificationCategory(
            identifier: "TRACKABLE_CATEGORY",
            actions: [acceptAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction] // Allows tracking of dismiss
        )
        
        // FULL_TRACKING_CATEGORY - Complete tracking with Accept, Decline, and Dismiss
        let fullTrackingCategory = UNNotificationCategory(
            identifier: "FULL_TRACKING_CATEGORY",
            actions: [acceptAction, declineAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction] // Allows tracking of dismiss
        )
        
        // Register categories with the notification center
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([trackableCategory, fullTrackingCategory])
        
        print("✅ [NOTIFICATION CATEGORIES] Successfully registered 2 categories:")
        print("   📌 TRACKABLE_CATEGORY:")
        print("      • Accept (opens app) → ACCEPT_ACTION")
        print("      • Dismiss (no app open) → Dismiss")
        print("")
        print("   📌 FULL_TRACKING_CATEGORY:")
        print("      • Accept (opens app) → ACCEPT_ACTION")
        print("      • Decline (opens app) → DECLINE_ACTION")
        print("      • Dismiss (no app open) → Dismiss")
        print("========================================")
    }
    
    // MARK: - Push Notification registration methods
    func registerForPushNotifications(_ application : UIApplication) {
        print("📱 [PUSH REGISTRATION] Starting push notification registration")
        let center = UNUserNotificationCenter.current()
        
        // Register notification categories FIRST (before requesting permission)
        registerNotificationCategories()
        
        // Ask for user permission
        print("📱 [PUSH REGISTRATION] Requesting authorization...")
        center.requestAuthorization(options: [.badge, .sound, .alert]) { [weak self] granted, error in
            if let error = error {
                print("❌ [PUSH REGISTRATION] Authorization error: \(error)")
                return
            }
            
            if granted {
                print("✅ [PUSH REGISTRATION] User granted notification permission")
                
                // Set delegate
                center.delegate = self
                print("✅ [PUSH REGISTRATION] Notification center delegate set")
                
                // Register for remote notifications
                DispatchQueue.main.async {
                    print("📱 [PUSH REGISTRATION] Registering for remote notifications...")
                    application.registerForRemoteNotifications()
                }
            } else {
                print("❌ [PUSH REGISTRATION] User denied notification permission")
            }
        }
    }
    
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("========================================")
        print("✅ [PUSH TOKEN] Device token received")
        print("🔑 [PUSH TOKEN] Token: \(token)")
        print("========================================")
        MobileCore.setPushIdentifier(deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("========================================")
        print("❌ [PUSH TOKEN] Failed to register for remote notifications")
        print("❌ [PUSH TOKEN] Error: \(error.localizedDescription)")
        print("========================================")
        MobileCore.setPushIdentifier(nil)
    }
    
    // MARK: - Handle Push Notification Reception
    // Delegate method that tells the app that a remote notification arrived that indicates there is data to be fetched.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("========================================")
        print("🔔 [SILENT NOTIFICATION] Received silent notification")
        print("📦 [SILENT NOTIFICATION] Full Payload:")
        print(userInfo)
        print("========================================")
        completionHandler(.noData)
    }
    

    // Delegate method to handle a notification that arrived while the app was running in the foreground.
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("========================================")
        print("🔔 [FOREGROUND NOTIFICATION] Notification arrived while app in FOREGROUND")
        print("========================================")
        
        let userInfo = notification.request.content.userInfo
        let title = notification.request.content.title
        let body = notification.request.content.body
        let categoryIdentifier = notification.request.content.categoryIdentifier
        
        print("📝 [FOREGROUND NOTIFICATION] Title: \(title)")
        print("📝 [FOREGROUND NOTIFICATION] Body: \(body)")
        print("📂 [FOREGROUND NOTIFICATION] Category Identifier: '\(categoryIdentifier)'")
        print("")
        
        // Verify category is present and valid
        if categoryIdentifier.isEmpty {
            print("⚠️⚠️⚠️ [FOREGROUND NOTIFICATION] WARNING: Category is EMPTY! ⚠️⚠️⚠️")
            print("❌ [FOREGROUND NOTIFICATION] Action buttons will NOT appear without a category")
            print("💡 [FOREGROUND NOTIFICATION] Make sure AJO sends 'category' field in aps payload")
        } else if categoryIdentifier == "TRACKABLE_CATEGORY" {
            print("✅ [FOREGROUND NOTIFICATION] Correct category: TRACKABLE_CATEGORY")
            print("📱 [FOREGROUND NOTIFICATION] Users should see: Accept & Dismiss buttons")
        } else if categoryIdentifier == "FULL_TRACKING_CATEGORY" {
            print("✅ [FOREGROUND NOTIFICATION] Correct category: FULL_TRACKING_CATEGORY")
            print("📱 [FOREGROUND NOTIFICATION] Users should see: Accept, Decline & Dismiss buttons")
        } else {
            print("⚠️ [FOREGROUND NOTIFICATION] Unknown category: '\(categoryIdentifier)'")
            print("❌ [FOREGROUND NOTIFICATION] This category is not registered in the app")
        }
        print("")
        
        print("📦 [FOREGROUND NOTIFICATION] Full Payload:")
        print(userInfo)
        print("")
        
        if let xdm = userInfo["_xdm"] as? [String: Any] {
            print("✅ [FOREGROUND NOTIFICATION] _xdm data found:")
            print(xdm)
        } else if let xdmString = userInfo["_xdm"] as? String {
            print("⚠️ [FOREGROUND NOTIFICATION] _xdm is a STRING (should be dictionary):")
            print(xdmString)
        } else {
            print("❌ [FOREGROUND NOTIFICATION] No _xdm data found in payload")
        }
        print("========================================")
        
        completionHandler([.alert, .sound, .badge])
    }

    // Delegate method is called when a notification is interacted with
    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("========================================")
        print("🔔 [NOTIFICATION INTERACTION] User interacted with notification")
        print("========================================")
        
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        let notificationId = response.notification.request.identifier
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        print("📝 [NOTIFICATION INTERACTION] Title: \(title)")
        print("📝 [NOTIFICATION INTERACTION] Body: \(body)")
        print("🆔 [NOTIFICATION INTERACTION] Notification ID: \(notificationId)")
        print("📂 [NOTIFICATION INTERACTION] Category Identifier: '\(categoryIdentifier)'")
        print("👆 [NOTIFICATION INTERACTION] Action Identifier: \(actionIdentifier)")
        print("")
        
        // Verify category
        if categoryIdentifier.isEmpty {
            print("⚠️⚠️⚠️ [NOTIFICATION INTERACTION] WARNING: No category in notification! ⚠️⚠️⚠️")
            print("❌ [NOTIFICATION INTERACTION] AJO did not send the category field")
            print("💡 [NOTIFICATION INTERACTION] Check AJO configuration: iOS category field must be set")
        } else if categoryIdentifier == "TRACKABLE_CATEGORY" {
            print("✅ [NOTIFICATION INTERACTION] Verified category: TRACKABLE_CATEGORY ✅")
            print("📱 [NOTIFICATION INTERACTION] Expected buttons: Accept & Dismiss")
        } else if categoryIdentifier == "FULL_TRACKING_CATEGORY" {
            print("✅ [NOTIFICATION INTERACTION] Verified category: FULL_TRACKING_CATEGORY ✅")
            print("📱 [NOTIFICATION INTERACTION] Expected buttons: Accept, Decline & Dismiss")
        } else {
            print("⚠️ [NOTIFICATION INTERACTION] Unknown category: '\(categoryIdentifier)'")
            print("❌ [NOTIFICATION INTERACTION] This category is NOT registered in the app")
            print("💡 [NOTIFICATION INTERACTION] Only TRACKABLE_CATEGORY and FULL_TRACKING_CATEGORY are supported")
        }
        print("")
        
        print("📦 [NOTIFICATION INTERACTION] Full Payload:")
        print(userInfo)
        print("")
        
        // Check for _xdm data
        if let xdm = userInfo["_xdm"] as? [String: Any] {
            print("✅ [NOTIFICATION INTERACTION] _xdm data found (Dictionary):")
            print(xdm)
            
            // Check for specific XDM fields
            if let mixins = xdm["mixins"] as? [String: Any] {
                print("✅ [NOTIFICATION INTERACTION] XDM has 'mixins' structure")
            } else if let cjm = xdm["cjm"] as? [String: Any] {
                print("✅ [NOTIFICATION INTERACTION] XDM has 'cjm' structure")
            }
        } else if let xdmString = userInfo["_xdm"] as? String {
            print("⚠️ [NOTIFICATION INTERACTION] _xdm is a STRING (should be dictionary):")
            print(xdmString)
            print("❌ [NOTIFICATION INTERACTION] Tracking will NOT work - _xdm must be a dictionary")
        } else {
            print("❌ [NOTIFICATION INTERACTION] No _xdm data found in payload")
            print("❌ [NOTIFICATION INTERACTION] Tracking will NOT work")
        }
        print("")
        
        // Determine action type
        let actionType: String
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            actionType = "DEFAULT (Tapped notification body)"
        case UNNotificationDismissActionIdentifier:
            actionType = "SYSTEM DISMISS (Cleared notification - iOS limitation)"
        case "ACCEPT_ACTION":
            actionType = "ACCEPT (Custom action - opens app)"
        case "DECLINE_ACTION":
            actionType = "DECLINE (Custom action - opens app)"
        case "Dismiss":
            actionType = "DISMISS (Custom action - no app open)"
        default:
            actionType = "CUSTOM: \(actionIdentifier)"
        }
        print("🎯 [NOTIFICATION INTERACTION] Action Type: \(actionType)")
        print("")
        
        // Call Messaging SDK
        print("📞 [NOTIFICATION INTERACTION] Calling Messaging.handleNotificationResponse()...")
        Messaging.handleNotificationResponse(response) { trackingStatus in
            print("========================================")
            print("📊 [TRACKING STATUS] Received tracking status")
            print("📊 [TRACKING STATUS] Status: \(trackingStatus)")
            
            switch trackingStatus {
            case .trackingInitiated:
                print("✅ [TRACKING STATUS] Tracking initiated successfully!")
            case .noTrackingData:
                print("❌ [TRACKING STATUS] No tracking data (_xdm missing or empty)")
            case .noDatasetConfigured:
                print("❌ [TRACKING STATUS] No dataset configured in SDK")
            case .unknownError:
                print("❌ [TRACKING STATUS] Unknown error occurred")
            @unknown default:
                print("⚠️ [TRACKING STATUS] Unknown status: \(trackingStatus)")
            }
            print("========================================")
        }

        // Always call the completion handler when done.
        completionHandler()
    }
}
