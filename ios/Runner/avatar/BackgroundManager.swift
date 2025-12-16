//
//  BackgroundManager.swift
//  Runner
//
//  Created by Noah Tratzsch on 19.11.25.
//


import Foundation
import UIKit
import RealityKit
import Flutter

enum AvatarBackground {

    static func attachImagePlane(
        assetOrPath: String,
        to camera: PerspectiveCamera,
        registrar: FlutterPluginRegistrar?,
        distance: Float = 5.0
    ) {
        guard let texture = loadTexture(from: assetOrPath, registrar: registrar) else {
            print("❌ BG: could not load texture")
            return
        }

        var material = UnlitMaterial()
        if #available(iOS 15.0, *) {
            material.color = .init(
                tint: .white,
                texture: .init(texture)
            )
        } else {
            // Fallback on earlier versions
        }

        // Groß genug, um das ganze View zu füllen
        let planeMesh = MeshResource.generatePlane(width: 10.0, height: 10.0)
        let plane = ModelEntity(mesh: planeMesh, materials: [material])

        // In Kamerakoordinaten: direkt vor die Kamera
        plane.position = [0, 0, -distance]      // -Z = vor der Kamera
        plane.orientation = simd_quatf()        // keine Rotation

        camera.addChild(plane)

        print("✅ BG plane attached to camera")
    }

    // MARK: - Texture Loader

    private static func loadTexture(
        from assetOrPath: String,
        registrar: FlutterPluginRegistrar?
    ) -> TextureResource? {

        // 1) Direkter Dateipfad
        if assetOrPath.hasPrefix("/") || assetOrPath.hasPrefix("file://") {
            var path = assetOrPath
            if path.hasPrefix("file://"), let url = URL(string: path) {
                path = url.path
            }
            do {
                let url = URL(fileURLWithPath: path)
                return try TextureResource.load(contentsOf: url)
            } catch {
                print("⚠️ BG: failed to load texture from file: \(error)")
            }
        }

        // 2) Flutter-Asset (flutter_assets)
        let key = registrar?.lookupKey(forAsset: assetOrPath) ?? assetOrPath
        let bundle = Bundle.main

        if let url = bundle.url(forResource: key, withExtension: nil, subdirectory: "flutter_assets")
            ?? bundle.resourceURL?
                .appendingPathComponent("flutter_assets")
                .appendingPathComponent(key) {

            do {
                return try TextureResource.load(contentsOf: url)
            } catch {
                print("⚠️ BG: failed to load texture from flutter asset url \(url): \(error)")
            }
        }

        // 3) Fallback: Asset Catalog
        if let img = UIImage(named: key),
           let cg = img.cgImage {
            do {
                if #available(iOS 15.0, *) {
                    return try TextureResource.generate(from: cg, options: .init(semantic: .color))
                } else {
                    // Fallback on earlier versions
                }
            } catch {
                print("⚠️ BG: generate texture from UIImage failed: \(error)")
            }
        }

        print("❌ BG: NO texture found for '\(assetOrPath)'")
        return nil
    }
}
