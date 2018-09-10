//
//  AppDelegate.swift
//  wallabag
//
//  Created by maxime marinel on 19/10/2016.
//  Copyright © 2016 maxime marinel. All rights reserved.
//

import UIKit
import AlamofireNetworkActivityIndicator
import CoreSpotlight
import UserNotifications
import RealmSwift
import WallabagCommon
import WallabagKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let setting: Setting = WallabagSetting()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        configureTheme()
        configureNetworkIndicator()
        configureGA()
        configureRealm()
        handleArgs()

        /*if Setting.isWallabagConfigured(),
            let host = Setting.getHost(),
            let clientId = Setting.getClientId(),
            let clientSecret = Setting.getClientSecret(),
            let username = Setting.getUsername(),
            let password = Setting.getPassword(username: username) {
            Log("Wallabag api is configured")
            let kit = WallabagKit(host: host, clientID: clientId, clientSecret: clientSecret)
            kit.requestAuth(username: username, password: password) { auth in
                switch auth {
                case .success(let data):
                    Setting.set(token: data.accessToken)
                    Setting.set(refreshToken: data.refreshToken)
                case .error, .invalidParameter, .unexpectedError:
                    break
                }
            }
            let navController = window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "articlesNavigation") as? UINavigationController

            guard let controller = navController?.viewControllers.first as? ArticlesTableViewController else {
                fatalError("Wrong root nav controller")
            }
            controller.wallabagkit = kit
            window?.rootViewController = navController
            //UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
            requestBadge()
        }

        setupQuickAction()
 */

        return true
    }

    private func configureTheme() {
        ThemeManager.manager.apply(setting.get(for: .theme))
    }

    private func handleArgs() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("RESET_APPLICATION") {
            resetApplication()
        }
    }

    private func configureGA() {
        let gai = GAI.sharedInstance()
        _ = gai?.tracker(withTrackingId: "UA-115437094-1")
        gai?.trackUncaughtExceptions = true
    }

    private func configureRealm() {
        Log("[LOG] Realm path" + (Realm.Configuration.defaultConfiguration.fileURL?.description)!)
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { _, _ in
        })

        Realm.Configuration.defaultConfiguration = config

        do {
            _ = try Realm()
        } catch {
            fatalError("real error")
        }
    }

    private func configureNetworkIndicator() {
        NetworkActivityIndicatorManager.shared.isEnabled = true
        NetworkActivityIndicatorManager.shared.startDelay = 0.1
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard
            let mainController = window?.rootViewController! as? UINavigationController,
            let articlesTable = mainController.viewControllers.first as? ArticlesTableViewController else {
                return false
        }
        articlesTable.restoreUserActivityState(userActivity)
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        //Refresh token quick fix
        /*if Setting.isWallabagConfigured(),
            let host = Setting.getHost(),
            let clientId = Setting.getClientId(),
            let clientSecret = Setting.getClientSecret(),
            let username = Setting.getUsername(),
            let password = Setting.getPassword(username: username) {
            let kit = WallabagKit(host: host, clientID: clientId, clientSecret: clientSecret)
            kit.requestAuth(username: username, password: password) { auth in
                switch auth {
                case .success(let data):
                    Setting.set(token: data.accessToken)
                    Setting.set(refreshToken: data.refreshToken)
                case .error, .invalidParameter, .unexpectedError:
                    break
                }

            }
        }*/
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        updateBadge()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        updateBadge()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
        /*if Setting.isWallabagConfigured() {
         ArticleSync.sharedInstance.sync { state in
         if state == .finished {
         self.updateBadge()
         completionHandler(.newData)
         }
         }
         } else {
         completionHandler(.noData)
         }*/
    }

    private func requestBadge() {
        if setting.get(for: .badgeEnabled) ?? false {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
    }

    private func updateBadge() {
        /*if !Setting.isBadgeEnable() {
            UIApplication.shared.applicationIconBadgeNumber = 0
            return
        }

        let entries = try? Realm().objects(Entry.self).filter(Setting.getDefaultMode().predicate())
        UIApplication.shared.applicationIconBadgeNumber = entries?.count ?? 0*/
    }

    private func setupQuickAction() {
        /*if setting.get(for: .wallabagIsConfigured) ?? false {
            let starredAction = UIApplicationShortcutItem(type: Setting.RetrieveMode.starredArticles.rawValue, localizedTitle: Setting.RetrieveMode.starredArticles.humainReadable().localized, localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "starred"), userInfo: [:])
            let unarchivedAction = UIApplicationShortcutItem(
                type: Setting.RetrieveMode.unarchivedArticles.rawValue,
                localizedTitle: Setting.RetrieveMode.unarchivedArticles.humainReadable().localized,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(templateImageName: "unreaded"),
                userInfo: [:]
            )
            let archivedAction = UIApplicationShortcutItem(type: Setting.RetrieveMode.archivedArticles.rawValue, localizedTitle: Setting.RetrieveMode.archivedArticles.humainReadable().localized, localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "readed"), userInfo: [:])
            UIApplication.shared.shortcutItems = [unarchivedAction, archivedAction, starredAction]
        }*/
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let navController = window!.rootViewController as? UINavigationController,
            let rootController = navController.viewControllers.first as? ArticlesTableViewController else {
                return
        }
        /*if let mode = Setting.RetrieveMode(rawValue: shortcutItem.type) {
            rootController.mode = mode
        }*/
    }

    func resetApplication() {
        /*Setting.purge()
        try? Realm().write {
            try? Realm().deleteAll()
        }*/
    }
}
