//
//  MainTabScreenView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 24..
//

import SwiftUI

struct MainTabScreenView: View {
	@FocusState var searchFocused
	
	var body: some View {
		TabView {
			Tab("Home", systemImage: "house") {
				HomeScreenView()
			}
			Tab("Chats", systemImage: "bubble.left.and.text.bubble.right") {
				Text("Chats tab")
			}
			Tab("Notifications", systemImage: "bell") {
				Text("Notifications tab")
			}
			Tab("Profile", systemImage: "person") {
				UserScreenView(userDid: UserManager.shared.loggedInDID)
			}
			Tab("Search", systemImage: "magnifyingglass", role: .search) {
				NavigationStack {
					Text("Search tab")
						.searchable(text: .constant(""), placement: .navigationBarDrawer, prompt: Text("Search for people, tags and posts"))
						.searchFocused($searchFocused)
				}
			}
		}
    }
}

#Preview {
    MainTabScreenView()
}
