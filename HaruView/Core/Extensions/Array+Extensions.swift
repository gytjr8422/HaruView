//
//  Array+Extensions.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element {
        indices.contains(index) ? self[index] : self[0] // fallback to first color
    }
}
