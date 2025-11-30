//
//  LoadingScreen.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 20..
//

import SwiftUI

import Network
import CoreData

@Observable
final class NetworkAvailabilityChecker {
	var networkIsAvailable = false
	
	private let networkPathMonitor = NWPathMonitor()
	private let dispatch = DispatchQueue(label: "NWAvailable")
	
	init() {
		networkPathMonitor.pathUpdateHandler = { [weak self] path in
			self?.networkIsAvailable = path.status == .satisfied
		}
		networkPathMonitor.start(queue: dispatch)
	}
	deinit {
		networkPathMonitor.cancel()
	}
}

@Observable
class LoadingScreenViewModel {
	var networkIsNotAvailable = false
	var loginFailed: Bool = false
	var applicationLoadIsCompleted: Bool = false
	var animateFlyIn: Bool = false
	var loginPresented: Bool = false
	
	private var nwChecker = NetworkAvailabilityChecker()
	
	@MainActor
	func executeLoadTasks(accounts: [Account], viewContext: NSManagedObjectContext, preferenceManager: PreferenceManager, appMessageManager: AppMessageManager) async {
		defer {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
				self?.applicationLoadIsCompleted = true
			}
		}
		
		let accountManager = AccountManager(accounts: accounts, viewContext: viewContext)
		
		// Start loading tasks
		
		guard nwChecker.networkIsAvailable else {
			networkIsNotAvailable = true
			return
		}
		networkIsNotAvailable = false
		
		// Load account
		if let accountHandle = preferenceManager.lastLoggedInAccount,
		   let account = accountManager.getAccount(handle: accountHandle) {
			// Execute login tasks
			do {
				try await UserManager.shared.loginToAccount(handle: account.handle, pds: account.pds, preferenceManager: preferenceManager)
			} catch {
				loginFailed = true
				appMessageManager.error = (error as? AppError) ?? AppError(type: .login, localizedMessage: error.localizedDescription)
			}
		}
		else if preferenceManager.lastLoggedInAccount == nil {
			loginPresented = true
		}
	}
}

struct LoadingScreen: View {
	@Environment(PreferenceManager.self) private var preferenceManager
	@Environment(AppMessageManager.self) private var appMessageManager
	@Environment(GlobalAppEnvironment.self) private var globalAppEnvironment
	
	@State private var viewModel = LoadingScreenViewModel()
	@Namespace private var loadingScreenNamespace
	@State private var presentLoginContent: Bool = false
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \Account.handle, ascending: true)],
		animation: .default
	) private var accounts: FetchedResults<Account>
	@Environment(\.managedObjectContext) private var viewContext
	
	var body: some View {
		Group {
			viewContents
		}
		.animation(.easeOut(duration: 0.4), value: viewModel.loginPresented)
	}
	
	@ViewBuilder
	var viewContents: some View {
		if viewModel.loginPresented {
			ZStack {
				LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
					.ignoresSafeArea()
				VStack {
					HStack {
						Image(systemName: "app.grid") // Stupid placeholder
							.resizable()
							.aspectRatio(contentMode: .fill)
							.foregroundStyle(.white)
							.frame(width: presentLoginContent ? 50 : 100, height: presentLoginContent ? 50 : 100)
							.matchedGeometryEffect(id: "appIcon", in: loadingScreenNamespace)
						Text("SkyGazer")
							.font(.title)
							.fontWeight(.semibold)
							.opacity(presentLoginContent ? 1 : 0)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding()
					Spacer()
					@Bindable var viewModel = viewModel
					LoginView(presentLoginContent: $presentLoginContent, applicationLoadIsCompleted: $viewModel.applicationLoadIsCompleted, loginPresented: $viewModel.loginPresented)
						.opacity(presentLoginContent ? 1 : 0)
				}
				.onAppear {
					withAnimation(.easeOut(duration: 0.4)) {
						presentLoginContent = true
					}
				}
			}
		} else if viewModel.applicationLoadIsCompleted {
			Group {
				if viewModel.networkIsNotAvailable || viewModel.loginFailed {
					errorView
				} else {
					MainTabScreenView()
						.onAppear {
							guard !globalAppEnvironment.sidebarIsOpenable else { return }
							globalAppEnvironment.sidebarIsOpenable = true
						}
				}
			}
			.overlay { // App open animation
				loadingScreenDesign
					.onAppear {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Leave enough time for the view to load
							withAnimation(.easeOut(duration: 0.7)) {
								viewModel.animateFlyIn = true
							}
						}
					}
			}
		} else {
			loadingView
		}
    }
	
	@ViewBuilder
	var loadingView: some View {
		loadingScreenDesign
			.task {
				try? await Task.sleep(nanoseconds: 1500000000) // Leave enough time for the view to load
				await viewModel.executeLoadTasks(accounts: accounts.map { $0 }, viewContext: viewContext, preferenceManager: preferenceManager, appMessageManager: appMessageManager)
			}
	}
	
	@ViewBuilder
	var loadingScreenDesign: some View {
		ZStack {
			LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
				.ignoresSafeArea()
			VStack {
				//Image() - app icon, which doesn't exist yet
				Image(systemName: "app.grid") // Stupid placeholder
					.resizable()
					.aspectRatio(contentMode: .fill)
					.foregroundStyle(.white)
					.frame(width: 100, height: 100)
					.scaleEffect(viewModel.animateFlyIn ? 10 : 1)
					.matchedGeometryEffect(id: "appIcon", in: loadingScreenNamespace)
			}
		}
		.opacity(viewModel.animateFlyIn ? 0 : 1)
	}
	
	var errorView: some View {
		ZStack {
			LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
				.ignoresSafeArea()
			VStack {
				ContentUnavailableView(
					viewModel.networkIsNotAvailable ? "No internet connection" : "Login failed",
					systemImage: viewModel.networkIsNotAvailable ? "wifi.slash" : "person.slash"
				)
				.symbolRenderingMode(.hierarchical)
				.padding()
				GlassEffectContainer {
					Button("Retry", systemImage: "arrow.clockwise") {
						withAnimation(.easeOut(duration: 0.7)) {
							viewModel.animateFlyIn = false
						} completion: {
							viewModel.applicationLoadIsCompleted = false
						}
					}
					if viewModel.loginFailed {
						Button("Go to login", systemImage: "person.text.rectangle") {
							withAnimation(.easeOut(duration: 0.7)) {
								viewModel.animateFlyIn = false
							} completion: {
								viewModel.loginPresented = true
							}
						}
						.padding(.top)
					}
				}
				.buttonStyle(.glass)
				.font(.title3)
			}
		}
	}
}

#Preview {
    LoadingScreen()
		.environment(PreferenceManager())
		.environment(AppMessageManager())
}
