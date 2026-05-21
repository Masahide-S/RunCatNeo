/*
 NSImage+Extension.swift
 Model

 Created by Takuto Nakamura on 2026/05/11.
 Copyright 2026 Koyme22 (Takuto Nakamura)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import AppKit
import CoreImage.CIFilterBuiltins

extension NSImage {
    var ciImage: CIImage? {
        guard let data = tiffRepresentation else { return nil }
        return CIImage(data: data)
    }

    var plane: NSImage {
        guard let ciImage else { return self }
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    func normalize() {
        let scale = size.height / 18.0
        size = CGSize(width: size.width / scale, height: size.height / scale)
    }

    func flip() {
        let filter = CIFilter.perspectiveRotate()
        filter.inputImage = ciImage
        filter.pitch = .pi
        guard let output = filter.outputImage else { return }
        let rep = NSCIImageRep(ciImage: output)
        representations.forEach { removeRepresentation($0) }
        addRepresentation(rep)
    }
}
