//
//  SkyGazerApp.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 30..
//

import SwiftUI
import CoreData

@main
struct SkyGazerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
