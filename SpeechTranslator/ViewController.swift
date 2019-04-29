//
// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import UIKit
import AVFoundation
import googleapis
import MultipeerConnectivity

let SAMPLE_RATE = 16000

class ViewController : UIViewController, AudioControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var selectedLanguage: UILabel!
  @IBOutlet weak var recievedMessage: UITextView!
  @IBOutlet weak var startStream: UIButton!
  @IBOutlet weak var stopStream: UIButton!
  
  // languages to select from with language code
  let languages = ["English (United States)", "English (India)", "Hindi (India)", "French (France)", "French (Canada)", "Italian (Italy)", "Gujarati (India)"]
  let languageCodes = ["en-US", "en-IN", "hi-IN", "fr-FR", "fr-CA", "it-IT", "gu-IN"]
  // variable to store selected language code
  var selectedLanguageCode: String = "en-US"
  // ASR Message text
    var finalTranscrpition: String = ""
  // Multipeer connectivity Variables
  var hosting: Bool!
  var peerID: MCPeerID!
  var mcSession: MCSession!
  var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
  var audioData: NSMutableData!

  override func viewDidLoad() {
    super.viewDidLoad()
    AudioController.sharedInstance.delegate = self
    // Multipeer variables
    self.textView.isEditable = false
    self.recievedMessage.isEditable = false
    // Set Hosting to False initially
    self.hosting = false
    // Set Peer ID to current devices name
    self.peerID = MCPeerID(displayName: UIDevice.current.name)
    // Set MCPeer Session
    self.mcSession = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
    self.mcSession.delegate = self
    self.mcSession.disconnect()
  }

  @IBAction func recordAudio(_ sender: NSObject) {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(AVAudioSessionCategoryRecord)
    } catch {

    }
    audioData = NSMutableData()
    _ = AudioController.sharedInstance.prepare(specifiedSampleRate: SAMPLE_RATE)
    SpeechRecognitionService.sharedInstance.sampleRate = SAMPLE_RATE
    _ = AudioController.sharedInstance.start()
  }

  @IBAction func stopAudio(_ sender: NSObject) {
    _ = AudioController.sharedInstance.stop()
    SpeechRecognitionService.sharedInstance.stopStreaming()
  }

  func processSampleData(_ data: Data) -> Void {
    audioData.append(data)

    // We recommend sending samples in 100ms chunks
    let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
      * Double(SAMPLE_RATE) /* samples/second */
      * 2 /* bytes/sample */);

    if (audioData.length > chunkSize) {
      SpeechRecognitionService.sharedInstance.streamAudioData(audioData, language: self.selectedLanguageCode,
                                                              completion:
        { [weak self] (response, error) in
            guard let strongSelf = self else {
                return
            }
            
            if let error = error {
                strongSelf.textView.text = error.localizedDescription
            } else if let response = response {
                var finished = false
                print(response)
                for result in response.resultsArray! {
                    if let result = result as? StreamingRecognitionResult {
                        if result.isFinal {
                            finished = true
                            for alternative in result.alternativesArray{
                                if let alternative = alternative as? SpeechRecognitionAlternative{
                                    strongSelf.textView.text = alternative.transcript
                                    self!.finalTranscrpition = alternative.transcript
                                }
                            }
                        }
                    }
                }
                //strongSelf.textView.text = response.description
                if finished {
                    strongSelf.stopAudio(strongSelf)
                    self?.sendMessageTapped(messageText: self!.finalTranscrpition)
                }
            }
      })
      self.audioData = NSMutableData()
    }
  }
    
    // Number of Rows in Picker View
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Labels in Picker View: Languages
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row]
    }
    
     // ******************************************
    // Number of Labels: Length of Languages Array
    // ******************************************
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    
    // **********************************
    // Selected Language from Picker View
    // **********************************
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedLanguage.text = languages[row]
        self.selectedLanguageCode = languageCodes[row]
    }
    
    // ********************************************************
    // Function to send the text message from ASR to other User
    // ********************************************************
    func sendMessageTapped(messageText: String){
        if (messageText != ""){
            print("ASR Message Text: \(messageText)")
            // show sent message
            self.textView.text = "\n\(String(describing: messageText))\n"
            
            let sentMsg = "\(self.selectedLanguageCode.split(separator: "-")[0])_" + messageText
            
            // Multi-peer can only send some string in form of data. so convert to data
            let message = sentMsg.data(using: String.Encoding.utf8, allowLossyConversion: false)
            
            // try to send data to other connected peers
            do{
                try self.mcSession.send(message!, toPeers: self.mcSession.connectedPeers, with: .reliable)
            }
            catch{
                print("Error sending meesage to peers.")
            }
        }
            // if the message field is empty, send an alert
        else{
            let emptyAlert = UIAlertController(title: "Empty Message, please enter some text", message: nil, preferredStyle: .alert)
            emptyAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyAlert, animated: true, completion: nil)
        }
    }
    
    // *********************************************************
    // Function to handle Multi-Peer Connection [Bluetooth/WiFi]
    // *********************************************************
    @IBAction func connectionButton(_ sender: Any) {
        // if session does not exist and i am not hosting
        if ((self.mcSession.connectedPeers.count == 0) && (!self.hosting)){
            let connectActionSheet = UIAlertController(title: "Our Chat", message: "Do you want to Host or Join a Chat?", preferredStyle: .actionSheet)
            connectActionSheet.addAction(UIAlertAction(title: "Host Chat", style: .default, handler: { (action: UIAlertAction) in
                self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "doesnt-matter", discoveryInfo: nil, session: self.mcSession)
                self.mcAdvertiserAssistant.start()
                self.hosting = true
            }))
            
            connectActionSheet.addAction(UIAlertAction(title: "Join Chat", style: .default, handler: { (action:UIAlertAction) in
                let mcBrowser = MCBrowserViewController(serviceType: "doesnt-matter", session: self.mcSession)
                mcBrowser.delegate = self
                self.present(mcBrowser, animated: true, completion: nil)
            }))
            connectActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(connectActionSheet, animated: true, completion: nil)
        }
            
            // if the session does not exist but I am hosting
        else if ((self.mcSession.connectedPeers.count == 0) && (self.hosting)){
            let waitActionSheet = UIAlertController(title: "Waiting...", message: "Waiting for others to join chat", preferredStyle: .actionSheet)
            waitActionSheet.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: { (action) in
                self.mcSession.disconnect()
                self.hosting = false
            }))
            waitActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(waitActionSheet, animated: true, completion: nil)
        }
            
            // else disconnect from the session
        else{
            let disconnectActionSheet = UIAlertController(title: "Are you sure you want to disconnect?", message: nil, preferredStyle: .actionSheet)
            disconnectActionSheet.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: { (action: UIAlertAction) in
                self.mcSession.disconnect()
            }))
            disconnectActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(disconnectActionSheet, animated: true, completion: nil)
        }
    }
    
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // ************************************************
    // Function to get current state of peer connection
    // ************************************************
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected to: \(peerID.displayName)")
        case MCSessionState.connecting:
            print("Connecting to: \(peerID.displayName)")
        case MCSessionState.notConnected:
            print("Peer not connected.")
        default:
            print("Peer Connected.")
        }
        
        if (mcSession.connectedPeers.count == 0){
            self.startStream.isEnabled = false
            self.stopStream.isEnabled = false
        }
        else{
            self.startStream.isEnabled = true
            self.stopStream.isEnabled = true
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            // To Do [Reciever Side]: Take Text from here and Translate to Person's Local Language
            let recvdTotalMsg = "\(String(describing: NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)!))\n"
            let recvdLangCode = recvdTotalMsg.split(separator: "_")[0]
            let recvdMsg = recvdTotalMsg.split(separator: "_")[1]
            if (self.selectedLanguageCode.split(separator: "-")[0] == recvdLangCode){
                self.recievedMessage.text += "\(String(describing: recvdMsg))\n"
            }
            else{
                self.translateText(recievedText: String(recvdMsg), languageCode: String(recvdLangCode), targetLanguageCode: String(self.selectedLanguageCode.split(separator: "-")[0]))
                
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Recieved Data Stream: \(streamName) from Peer Name: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Recieving Data Stream: \(resourceName) from Peer Name: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Data Stream transfer completed for: \(resourceName) from Peer Name: \(peerID.displayName)")
    }
    
    // ***************************************************
    // Function to Translate Text Recieved from Other User
    // ***************************************************
    func translateText(recievedText: String, languageCode: String, targetLanguageCode: String){
        if (recievedText.isEmpty){
            return
        }
        let task = try? GoogleTranslate.sharedInstance.translateTextTask(text: recievedText, sourceLanguage: languageCode, targetLanguage: targetLanguageCode, completionHandler: { (translatedText: String?, error: Error?) in
            debugPrint(error?.localizedDescription)
            
            DispatchQueue.main.async {
                self.recievedMessage.text = "\(String(describing: translatedText!))\n"
            }
            
        })
        task?.resume()
    }
}
