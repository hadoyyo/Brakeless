//
//  GameViewController.swift
//  Cars
//
//  Created by Hubert on 08/04/2025.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
   
   override func viewDidLoad() {
       super.viewDidLoad()
       
       // View
       let skView = SKView(frame: view.bounds)
       self.view = skView
       
       // Scene
       let menuScene = MenuScene(size: skView.bounds.size)
       menuScene.scaleMode = .aspectFill
       
       // Scene Presentation
       skView.presentScene(menuScene)
       
       // Debug
       skView.ignoresSiblingOrder = true
       skView.showsFPS = false
       skView.showsNodeCount = false
       skView.showsPhysics = false
   }
   
   override var shouldAutorotate: Bool {
       return false // Rotation OFF
   }
   
   override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
   }
   
   override var prefersStatusBarHidden: Bool {
       return true
   }
}
