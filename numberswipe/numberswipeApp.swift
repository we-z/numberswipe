//
//  numberswipeApp.swift
//  numberswipe
//
//  Created by Wheezy Capowdis on 8/14/24.
//

import SwiftUI

@main
struct numberswipeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .prefersPersistentSystemOverlaysHidden()
        }
    }
}

extension View {

    func prefersPersistentSystemOverlaysHidden() -> some View {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.persistentSystemOverlays(.hidden)
        } else {
            return self
        }
    }
}
