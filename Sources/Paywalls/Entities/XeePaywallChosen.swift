// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallChosen.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.03.2024
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
