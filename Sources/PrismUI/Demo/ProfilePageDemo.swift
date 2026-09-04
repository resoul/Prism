import Foundation
import CoreGraphics
import PrismCore

/// Profile navigation tabs matching the ProfilePage prototype.
public enum ProfileTab: String, CaseIterable, TabItem {
    case posts
    case likes
    case reposts

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .posts: return "Posts"
        case .likes: return "Likes"
        case .reposts: return "Reposts"
        }
    }
}

/// Lightweight grid item representation for the demo.
public struct ProfileGridItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let imageURL: URL
    public let title: String

    public init(id: String, imageURL: URL, title: String) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
    }
}

/// Header component displaying user avatar, name, handle, bio, and follow stats.
public struct ProfileHeader: Component {
    public let name: String
    public let handle: String
    public let bio: String
    public let followersCount: String
    public let followingCount: String

    public init(
        name: String = "Tim Cook",
        handle: String = "@cooktim",
        bio: String = "Apple CEO • Prism UI Framework Integration",
        followersCount: String = "1.2M",
        followingCount: String = "42"
    ) {
        self.name = name
        self.handle = handle
        self.bio = bio
        self.followersCount = followersCount
        self.followingCount = followingCount
    }

    public func body(context: ComponentContext) -> RenderElement {
        let avatarID = ElementID(typeName: "Circle", key: "avatar")
        let avatar = RenderElement(
            id: avatarID,
            kind: .shape(.circle),
            modifiers: [
                .width(72.0),
                .height(72.0)
            ]
        )

        let nameElement = RenderElement(
            id: ElementID(typeName: "Text", key: "name"),
            kind: .text(name)
        )

        let handleElement = RenderElement(
            id: ElementID(typeName: "Text", key: "handle"),
            kind: .text(handle)
        )

        let bioElement = RenderElement(
            id: ElementID(typeName: "Text", key: "bio"),
            kind: .text(bio)
        )

        let statsText = "\(followersCount) Followers • \(followingCount) Following"
        let statsElement = RenderElement(
            id: ElementID(typeName: "Text", key: "stats"),
            kind: .text(statsText)
        )

        let headerContainerID = ElementID(typeName: "ProfileHeader", key: "container")
        return RenderElement(
            id: headerContainerID,
            kind: .stack(axis: .vertical, alignment: .start, spacing: 8.0),
            modifiers: [
                .padding(.init(top: 16, leading: 16, bottom: 12, trailing: 16)),
                .height(188.0)
            ],
            children: [avatar, nameElement, handleElement, bioElement, statsElement]
        )
    }
}

/// Helper generating synthetic paginated datasets for heavy integration benchmarks (e.g. 10,000 items).
public enum ProfileDataBenchmark {
    @MainActor
    public static func makeSyntheticStore(
        category: String,
        totalItems: Int = 10_000,
        pageSize: Int = 30
    ) -> PagedStore<ProfileGridItem, String, Int> {
        let loader = AnyPageLoader<ProfileGridItem, String, Int> { query, cursor, count in
            let startIndex = cursor ?? 0
            let endIndex = min(startIndex + count, totalItems)

            var items: [ProfileGridItem] = []
            for i in startIndex..<endIndex {
                let url = URL(string: "https://example.com/images/\(category)_\(i).jpg")!
                items.append(ProfileGridItem(
                    id: "\(category)_\(i)",
                    imageURL: url,
                    title: "\(category) #\(i)"
                ))
            }

            let nextCursor = endIndex < totalItems ? endIndex : nil
            return PageResult(items: items, nextCursor: nextCursor, totalCount: totalItems)
        }

        let store = PagedStore(
            query: category,
            loader: loader,
            pageSize: pageSize
        )
        return store
    }
}

/// Full End-to-End Collapsing Tab Pager screen implementation reproducing the ProfilePage prototype.
public struct ProfilePageDemo: Component {
    public let postsStore: PagedStore<ProfileGridItem, String, Int>
    public let likesStore: PagedStore<ProfileGridItem, String, Int>
    public let repostsStore: PagedStore<ProfileGridItem, String, Int>
    public var selectedTab: ProfileTab
    public let onTabChanged: @Sendable (ProfileTab) -> Void

    public init(
        postsStore: PagedStore<ProfileGridItem, String, Int>,
        likesStore: PagedStore<ProfileGridItem, String, Int>,
        repostsStore: PagedStore<ProfileGridItem, String, Int>,
        selectedTab: ProfileTab = .posts,
        onTabChanged: @escaping @Sendable (ProfileTab) -> Void = { _ in }
    ) {
        self.postsStore = postsStore
        self.likesStore = likesStore
        self.repostsStore = repostsStore
        self.selectedTab = selectedTab
        self.onTabChanged = onTabChanged
    }

    public func body(context: ComponentContext) -> RenderElement {
        let pager = CollapsingTabPager<ProfileTab>(
            selection: selectedTab,
            onTabSelected: onTabChanged,
            expandedHeaderHeight: 188.0,
            collapsedHeaderHeight: 0.0
        ) {
            CollapsingHeader(expandedHeight: 188.0, collapsedHeight: 0.0) {
                ProfileHeader()
            }

            PinnedTabs(
                ProfileTab.allCases,
                selection: selectedTab,
                height: 44.0,
                onSelect: onTabChanged
            )
        } pages: {
            TabPage(ProfileTab.posts) {
                renderGrid(for: postsStore, context: context)
            }
            TabPage(ProfileTab.likes) {
                renderGrid(for: likesStore, context: context)
            }
            TabPage(ProfileTab.reposts) {
                renderGrid(for: repostsStore, context: context)
            }
        }

        return pager.body(context: context)
    }

    private func renderGrid(for store: PagedStore<ProfileGridItem, String, Int>, context: ComponentContext) -> [RenderElement] {
        let items: [ProfileGridItem]
        if Thread.isMainThread {
            items = MainActor.assumeIsolated { store.items }
        } else {
            items = DispatchQueue.main.sync {
                MainActor.assumeIsolated { store.items }
            }
        }

        let grid = LazyGrid(
            columns: .fixed(3),
            data: items,
            id: \.id,
            spacing: 2.0,
            estimatedRowHeight: 120.0
        ) { item in
            Image(url: item.imageURL)
                .contentMode(.fill)
                .cornerRadius(0.0)
        }
        .prefetch(distance: 9) {
            Task { @MainActor in
                store.loadNextPage()
            }
        }

        return grid.asRenderElements(in: context)
    }
}
