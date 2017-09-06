//
//  ViewController.swift
//  ARShooter
//
//  Created by Jordan Russell Weatherford on 8/17/17.
//  Copyright © 2017 Jordan Weatherford. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var score = 0
    var scoreLabel = UILabel()
    var timer = Timer()
    var timerLabel = UILabel()
    var seconds = 0
    var minutes = 0
    var origin = SCNMatrix4()
    var fireButton = UIButton()
    var targetButton = UIButton()
    var timerRunning = false
    var gameOverLabel = UILabel()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        addFireButton()
        addTargetButton()
        addScoreLabel()
        addTimerLabel()
        addGameOverLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureScene()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func addGameOverLabel() {
        let midX = self.sceneView.bounds.midX
        let midY = self.sceneView.bounds.midY
        let frame = CGRect(x: midX - 125, y: midY - 25, width: 250, height: 50)
        gameOverLabel.frame = frame
        gameOverLabel.text = "Game Over"
        gameOverLabel.textColor = UIColor.red
        gameOverLabel.font = gameOverLabel.font.withSize(50)
        gameOverLabel.isHidden = true
        
        self.sceneView.addSubview(gameOverLabel)
    }
    
    func addFireButton() {
        let screenHeight = self.sceneView.bounds.height
        let screenWidth = self.sceneView.bounds.width
        let frame = CGRect(x: (screenWidth / 2) - 25, y: (screenHeight - 75), width: 50, height: 50)
        fireButton = UIButton(frame: frame)
        
        fireButton.layer.cornerRadius = 25
        fireButton.backgroundColor = UIColor.red
        fireButton.addTarget(self, action: #selector(fireBullet), for: .touchDown)
        fireButton.isHidden = true
        
        self.sceneView.addSubview(fireButton)
    }
    
    func addTargetButton() {
        let screenHeight = self.sceneView.bounds.height
        let screenWidth = self.sceneView.bounds.width
        let frame = CGRect(x: (screenWidth / 2) - 25, y: (screenHeight - 75), width: 50, height: 50)
        targetButton = UIButton(frame: frame)
        
        targetButton.layer.cornerRadius = 25
        targetButton.backgroundColor = UIColor.blue
        targetButton.addTarget(self, action: #selector(addTarget), for: .touchUpInside)
        
        self.sceneView.addSubview(targetButton)
    }
    
    func addScoreLabel() {
        let screenWidth = self.sceneView.bounds.width
        let frame = CGRect(x: (screenWidth / 2) - 60, y: 20, width: 120, height: 80)
        
        self.scoreLabel.frame = frame
        self.scoreLabel.text = "\(self.score)"
        self.scoreLabel.textAlignment = .center
        self.scoreLabel.textColor = UIColor.white
        
        self.scoreLabel.font = UIFont.boldSystemFont(ofSize: 50)
        
        self.sceneView.addSubview(self.scoreLabel)
    }
    
    func addTimerLabel() {
        let screenWidth = self.sceneView.bounds.width
        let frame = CGRect(x: screenWidth - 100, y: 20, width: 75, height: 30)
        
        self.timerLabel.frame = frame
        self.timerLabel.textAlignment = .center
        self.timerLabel.textColor = UIColor.white
        self.timerLabel.layer.cornerRadius = 15
        self.timerLabel.text = "00:00"
        
        self.sceneView.addSubview(self.timerLabel)
    }
    
    
    @objc func fireBullet() {
        // assure they have bullets / time
        if !(self.score > 0) {
            return
        }
        
        
        //  subtract 1 from score for bullet
        self.score -= 1
        self.scoreLabel.text = "\(self.score)"
        
        //  set timerLabel text color
        if (self.score == 0) {
            self.timerLabel.textColor = UIColor.green
        } else {
            self.timerLabel.textColor = UIColor.white
        }
        
        //  set score label color
        if (self.score > 9) {
            self.scoreLabel.textColor = UIColor.white
        }
        
        if (self.score < 10 && self.score > 3) {
            self.scoreLabel.textColor = UIColor.orange
        }
        
        if (self.score < 4) {
            self.scoreLabel.textColor = UIColor.red
        }
        
        // create bullet node
        let radius = CGFloat(0.004)
        let shape = SCNSphere(radius: radius)
        let node = SCNNode(geometry: shape)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        
        // add physics
        let physicsShape = SCNPhysicsShape(geometry: node.geometry!, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.isAffectedByGravity = false
        
        
        // bitmask stuff that I don't quite understand
        physicsBody.categoryBitMask = 1
        physicsBody.collisionBitMask = 1
        physicsBody.contactTestBitMask = 1
        
        // set physics body
        node.physicsBody = physicsBody
        
        
        
        // get current position and set node in front of camera
        if let camera = self.sceneView.pointOfView {
            let position = SCNVector3Make(0, 0, -0.1)
            
            node.position = camera.convertPosition(position, to: nil)
            node.rotation = camera.rotation
        }
        
        let (direction, position) = self.getUserVector()
        node.position = position
        
        let bulletDirection = direction
        node.physicsBody?.applyForce(bulletDirection, asImpulse: true)
        
        
        // remove action
        let removeAction = SCNAction.removeFromParentNode()
        let timer = SCNAction.wait(duration: 5.0)
        let sequenceOfActions = SCNAction.sequence([timer, removeAction])
        node.runAction(sequenceOfActions)
        
        
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    @objc func addTarget() {
        self.gameOverLabel.isHidden = true
        self.timerLabel.textColor = UIColor.white
        self.scoreLabel.textColor = UIColor.white
        self.timerRunning = false
        
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
        
        self.score = 10
        self.scoreLabel.text = "\(self.score)"
        self.seconds = 0
        self.minutes = 0
        self.timerLabel.text = "00:00"
        let shape = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let bigNode = SCNNode(geometry: shape)
        
        bigNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        bigNode.geometry?.firstMaterial?.isDoubleSided = true
        
        
        
        if let userPos = self.sceneView.pointOfView?.transform {
            bigNode.transform = userPos
            let translation = SCNVector3Make(0, 0, -0.7)
            bigNode.localTranslate(by: translation)
        }
        
        let physicsBodyShape = SCNPhysicsShape(geometry: shape, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsBodyShape)
        
        physicsBody.isAffectedByGravity = false
        bigNode.physicsBody = physicsBody
        
        // set origin variable
        self.origin = bigNode.transform
        
        self.sceneView.scene.rootNode.addChildNode(bigNode)
        self.fireButton.isHidden = false
        self.targetButton.isHidden = true
    }
    
    
    // helper function
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    
    func setupScene() {
        self.sceneView.delegate = self
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
        
        //  debugging stats
//        self.sceneView.showsStatistics = true
//        self.sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
    }
    
    func configureScene() {
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        // not sure
        configuration.worldAlignment = .gravityAndHeading
        
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    
    @objc func updateTime() {
        if (self.score <= 0) {
            // game over
            //update ui
            DispatchQueue.main.async {
                self.gameOverLabel.isHidden = false
                self.fireButton.isHidden = true
                self.targetButton.isHidden = false
            }
            
            self.timer.invalidate()
            self.timerRunning = false
            
        // increment time, score, update ui accordingly
        } else {
            self.score -= 1
            self.scoreLabel.text = "\(self.score)"
            
            if (self.seconds < 59) {
                self.seconds += 1
            } else {
                self.minutes += 1
                self.seconds = 0
            }
            
            
            //  format timer label and set text
            if (self.minutes < 1) {
                if (self.seconds < 10) {
                    self.timerLabel.text = "0\(self.minutes):0\(self.seconds)"
                } else {
                    self.timerLabel.text = "0\(self.minutes):\(self.seconds)"
                }
            } else {
                if (self.seconds < 10) {
                    self.timerLabel.text = "\(self.minutes):0\(self.seconds)"
                } else {
                    self.timerLabel.text = "\(self.minutes):\(self.seconds)"
                }
            }
            
            //  set timerLabel text color
            if (self.score == 0) {
                self.timerLabel.textColor = UIColor.green
            } else {
                self.timerLabel.textColor = UIColor.white
            }
            
            //  set score label color
            if (self.score > 9) {
                self.scoreLabel.textColor = UIColor.white
            }
                
            if (self.score < 10 && self.score > 3) {
                self.scoreLabel.textColor = UIColor.orange
            }
            
            if (self.score < 4) {
                self.scoreLabel.textColor = UIColor.red
            }
        }
    }
    
    
    // collision detection
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // do nothing if the game has already ended
        DispatchQueue.main.async {
            if (!self.scoreLabel.isHidden) {
                return
            }
        }
        
        // start timer meow
        if (!self.timerRunning) {
            DispatchQueue.main.async {
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.updateTime), userInfo: nil, repeats: true)
                self.timerRunning = true
            }
        }
        
        self.score += 3
        
        DispatchQueue.main.async {
            self.scoreLabel.text = "\(self.score)"
        }
        // turn green to indicate a hit
        contact.nodeA.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        
        
        // add new target at random position
        let shape = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let bigNode = SCNNode(geometry: shape)
        
        let matRed = SCNMaterial()
        matRed.diffuse.contents = UIColor.red
        
        let matCyan = SCNMaterial()
        matCyan.diffuse.contents = UIColor.cyan
        
        let matBlue = SCNMaterial()
        matBlue.diffuse.contents = UIColor.blue
        
        let matYellow = SCNMaterial()
        matYellow.diffuse.contents = UIColor.yellow
        
        let matPurple = SCNMaterial()
        matPurple.diffuse.contents = UIColor.purple
        
        let matOrange = SCNMaterial()
        matOrange.diffuse.contents = UIColor.orange
        
        bigNode.geometry?.materials = [matRed, matCyan, matPurple, matYellow, matOrange, matBlue]
        
        
        let randX = (Float(arc4random_uniform(21)) - 10) / 20
        let randY = (Float(arc4random_uniform(21)) - 10) / 20
        let randZ = (Float(arc4random_uniform(101)) - 50) / 100
        
        bigNode.transform = self.origin
        
        let translation = SCNVector3Make(randX, randY, randZ)
        
        bigNode.localTranslate(by: translation)
        
        
        let physicsBodyShape = SCNPhysicsShape(geometry: shape, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsBodyShape)
        
        physicsBody.isAffectedByGravity = false
        bigNode.physicsBody = physicsBody
        
        self.sceneView.scene.rootNode.addChildNode(bigNode)
        
        // delete bullet node
        contact.nodeB.removeFromParentNode()
        
        // remove action
        let removeAction = SCNAction.removeFromParentNode()
        let timer = SCNAction.wait(duration: 3.0)
        let sequenceOfActions = SCNAction.sequence([timer, removeAction])
        contact.nodeA.runAction(sequenceOfActions)
            
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
