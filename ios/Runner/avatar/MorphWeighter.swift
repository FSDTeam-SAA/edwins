//
//  MorphWeighter.swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//

import CoreGraphics

protocol MorphWeighter {
    var targetCount: Int { get }
    func setWeight(_ w: CGFloat, index: Int)
}
