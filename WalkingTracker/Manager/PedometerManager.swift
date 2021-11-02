//
//  PedometerManager.swift
//  WalkingTracker
//
//  Created by Mahmoud Abdelshafi on 01/11/2021.
//

import Foundation
import CoreMotion
import UIKit

class PedometerManager {
    
    // MARK: - Properties
    
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private var endDate: Date?
    private var startDate: Date?
    private let date = Date()
    private let lastWeekDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
    private var zeroSeconds = DateComponents()
    private var timer: Timer?
    private var backgroundTime: Date?
    private var currentNumberOfSteps: NSNumber = 0 {
        didSet {
            resetTimer()
        }
    }
    
    // MARK: - Init
    
    init() {
        let _ = CachingManager.sharedInstance()
        setupActivityManager()
        setupOneMinuteTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnterdBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: - Methods
    
    func getLastWeekSteps(completion: @escaping(_ weeklySteps: NSNumber?, _ error: Error?) -> ())  {
        pedometer.queryPedometerData(from: lastWeekDate ?? Date(), to: date) { data, error in
            DispatchQueue.main.async {
                completion(data?.numberOfSteps, error)
            }
        }
    }
    
    func countingSteps() {
        pedometer.startUpdates(from: date) { [weak self] (data, errors) in
            guard let self = self else { return }
            if let error = errors {
                print(error.localizedDescription)
                return
            }
            guard let data = data else { return }
            self.currentNumberOfSteps = data.numberOfSteps
            if data.numberOfSteps != 0 {
                self.countSteps(data)
            }
        }
    }
    
    func countSteps(_ data: CMPedometerData) {
        ///if user stops 1 min. Trip ended.
        if endDate?.advanced(by: TimeInterval(60)) ?? date > startDate ?? date  {
            CachingManager.trips.append(Trip(numberOfSteps: data.numberOfSteps))
        }
    }
    
    func startTrackingWalkingSteps() {
        activityManager.startActivityUpdates(to: OperationQueue.main) {
            [weak self] (activity: CMMotionActivity?) in
            guard let self = self else { return }
            guard let activity = activity else { return }
            if activity.stationary {
                self.pedometer.stopUpdates()
                self.endDate = activity.startDate
            } else if activity.walking {
                self.countingSteps()
                self.startDate = activity.startDate
            }
        }
    }
}

//MARK: - Private Methods

extension PedometerManager {
    private func setupActivityManager() {
        if CMMotionActivityManager.isActivityAvailable() && CMPedometer.authorizationStatus() == .authorized && CMPedometer.isStepCountingAvailable() {
        } else {
            print("Permission is not available")
        }
    }
    
    private func resetTimer() {
        self.timer = nil
        self.setupOneMinuteTimer()
    }
    
    private func setupOneMinuteTimer() {
        let calendar: Calendar = .current
        let seconds = calendar.component(.second, from: Date())
        timer = Timer.scheduledTimer(
            withTimeInterval: 60 - TimeInterval(seconds), repeats: true
        ) { [weak self] timer in
            CachingManager.trips.append(Trip(numberOfSteps: self?.currentNumberOfSteps ?? NSNumber()))
            self?.resetTimer()
        }
    }
    
    @objc private func handleAppEnterdBackground() {
        backgroundTime = Date()
    }
    
    @objc private func appMovedToForground() {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.month, .day, .hour, .minute, .second]
        formatter.maximumUnitCount = 2
        let diffComponents = Calendar.current.dateComponents([.month, .day, .hour, .minute, .second], from: backgroundTime ?? Date(), to: Date())
        guard let seconds = diffComponents.second else {return}
        if seconds > 60 {
            CachingManager.trips.append(Trip(numberOfSteps: self.currentNumberOfSteps))
        }
        self.backgroundTime = nil
    }
}
