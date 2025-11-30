//
//  UserScreenView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 09. 14..
//

import SwiftUI

@Observable
final class UserScreenViewModel {
	let userManager = UserManager.shared
	
	var user: User? = nil
	var selectedTabIndex: Int = 0
	
	@ObservationIgnored var reload: Bool = true
	
	@MainActor
	func loadUserAccount(did: String?, messageManager: AppMessageManager) async {
		guard reload && userManager.loggedInDID != nil,
			  let did else { return }
		
		do {
			user = try await userManager.getFullUser(did: did)
			reload = false
		} catch {
			messageManager.error = ActionedAppError(type: .network, message: "Failed getting profile: \(error.localizedDescription)", actionTitle: "Retry", action: {
				Task { [weak self] in
					await self?.loadUserAccount(did: did, messageManager: messageManager)
				}
			})
		}
	}
}

struct UserScreenView: View {
	let userDid: String?
	
	@State private var viewModel = UserScreenViewModel()
	@State private var showCompactUserView: Bool = false
	
	@Environment(AppMessageManager.self) private var messageManager
	
	var body: some View {
		ZStack(alignment: .top) {
			contents
			if showCompactUserView {
				@Bindable var viewModel = viewModel
				CompactProfileView(user: $viewModel.user)
					.transition(.move(edge: .top).combined(with: .opacity))
			}
		}
		.animation(.smooth, value: viewModel.selectedTabIndex)
		.animation(.bouncy, value: showCompactUserView)
		.task {
			await viewModel.loadUserAccount(did: userDid, messageManager: messageManager)
		}
		.navigationTitle((viewModel.user?.name?.isEmpty == false ? viewModel.user?.name : viewModel.user?.handle) ?? "Profile")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	var contents: some View {
		ScrollView {
			LazyVStack {
				if viewModel.user != nil {
					@Bindable var viewModel = viewModel
					ProfileView(user: $viewModel.user, selectedTabIndex: $viewModel.selectedTabIndex)
						.padding(.bottom)
						.onAppear {
							showCompactUserView = false
						}
						.onDisappear {
							showCompactUserView = true
						}
					pageView
				} else {
					ProgressView()
						.padding(.top)
				}
			}
		}
    }
	
	@ViewBuilder
	private var pageView: some View {
		Group {
			switch viewModel.selectedTabIndex {
			case 0:
				HStack {
					Spacer()
					Text("POSTS")
					Spacer()
				}
			case 1:
				HStack {
					Spacer()
					Text("REPLIES")
					Spacer()
				}
			case 2:
				HStack {
					Spacer()
					Text("MEDIA")
					Spacer()
				}
			case 3:
				HStack {
					Spacer()
					Text("VIDEOS")
					Spacer()
				}
			default:
				VStack {
					Text("How did we get here?")
					Text("Seriously. This shouldn't be visible!")
					Button("Take me back :3") {
						viewModel.selectedTabIndex = 0
					}
					.buttonStyle(.glass)
				}
			}
		}
		.frame(maxWidth: .infinity)
		.transition(.slide)
	}
}

#Preview {
	UserScreenView(userDid: nil)
}
