//
//  messageAIApp.swift
//  messageAI
//
//  Created by Miriam Flander on 10/20/25.
//

import SwiftUI
import SwiftData

@main
struct MessageAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let modelContainer = ModelContainerProvider.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
