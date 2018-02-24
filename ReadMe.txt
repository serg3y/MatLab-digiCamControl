 Controller for tethered DSLR cameras using digiCamControl (Windows app) 
 C = CameraController -create class and auto-detect digiCamControl
 C = CameraController(ip) -address of pc running digiCamControl webserver
 C = CameraController(fold) -folder containing digiCamControl app
 
Instruction:
1.Install and run digiCamControl, BETA v2.0.69 or greater, from:
 https://sourceforge.net/projects/digicamcontrol/files/latest/download
2.Enable webserver: File>Settings>Webserver>Enable **RESTART REQUIRED**.
3.Connect one or more cameras using USB cable (or WiFi if supported).
4.For full manual control set camera mode to (M) and lens to (MF).
5.Test the connection through digiCamControl GUI.
6.Try the examples and read this help.
 
Remarks:
-This class can be used to control supported cameras, stream liveview,
 capture photos & video, download captured files, change settings such as
 ISO, exposure, focus, aperture(fnumber), white balance, compression, etc. 
-digiCamControl is a multi purpose, free, open source, but Windows only
 application that can control a host of supported cameras. 
-This class communicates with camera(s) via digiCamControl's included 
 HTTP webserver(recommended) or CMD Utility. 
-The webserver is much faster and allows camera(s) to be controlled from
 any Windows/Linux computer on the network or via the internet. 
-Visit http://digiCamControl.com for documentation, forums and to donate.
-Method in this class are Capitalised and have additional descriptions.
-When this class is created it does a one of retrieval of allowed camera
 options. Redefine this class when swapping cameras.
 
Limitations:
-This class cannot download old photos, user has to use digiCamControl app
 manually: digiCamControl>Download photos. 
-This class can only stream liveview (low-rez, noisy, ~15Hz) from 
 supported cameras. However digiCamControl does support "Open Broadcaster
 Software" (OBS) and "XSplit", see Streaming and Search Forums for info.
-This class does not know when capture+download finish, if its > ~3sec.
-No alphanumeric characters found in some Nikon camera properties are
 being removed. These properties can be queried but can not be set. 
 eg "-", "." in "center-weighted_area" "active_d-lighting" "long_exp._nr"
-digiCamControl issues: http://digicamcontrol.com/phpbb/viewforum.php?f=4
 
Camera Settings:
-Some settings will not have affect if camera is not in Manual mode (M).
-To control focus ensure lens is set to Manual Focus (MF):
-Focus step size & speed can be modified in: File>Settings>Live view
-Note: Lenses use servo motors which have no discrete physical 'steps'. To
 achieve a specific focus reproducibly try to go to the lens's physical
 limit, in either direction, and apply a set change from there.
 
Image Capture:
-To reduce capture latency from 0.3-0.6 sec to ~0.05s enable HTTP
 webserver, File>Settings>Webserver *RESTART IS REQUIRED*
-To measure the delay and variance try imaging the computer's own clock by
 calling the "Clock" method provided with this class, ie C.Clock
-Cmd('CaptureAll') will trigger all connected cameras but there will be a
 lag of 0.005-0.020 sec between consecutive cameras.
-To record video turn on live preview using Cmd('LiveViewWnd_Show') and
 user Cmd('StartRecord') and Cmd('StopRecord').
-The Capture method blocks code except, but only if acquisition + download
 take more then ~3 sec, then digiCamControl returns without error.
 
Download settings:
-Download is affected by: 1) Transfer mode, 2) session settings
-Transfer mode can ONLY be set via the GUI: "PC Only"|"Cam Only"|"PC+Cam".
-Transfer mode restricts where photos are allowed to be saved and session
 settings can further restrict those limits, but not expand them.
RECOMMENDATION:use "PC+Cam"+"deletefileaftertransfer" instead of "PC only"
-Some session settings only work under certain conditions:
 "downloadonlyjpg" prevents RAWs from downloading only if mode="PC+Cam"
 "deletefileaftertransfer" only works if mode="PC+Cam"
 "useoriginalfilename" only works when mode="PC+Cam" 
 "downloadthumbonly" never works (v2.0.72.9)
 "filenametemplate" only works when "useoriginalfilename" is off
-"filenametemplate" is only applied to downloaded files, not camera files.
-"filenametemplate" supports many useful [tags], eg: [Date yyyy-MM-dd],
 [Time hh-mm-ss], [Date yyyy-MM-dd-hh-mm-ss], [Exif.Photo.ExposureTime],
 [Exif.Photo.FNumber], [Exif.Photo.ISOSpeedRatings], etc
 (for a full list go to: Session>Edit Current Session>File Name Template)
-"filenametemplate" can be set when calling the Capture method.
-"filenametemplate" applies to all connected cameras, to make sure files
 are downloaded with different filenames use [Camera Name], [Camera Counter 4 digit]
-"folder" does not support [tags], so use a "\" in the filename instead.
 
Ex: download settings, see also "Transfer" in bottom left of GUI
 C = CameraController;
 C.session.folder = 'C:\DSLR';
 C.session.filenametemplate = '[Camera Name]\[Date yyyy-MM-dd-hh-mm-ss]';
 C.session.useoriginalfilename = 0; %ignores "filenametemplate"
 C.session.downloadthumbonly = 0; %not working (v2.0.72.9)
 C.session.downloadonlyjpg = 0; %only used if "PC+CAM"
 C.session.deletefileaftertransfer = 1; %only has affect if Transfer="Cam+PC" and affectively converts it to "PC only"
 C.session.asksavepath = 0; %dialog popup for after capture
 C.session.allowoverwrite = 0; %overwrite if file exists
 C.session.lowercaseextension = 1; %use "*.jpg" instead of "*.JPG"
 
Ex: basic camera settings
 C = CameraController;
 C.camera.isonumber = 100;
 C.camera.fnumber = 4;
 C.camera.shutterspeed = 1/200;
 C.camera.compressionsetting = 'Large Fine JPEG';
 C.camera.drive_mode = 'Single-Frame Shooting';
 
Ex: simple capture
 C = CameraController; %initialise
 C.Capture %capture (filename set by "session.filenametemplate") 
 C.Capture('MyPhoto') %capture (set custom filename)
 C.Capture('[Time hh-mm-ss]') %capture (use time tag as filename)
 file = C.lastfile %get last downloaded filenames
 
Ex: timed capture
 C = CameraController;
 time = ceil(now*24*60*6)/24/60/60; %upcoming whole second
 file = [datestr(time,'yyyy-mm-dd_HHMMSS.FFF') '_' C.property.devicename]; %timestamp & camera name
 C.Capture(file,time); %capture
 datestr(time)
 
Ex: two cameras
 C = CameraController;
 C.session.filenametemplate = 'MyTest_[Camera Name]'; %set filename pattern
 C.Cameras(1), C.property.devicename = 'Cam1'; %set camera name (optional)
 C.Cameras(2), C.property.devicename = 'Cam2';
 C.Cmd('CaptureAll')
 
Ex: focus stacking
 C = CameraController;
 C.Cmd('LiveViewWnd_Show'), pause(1) %turn on live preview
 for k = 0:2 %take 3 photos
 C.Focus(-2,'small',1) %two small step towards near focus
 C.Capture(num2str(k,'Focus%g')); %capture and number the photos
 end
 C.Cmd('LiveViewWnd_Hide') %turn off live preview to save battery
 
Ex: stream live view
To remove rectangle: Live View>Display>Show focus rectangle
To reduce lag enable: Live View>Display>No processing
 C = CameraController;
 C.Cmd('LiveViewWnd_Show'); %start live view
 C.Cmd('All_Minimize'); %minimise digiCamControl
 pause(3) %wait for live view
 clf, h = imshow(C.LiveView); %prepare figure
 uicontrol('str','Capture','call','C.Capture') %capture button
 while ishandle(h) %loop until closed
 set(h,'cdata',C.LiveView) %update live view
 drawnow %update display
 end
 C.Cmd('LiveViewWnd_Hide'); %stop live view
 
Ex: debugging
 C = CameraController;
 C.Clock %show a clock with milliseconds
 C.dbg = 2; %display commands and replies
 C.Capture %capture photo
 
Serge 2017
 Email questions/bugs/fixes to: s3rg3y@hotmail.com
