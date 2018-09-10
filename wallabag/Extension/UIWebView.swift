//
//  UIWebView.swift
//  wallabag
//
//  Created by maxime marinel on 11/06/2018.
//  Copyright © 2018 maxime marinel. All rights reserved.
//

import Foundation
import WallabagCommon

extension UIWebView {
    func load(entry: Entry) {
        DispatchQueue.main.async { [unowned self] in
            self.loadHTMLString(self.contentForWebView(entry), baseURL: Bundle.main.bundleURL)
        }
    }

    func contentForWebView(_ entry: Entry) -> String {
        let setting = WallabagSetting()
        do {
            let html = try String(contentsOfFile: Bundle.main.path(forResource: "article", ofType: "html")!)
            let justify = (setting.get(for: .justifyArticle) ?? false) ? "justify.css" : ""

            return String(format: html, arguments: [justify, setting.get(for: .theme) ?? "", entry.title!, entry.content!])
        } catch {
            fatalError("Unable to load article view")
        }
    }
}
