//
//  Extensions.swift
//  Arknights
//
//  Created by apple on 12/24/23.
//

import CoreGraphics

import simd

import SpriteKit

// 拓展点和向量
extension CGPoint {
    
    init(_ point: simd_float2) {
        
        self.init(x: CGFloat(point.x), y: CGFloat(point.y))
        
    }
    
}

extension simd_float2 {
    
    init(_ point: CGPoint) {
        
        self.init(x: Float(point.x), y: Float(point.y))
        
    }

    func distanceTo(point: simd_float2) -> Float {
        
        let xDist = self.x - point.x
        
        let yDist = self.y - point.y
        
        return sqrt((xDist * xDist) + (yDist * yDist))
        
    }
    
}

// 旋转node
extension SKNode {
    
    func rotateToFaceNode(targetNode: SKNode, sourceNode: SKNode) {
        
        print("Source position: \(sourceNode.position)")
        
        print("Target position: \(targetNode.position)")
        
        let angle = atan2(targetNode.position.y - sourceNode.position.y,
                          targetNode.position.x - sourceNode.position.x) - CGFloat(Double.pi / 2)
        
        print("Angle: \(angle)")
        
        self.run(SKAction.rotate(toAngle: angle, duration: 0))
        
    }
    
}

// 引入弧度制
let π = CGFloat(Double.pi)

public extension Int {
    
    func degreesToRadians() -> CGFloat {
        
        return CGFloat(self).degreesToRadians()
        
    }
    
}

public extension CGFloat {
    
    func degreesToRadians() -> CGFloat {
        
        return π * self / 180.0
        
    }

    func radiansToDegrees() -> CGFloat {
        
        return self * 180.0 / π
        
    }
    
}

func delay(_ delay: Double, closure: @escaping () -> ()) {
    
    let when = DispatchTime.now() + delay
    
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    
}

// 计算距离
func distanceBetween(nodeA: SKNode, nodeB: SKNode) -> CGFloat {
    
    return CGFloat(hypotf(Float(nodeB.position.x - nodeA.position.x),
                          Float(nodeB.position.y - nodeA.position.y)));
    
}

