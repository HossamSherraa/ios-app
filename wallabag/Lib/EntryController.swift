//
//  ArticleSync.swift
//  wallabag
//
//  Created by maxime marinel on 07/05/2017.
//  Copyright © 2017 maxime marinel. All rights reserved.
//

import Foundation
import CoreSpotlight
import RealmSwift
import WallabagKit
import WallabagCommon

final class EntryController {
    enum State {
        case finished, running, error
    }
    private let syncQueue = DispatchQueue(label: "fr.district-web.wallabag.articleSyncQueue", qos: .utility)
    private var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Sync operation queue"
        queue.qualityOfService = .utility
        return queue
    }()
    private let group = DispatchGroup()

    var state: State = .finished
    var pageCompleted: Int = 1
    var maxPage: Int = 1
    let wallabagKit: WallabagKitProtocol
    let setting = WallabagSetting()
    var entriesSynced: [Int] = []

    init(wallabagKit: WallabagKitProtocol) {
        self.wallabagKit = wallabagKit
    }

    func sync(completion: @escaping (State) -> Void) {
        if state == .running {
            return
        }
        state = .running

        group.enter()
        wallabagKit.entry(parameters: ["page": 1], queue: syncQueue) { response in
            switch response {
            case .success(let collection):
                self.maxPage = collection.pages
                completion(.running)
                self.handle(result: collection.items)

                if self.maxPage > 1 {
                    for page in 2...self.maxPage {
                        self.group.enter()
                        /*let syncOperation = SyncOperation(entryController: self, page: page, queue: self.syncQueue, wallabagKit: self.wallabagKit)
                        syncOperation.completionBlock = {
                            self.pageCompleted += 1
                            completion(.running)
                            self.group.leave()
                        }
                        self.operationQueue.addOperation(syncOperation)*/
                    }
                }
            case .error:
                /*if let username = self.setting.get(for: .username),
                    let password = self.setting.getPassword() {
                    self.wallabagKit.requestAuth(username: username, password: password) { response in
                        print(response)
                        completion(.finished)
                    }
                }*/
                break
            }
            self.group.leave()
        }

        group.notify(queue: syncQueue) {
            self.state = .finished
            self.pageCompleted = 1
            completion(.finished)
            if 0 != self.entriesSynced.count {
                self.purge()
            }

            self.entriesSynced = []
        }
    }

    func handle(result: [WallabagKitEntry]) {
        do {
            let realm = try Realm()
            realm.beginWrite()
            for wallabagEntry in result {
                entriesSynced.append(wallabagEntry.id)
                if let entry = realm.object(ofType: Entry.self, forPrimaryKey: wallabagEntry.id) {
                    self.update(entry: entry, from: wallabagEntry)
                } else {
                    self.insert(wallabagEntry, realm)
                }
            }
            try realm.commitWrite()
        } catch _ {

        }
    }

    private func purge() {
        do {
            let realmPurge = try Realm()
            try realmPurge.write {
                let entries = realmPurge.objects(Entry.self).filter("NOT (id IN %@)", entriesSynced)
                realmPurge.delete(entries)
            }
        } catch _ {

        }
    }

    func insert(_ wallabagEntry: WallabagKitEntry, _ realm: Realm) {
        let entry = Entry()
        Log("Insert article \(wallabagEntry.id)")
        entry.hydrate(from: wallabagEntry)
        realm.add(entry)

        let searchableItem = CSSearchableItem(uniqueIdentifier: entry.spotlightIdentifier,
                                              domainIdentifier: "entry",
                                              attributeSet: entry.searchableItemAttributeSet
        )
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { (error) -> Void in
            if error != nil {
                Log(error!.localizedDescription)
            }
        }
    }

    private func update(entry: Entry, from article: WallabagKitEntry) {
        let articleUpdatedAt = Date.fromISOString(article.updatedAt)!
        if entry.updatedAt != articleUpdatedAt {
            if articleUpdatedAt > entry.updatedAt! {
                entry.hydrate(from: article)
            } else {
                update(entry: entry)
            }
        }
    }

    /**
     * Push data to server
     */
    func update(entry: Entry) {
        let entryRef = ThreadSafeReference(to: entry)
        wallabagKit.entry(
            update: entry.id,
            parameters: [
                "archive": entry.isArchived.hashValue,
                "starred": entry.isStarred.hashValue
            ],
            queue: syncQueue) { response in
                switch response {
                case .success(let entryFromServer):
                    do {
                        let realm = try Realm()
                        if let entry = realm.resolve(entryRef) {
                            try realm.write {
                                entry.updatedAt = Date.fromISOString(entryFromServer.updatedAt)
                            }
                        }
                    } catch _ {

                    }
                case .error:
                    break
                }
        }
    }

    func delete(entry: Entry, callServer: Bool = true) {
        Log("Delete entry \(entry.id)")
        if callServer {
            wallabagKit.entry(delete: entry.id) {}
        }
        do {
            CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [entry.spotlightIdentifier], completionHandler: nil)
            let realm = try Realm()
            try realm.write {
                realm.delete(entry)
            }
        } catch _ {

        }
    }

    func add(url: URL) {
        wallabagKit.entry(add: url, queue: syncQueue) { response in
            switch response {
            case .success(let entry):
                do {
                    let realm = try Realm()
                    try realm.write {
                        self.insert(entry, realm)
                    }
                } catch _ {

                }
            case .error:
                break
            }
        }
    }
}
