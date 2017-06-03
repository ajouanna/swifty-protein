//
//  GameViewController.swift
//  swifty-protein
//
//  Created by Antoine JOUANNAIS on 5/26/17.
//  Copyright © 2017 Antoine JOUANNAIS. All rights reserved.
//

import UIKit
import SceneKit
import Foundation

// extension pour se simplifier la lecture d'une sous-chaine
extension String {

    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.characters.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.characters.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return self[startIndex ..< endIndex]
    }
}

class Atom : NSObject {
/*
     Record Format
     
     COLUMNS        DATA  TYPE    FIELD        DEFINITION
     -------------------------------------------------------------------------------------
     1 -  6        Record name   "ATOM  "
     7 - 11        Integer       serial       Atom  serial number.
     13 - 16        Atom          name         Atom name.
     17             Character     altLoc       Alternate location indicator.
     18 - 20        Residue name  resName      Residue name.
     22             Character     chainID      Chain identifier.
     23 - 26        Integer       resSeq       Residue sequence number.
     27             AChar         iCode        Code for insertion of residues.
     31 - 38        Real(8.3)     x            Orthogonal coordinates for X in Angstroms.
     39 - 46        Real(8.3)     y            Orthogonal coordinates for Y in Angstroms.
     47 - 54        Real(8.3)     z            Orthogonal coordinates for Z in Angstroms.
     55 - 60        Real(6.2)     occupancy    Occupancy.
     61 - 66        Real(6.2)     tempFactor   Temperature  factor.
     77 - 78        LString(2)    element      Element symbol, right-justified.
     79 - 80        LString(2)    charge       Charge  on the atom.
*/
    var serial : Int
    var name : String
    var chainID : Character
    var x : Float
    var y : Float
    var z : Float
    var element : String
    var color : UIColor
    
    var linkedAtoms : [Int] = []
    init(record : String) {
        // on recupere un "record" complet et on le transforme en objet
        print("init : record = \(record)")
        self.serial = Int(record.substring(from: 6, to: 10).trimmingCharacters(in: .whitespaces))!
        self.name = record.substring(from: 12, to: 15)
        self.chainID = record[21]
        self.x = Float(record.substring(from: 30, to: 37).trimmingCharacters(in: .whitespaces))!
        self.y = Float(record.substring(from: 38, to: 45).trimmingCharacters(in: .whitespaces))!
        self.z = Float(record.substring(from: 46, to: 53).trimmingCharacters(in: .whitespaces))!
        self.element = record.substring(from: 76, to: 77)
        // couleurs definies ici : https://en.wikipedia.org/wiki/CPK_coloring
        switch element {
        case " H":
            color = UIColor.white
        case " C":
            color = UIColor.black
        case " N":
            color = UIColor.blue
        case " O":
            color = UIColor.red
        case " F", "Cl":
            color = UIColor.green
        case "Br":
            color = UIColor.red
        case " I":
            color = UIColor.purple
        case "He", "Ne","Ar","Xe", "Kr":
            color = UIColor.cyan
        case " P":
            color = UIColor.orange
        case " S":
            color = UIColor.yellow
        case " B":
            color = UIColor.orange
        case "Li", "Na"," K", "Rb", "Cs", "Fr":
            color = UIColor.purple
        case "Be", "Mg", "Ca", "Sr", "Ba", "Ra":
            color = UIColor.green
        case "Ti":
            color = UIColor.darkGray
        case "Fe":
            color = UIColor.orange
        default:
            color = UIColor.magenta
        }
    }
    
    func addLink(_ atomSerial : Int) {
        self.linkedAtoms.append(atomSerial)
    }
    
    override var description : String {
        var str = "serial: \(serial), name: \(name), x: \(x), y: \(y), z: \(z), element: \(element), links: "
        for link in self.linkedAtoms {
            str += "\(link) "
        }
        return str
    }
}

class GameViewController: UIViewController {
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var ligand: String = ""
    var atoms : [Int: Atom] = [:]
    
    func addLinks(conect:String) {
        /*
         The CONECT records specify connectivity between atoms for which coordinates are supplied. The connectivity is described using the atom serial number as shown in the entry. CONECT records are mandatory for HET groups (excluding water) and for other bonds not specified in the standard residue connectivity table. These records are generated automatically.
         
         Record Format
         
         COLUMNS       DATA  TYPE      FIELD        DEFINITION
         -------------------------------------------------------------------------
         1 -  6        Record name    "CONECT"
         7 - 11       Integer        serial       Atom  serial number
         12 - 16        Integer        serial       Serial number of bonded atom
         17 - 21        Integer        serial       Serial  number of bonded atom
         22 - 26        Integer        serial       Serial number of bonded atom
         27 - 31        Integer        serial       Serial number of bonded atom
         */
        let atomSerial = Int(conect.substring(from: 6, to: 10).trimmingCharacters(in: .whitespaces))!
        let firstBondedAtom = Int(conect.substring(from: 11, to: 15).trimmingCharacters(in: .whitespaces))!
        if let atom = atoms[atomSerial] {
            atom.addLink(firstBondedAtom)
            if let secondBondedAtom = Int(conect.substring(from: 16, to: 20).trimmingCharacters(in: .whitespaces)) {
                atoms[atomSerial]?.addLink(secondBondedAtom)
            }
            if let thirdBondedAtom = Int(conect.substring(from: 21, to: 25).trimmingCharacters(in: .whitespaces)) {
                atom.addLink(thirdBondedAtom)
            }
            if let fourthBondedAtom = Int(conect.substring(from: 26, to: 30).trimmingCharacters(in: .whitespaces)) {
                atom.addLink(fourthBondedAtom)
            }
        }
        else {
            print("Bizarre, j'ai trouvé un lien pour un atom inconnu... Il est donc ignoré")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        getLigand()
       }
   

    
    func processLigandFile(_ data : String) {
        print(data)
        let records : [String] = data.components(separatedBy: "\n")
        // je recupere tous les records de type ATOM
        var searchString = "ATOM"
        let atomRecords = records.filter({ (record) -> Bool in
            let recordText: String = record
            return (recordText.range(of: searchString) != nil)
        })
        
        // on remet la liste a zero
        self.atoms = [:]
        // on charge la liste des atomes
        for atom in atomRecords {
            print("atom : \(atom)")
            let index = Int(atom.substring(from: 6, to: 10).trimmingCharacters(in: .whitespaces))!
            self.atoms[index] = Atom(record: atom)
        }
        // je recupere tous les records de type CONECT
        searchString = "CONECT"
        let conectRecords = records.filter({ (record) -> Bool in
            let recordText: String = record
            return (recordText.range(of: searchString) != nil)
        })
        for conect in conectRecords {
            print("conect : \(conect)")
            self.addLinks(conect: conect)
        }
        
        // debug
        for atom in self.atoms {
            print(atom)
        }
    }
   
    func getLigand() {
        print("getLigang \(self.ligand)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let urlString = "https://files.rcsb.org/ligands/view/\(self.ligand)_model.pdb"
        guard let requestUrl = URL(string:urlString) else {
            print("url is incorrect : \(urlString)")
            return
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let err = error {
                // DispatchQueue.main.async
                let errMsg = NSLocalizedString("Network error", comment: "An error message")
                print("\(errMsg) : \(err)")
                let alert = UIAlertController(title: "Error", message: errMsg, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Ok", style: .destructive, handler: nil)
                alert.addAction(alertAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            else if let usableData = data {
                let returnData = String(data: usableData, encoding: .utf8)
                if let resp = response as? HTTPURLResponse {
                    print("Status code de la reponse : \(resp.statusCode)")
                }
                self.processLigandFile(returnData!)
                self.displayLigands()
            }
        }
        task.resume()
    }
    
    // je veux garder la status bar pour pouvoir afficher la roue d'activité réseau
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
    }

    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
    }
    
    func setupCamera(_ position : SCNVector3) {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = position
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func displayLigands() {
        print("displayLigands")
        var cameraOn = false

        // dessiner les differents atoms
        for (_, atom) in self.atoms {
            if cameraOn == false {
                cameraOn = true
                let camPos = SCNVector3(atom.x, atom.y, 15 + atom.z)
                setupCamera(camPos)
            }
            drawAtom(atom)
        }
    }
    
    func drawAtom(_ atom : Atom) {
        let sphere = SCNSphere(radius: CGFloat(0.5))
        sphere.materials.first?.diffuse.contents = atom.color
        let sphereNode = SCNNode(geometry: sphere)
        scnScene.rootNode.addChildNode(sphereNode)
        sphereNode.position = SCNVector3(atom.x, atom.y, atom.z)
        for linked in atom.linkedAtoms {
            if let b = self.atoms[linked] {
                drawStick(node: sphereNode, a: atom, b: b)
            }
        }
    }
    
    // dessine un baton entre un atome est ceux auxquel il est lie
    func drawStick(node : SCNNode, a: Atom, b: Atom) {
        /*
        let len = sqrt(pow((b.x - a.x),2) + pow((b.y - a.y),2) + pow((b.z - a.z),2))
        let stick = SCNCylinder(radius: 0.1, height: CGFloat(len))
        let stickNode = SCNNode(geometry: stick)
        node.addChildNode(stickNode)
        stickNode.position = SCNVector3( 0, len/2, 0)
        // stickNode.orientation = SCNVector4(x: b.x - a.x, y: b.y - a.y, z: b.z - a.z, w: 0)
        */
        
    }
}
