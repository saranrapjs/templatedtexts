//
//  Item.swift
//  templatedtexts
//
//  Created by Jeffrey Sisson on 8/12/24.
//

import Foundation
import SwiftData

@Model
final class TextMessage {
    var text: String
    var groupID: String?
    
    init(text: String, groupID: String?) {
        self.text = text
        self.groupID = groupID
    }
}
