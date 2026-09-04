import Foundation

/// Pure deterministic flexbox layout solver supporting 1D/2D flex distribution,
/// wrapping, alignment, baseline calculations, and absolute/fixed positioning.
public enum FlexSolver {

    // MARK: - Pass 1: Measure Container

    public static func measureContainer(node: LayoutNode, constraint: SizeConstraint) -> MeasuredSize {
        let flowChildren = node.children.filter { $0.style.positionType == .flow }

        let paddingH = node.style.padding.leading + node.style.padding.trailing
        let paddingV = node.style.padding.top + node.style.padding.bottom

        let isRow = node.style.direction.isRow

        // Content space available from parent constraint
        let availableMain: Double?
        let availableCross: Double?

        if isRow {
            availableMain = constraint.width.maxAvailable.map { max(0, $0 - paddingH) }
            availableCross = constraint.height.maxAvailable.map { max(0, $0 - paddingV) }
        } else {
            availableMain = constraint.height.maxAvailable.map { max(0, $0 - paddingV) }
            availableCross = constraint.width.maxAvailable.map { max(0, $0 - paddingH) }
        }

        // Measure all flow children
        var childSizes: [MeasuredSize] = []

        for child in flowChildren {
            let childConstraint: SizeConstraint
            if isRow {
                childConstraint = SizeConstraint(
                    width: .unspecified,
                    height: availableCross.map { .atMost($0) } ?? .unspecified
                )
            } else {
                childConstraint = SizeConstraint(
                    width: availableCross.map { .atMost($0) } ?? .unspecified,
                    height: .unspecified
                )
            }
            let measured = child.measure(constraint: childConstraint)
            childSizes.append(measured)
        }

        // Measure non-flow children (absolute/fixed) with containing block bounds
        let nonFlowChildren = node.children.filter { $0.style.positionType != .flow }
        let nonFlowConstraint = SizeConstraint(
            width: availableMain.map { .atMost($0) } ?? .unspecified,
            height: availableCross.map { .atMost($0) } ?? .unspecified
        )
        for child in nonFlowChildren {
            child.measure(constraint: nonFlowConstraint)
        }

        if flowChildren.isEmpty {
            let intrinsic = MeasuredSize(width: paddingH, height: paddingV)
            return ConstraintResolver.resolveSize(style: node.style, constraint: constraint, intrinsic: intrinsic)
        }

        let gap = node.style.gap
        let crossGap = node.style.crossGap

        let contentWidth: Double
        let contentHeight: Double

        if node.style.flexWrap == .noWrap || availableMain == nil {
            // Single-line (noWrap)
            var totalMain: Double = 0
            var maxCross: Double = 0

            for (index, child) in flowChildren.enumerated() {
                let size = childSizes[index]
                let marginH = child.style.margin.leading + child.style.margin.trailing
                let marginV = child.style.margin.top + child.style.margin.bottom

                if isRow {
                    totalMain += size.width + marginH
                    maxCross = max(maxCross, size.height + marginV)
                } else {
                    totalMain += size.height + marginV
                    maxCross = max(maxCross, size.width + marginH)
                }
            }

            totalMain += max(0, Double(flowChildren.count - 1)) * gap

            if isRow {
                contentWidth = totalMain
                contentHeight = maxCross
            } else {
                contentWidth = maxCross
                contentHeight = totalMain
            }
        } else {
            // Multi-line (wrap)
            let maxLineMain = availableMain ?? Double.greatestFiniteMagnitude
            var lineMainSizes: [Double] = []
            var lineCrossSizes: [Double] = []

            var currentLineMain: Double = 0
            var currentLineCross: Double = 0
            var itemsInLine = 0

            for (index, child) in flowChildren.enumerated() {
                let size = childSizes[index]
                let marginH = child.style.margin.leading + child.style.margin.trailing
                let marginV = child.style.margin.top + child.style.margin.bottom

                let childMain = isRow ? (size.width + marginH) : (size.height + marginV)
                let childCross = isRow ? (size.height + marginV) : (size.width + marginH)

                let neededMain = itemsInLine > 0 ? (currentLineMain + gap + childMain) : childMain

                if itemsInLine > 0 && neededMain > maxLineMain {
                    // Wrap to new line
                    lineMainSizes.append(currentLineMain)
                    lineCrossSizes.append(currentLineCross)
                    currentLineMain = childMain
                    currentLineCross = childCross
                    itemsInLine = 1
                } else {
                    currentLineMain = neededMain
                    currentLineCross = max(currentLineCross, childCross)
                    itemsInLine += 1
                }
            }

            if itemsInLine > 0 {
                lineMainSizes.append(currentLineMain)
                lineCrossSizes.append(currentLineCross)
            }

            let totalWrapMain = lineMainSizes.max() ?? 0
            let totalWrapCross = lineCrossSizes.reduce(0, +) + max(0, Double(lineCrossSizes.count - 1)) * crossGap

            if isRow {
                contentWidth = totalWrapMain
                contentHeight = totalWrapCross
            } else {
                contentWidth = totalWrapCross
                contentHeight = totalWrapMain
            }
        }

        let intrinsic = MeasuredSize(width: contentWidth + paddingH, height: contentHeight + paddingV)
        return ConstraintResolver.resolveSize(style: node.style, constraint: constraint, intrinsic: intrinsic)
    }

    // MARK: - Pass 2: Top-down Layout

    public static func layoutContainer(
        node: LayoutNode,
        frame: LayoutFrame,
        roundingPolicy: PixelRoundingPolicy = PixelRoundingPolicy()
    ) {
        let paddingL = node.style.padding.leading
        let paddingT = node.style.padding.top
        let paddingR = node.style.padding.trailing
        let paddingB = node.style.padding.bottom

        let contentX = frame.origin.x + paddingL
        let contentY = frame.origin.y + paddingT
        let contentW = max(0, frame.width - paddingL - paddingR)
        let contentH = max(0, frame.height - paddingT - paddingB)

        let isRow = node.style.direction.isRow
        let contentMain = isRow ? contentW : contentH
        let contentCross = isRow ? contentH : contentW

        let flowChildren = node.children.filter { $0.style.positionType == .flow }
        let gap = node.style.gap
        let crossGap = node.style.crossGap

        // 1. Partition flow children into lines (nowrap = 1 line; wrap = multiple lines)
        var lines: [[(node: LayoutNode, baseMain: Double, baseCross: Double)]] = []

        if node.style.flexWrap == .noWrap || contentMain <= 0 {
            var singleLine: [(node: LayoutNode, baseMain: Double, baseCross: Double)] = []
            for child in flowChildren {
                let size = child.measuredSize ?? .zero
                let main = isRow ? size.width : size.height
                let cross = isRow ? size.height : size.width
                singleLine.append((child, main, cross))
            }
            if !singleLine.isEmpty {
                lines.append(singleLine)
            }
        } else {
            var currentLine: [(node: LayoutNode, baseMain: Double, baseCross: Double)] = []
            var currentMain: Double = 0

            for child in flowChildren {
                let size = child.measuredSize ?? .zero
                let main = isRow ? size.width : size.height
                let cross = isRow ? size.height : size.width

                let neededMain = currentLine.isEmpty ? main : (currentMain + gap + main)

                if !currentLine.isEmpty && neededMain > contentMain {
                    lines.append(currentLine)
                    currentLine = [(child, main, cross)]
                    currentMain = main
                } else {
                    currentLine.append((child, main, cross))
                    currentMain = neededMain
                }
            }

            if !currentLine.isEmpty {
                lines.append(currentLine)
            }
        }

        // 2. Layout each line
        var currentCrossOffset: Double = 0

        for line in lines {
            let lineItemCount = line.count
            let totalBaseMain = line.reduce(0) { $0 + $1.baseMain } + max(0, Double(lineItemCount - 1)) * gap
            let lineCrossSize = line.map { $0.baseCross }.max() ?? 0
            let effectiveLineCross = (node.style.flexWrap == .noWrap) ? max(lineCrossSize, contentCross) : lineCrossSize

            let freeSpace = contentMain - totalBaseMain

            // Grow / Shrink distribution
            var finalMainSizes: [Double] = []

            if freeSpace > 0 {
                let totalGrow = line.reduce(0) { $0 + $1.node.style.flexGrow }
                if totalGrow > 0 {
                    for item in line {
                        let growFraction = item.node.style.flexGrow / totalGrow
                        let added = freeSpace * growFraction
                        let targetMain = item.baseMain + added
                        let clamped = clampMain(item.node, value: targetMain, isRow: isRow)
                        finalMainSizes.append(clamped)
                    }
                } else {
                    finalMainSizes = line.map { $0.baseMain }
                }
            } else if freeSpace < 0 {
                let totalShrink = line.reduce(0) { $0 + ($1.node.style.flexShrink * $1.baseMain) }
                if totalShrink > 0 {
                    let overflow = -freeSpace
                    for item in line {
                        let shrinkScaled = item.node.style.flexShrink * item.baseMain
                        let reduction = overflow * (shrinkScaled / totalShrink)
                        let targetMain = max(0, item.baseMain - reduction)
                        let clamped = clampMain(item.node, value: targetMain, isRow: isRow)
                        finalMainSizes.append(clamped)
                    }
                } else {
                    finalMainSizes = line.map { $0.baseMain }
                }
            } else {
                finalMainSizes = line.map { $0.baseMain }
            }

            // JustifyContent calculation along main axis
            let finalTotalMain = finalMainSizes.reduce(0, +)
            let remainingSpace = max(0, contentMain - finalTotalMain)

            let startMainOffset: Double
            let itemSpacing: Double

            switch node.style.justifyContent {
            case .start:
                startMainOffset = 0
                itemSpacing = gap

            case .center:
                startMainOffset = remainingSpace / 2.0
                itemSpacing = gap

            case .end:
                startMainOffset = remainingSpace
                itemSpacing = gap

            case .spaceBetween:
                startMainOffset = 0
                itemSpacing = lineItemCount > 1 ? (remainingSpace / Double(lineItemCount - 1)) : 0

            case .spaceAround:
                let spacePerItem = lineItemCount > 0 ? (remainingSpace / Double(lineItemCount)) : 0
                startMainOffset = spacePerItem / 2.0
                itemSpacing = spacePerItem

            case .spaceEvenly:
                let spacePerSlot = lineItemCount > 0 ? (remainingSpace / Double(lineItemCount + 1)) : 0
                startMainOffset = spacePerSlot
                itemSpacing = spacePerSlot
            }

            // Position items in line
            var currentMainPos = startMainOffset

            for (index, item) in line.enumerated() {
                let childMainSize = finalMainSizes[index]

                // AlignItems / AlignSelf calculation along cross axis
                let effectiveAlign = item.node.style.alignSelf ?? node.style.alignItems
                let isStretch = effectiveAlign == .stretch && !hasExplicitCross(item.node.style, isRow: isRow)

                let childCrossSize: Double
                if isStretch {
                    childCrossSize = max(item.baseCross, effectiveLineCross)
                } else {
                    childCrossSize = item.baseCross
                }

                let childCrossOffset: Double
                switch effectiveAlign {
                case .start:
                    childCrossOffset = 0

                case .center:
                    childCrossOffset = (effectiveLineCross - childCrossSize) / 2.0

                case .end:
                    childCrossOffset = effectiveLineCross - childCrossSize

                case .stretch:
                    childCrossOffset = 0

                case .baseline:
                    childCrossOffset = 0 // Future baseline offset extension point
                }

                let itemX: Double
                let itemY: Double
                let itemW: Double
                let itemH: Double

                if isRow {
                    itemX = contentX + currentMainPos
                    itemY = contentY + currentCrossOffset + childCrossOffset
                    itemW = childMainSize
                    itemH = childCrossSize
                } else {
                    itemX = contentX + currentCrossOffset + childCrossOffset
                    itemY = contentY + currentMainPos
                    itemW = childCrossSize
                    itemH = childMainSize
                }

                let childFrame = LayoutFrame(x: itemX, y: itemY, width: itemW, height: itemH)
                item.node.layout(frame: childFrame, roundingPolicy: roundingPolicy)

                currentMainPos += childMainSize + itemSpacing
            }

            currentCrossOffset += lineCrossSize + crossGap
        }

        // 3. Position non-flow children (Absolute / Fixed)
        let nonFlowChildren = node.children.filter { $0.style.positionType != .flow }

        for child in nonFlowChildren {
            let containingX: Double
            let containingY: Double
            let containingW: Double
            let containingH: Double

            if child.style.positionType == .absolute {
                containingX = contentX
                containingY = contentY
                containingW = contentW
                containingH = contentH
            } else {
                // Fixed: relative to origin of host window/frame
                containingX = 0
                containingY = 0
                containingW = frame.width
                containingH = frame.height
            }

            let measured = child.measuredSize ?? .zero
            let offsets = child.style.offsets

            let itemX: Double
            let itemW: Double

            if let leading = offsets.leading, let trailing = offsets.trailing {
                itemX = containingX + leading
                itemW = max(0, containingW - leading - trailing)
            } else if let leading = offsets.leading {
                itemX = containingX + leading
                itemW = measured.width
            } else if let trailing = offsets.trailing {
                itemW = measured.width
                itemX = containingX + containingW - trailing - itemW
            } else {
                itemX = containingX
                itemW = measured.width
            }

            let itemY: Double
            let itemH: Double

            if let top = offsets.top, let bottom = offsets.bottom {
                itemY = containingY + top
                itemH = max(0, containingH - top - bottom)
            } else if let top = offsets.top {
                itemY = containingY + top
                itemH = measured.height
            } else if let bottom = offsets.bottom {
                itemH = measured.height
                itemY = containingY + containingH - bottom - itemH
            } else {
                itemY = containingY
                itemH = measured.height
            }

            let childFrame = LayoutFrame(x: itemX, y: itemY, width: itemW, height: itemH)
            child.layout(frame: childFrame, roundingPolicy: roundingPolicy)
        }
    }

    // MARK: - Helpers

    private static func clampMain(_ node: LayoutNode, value: Double, isRow: Bool) -> Double {
        var result = value
        if isRow {
            if let minW = node.style.minWidth { result = max(minW, result) }
            if let maxW = node.style.maxWidth { result = min(maxW, result) }
        } else {
            if let minH = node.style.minHeight { result = max(minH, result) }
            if let maxH = node.style.maxHeight { result = min(maxH, result) }
        }
        return max(0, result)
    }

    private static func hasExplicitCross(_ style: LayoutStyle, isRow: Bool) -> Bool {
        if isRow {
            return style.height.isFixed
        } else {
            return style.width.isFixed
        }
    }
}
