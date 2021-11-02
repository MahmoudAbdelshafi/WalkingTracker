//
//  ViewController.swift
//  WalkingTracker
//
//  Created by Mahmoud Abdelshafi on 01/11/2021.
//

import UIKit
import HealthKit
import CoreMotion

class ViewController: UIViewController {
    
    @IBOutlet weak var lastWeekStepsLbl: UILabel!
    @IBOutlet weak var currentStepsLbl: UILabel!
    
    
    let pedometerManager = PedometerManager()
    
    private var isPedometerAvailable: Bool {
        return CMPedometer.isPedometerEventTrackingAvailable() && CMPedometer.isDistanceAvailable() && CMPedometer.isStepCountingAvailable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pedometerManager.getLastWeekSteps { weeklySteps, error in
            if error != nil {
                self.lastWeekStepsLbl.text = " Last week steps: \(weeklySteps ?? 0)"
            }
        }
    }
    
    @IBAction func trackBtnPressed(_ sender: Any) {
        pedometerManager.startTrackingWalkingSteps()
        if CachingManager.trips.count != 0 {
            currentStepsLbl.text = " Current steps:  \(CachingManager.trips.count)"
        }
        
    }
}

