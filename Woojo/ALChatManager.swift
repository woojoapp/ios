//
//  ALChatManager.swift
//  applozicswift
//
//  Created by Devashish on 30/12/15.
//  Copyright © 2015 Applozic. All rights reserved.
//

import UIKit
import Applozic
import NotificationCenter

var TYPE_CLIENT : Int16 = 0
var TYPE_APPLOZIC : Int16 = 1
var TYPE_FACEBOOK : Int16 = 2

var APNS_TYPE_DEVELOPMENT : Int16 = 0
var APNS_TYPE_DISTRIBUTION : Int16 = 1

class ALChatManager: NSObject {
    
    static let shared = ALChatManager(applicationKey: Constants.App.Chat.applozicApplicationId)
    
    init(applicationKey: String) {
        ALUserDefaultsHandler.setApplicationKey(applicationKey)
    }
    
    // ----------------------
    // Call This at time of your app's user authentication OR User registration.
    // This will register your User at applozic server.
    //----------------------
    
    /*func registerUser(_ alUser: ALUser) {
     
     let alChatLauncher: ALChatLauncher = ALChatLauncher(applicationId: getApplicationKey() as String)
     ALDefaultChatViewSettings()
     
     let registerUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
     registerUserClientService.initWithCompletion(alUser, withCompletion: { (response, error) in
     
     if (error != nil)
     {
     print("error while registering to applozic");
     }
     else if(response?.message.isEqual("PASSWORD_INVALID"))!
     {
     ALUtilityClass.showAlertMessage("Invalid Password", andTitle: "Oops!!!")
     }
     else
     {
     print("registered")
     if(ALChatManager.isNilOrEmpty(ALUserDefaultsHandler.getApnDeviceToken() as NSString?))
     {
     alChatLauncher.registerForNotification()
     }
     }
     })
     }*/
    
    /*func getApplicationKey() -> NSString {
     
     let appKey = ALUserDefaultsHandler.getApplicationKey() as NSString?
     //    let applicationKey = (appKey != nil) ? appKey : ALChatManager.applicationId
     let applicationKey = appKey
     return applicationKey!;
     
     }*/
    
    class func isNilOrEmpty(_ string: NSString?) -> Bool {
        switch string {
        case .some(let nonNilString): return nonNilString.length == 0
        default:return true
        }
    }
    
    func registerUser(_ alUser: ALUser, completion : @escaping (_ response: ALRegistrationResponse, _ error: NSError?) -> Void) {
        
        let alChatLauncher = ALChatLauncher(applicationId: ALUserDefaultsHandler.getApplicationKey())
        
        ALDefaultChatViewSettings()
        
        let registerUserClientService = ALRegisterUserClientService()
        registerUserClientService.initWithCompletion(alUser, withCompletion: { (response, error) in
            
            if (error != nil) {
                print("error while registering to applozic");
            }
            else if(response?.message.isEqual("PASSWORD_INVALID"))! {
                print("Invalid Password")
            }
            else {
                print("registered")
                if(ALChatManager.isNilOrEmpty(ALUserDefaultsHandler.getApnDeviceToken() as NSString?)) {
                    alChatLauncher?.registerForNotification()
                }
                
                ALApplozicSettings.setListOfViewControllers(["Woojo.EventsViewController",
                                                             "Woojo.AddEventViewController",
                                                             "Woojo.MyEventsTableViewController",
                                                             "Woojo.SearchEventsViewController",
                                                             "Woojo.ExploreEventsViewController",
                                                             "Woojo.CandidatesViewController",
                                                             "Woojo.NavigationController",
                                                             "Woojo.UserDetailsViewController",
                                                             "Woojo.SettingsViewController",
                                                             "Woojo.PreferencesViewController",
                                                             "Woojo.ProfileViewController",
                                                             "Woojo.AlbumsTableViewController",
                                                             "Woojo.PhotoCollectionViewController",
                                                             "Woojo.AboutTableViewController",
                                                             "Woojo.AboutWebViewController",
                                                             "UIAlertViewController",
                                                             "PUUIAlbumListViewController",
                                                             "PUUIMomentsGridViewController",
                                                             "RSKImageCropViewController",
                                                             "PUUIPhotosAlbumViewController"])
                ALMQTTConversationService.sharedInstance().subscribeToConversation()
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.newMessageReceived(notification:)), name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
                completion(response! , error as NSError?)
            }
        })
    }
    
    func newMessageReceived(notification: Notification) {
        // Push notification to firebase
        if let messageArray = notification.object as? NSMutableArray {
            for message in messageArray {
                if let message = message as? ALMessage, var excerpt = message.message {
                    if excerpt.characters.count > 100 {
                        excerpt = excerpt.substring(to: excerpt.index(excerpt.startIndex, offsetBy: 100))
                    }
                    let messageNotification = CurrentUser.MessageNotification(id: UUID().uuidString, created: Date(), otherId: message.contactIds, excerpt: excerpt)
                    messageNotification.save()
                }
            }
        }
    }
    
    // ----------------------  ------------------------------------------------------/
    // convenient method to launch chat-list, after user registration is done on applozic server.
    //
    // This will automatically handle unregistered users provided getLoggedinUserInformation is implemented properly.
    // ----------------------  ------------------------------------------------------/
    
    /*func launchChat(_ fromViewController:UIViewController){
     self.registerUserAndLaunchChat(nil, fromController: fromViewController, forUser: nil)
     }
     
     // ----------------------  ------------------------------------------------------/
     // convenient method to directly launch individual user chat screen. UserId parameter define users for which it intented to launch chat screen.
     //
     // This will automatically handle unregistered users provided getLoggedinUserInformation is implemented properly.
     // ----------------------  ------------------------------------------------------/
     
     func launchChatForUser(_ forUserId : String ,fromViewController:UIViewController){
     self.registerUserAndLaunchChat(nil, fromController: fromViewController, forUser: forUserId)
     }
     
     // ----------------------  ------------------------------------------------------/
     //      Method to register + lauch chats screen. If user is already registered, directly chats screen will be launched.
     //      If user information is not passed, it will try to get user information from getLoggedinUserInformation.
     //-----------------------  ------------------------------------------------------/
     
     func registerUserAndLaunchChat(_ alUser:ALUser?, fromController:UIViewController,forUser:String?)
     {
     let alChatLauncher: ALChatLauncher = ALChatLauncher(applicationId: getApplicationKey() as String)
     
     if(!ALChatManager.isNilOrEmpty(ALUserDefaultsHandler.getDeviceKeyString() as NSString?))
     {
     if (ALChatManager.isNilOrEmpty(forUser as NSString?))
     {
     let title  = ALChatManager.isNilOrEmpty(fromController.title as NSString?) ? "< Back" : fromController.title;
     alChatLauncher.launchChatList(title, andViewControllerObject:fromController);
     }
     else
     {
     alChatLauncher.launchIndividualChat(forUser, withGroupId: nil, andViewControllerObject: fromController, andWithText: nil)
     }
     return;
     }
     
     //register user as it is not registered already ...
     var user : ALUser;
     if (alUser == nil) {
     user = ALChatManager.getUserDetail()
     }else {
     user = alUser!;
     
     }
     ALDefaultChatViewSettings();
     
     // register and launch...
     let registerUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
     registerUserClientService.initWithCompletion(user, withCompletion: { (response, error) in
     if (error != nil) {
     //TODO : show/handle error
     print("error while registering to applozic");
     return;
     } else if(response?.message == "REGISTERD"){
     print("registered!!!")
     if(ALChatManager.isNilOrEmpty(ALUserDefaultsHandler.getApnDeviceToken() as NSString?)){
     alChatLauncher.registerForNotification()
     }
     //let messageClientService: ALMessageClientService = ALMessageClientService()
     //messageClientService.addWelcomeMessage()
     }
     if (ALChatManager.isNilOrEmpty(forUser as NSString?)){
     let title  = ALChatManager.isNilOrEmpty(fromController.title as NSString?) ?"< Back" : fromController.title;
     alChatLauncher.launchChatList(title, andViewControllerObject:fromController);
     }else {
     alChatLauncher.launchIndividualChat(forUser, withGroupId: nil, andViewControllerObject: fromController, andWithText: nil)
     }
     })
     }
     
     // ----------------------  ---------------------------------------------------------------------------------------------//
     //     This method can be used to get app logged-in user's information.
     //     if user information is stored in DB or preference, Code to get user's information should go here.
     //     This might be used to get existing user information in case of app update.
     //----------------------   -----------------------------------------------------------------------------------------//
     
     class func getUserDetail() -> ALUser {
     
     // TODO:Write your won code to get userId in case of update or in case of user is not registered....
     
     let user: ALUser = ALUser()
     user.userId = "iosdevtest"
     user.applicationId = ALChatManager.applicationId
     return user;
     
     }
     
     class func isNilOrEmpty(_ string: NSString?) -> Bool {
     
     switch string {
     case .some(let nonNilString): return nonNilString.length == 0
     default:return true
     
     }
     }
     
     // ----------------------  ------------------------------------------------------/
     // convenient method to directly launch individual context-based user chat screen. UserId parameter define users for which it intented to launch chat screen.
     //
     // This will automatically handle unregistered users provided getLoggedinUserInformation is implemented properly.
     // ----------------------  ------------------------------------------------------/
     
     func createAndLaunchChatWithSellerWithConversationProxy (_ alConversationProxy: ALConversationProxy?, fromViewController: UIViewController) {
     
     let alChatLauncher: ALChatLauncher = ALChatLauncher(applicationId: getApplicationKey() as String)
     
     let alconversationService : ALConversationService = ALConversationService()
     //        alconversationService.createConversation(alConversationProxy) { (error:NSError?, proxyObject: ALConversationProxy!) -> Void in
     //
     //            if((error == nil)){
     //                let finalProxy : ALConversationProxy = makeFinalProxyWithGeneratedProxy(alConversationProxy!, responseProxy: proxyObject)
     //                alChatLauncher.launchIndividualContextChat(finalProxy, andViewControllerObject: fromViewController, userDisplayName: "User", andWithText: nil)
     //            }
     //        }
     }
     }
     
     func getApplicationKey() -> NSString {
     
     let appKey = ALUserDefaultsHandler.getApplicationKey() as NSString?
     //    let applicationKey = (appKey != nil) ? appKey : ALChatManager.applicationId
     let applicationKey = appKey
     return applicationKey!;
     
     }
     
     //----------------------------------------------------------------------------------------------------
     // The below method combines the conversationID got from server's response with the details already set.
     //----------------------------------------------------------------------------------------------------
     
     func makeFinalProxyWithGeneratedProxy (_ generatedProxy:ALConversationProxy, responseProxy:ALConversationProxy)->ALConversationProxy{
     
     let finalProxy : ALConversationProxy = ALConversationProxy()
     finalProxy.userId = generatedProxy.userId;
     finalProxy.topicDetailJson = generatedProxy.topicDetailJson;
     finalProxy.id = responseProxy.id;
     finalProxy.groupId = responseProxy.groupId;
     
     return finalProxy;
     }*/
    
    //--------------------------------------------------------------------------------------------------------------
    // This method helps you customise various settings
    //--------------------------------------------------------------------------------------------------------------
    
    func ALDefaultChatViewSettings() {
        
        //////////////////////////   SET AUTHENTICATION-TYPE-ID FOR INTERNAL USAGE ONLY ////////////////////////
        ALUserDefaultsHandler.setUserAuthenticationTypeId(TYPE_APPLOZIC)
        ////////////////////////// ////////////////////////// ////////////////////////// ///////////////////////
        
        
        /*********************************************  NAVIGATION SETTINGS  ********************************************/
        
        //ALApplozicSettings.setStatusBarBGColor(UIColor(red:247.0/255, green:247.0/255, blue:247.0/255, alpha:1))
        //ALApplozicSettings.setStatusBarStyle(.lightContent)
        /* BY DEFAULT Black:UIStatusBarStyleDefault IF REQ. White: UIStatusBarStyleLightContent  */
        /* ADD property in info.plist "View controller-based status bar appearance" type: BOOLEAN value: NO */
        
        //ALApplozicSettings.setColorForNavigation(UIColor(red:247.0/255, green:247.0/255, blue:247.0/255, alpha:1))
        //ALApplozicSettings.setColorForNavigation(UIColor.clear)
        ALApplozicSettings.setColorForNavigationItem(UIColor.black)
        ALUserDefaultsHandler.setNavigationRightButtonHidden(false)
        ALUserDefaultsHandler.setBackButtonHidden(true)
        //ALUserDefaultsHandler.setNavigationRightButtonHidden(false)
        ALUserDefaultsHandler.setBottomTabBarHidden(false)
        ALApplozicSettings.setTitleForConversationScreen("Chats")
        
        ALApplozicSettings.hideRefreshButton(true)
        ALApplozicSettings.setCustomNavRightButtonMsgVC(false)               /*  SET VISIBILITY FOR REFRESH BUTTON (COMES FROM TOP IN MSG VC)   */
        
        //ALApplozicSettings.setTitleForBackButtonMsgVC("Back")                /*  SET BACK BUTTON FOR MSG VC  */
        //ALApplozicSettings.setTitleForBackButtonChatVC("Back")               /*  SET BACK BUTTON FOR CHAT VC */
        /****************************************************************************************************************/
        
        
        /***************************************  SEND RECEIVE MESSAGES SETTINGS  ***************************************/
        
        ALApplozicSettings.setSendMsgTextColor(UIColor.white)
        ALApplozicSettings.setReceiveMsgTextColor(UIColor.black)
        ALApplozicSettings.setColorForReceiveMessages(UIColor(red:230.0/255, green:230.0/255, blue:230.0/255, alpha:1))
        ALApplozicSettings.setFontFace(UIFont.systemFont(ofSize: 14.0).fontName)
        
        //****************** DATE COLOUR : AT THE BOTTOM OF MESSAGE BUBBLE ******************/
        
        ALApplozicSettings.setDateColor(UIColor.lightGray)
        
        //****************** MESSAGE SEPERATE DATE COLOUR : DATE MESSAGE ******************/
        
        ALApplozicSettings.setMsgDateColor(UIColor.lightGray)
        
        /***************  SEND MESSAGE ABUSE CHECK  ******************/
        
        //ALApplozicSettings.setAbuseWarningText("AVOID USE OF ABUSE WORDS")
        //ALApplozicSettings.setMessageAbuseMode(true)
        
        //****************** SHOW/HIDE RECEIVER USER PROFILE ******************/
        
        //ALApplozicSettings.setReceiverUserProfileOption(false)
        
        /****************************************************************************************************************/
        
        
        /**********************************************  IMAGE SETTINGS  ************************************************/
        
        //ALApplozicSettings.setMaxCompressionFactor(0.1)
        //ALApplozicSettings.setMaxImageSizeForUploadInMB(3)
        //ALApplozicSettings.setMultipleAttachmentMaxLimit(5)
        /****************************************************************************************************************/
        
        
        /**********************************************  GROUP SETTINGS  ************************************************/
        
        //ALApplozicSettings.setGroupOption(false)
        //ALApplozicSettings.setGroupExitOption(true)
        //ALApplozicSettings.setGroupMemberAddOption(true)
        //ALApplozicSettings.setGroupMemberRemoveOption(true)
        /****************************************************************************************************************/
        
        
        /******************************************** NOTIIFCATION SETTINGS  ********************************************/
        
        //ALUserDefaultsHandler.setDeviceApnsType(APNS_TYPE_DEVELOPMENT)
        //For Distribution CERT::
        ALUserDefaultsHandler.setDeviceApnsType(APNS_TYPE_DISTRIBUTION)
        
        //let appName = Bundle.main.infoDictionary!["CFBundleName"]
        //ALApplozicSettings.setNotificationTitle((appName as AnyObject).string)
        
        //    ALApplozicSettings.enableNotification() //0
        ALApplozicSettings.disableNotification() //2
        //    ALApplozicSettings.disableNotificationSound() //1                /*  IF NOTIFICATION SOUND NOT NEEDED  */
        //    ALApplozicSettings.enableNotificationSound() //0                   /*  IF NOTIFICATION SOUND NEEDED    */
        /****************************************************************************************************************/
        
        
        /********************************************* CHAT VIEW SETTINGS  **********************************************/
        
        ALApplozicSettings.setVisibilityForNoMoreConversationMsgVC(false)               /*  SET VISIBILITY NO MORE CONVERSATION (COMES FROM TOP IN MSG VC)  */
        ALApplozicSettings.setEmptyConversationText("You have no conversations yet")    /*  SET TEXT FOR EMPTY CONVERSATION    */
        ALApplozicSettings.setVisibilityForOnlineIndicator(true)                        /*  SET VISIBILITY FOR ONLINE INDICATOR */
        
        ALApplozicSettings.setColorForSendButton(UIColor.white) /*  SET COLOR FOR SEND BUTTON   */
        
        ALApplozicSettings.setColorForTypeMsgBackground(UIColor.white)             /*  SET COLOR FOR TYPE MESSAGE OUTER VIEW */
        ALApplozicSettings.setMsgTextViewBGColor(UIColor.white)                /*  SET BG COLOR FOR MESSAGE TEXT VIEW */
        ALApplozicSettings.setPlaceHolderColor(UIColor.gray)                       /*  SET COLOR FOR PLACEHOLDER TEXT */
        ALApplozicSettings.setVisibilityNoConversationLabelChatVC(true)            /*  SET NO CONVERSATION LABEL IN CHAT VC    */
        ALApplozicSettings.setBGColorForTypingLabel(UIColor(red:247/255.0, green:247/255.0, blue:247/255.0, alpha:0.95))   /*  SET COLOR FOR TYPING LABEL  */
        ALApplozicSettings.setTextColorForTypingLabel(UIColor(red:51.0/255, green:51.0/255, blue:51.0/255, alpha:0.5))  /*  SET COLOR FOR TEXT TYPING LABEL  */
        /****************************************************************************************************************/
        
        
        /********************************************** CHAT TYPE SETTINGS  *********************************************/
        
        //ALApplozicSettings.setContextualChat(true)                                 /*  IF CONTEXTUAL NEEDED    */
        /*  Note: Please uncomment below setter to use app_module_name */
        //   ALUserDefaultsHandler.setAppModuleName("<APP_MODULE_NAME>")
        //   ALUserDefaultsHandler.setAppModuleName("SELLER")
        /****************************************************************************************************************/
        
        
        /*********************************************** CONTACT SETTINGS  **********************************************/
        
        //ALApplozicSettings.setFilterContactsStatus(true)                           /*  IF NEEDED ALL REGISTERED CONTACTS   */
        //ALApplozicSettings.setOnlineContactLimit(0)                                /*  IF NEEDED ONLINE USERS WITH LIMIT   */
        /****************************************************************************************************************/
        
        
        /***************************************** TOAST + CALL OPTION SETTINGS  ****************************************/
        
        ALApplozicSettings.setColorForToastText(UIColor.black)                     /*  SET COLOR FOR TOAST TEXT    */
        ALApplozicSettings.setColorForToastBackground(UIColor.gray)                /*  SET COLOR FOR TOAST BG      */
        //ALApplozicSettings.setCallOption(true)                                     /*  IF CALL OPTION NEEDED   */
        /****************************************************************************************************************/
        
        
        /********************************************* DEMAND/MISC SETTINGS  ********************************************/
        
        ALApplozicSettings.setUnreadCountLabelBGColor(UIColor.red)
        ALApplozicSettings.setCustomClassName("ALChatManager")                     /*  SET 3rd Party Class Name OR ALChatManager */
        ALUserDefaultsHandler.setFetchConversationPageSize(20)                     /*  SET MESSAGE LIST PAGE SIZE  */ // DEFAULT VALUE 20
        ALUserDefaultsHandler.setUnreadCountType(1)                                /*  SET UNRAED COUNT TYPE   */ // DEFAULT VALUE 0
        ALApplozicSettings.setMaxTextViewLines(4)
        ALUserDefaultsHandler.setDebugLogsRequire(false)                            /*   ENABLE / DISABLE LOGS   */
        ALUserDefaultsHandler.setLoginUserConatactVisibility(false)
        ALApplozicSettings.setUserProfileHidden(true)
        //ALApplozicSettings.setFontFace("Helvetica")
        //ALApplozicSettings.setChatWallpaperImageName("<WALLPAPER NAME>")
        /****************************************************************************************************************/
        
        
        /***************************************** APPLICATION URL CONFIGURATION + ENCRYPTION  ***************************************/
        
        //ALUserDefaultsHandler.setEnableEncryption(false)                            /* Note: PLEASE DO YES (IF NEEDED)  */
        /****************************************************************************************************************/
    }
}
