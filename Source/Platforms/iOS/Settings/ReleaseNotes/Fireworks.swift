// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

#if os(iOS)
import SwiftUI
import UIKit

// SwiftUI wrapper for CAEmitterLayer
struct FireworksView: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    
    let emitter = CAEmitterLayer()
    
    emitter.emitterPosition = CGPoint(x:UIScreen.main.bounds.width/2, y: -200)
    emitter.emitterShape = .line
    emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
    emitter.renderMode = .additive
    
    func makeEmitterCell(color: UIColor) -> CAEmitterCell {
      let cell = CAEmitterCell()
      cell.birthRate = 120
      cell.lifetime = 1.0
      cell.lifetimeRange = 5
      cell.velocity = 200
      cell.velocityRange = 50
      cell.emissionLongitude = .pi // Upward
      cell.emissionRange = .pi / 4
      cell.spin = 1
      cell.spinRange = 3
      cell.scale = 0.0001
      cell.scaleRange = 0.02
      cell.color = color.cgColor
      cell.contents = UIImage(named: "star")?.cgImage // Ensure you have a 'confetti' image in assets.
      return cell
    }
    
    // Colors for the confetti
    let colors = [UIColor.red, UIColor.green, UIColor.blue, UIColor.yellow, UIColor.purple, UIColor.orange]
    emitter.emitterCells = colors.map { color in makeEmitterCell(color: color) }
    
    view.layer.addSublayer(emitter)
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    // Update logic if needed
  }
}
#endif
