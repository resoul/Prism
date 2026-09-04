import Foundation
@_exported import PrismCore

#if canImport(UIKit)
public typealias PrismHostView = HostUIView
#elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
public typealias PrismHostView = HostNSView
#endif
