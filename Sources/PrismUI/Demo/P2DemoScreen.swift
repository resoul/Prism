import Foundation
@_exported import PrismCore

/// Demonstration screen showcasing all Phase 05 P2 Data Display and Layout components:
/// - CodeBlock & Kbd
/// - Skeleton (with reduce motion check)
/// - Empty state
/// - Table
/// - Timeline
/// - HoverCard
/// - Accordion & Collapsible
/// - AspectRatio
public struct P2DemoScreen: Component {
    public var isHoverCardOpen: Bool
    public var expandedAccordionSections: Set<String>

    public init(
        isHoverCardOpen: Bool = false,
        expandedAccordionSections: Set<String> = ["faq-1"]
    ) {
        self.isHoverCardOpen = isHoverCardOpen
        self.expandedAccordionSections = expandedAccordionSections
    }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(alignment: .stretch, spacing: 28) {
            // Title
            VStack(alignment: .start, spacing: 4) {
                Text("Prism P2 Components Showcase")
                    .font(.heading)
                Text("Data display, feedback, layout, and disclosure primitives")
                    .font(.body)
            }

            // 1. CodeBlock & Kbd
            VStack(alignment: .start, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text("Keyboard Shortcuts:")
                        .font(.heading)
                    Kbd("⌘")
                    Kbd("K")
                    Text("to search, or")
                        .font(.body)
                    Kbd("↵")
                    Text("to submit.")
                        .font(.body)
                }

                CodeBlock(
                    code: "let view = Text(\"Hello Prism!\")\n    .font(.heading)\n    .padding(16)",
                    language: "swift",
                    showLineNumbers: true
                )
            }

            // 2. Skeleton Placeholders
            VStack(alignment: .start, spacing: 10) {
                Text("Skeleton Loaders:")
                    .font(.heading)

                HStack(alignment: .center, spacing: 12) {
                    Skeleton(shape: .circle, width: 44, height: 44)
                    VStack(alignment: .start, spacing: 6) {
                        Skeleton(shape: .rounded(radius: 4), width: 180, height: 14)
                        Skeleton(shape: .rounded(radius: 4), width: 120, height: 12)
                    }
                }
            }

            // 3. Static Table
            VStack(alignment: .start, spacing: 8) {
                Text("Static Table (Up to 1k rows):")
                    .font(.heading)

                Table(
                    columns: [
                        TableColumn(title: "Component", width: 140),
                        TableColumn(title: "Tier", width: 80),
                        TableColumn(title: "Status", width: 100)
                    ],
                    rows: [
                        TableRow(cells: ["CodeBlock", "P2", "Shipped"]),
                        TableRow(cells: ["Table", "P2", "Shipped"]),
                        TableRow(cells: ["Timeline", "P2", "Shipped"]),
                        TableRow(cells: ["Accordion", "P2", "Shipped"])
                    ]
                )
            }

            // 4. Timeline
            VStack(alignment: .start, spacing: 8) {
                Text("Timeline Progression:")
                    .font(.heading)

                Timeline(items: [
                    TimelineItem(title: "Task 16 Navigation", timestamp: "00:44", description: "Router and Scaffold merged", status: .completed),
                    TimelineItem(title: "Task 17 Metal Renderer", timestamp: "00:57", description: "SDF rect and glass shaders merged", status: .completed),
                    TimelineItem(title: "Task 18 P2 Display & Layout", timestamp: "Current", description: "Implementing P2 catalog", status: .active)
                ])
            }

            // 5. HoverCard Contextual Preview
            VStack(alignment: .start, spacing: 8) {
                Text("HoverCard Preview:")
                    .font(.heading)

                HoverCard(isOpen: isHoverCardOpen, anchor: {
                    Text("@resoul (Hover / Focus)")
                        .font(.heading)
                }, card: {
                    VStack(alignment: .start, spacing: 6) {
                        Text("Resoul — Core Contributor")
                            .font(.heading)
                        Text("Working on Prism UI and reactive data flows.")
                            .font(.body)
                    }
                })
            }

            // 6. Accordion / Collapsible
            VStack(alignment: .start, spacing: 8) {
                Text("Accordion Disclosures:")
                    .font(.heading)

                Accordion(
                    items: [
                        AccordionItem(id: "faq-1", title: "What is Prism?") {
                            Text("Prism is a cross-platform pure Swift UI library built on CALayer and Metal.")
                        },
                        AccordionItem(id: "faq-2", title: "Does it leak platform types?") {
                            Text("No. Public APIs never leak UIKit, AppKit, or SwiftUI.")
                        }
                    ],
                    mode: .single,
                    expandedIDs: Binding(
                        get: { expandedAccordionSections },
                        set: { _ in }
                    )
                )
            }

            // 7. AspectRatio Box
            VStack(alignment: .start, spacing: 8) {
                Text("Aspect Ratio Container (16:9):")
                    .font(.heading)

                AspectRatio(16.0 / 9.0) {
                    VStack(alignment: .center) {
                        Text("16:9 Frame Content")
                            .font(.heading)
                    }
                    .padding(24)
                    .background(Color(red: 0.15, green: 0.18, blue: 0.25))
                    .sdfRoundedRect(cornerRadius: 8)
                }
                .width(280)
            }

            // 8. Empty State View
            VStack(alignment: .start, spacing: 8) {
                Text("Empty State:")
                    .font(.heading)

                Empty(
                    title: "No Inactive Tasks",
                    description: "All phase components have been actively scheduled.",
                    iconName: "checkmark.circle"
                )
            }
        }
        .padding(24)
        .render(in: context)
    }
}
