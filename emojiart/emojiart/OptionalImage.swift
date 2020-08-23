//
//  OptionalImage.swift
//  emojiart
//
//  Created by Igor Kim on 17.08.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
