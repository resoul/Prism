import Foundation
@_exported import PrismCore

/// A syntax and code snippet display component with monospace typography, line numbers,
/// and an integrated copy action.
///
/// Complies with strict security guidelines: renders pure text elements without evaluating
/// or executing arbitrary script or template code.
public struct CodeBlock: Component {
    public let code: String
    public let language: String?
    public let showLineNumbers: Bool
    public let onCopy: (@Sendable @MainActor () -> Void)?

    public init(
        code: String,
        language: String? = nil,
        showLineNumbers: Bool = false,
        onCopy: (@Sendable @MainActor () -> Void)? = nil
    ) {
        self.code = code
        self.language = language
        self.showLineNumbers = showLineNumbers
        self.onCopy = onCopy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight
        let lines = code.components(separatedBy: "\n")

        return VStack(alignment: .stretch, spacing: 0) {
            // Header bar (if language or copy action is present)
            if language != nil || onCopy != nil {
                HStack(alignment: .center) {
                    if let language {
                        Text(language.uppercased())
                            .font(.mono)
                            .foregroundColor(colors.mutedForeground)
                    }

                    Spacer()

                    if let onCopy {
                        Button("Copy", variant: .ghost, size: .sm, action: onCopy)
                    }
                }
                .padding(DirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .background(colors.secondary)
            }

            // Code content with optional line numbers
            HStack(alignment: .start, spacing: 12) {
                if showLineNumbers {
                    VStack(alignment: .end, spacing: 4) {
                        for i in 1...max(1, lines.count) {
                            Text("\(i)")
                                .font(.mono)
                                .foregroundColor(colors.mutedForeground)
                        }
                    }
                }

                VStack(alignment: .start, spacing: 4) {
                    for line in lines {
                        Text(line.isEmpty ? " " : line)
                            .font(.mono)
                            .foregroundColor(colors.foreground)
                    }
                }
            }
            .padding(16)
        }
        .background(colors.background)
        .sdfRoundedRect(
            cornerRadius: 8,
            borderWidth: 1,
            borderColor: colors.border,
            fill: colors.background
        )
        .accessibilityElement(label: "Code Block\(language != nil ? " in " + language! : "")", role: "code")
        .render(in: context)
    }
}
