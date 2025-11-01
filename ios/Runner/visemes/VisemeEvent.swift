//
//  VisemeEvent.swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//
import CoreGraphics

/// A viseme event for a blendshape-Index in a timeframe [start, end) in samples
struct VisemeEvent {
    let index: Int
    let start: Int64
    let end: Int64
    let weight: CGFloat
}
