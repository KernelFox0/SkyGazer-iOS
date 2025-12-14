//
//  MainTabScreenView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 24..
//

import SwiftUI

struct MainTabScreenView: View {
	@State private var currentTabSelection: String = "home"
	@State private var presentPostCreatorScreen: Bool = false
	@State private var selectedDetent: PresentationDetent = .large
	
	@Environment(PreferenceManager.self) private var preferenceManager
	
	@FocusState var searchFocused
	
	var body: some View {
		TabView(selection: $currentTabSelection) {
			Tab("Home", systemImage: "house", value: "home") {
				HomeScreenView()
			}
			Tab("Chats", systemImage: "bubble.left.and.text.bubble.right", value: "chat") {
				Text("Chats tab")
			}
			Tab("Notifications", systemImage: "bell", value: "notif") {
				Text("Notifications tab")
			}
			Tab("Profile", systemImage: "person", value: "user") {
				UserScreenView(userDid: UserManager.shared.loggedInDID)
			}
			Tab("Search", systemImage: "magnifyingglass", value: "search", role: .search) {
				NavigationStack {
					Text("Search tab")
						.searchable(text: .constant(""), placement: .navigationBarDrawer, prompt: Text("Search for people, tags and posts"))
						.searchFocused($searchFocused)
				}
			}
		}
		.safeAreaInset(edge: .bottom, alignment: .trailing) {
			createPostButton
		}
		.sheet(isPresented: $presentPostCreatorScreen) {
			PostCreationScreenView()
				.presentationDetents([.large, .medium], selection: $selectedDetent)
		}
    }
	
	private var createPostButton: some View {
		Image(systemName: currentTabSelection == "chat" ? "plus.bubble" : "plus")
			.resizable()
			.aspectRatio(contentMode: .fit)
			.frame(width: 23, height: 23)
			.foregroundStyle(.white)
			.padding(17)
			.glassEffect(.regular.tint(preferenceManager.accentColor).interactive(), in: Circle())
			.contentShape(Circle())
			.padding(10)
			.padding(.bottom, 55)
			.onTapGesture {
				HapticsManager.impact(style: .medium)
				
				if currentTabSelection != "chat" {
					selectedDetent = .large
					presentPostCreatorScreen = true
				} else {
					
				}
			}
	}
}

#Preview {
    MainTabScreenView()
}
