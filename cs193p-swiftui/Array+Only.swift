//
//  Array+Only.swift
//  CS193p
//
//  Created by Igor Kim on 16.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import Foundation

extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
