//
//  ArticleListView.swift
//  wallabag
//
//  Created by Marinel Maxime on 11/07/2019.
//

import RealmSwift
import SwiftUI

struct ArticleListView: View {
    @Injector var realm: Realm
    @EnvironmentObject var appSync: AppSync
    @ObservedObject var entryPublisher = EntryPublisher()

    var body: some View {
        NavigationView {
            VStack {
                RetrieveModePicker(filter: $entryPublisher.retrieveMode)
                List(entryPublisher.entries, id: \.id) { entry in
                    NavigationLink(destination: ArticleView(entry: entry)) {
                        ArticleRowView(entry: entry).contextMenu {
                            Button(action: {}, label: {
                                Text("Mark as read")
                                Image(systemName: "book")
                            })
                            Button(action: {}, label: {
                                Text("Mark as favorite")
                                Image(systemName: "star")
                            })
                            Button(action: {}, label: {
                                Text("Delete")
                                Image(systemName: "trash")
                            })
                        }
                    }
                }.onAppear(perform: entryPublisher.loadEntries)
                    .navigationBarTitle("Articles")
                    .navigationBarItems(trailing:
                        ViewBuilder.buildBlock(
                            HStack {
                                Button(
                                    action: {
                                        self.appSync.requestSync()
                                    },
                                    label: {
                                        Image(systemName: "arrow.counterclockwise")
                                    }
                                ).disabled(appSync.inProgress)
                                NavigationLink(destination: StubView(), label: { Image(systemName: "plus") })
                            }
                    ))
            }
        }
    }
}

#if DEBUG
    struct ArticleListView_Previews: PreviewProvider {
        static var previews: some View {
            ArticleListView()
        }
    }
#endif
