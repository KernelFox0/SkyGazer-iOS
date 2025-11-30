//
//  Home.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 24..
//

import SwiftUI

@Observable
class HomeScreenViewModel {
	let userManager = UserManager.shared
	var postManager = PostManager()
	
	var feeds: [SavedFeed] = []
	var posts: Dictionary<SavedFeed, [FeedPost]?> = [:]
	var feedScrollData: Dictionary<SavedFeed, (String?, UUID?)?> = [:]
	var scrollPosPostID: UUID?
	var selectedFeedId: Int = 0
	var endOfFeed: Bool = false
	
	// UI properties
	var showFeedPicker: Bool = false
	
	var turningPoint = CGFloat.zero
	let thresholdScrollDistance: CGFloat = 100
	
	@ObservationIgnored var reload: Bool = true
	var errorHappened: Bool = false
	var shouldScrollToPost = false
	
	@MainActor
	private func getPosts(messageManager: AppMessageManager) async {
		guard selectedFeedId < feeds.count else { return }
		
		// Get posts
		let selectedFeed = feeds[selectedFeedId]
		
		do {
			posts[selectedFeed] = try await postManager.getFeed(at: selectedFeed.uri)
		} catch {
			messageManager.error = AppError(type: .network, message: "Failed getting posts from feed \"\(selectedFeed.name)\": \(error.localizedDescription)")
		}
	}
	
	@MainActor
	func executeFirstLoad(messageManager: AppMessageManager) async {
		guard reload || errorHappened else { return } // Make sure full view data reload only happens if necessary
		
		defer {
			reload = false
		}
		
		// Make sure all related values are empty
		postManager.cursor = nil
		feeds = []
		posts = [:]
		feedScrollData = [:]
		selectedFeedId = 0
		endOfFeed = false
		errorHappened = false
		
		feeds = userManager.preferences.feeds
		
		// If feeds list is empty try retrieving again
		do {
			if feeds.isEmpty {
				try await userManager.getPreferences()
			}
		} catch {
			messageManager.error = AppError(type: .network, message: "Failed getting saved feeds: \(error.localizedDescription)")
		}
		
		guard !feeds.isEmpty else {
			errorHappened = true
			return
		}
		
		await getPosts(messageManager: messageManager)
	}
	
	@MainActor
	func loadNewFeed(messageManager: AppMessageManager, oldFeedId: Int) async {
		// Save previous feed
		
		feedScrollData[feeds[oldFeedId]] = (postManager.cursor, scrollPosPostID)
		
		endOfFeed = false
		
		// Check if posts feed was viewed
		
		let currentFeed = feeds[selectedFeedId]
		
		guard feedScrollData.keys.contains(where: { $0 == currentFeed}),
			  let data = feedScrollData[currentFeed] ?? (nil, nil),
			  posts.keys.contains(where: { $0 == currentFeed}),
			  (posts[currentFeed] ?? [])?.isEmpty == false else {
			postManager.cursor = nil // Important to reset cursor before feed switching
			await getPosts(messageManager: messageManager)
			return
		}
		
		postManager.cursor = data.0
		shouldScrollToPost = true
		scrollPosPostID = data.1
	}
	
	@MainActor
	func refreshFeed(messageManager: AppMessageManager) async {
		guard !errorHappened else { // If an error happened during initial load, pulling down to refresh should try reloading all data
			await executeFirstLoad(messageManager: messageManager)
			return
		}
		
		postManager.cursor = nil
		endOfFeed = false
		await getPosts(messageManager: messageManager)
	}
	
	@MainActor
	func loadNewPosts(messageManager: AppMessageManager) async {
		guard !endOfFeed else { return }
		
		let selectedFeed = feeds[selectedFeedId]
		
		guard let newPosts = try? await postManager.getFeed(at: selectedFeed.uri) else {
			messageManager.error = AppError(type: .network, message: "Failed getting further posts from feed \"\(selectedFeed.name)\"")
			return
		}
		
		guard !newPosts.isEmpty else {
			endOfFeed = true
			return
		}
		
		var addPosts = (posts[selectedFeed] ?? []) ?? []
		let oldCount = addPosts.count
		
		addPosts.append(contentsOf: newPosts.compactMap({ post in
			if !addPosts.contains(where: { $0.uri == post.uri }) {
				return post
			}
			return nil
		}))
		
		guard addPosts.count != oldCount else {
			endOfFeed = true
			return
		}
		
		posts[selectedFeed] = addPosts
	}
}

struct HomeScreenView: View {
	@State private var viewModel = HomeScreenViewModel()
	@Environment(AppMessageManager.self) private var messageManager
	@Environment(GlobalAppEnvironment.self) private var globalAppEnvironment
	
	var body: some View {
		NavigationStack {
			ZStack(alignment: .top) {
				feedView
				if viewModel.showFeedPicker &&
					viewModel.feeds.count > 0 &&
					!viewModel.errorHappened {
					feedPicker
				}
			}
			.animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.showFeedPicker)
			.toolbar {
				feedNavigationToolbar
			}
			.navigationTitle("Home")
			.navigationBarTitleDisplayMode(.inline)
		}
		.containerBackground(.clear, for: .navigation)
	}
	
	@ToolbarContentBuilder
	var feedNavigationToolbar: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				globalAppEnvironment.isSidebarPresented.toggle()
			} label: {
				Image(systemName: "line.3.horizontal")
			}
		}
		ToolbarItem(placement: .topBarTrailing) {
			NavigationLink {
				Text("Feeds")
			} label: {
				Image(systemName: "number")
			}
		}
	}
	
	@ViewBuilder
	private var feedPicker: some View {
		SegmentedPicker(
			values: viewModel.feeds.map { $0.name },
			selection: $viewModel.selectedFeedId
		)
		.padding(.horizontal)
		.transition(.move(edge: .top).combined(with: .opacity))
		.onChange(of: viewModel.selectedFeedId) { oldSelection, selection in
			Task {
				await viewModel.loadNewFeed(messageManager: messageManager, oldFeedId: oldSelection)
			}
		}
	}
	
	@ViewBuilder
	private var feedView: some View {
		GeometryReader { frameProxy in
			let scrollHeight = frameProxy.size.height
			ScrollViewReader { reader in
				@Bindable var viewModel = viewModel
				ScrollView {
					LazyVStack {
						postsView
					}
					.background {
						disappearingPickerController(scrollHeight)
					}
					.task {
						// Perform load feeds and contents of first feed
						await viewModel.executeFirstLoad(messageManager: messageManager)
					}
					.scrollTargetLayout()
				}
				.scrollPosition(id: $viewModel.scrollPosPostID, anchor: .top)
				.onChange(of: viewModel.scrollPosPostID) { oldValue, newValue in
					guard viewModel.shouldScrollToPost && oldValue != newValue else { return }
					
					DispatchQueue.main.async {
						if let newValue {
							reader.scrollTo(newValue, anchor: .top)
						}
						viewModel.shouldScrollToPost = false
					}
				}
			}
			.coordinateSpace(name: "feedPostsScrollView")
			.refreshable {
				await viewModel.refreshFeed(messageManager: messageManager)
			}
		}
	}
	
	@ViewBuilder
	private var postsView: some View {
		Group {
			Spacer(minLength: 65)
			if viewModel.selectedFeedId < viewModel.feeds.count,
			   let posts = viewModel.posts[viewModel.feeds[viewModel.selectedFeedId]],
			   let posts {
				if !posts.isEmpty {
					ForEach(posts, id: \.id) { post in
						PostView(post: post)
							.id(post.id)
					}
					if viewModel.endOfFeed {
						Text("End of feed")
							.padding(.vertical)
					} else {
						ProgressView()
							.padding(.vertical)
							.onAppear {
								Task {
									await viewModel.loadNewPosts(messageManager: messageManager)
								}
							}
					}
				} else if !viewModel.errorHappened {
					ContentUnavailableView("No posts here. Weird...", systemImage: "nosign")
				} else {
					ContentUnavailableView("Saved feeds appear to be empty", systemImage: "xmark.circle")
				}
			} else {
				ProgressView()
					.controlSize(.large)
			}
		}
	}
	
	@ViewBuilder
	private func disappearingPickerController(_ scrollHeight: CGFloat) -> some View {
		GeometryReader { proxy in
			let contentHeight: CGFloat = proxy.size.height
			let minY: CGFloat = max(
				min(0, proxy.frame(in: .named("feedPostsScrollView")).minY),
				scrollHeight - contentHeight
			)
			Color.clear
				.onChange(of: minY) { oldValue, newValue in
					if (viewModel.showFeedPicker && newValue > oldValue) || (!viewModel.showFeedPicker && newValue < oldValue) {
						viewModel.turningPoint = newValue
					}
					if (viewModel.showFeedPicker && (viewModel.turningPoint - newValue) > viewModel.thresholdScrollDistance) ||
						(!viewModel.showFeedPicker && (newValue - viewModel.turningPoint) > viewModel.thresholdScrollDistance) {
						viewModel.showFeedPicker = newValue > viewModel.turningPoint
					}
					if newValue == 0 && !viewModel.showFeedPicker {
						// Show picker every time top is reached so if the scroll up is not in threshold but top is reached you won't stay pickerless :3
						viewModel.showFeedPicker = true
					}
				}
		}
	}
}

#Preview {
	HomeScreenView()
}
