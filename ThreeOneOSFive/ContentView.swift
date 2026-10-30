import SwiftUI
import UIKit

struct ContentView: View {
        @State private var showProxyKH = true
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var tabNavigation: AppTabNavigationState
    @State private var showSettings = false
    @State private var showLogs = false

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-new-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-sources-tab") {
            initialTab = 2
        } else if arguments.contains("--simulate-installed-tab")
                    || arguments.contains("--simulate-patch-tab")
                    || arguments.contains("--simulate-wallpaper-tab") {
            initialTab = 3
        } else if arguments.contains("--simulate-files-tab") {
            initialTab = 4
        } else if arguments.contains("--simulate-search-tab") {
            initialTab = 5
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
        _showSettings = State(
            initialValue: arguments.contains("--simulate-settings")
        )
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
    if showProxyKH {
        ProxyKHPanelView()
    } else {
        Group {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.installed.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.installed.rawValue) }
        }
        .onChange(of: developerModeEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }
    }
    }
    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach(featureVisibility.visibleSections) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(
                            title: language.text(section.titleKey),
                            systemImage: section.systemImage
                        )
                    }
                    .tag(section.rawValue)
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(featureVisibility.visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        Label(language.text(section.titleKey), systemImage: section.systemImage)
                            .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab ? .isSelected : []
                    )
                }
            }
            .navigationTitle("3105")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            RepositoryHomeView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .new:
            RepositoryNewView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .sources:
            RepositorySourcesView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .installed:
            PatchProjectsView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession,
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .search:
            RepositorySearchView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { tabNavigation.selectedTab },
            set: { tabNavigation.select($0) }
        )
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { tabNavigation.filesTabs },
            set: { tabNavigation.setFilesTabs($0) }
        )
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(developerModeEnabled: developerModeActive)
    }

    private var developerModeActive: Bool {
#if targetEnvironment(simulator)
        developerModeEnabled
            || ProcessInfo.processInfo.arguments.contains("--simulate-developer-mode")
            || ProcessInfo.processInfo.arguments.contains("--simulate-files-tab")
#else
        developerModeEnabled
#endif
    }

    private var selectedVisibleSection: AppSection {
        let selected = AppSection(rawValue: tabNavigation.selectedTab)
        return selected.flatMap {
            featureVisibility.isVisible($0) ? $0 : nil
        } ?? .home
    }

    private func openSettings() {
        showSettings = true
    }

    private func openLogs() {
        showLogs = true
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .new: return "tab.new"
        case .sources: return "tab.sources"
        case .installed: return "tab.installed"
        case .files: return "tab.files"
        case .search: return "tab.search"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .new: return "clock.fill"
        case .sources: return "shippingbox.fill"
        case .installed: return "tray.full.fill"
        case .files: return "folder.fill"
        case .search: return "magnifyingglass"
        }
    }
}



struct ProxyKHPanelView: View {
    @State private var selectedGame = "FFTH"
    @State private var showFunctions = false
    @State private var filesEnabled = true
    @State private var patchEnabled = true
    @State private var statusEnabled = true
    @State private var showSettings = false
    @State private var filesTabSession = FilesTabSession()

    private let blue = Color(red: 0.05, green: 0.75, blue: 0.95)
    private let background = Color(red: 0.015, green: 0.035, blue: 0.055)

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        header

                        if showFunctions {
                            functionsPage
                        } else {
                            homePage
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("KHEWIN STORE")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarLeading) {
                    if showFunctions {
                        Button {
                            withAnimation {
                                showFunctions = false
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(blue)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(blue)
                    }
                }
            }
            .toolbarBackground(background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .tint(blue)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 10) {
            AppLogo(size: 64)

            Text("KHEWIN STORE")
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(.white)

            Text("SYSTEM MODZ")
                .font(.system(size: 12, weight: .bold))
                .tracking(4)
                .foregroundStyle(blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
    }

    private var homePage: some View {
        VStack(spacing: 22) {
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 9, height: 9)

                Text("KHSTORE CORE • ONLINE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("READY")
                    .font(.caption.bold())
                    .foregroundStyle(blue)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            sectionTitle(
                "เลือกเกม",
                subtitle: "เลือกเกมเพื่อเข้าสู่หน้าฟังก์ชัน"
            )

            gameCard("FFTH", subtitle: "FREE FIRE")
            gameCard("FFMAX", subtitle: "FREE FIRE MAX")

            sectionTitle(
                "SYSTEM TOOLS",
                subtitle: "เครื่องมือเดิมของแอป"
            )

            NavigationLink {
                AppDataBrowserView(tabSession: $filesTabSession)
            } label: {
                toolButton("FILES", icon: "folder.fill")
            }
            .buttonStyle(.plain)

            NavigationLink {
                PatchProjectsView()
            } label: {
                toolButton(
                    "PATCH PROJECTS",
                    icon: "wrench.and.screwdriver.fill"
                )
            }
            .buttonStyle(.plain)

            Text("KH STORE • VERSION 1.1.5")
                .font(.caption2.bold())
                .tracking(2)
                .foregroundStyle(.gray)
                .padding(.top, 8)
        }
    }

    private var functionsPage: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(selectedGame) FUNCTIONS")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(
                    selectedGame == "FFTH"
                    ? "FREE FIRE"
                    : "FREE FIRE MAX"
                )
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            sectionTitle(
                "FUNCTIONS",
                subtitle: "เปิดหรือปิดฟังก์ชันที่ต้องการ"
            )

            VStack(spacing: 12) {
                functionToggle(
                    title: "FILE MANAGEMENT",
                    subtitle: "การเข้าถึงระบบจัดการไฟล์",
                    icon: "folder.fill",
                    isOn: $filesEnabled
                )

                functionToggle(
                    title: "PATCH PROJECTS",
                    subtitle: "การเข้าถึงระบบ Patch",
                    icon: "wrench.and.screwdriver.fill",
                    isOn: $patchEnabled
                )

                functionToggle(
                    title: "SYSTEM STATUS",
                    subtitle: "แสดงสถานะระบบ",
                    icon: "chart.bar.fill",
                    isOn: $statusEnabled
                )
            }

            sectionTitle(
                "SYSTEM TOOLS",
                subtitle: "เครื่องมือเดิมของแอป"
            )

            if filesEnabled {
                NavigationLink {
                    AppDataBrowserView(tabSession: $filesTabSession)
                } label: {
                    toolButton("FILES", icon: "folder.fill")
                }
                .buttonStyle(.plain)
            }

            if patchEnabled {
                NavigationLink {
                    PatchProjectsView()
                } label: {
                    toolButton(
                        "PATCH PROJECTS",
                        icon: "wrench.and.screwdriver.fill"
                    )
                }
                .buttonStyle(.plain)
            }

            if statusEnabled {
                Text("KHSTORE CORE • ONLINE")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(blue)
                    .padding(.vertical, 15)
            }
        }
    }

    private func gameCard(
        _ game: String,
        subtitle: String
    ) -> some View {
        Button {
            selectedGame = game
            withAnimation {
                showFunctions = true
            }
        } label: {
            HStack(spacing: 15) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(blue)
                    .frame(width: 58, height: 58)
                    .background(blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    Text(game)
                        .font(.headline.bold())
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.caption.bold())
                        .foregroundStyle(blue)

                    Text("แตะเพื่อเปิดหน้าฟังก์ชัน")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(blue)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.055))
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(blue.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }

    private func functionToggle(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(blue)
                .frame(width: 35)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(blue)
        }
        .padding(15)
        .background(Color.white.opacity(0.055))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(blue.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sectionTitle(
        _ title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(blue)
                    .frame(width: 4, height: 24)

                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Spacer()
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toolButton(
        _ title: String,
        icon: String
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .foregroundStyle(blue)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding(17)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}
