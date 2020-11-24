//
//  PickImageView.swift
//  emojiart
//
//  Created by Igor Kim on 24.11.20.
//  Copyright © 2020 Igor Kim. All rights reserved.
//

import SwiftUI

struct PickImageView: View {
    @State private var showImagePicker = false
    @State private var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
    
    var onImageChoose: (UIImage) -> Void = {_ in }
    
    var body: some View {
        HStack {
            Button(action: {
                imagePickerSourceType = .photoLibrary
                showImagePicker = true
            }) {
                Image(systemName: "photo")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(action: {
                    imagePickerSourceType = .camera
                    showImagePicker = true
                }) {
                    Image(systemName: "camera")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                }
            }
            
            Text("\(self.imagePickerSourceType.rawValue)")
                .opacity(0.0)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                if let image = image {
                    DispatchQueue.main.async {
                        onImageChoose(image)
                    }
                }
                showImagePicker = false
            }
        }
        
    }
}
