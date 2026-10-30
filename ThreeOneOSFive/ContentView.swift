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
    @State private var filesEnabled = true
    @State private var patchEnabled = true
    @State private var statusEnabled = true
    @State private var showSettings = false
    @State private var filesTabSession = FilesTabSession()

    private let blue = Color(red: 0.05, green: 0.75, blue: 0.95)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.015, green: 0.035, blue: 0.055)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {

                        // HEADER
                        VStack(spacing: 10) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 48))
                                .foregroundStyle(blue)

                            Text("KHEWIN STORE • READY")
                                .font(.system(size: 25, weight: .black))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text("SYSTEM MODZ")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(4)
                                .foregroundStyle(blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 25)

                        // STATUS
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 9, height: 9)

                            Text("SECURE / KHSTORE // CORE / ONLINE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // KEY STATUS
                        VStack(alignment: .leading, spacing: 9) {
                            Text("เวลาคีย์คงเหลือ")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("(อยู่ในช่วง ปรับปรุงแอพ)")
                                .font(.subheadline)
                                .foregroundStyle(.gray)

                            Text("ACTIVE")
                                .font(.caption.bold())
                                .foregroundStyle(blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(blue.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        // GAME SELECTION
                        sectionTitle("เลือกเกม", subtitle: "เลือกเกมเพื่อจัดการไฟล์")

                        HStack(spacing: 12) {
                            gameButton("FFTH", subtitle: "FREE FIRE")
                            gameButton("FFMAX", subtitle: "FREE FIRE MAX")
                        }

                        // FUNCTIONS
                        sectionTitle(
                            "FUNCTIONS",
                            subtitle: "เปิดหรือปิดฟังก์ชันที่ต้องการ"
                        )

                        VStack(spacing: 12) {
                            functionToggle(
                                title: "FILE MANAGEMENT",
                                subtitle: "เปิดหรือปิดการเข้าถึงระบบจัดการไฟล์",
                                icon: "folder.fill",
                                isOn: $filesEnabled
                            )

                            functionToggle(
                                title: "PATCH PROJECTS",
                                subtitle: "เปิดหรือปิดการเข้าถึงระบบ Patch",
                                icon: "wrench.and.screwdriver.fill",
                                isOn: $patchEnabled
                            )

                            functionToggle(
                                title: "SYSTEM STATUS",
                                subtitle: "แสดงสถานะระบบบนหน้า HOME",
                                icon: "chart.bar.fill",
                                isOn: $statusEnabled
                            )
                        }

                        // OLD SYSTEM ACCESS
                        sectionTitle("SYSTEM TOOLS", subtitle: "เครื่องมือเดิมของแอป")

                        if filesEnabled {
                            NavigationLink {
                                AppDataBrowserView(
                                    tabSession: $filesTabSession
                                )
                            } label: {
                                toolButton("FILES", icon: "folder.fill")
                            }
                            .buttonStyle(.plain)
                        }

                        if patchEnabled {
                            NavigationLink {
                                PatchProjectsView()
                            } label: {
                                toolButton("PATCH PROJECTS", icon: "wrench.and.screwdriver.fill")
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
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("KH STORE")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
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
            .toolbarBackground(
                Color(red: 0.015, green: 0.035, blue: 0.055),
                for: .navigationBar
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .tint(blue)
        .preferredColorScheme(.dark)
    }

    // MARK: - GAME BUTTON

    private func gameButton(
        _ game: String,
        subtitle: String
    ) -> some View {
        let selected = selectedGame == game

        return Button {
            selectedGame = game
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(selected ? blue : .gray)

                Text(game)
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)

                Text(selected ? "SELECTED" : "SELECT")
                    .font(.caption.bold())
                    .foregroundStyle(selected ? blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white.opacity(0.055))
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(
                        selected ? blue : Color.white.opacity(0.12),
                        lineWidth: selected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }

    // MARK: - FUNCTION SWITCH

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

    // MARK: - SECTION TITLE

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

    // MARK: - TOOL BUTTON

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
