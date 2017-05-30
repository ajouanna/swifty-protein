//
//  GameViewController.swift
//  swifty-protein
//
//  Created by Antoine JOUANNAIS on 5/26/17.
//  Copyright © 2017 Antoine JOUANNAIS. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var scnScene: SCNScene!
    var ligand: String!
    
    override func viewDidLoad() {
        print("viewDidLoad : ligand=\(self.ligand)")
        super.viewDidLoad()
        setupView()
        setupScene()
       }
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
    }

    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
    }
}
