//
//  Firing.swift
//  Arknights
//
//  Created by apple on 12/24/23.
//

import SpriteKit

import GameplayKit

class FiringComponent: GKComponent {
    
    let towerType: TowerType
    
    let parentNode: SKNode
    
    var currentTarget: EnemyEntity?
    
    var timeTillNextShot: TimeInterval = 0

    init(towerType: TowerType,
         parentNode: SKNode) {
        
        self.towerType = towerType
        
        self.parentNode = parentNode
        
        super.init()
        
    }

    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) 已完成")
        
    }

    override func update(deltaTime seconds: TimeInterval) {
        
        super.update(deltaTime: seconds)
        
        guard let target = currentTarget else {
            
            return
            
        }
        
        timeTillNextShot -= seconds
        
        if timeTillNextShot > 0 {
            
            return
            
        }
        
        timeTillNextShot = towerType.fireRate
        
        let projectile = ProjectileEntity(towerType: towerType)
        
        let projectileNode = projectile.spriteComponent.node
        
        // 设置炮弹初始相对位置
        projectileNode.position = CGPoint(x: 0.0,  y: 50.0)
        
        parentNode.addChild(projectileNode)
        
        // 设置炮弹目标
        let targetNode = target.spriteComponent.node
        
        projectileNode.rotateToFaceNode(targetNode: targetNode,
                                        sourceNode: parentNode)
        
        // 设置炮弹方向
        let fireVector = CGVector(dx: targetNode.position.x - parentNode.position.x,
                                  dy: targetNode.position.y - parentNode.position.y)
        
        // 播放动画和音乐
        let soundAction = SKAction.playSoundFileNamed("\(towerType.rawValue)Fire.mp3",
                                                      waitForCompletion: false)
        
        let fireAction = SKAction.move(by: fireVector, duration: 0.4)
        
        // 击中目标后移除
        let damageAction = SKAction.run { () -> Void in
            
            target.healthComponent.takeDamage(damage: self.towerType.damage)
            
            if self.towerType.hasSlowingEffect {
                
                target.slowed(slowFactor: self.towerType.slowFactor)
                
            }
            
        }
        
        let removeAction = SKAction.run { () -> Void in
            
            projectileNode.removeFromParent()
            
        }
        
        let action = SKAction.sequence([soundAction, fireAction, damageAction, removeAction])
        
        projectileNode.run(action)
        
    }
    
}

