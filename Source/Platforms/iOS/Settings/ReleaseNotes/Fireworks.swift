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
    let view = UIView()
    view.backgroundColor = UIColor.clear
    
    let colors: [UIColor] = [
      .red, .green, .yellow, .purple, .orange, .cyan
    ]
    
    let screenBounds = UIScreen.main.bounds
    let deviceWidth = screenBounds.width
    let deviceHeight = screenBounds.height
    
    
    // Top row of fireworks - create three evenly spaced fireworks
    let positions = [deviceWidth/4, (deviceWidth/4)*2, (deviceWidth/4)*3]
    
    for position in positions {
      let randomColor = colors.randomElement() ?? .white
      self.createFirework(in: view, at: CGPoint(x: position, y: 50), color: randomColor)
    }

    // Create a timer to continuously generate new fireworks, the superview will
    // remove the fireworks view completely
    Timer.scheduledTimer(withTimeInterval:0.2, repeats: true) { _ in
      let randomX = CGFloat.random(in: 0...deviceWidth - 10)
      let randomY = CGFloat.random(in: 200...deviceHeight - 100)
      let randomColor = colors.randomElement() ?? .white
      
      self.createFirework(in: view, at: CGPoint(x: randomX, y: randomY), color: randomColor)
    }
    
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    // Update view if needed
  }
  
  private func createFirework(in view: UIView, at position: CGPoint, color: UIColor) {
    // Create emitter layer for firework particles
    let emitterLayer = CAEmitterLayer()
    emitterLayer.emitterPosition = position
    emitterLayer.emitterSize = CGSize(width: 5, height: 5)
    emitterLayer.emitterShape = .circle
    emitterLayer.emitterMode = .outline
    
    // Create emitter cell
    let emitterCell = CAEmitterCell()
    emitterCell.birthRate = 200
    emitterCell.lifetime = 1.5
    emitterCell.velocity = 80
    emitterCell.velocityRange = 50
    emitterCell.emissionRange = .pi * 2.5
    emitterCell.scale = 0.03
    emitterCell.scaleRange = 0.06
    emitterCell.scaleSpeed = -0.1
    //        emitterCell.alphaSpeed = -0.5
    emitterCell.color = color.cgColor
    emitterCell.contents = createParticleImage().cgImage
    
    emitterLayer.emitterCells = [emitterCell]
    view.layer.addSublayer(emitterLayer)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
      emitterLayer.removeFromSuperlayer()
    }
    
    createExplosionEffect(in: view, at: position, color: color)
  }
  
  private func createParticleImage() -> UIImage {
    let size = CGSize(width: 6, height: 6)
    let renderer = UIGraphicsImageRenderer(size: size)
    
    return renderer.image { context in
      context.cgContext.setFillColor(UIColor.white.cgColor)
      context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
    }
  }
  
  private func createExplosionEffect(in view: UIView, at position: CGPoint, color: UIColor) {
    // Create a brief flash effect
    let flashView = UIView(frame: CGRect(x: position.x - 25, y: position.y - 25, width: 15, height: 15))
    flashView.backgroundColor = color
    flashView.layer.cornerRadius = 25
    //        flashView.alpha = 0
    
    view.addSubview(flashView)
    
    UIView.animate(withDuration: 0.2, animations: {
      flashView.alpha = 1.0
      flashView.transform = CGAffineTransform(scaleX: 2, y: 2)
    }) { _ in
      UIView.animate(withDuration: 0.3, animations: {
        flashView.alpha = 0
        flashView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
      }) { _ in
        flashView.removeFromSuperview()
      }
    }
  }
}
#endif
