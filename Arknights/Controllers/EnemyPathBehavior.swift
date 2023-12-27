//
//  EnemyPathBehavior.swift
//  Arknights
//
//  Created by apple on 12/24/23.
//

import Foundation

import GameplayKit

// 敌人的运动属性
class EnemyPathBehavior: GKBehavior {
    
    static func pathBehavior(forAgent agent: GKAgent, onPath path: GKPath,
                             avoidingObstacles obstacles: [GKPolygonObstacle]) -> EnemyPathBehavior {
        
        let behavior = EnemyPathBehavior()
        
        behavior.setWeight(0.5, for: GKGoal(toReachTargetSpeed: agent.maxSpeed))
        
        behavior.setWeight(1.0, for: GKGoal(toAvoid: obstacles,maxPredictionTime: 0.5))
        
        behavior.setWeight(1.0, for: GKGoal(toFollow: path,maxPredictionTime: 0.5, forward: true))
        
        behavior.setWeight(1.0, for: GKGoal(toStayOn: path, maxPredictionTime: 0.5))
        
        return behavior
        
    }
    
}

