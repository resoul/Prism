import Foundation
@_exported import PrismCore

/// Status of an individual milestone in a `Timeline`.
public enum TimelineStatus: Equatable, Sendable {
    case completed
    case active
    case upcoming
}

/// A milestone entry within a chronological `Timeline`.
public struct TimelineItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let timestamp: String?
    public let description: String?
    public let iconName: String?
    public let status: TimelineStatus

    public init(
        id: String = UUID().uuidString,
        title: String,
        timestamp: String? = nil,
        description: String? = nil,
        iconName: String? = nil,
        status: TimelineStatus = .completed
    ) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.description = description
        self.iconName = iconName
        self.status = status
    }
}

/// Vertical chronological progression and milestone display component.
public struct Timeline: Component {
    public let items: [TimelineItem]

    public init(items: [TimelineItem]) {
        self.items = items
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight

        return VStack(alignment: .stretch, spacing: 0) {
            for (index, item) in items.enumerated() {
                let isLast = index == items.count - 1

                HStack(alignment: .start, spacing: 16) {
                    // Marker & connecting line column
                    VStack(alignment: .center, spacing: 0) {
                        // Dot indicator
                        markerView(for: item.status, iconName: item.iconName, colors: colors)

                        // Vertical connecting line
                        if !isLast {
                            Rectangle()
                                .fill(colors.border)
                                .width(2)
                                .minHeight(36)
                        }
                    }
                    .width(24)

                    // Content column
                    VStack(alignment: .start, spacing: 4) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(item.title)
                                .font(.heading)
                                .foregroundColor(colors.foreground)

                            if let timestamp = item.timestamp {
                                Text(timestamp)
                                    .font(.mono)
                                    .foregroundColor(colors.mutedForeground)
                            }
                        }

                        if let desc = item.description {
                            Text(desc)
                                .font(.body)
                                .foregroundColor(colors.mutedForeground)
                        }

                        Spacer().height(16)
                    }
                }
                .accessibilityElement(
                    label: "Milestone: \(item.title), status \(item.status)\(item.timestamp != nil ? ", " + item.timestamp! : "")",
                    role: "group"
                )
            }
        }
        .accessibilityElement(label: "Timeline with \(items.count) milestones", role: "list")
        .render(in: context)
    }

    private func markerView(for status: TimelineStatus, iconName: String?, colors: ThemeColors) -> RenderElement {
        let dotColor: Color
        switch status {
        case .completed: dotColor = colors.primary
        case .active: dotColor = colors.primary
        case .upcoming: dotColor = colors.mutedForeground.opacity(0.4)
        }

        return Circle()
            .fill(dotColor)
            .frame(width: 12, height: 12)
            .padding(2)
    }
}
