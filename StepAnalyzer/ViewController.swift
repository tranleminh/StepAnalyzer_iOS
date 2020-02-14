//
//  ViewController.swift
//  StepAnalyzer
//
//  Created by Le Minh Tran on 05/02/2020.
//  Copyright © 2020 Meow. All rights reserved.
//

import UIKit
import CoreMotion
import Firebase

class ViewController: UIViewController {
    
    // MARK: - Attributes
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private var counting = false
    private let FIRST_LINE = "Date; Cadence\n"
    private let DF = DateFormatter()
    private let DF2 = DateFormatter()
    private let FILE_NAME = "Steps_"
    private var DocumentsDirectory = FileManager().urls(for:.documentDirectory, in:.userDomainMask).first!
    private let FILE_EXTENSION = ".csv"
    
    private var filename : String = ""
    private var filepath : URL!
    
    @IBOutlet weak var nbStepTV: UITextView!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var status: UITextView!
    @IBOutlet weak var cadenceTV: UITextView!
    
    // MARK: - Main functional code part
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        DF.dateFormat = "HH:mm:ss"
        
        DF2.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        
//        print(DF.string(from: Date()))
        
        setupStartBtn()
    }
    
    // MARK: - Private methods
    @objc private func startCountingSteps(button: UIButton) {
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let ref = storageRef.child("111_Minh_iPhoneX/" + filename)
        
        if !counting {
            
            filename = FILE_NAME + DF2.string(from: Date()) + FILE_EXTENSION
            filepath = self.DocumentsDirectory.appendingPathComponent(filename)
            
            do {
                try FIRST_LINE.write(to: self.filepath, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                
            }
            
            pedometer.startUpdates(from: Date()) { (data, error) in
                if let nbSteps = data?.numberOfSteps, let currentCadence = data?.currentCadence {
                    DispatchQueue.main.async {
                        let date = self.DF.string(from: Date())
                        let cadence = Double(round(1000 * Double(currentCadence))/1000)
                        self.nbStepTV.text = "Number of Steps : \(nbSteps)"
                        self.cadenceTV.text = "Current Cadence : \(cadence)"
                        let line = "\(date); \(cadence)\n"
                        print ("Line = \(line)")
                        let data = Data(line.utf8)
                        do {
                            let fileHandle = try FileHandle(forWritingTo: self.filepath)
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            fileHandle.closeFile()
                        } catch {}
                        
                        
                        /*do {
                            try line.write(to: self.filepath, atomically: true, encoding: String.Encoding.utf8)
                        } catch {
                            
                        }*/
//                        print(filename)
                    }
                }
            }
            status.text = "Status : Counter Started !"
            self.startBtn.setTitle("Stop", for: .normal)
            counting = true
        }
        else {
            
            _ = ref.putFile(from: filepath, metadata: nil) {metadata, error in
                guard metadata != nil else {
                    print(error as Any)
                    return
                }
            }
        ref.downloadURL { (url, error) in
                if let downloadURL = url, let error = error {
                    self.status.text = "File saved at \(downloadURL). Counter stopped."
                    print("OK Link")
                }
                else {
                    print("KO Link because of \(error)")
                    self.status.text = "Counter stopped."
                    return
                }
            }
            
            self.nbStepTV.text = "Number of Steps : 0"
            self.cadenceTV.text = "Current Cadence : 0"
            pedometer.stopUpdates()
            self.startBtn.setTitle("Start", for: .normal)
            counting = false
        }
    }
    
    private func setupStartBtn() {
        self.startBtn.addTarget(self, action: #selector(ViewController.startCountingSteps(button:)), for: .touchDown)
    }


}

