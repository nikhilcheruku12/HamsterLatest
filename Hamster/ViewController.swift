//
//  ViewController.swift
//  Hamster
//
//  Created by Teresa Liu on 11/12/16.
//  Copyright © 2016 Teresa Liu. All rights reserved.
//

import UIKit

class ViewController: UIViewController,
SPTAudioStreamingPlaybackDelegate {
    
    let kClientID = "487496c08cab4d7e84620e9f95fad61e"
    let kCallbackURL = "hamster://returnAfterLogin"
   // let kCallbackURL = "www.google.com"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshServiceURL = "http://localhost:1234/refresh"
    
    var session:SPTSession!
    var player:SPTAudioStreamingController?
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.hidden = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAfterFirstLogin", name: "loginSuccessfull", object: nil)
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let sessionObj:AnyObject = userDefaults.objectForKey("SpotifySession") { // session available
            let sessionDataObj = sessionObj as! NSData
            
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !session.isValid() {
                SPTAuth.defaultInstance().renewSession(session, withServiceEndpointAtURL: NSURL(string: kTokenRefreshServiceURL), callback: { (error:NSError!, renewdSession:SPTSession!) -> Void in
                    if error == nil {
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                        userDefaults.setObject(sessionData, forKey: "SpotifySession")
                        userDefaults.synchronize()
                        
                        self.session = renewdSession
                       // self.playUsingSession(renewdSession)
                        self.showNextVC()
                    }else{
                        print("error refreshing session")
                    }
                })
            }else{
                print("session valid")
                self.session = session
                self.showNextVC()
               // playUsingSession(session)
            }
            
            
            
        }else{
            loginButton.hidden = false
        }
        
        
    }
    
    
    func updateAfterFirstLogin () {
        loginButton.hidden = true
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let sessionObj:AnyObject = userDefaults.objectForKey("SpotifySession") {
//            let sessionDataObj = sessionObj as! NSData
//            let firstTimeSession = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
//            self.session = firstTimeSession
//            playUsingSession(firstTimeSession)
            
           showNextVC()
            
        }
        
    }
    
    func showNextVC(){
        let vc : AnyObject! = self.storyboard?.instantiateViewControllerWithIdentifier("PlaylistViewController")
        self.showViewController(vc as! UIViewController, sender: vc)
        
      //  self.presentViewController(vc as! UIViewController, animated: true, completion: nil)
        
    }
    
    func playUsingSession(sessionObj:SPTSession!){
        if player == nil {
            player = SPTAudioStreamingController(clientId: kClientID)
            player?.playbackDelegate = self
        }
        
        player?.loginWithSession(sessionObj, callback: { (error:NSError!) -> Void in
            if error != nil {
                print("Enabling playback got error \(error)")
                return
            }
            
           /* SPTRequest.requestItemAtURI(NSURL(string: "spotify:album:4L1HDyfdGIkACuygktO7T7"), withSession: sessionObj, callback: { (error:NSError!, albumObj:AnyObject!) -> Void in
             if error != nil {
             print("Album lookup got error \(error)")
             return
             }
             
             let album = albumObj as! SPTAlbum
             
             self.player?.playTrackProvider(album, callback: nil)
             })*/
            
            SPTRequest.performSearchWithQuery("let it go", queryType: SPTSearchQueryType.QueryTypeTrack, offset: 0, session: nil, callback: { (error:NSError!, result:AnyObject!) -> Void in
                let trackListPage = result as! SPTListPage
                
                let partialTrack = trackListPage.items.first as! SPTPartialTrack
                
                SPTRequest.requestItemFromPartialObject(partialTrack, withSession: nil, callback: { (error:NSError!, results:AnyObject!) -> Void in
                    let track = results as! SPTTrack
                    self.player?.playTrackProvider(track, callback: nil)
                })
                
                
            })
            
        })
        
    }
    
    @IBAction func loginWithSpotify(sender: UIButton) {let auth = SPTAuth.defaultInstance()
        
        let loginURL = auth.loginURLForClientId(kClientID, declaredRedirectURL: NSURL(string: kCallbackURL), scopes: [SPTAuthStreamingScope])
        
        UIApplication.sharedApplication().openURL(loginURL)
    }
//    @IBAction func loginWithSpotify(sender: AnyObject) {
//        let auth = SPTAuth.defaultInstance()
//        
//        let loginURL = auth.loginURLForClientId(kClientID, declaredRedirectURL: NSURL(string: kCallbackURL), scopes: [SPTAuthStreamingScope])
//        
//        UIApplication.sharedApplication().openURL(loginURL)
//    }
    
    
    func updateCoverArt(){
        if player?.currentTrackMetadata == nil {
            artworkImageView.image = UIImage()
            return
        }
        
        let uri = player?.currentTrackMetadata[SPTAudioStreamingMetadataAlbumURI] as! String
        
        SPTAlbum.albumWithURI(NSURL(string: uri), session: session) { (error:NSError!, albumObj:AnyObject!) -> Void in
            let album = albumObj as! SPTAlbum
            
            if let imgURL = album.largestCover.imageURL as NSURL! {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    var error:NSError? = nil
                    var coverImage = UIImage()
                    
                    if let imageData = NSData(contentsOfURL: imgURL){
                        if error == nil {
                            coverImage = UIImage(data: imageData)!
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.artworkImageView.image = coverImage
                    })
                    
                    
                })
            }
            
        }
        
    }
    
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        updateCoverArt()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

