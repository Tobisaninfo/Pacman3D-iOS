//
//  MainViewController.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 15.07.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {

    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = Bundle.main.url(forResource: "pacman_beginning", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        player?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        player?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
