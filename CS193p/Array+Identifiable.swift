//
//  Array+Identifiable.swift
//  CS193p
//
//  Created by Igor Kim on 16.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import Foundation

extension Array where Element: Identifiable {
    func firstIndex(matching: Element) -> Int? {
        for index in 0..<self.count {
            if matching.id == self[index].id {
                return index
            }
        }
        return nil // TODO: bogus
    }
}
