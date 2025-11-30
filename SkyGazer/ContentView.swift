//
//  ContentView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 30..
//

import SwiftUI
import CoreData

@Observable
final class GlobalAppEnvironment {
	var sidebarIsOpenable: Bool = false
	var isSidebarPresented: Bool = false
	var sidebarSelectedButtonId: Int? = nil
}

struct SidebarNavigationButtonView: View {
	let name: LocalizedStringKey
	let systemImage: String
	let id: Int
	
	@Environment(GlobalAppEnvironment.self) private var globalAppEnvironment
	
	@State private var isHovered: Bool = false
	
	var body: some View {
		Button {
			globalAppEnvironment.sidebarSelectedButtonId = id
			globalAppEnvironment.isSidebarPresented = false
			isHovered = false
		} label: {
			HStack {
				Image(systemName: systemImage)
					.frame(minWidth: 40)
				Text(name)
			}
		}
		.font(.title3)
		.foregroundStyle(.primary)
		.fontWeight(.regular)
		.buttonStyle(.plain)
		.padding(.vertical, 7)
		.padding(.horizontal, 6)
		.contentShape(Capsule())
		.onHover { isHovered = $0 }
		.background {
			if isHovered {
				Capsule()
					.fill(.ultraThinMaterial)
			}
		}
	}
}

struct ContentView: View {
	@State var preferredColumn: NavigationSplitViewColumn = .detail
	@State var preferenceManager = PreferenceManager()
	@State var appMessageManager = AppMessageManager()
	@State var globalAppEnvironment = GlobalAppEnvironment()
	
	@State private var closeGestureOffset: CGFloat = 0
	
    var body: some View {
		LoadingScreen()
			.environment(preferenceManager)
			.environment(appMessageManager)
			.environment(globalAppEnvironment)
			.messageBanner(error: $appMessageManager.error, message: $appMessageManager.message)
			.simultaneousGesture(
				DragGesture()
					.onChanged{ value in
						guard globalAppEnvironment.sidebarIsOpenable else { return }
						guard value.translation.height.absoluteValue < 30 else { // Don't invoke sidebar gesture while scrolling
							withAnimation { // Reset state (this also hides sidebar when it's open and the user interacts with the content)
								closeGestureOffset = -270
							}
							globalAppEnvironment.isSidebarPresented = false
							closeGestureOffset = 0
							return
						}
						let width = value.translation.width
						globalAppEnvironment.isSidebarPresented = true
						withAnimation {
							closeGestureOffset = (-270 + width)
						}
					}
					.onEnded { value in
						guard globalAppEnvironment.sidebarIsOpenable else { return }
						if (-270 + value.translation.width) > -150 {
							withAnimation(.bouncy) {
								closeGestureOffset = 0
							}
						} else {
							withAnimation {
								closeGestureOffset = -270
							}
							globalAppEnvironment.isSidebarPresented = false
							closeGestureOffset = 0
						}
					}
			)
			.overlay(alignment: .leading) {
				if globalAppEnvironment.isSidebarPresented && globalAppEnvironment.sidebarIsOpenable {
					VStack(alignment: .leading) {
						HStack {
							Spacer()
							Button("", systemImage: "sidebar.leading") {
								globalAppEnvironment.isSidebarPresented.toggle()
							}
							.buttonStyle(.plain)
							.font(.title2)
							.padding(6)
							.padding(.vertical, 9)
						}
						ScrollView {
							VStack(alignment: .leading) {
								Text("PROFILE")
								Divider()
								SidebarNavigationButtonView(name: "Home", systemImage: "house", id: 0)
								SidebarNavigationButtonView(name: "Chats", systemImage: "bubble.left.and.text.bubble.right", id: 1)
								SidebarNavigationButtonView(name: "Notifications", systemImage: "bell", id: 2)
								SidebarNavigationButtonView(name: "Profile", systemImage: "person", id: 3)
								SidebarNavigationButtonView(name: "Explore", systemImage: "magnifyingglass", id: 4)
								SidebarNavigationButtonView(name: "Feeds", systemImage: "number", id: 5)
								SidebarNavigationButtonView(name: "Lists", systemImage: "list.bullet", id: 6)
								SidebarNavigationButtonView(name: "Saved", systemImage: "bookmark", id: 7)
								SidebarNavigationButtonView(name: "Settings", systemImage: "gearshape", id: 8)
							}
						}
						.scrollClipDisabled()
						.frame(maxHeight: .infinity, alignment: .leading)
						.padding(.horizontal, 10)
						.environment(globalAppEnvironment)
					}
					.clipShape(RoundedRectangle(cornerRadius: 28))
					.clipped()
					.frame(maxWidth: 250, maxHeight: .infinity, alignment: .leading)
					.contentShape(RoundedRectangle(cornerRadius: 28))
					.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 28))
					.padding(.leading, 2)
					.transition(.move(edge: .leading))
					.offset(x: closeGestureOffset)
					.simultaneousGesture(
						DragGesture()
							.onChanged { value in
								let width = value.translation.width
								withAnimation {
									if width > 30 {
										closeGestureOffset = 30
									} else {
										closeGestureOffset = width
									}
								}
							}
							.onEnded { value in
								if value.translation.width < -150 {
									globalAppEnvironment.isSidebarPresented = false
									closeGestureOffset = 0
								} else {
									withAnimation(.bouncy) {
										closeGestureOffset = 0
									}
								}
							}
					)
				}
			}
			.animation(.spring, value: globalAppEnvironment.isSidebarPresented)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
