//
//  Extensions.swift
//  PO2
//
//  Created by Wheezy Capowdis on 12/12/24.
//

import Foundation
import SwiftUI

let hapticManager = HapticManager.instance
let impactLight = UIImpactFeedbackGenerator(style: .light)

class HapticManager {
    static let instance = HapticManager()
    private init() {}
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) { UINotificationFeedbackGenerator().notificationOccurred(type) }
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) { UIImpactFeedbackGenerator(style: style).impactOccurred() }
}
