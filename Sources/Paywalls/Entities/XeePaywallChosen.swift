//  XeePaywallChosen.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

enum XeePaywallChosen<Content: PaywallContent>: Sendable {
    case restore(Content)
    case draw(XeePaywall.Draw<Content>)
}

extension XeePaywallChosen {
    var content: Content {
        switch self {
        case let .restore(content):
            content
        case let .draw(draw):
            draw.content
        }
    }
}
