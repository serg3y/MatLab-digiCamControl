 Controller for tethered DSLR cameras using digiCamControl (Windows app) 
 C = CameraController -create class and auto-detect digiCamControl
 C = CameraController(ip) -address of pc running digiCamControl webserver
 C = CameraController(fold) -folder containing digiCamControl app
 
Instruction:
1.Install and run digiCamControl, BETA v2.0.69 or greater, from:
 https://sourceforge.net/projects/digicamcontrol/files/latest/download
2.Enable webserver: File>Settings>Webserver>Enable>RESTART APP.
3.Connect one or more cameras using USB cable (or WiFi if supported).
4.For full control set camera to (M) and lens to (MF).
5.Ensure camera is working through digiCamControl.
6.Try the examples bellow and read this help.
 
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
-To reduce capture latency from 0.3-0.6 sec to ~0.05s ensure webserver is
 enabled, File>Settings>Webserver>Enable>RESTART APP
-To measure delay and variance try imaging the computer's own clock by
 calling the "Clock" method provided with this class, C.Clock, however
 I do not know how to measure monitor display latency and variance.
-Cmd('CaptureAll') will trigger all connected cameras but there will be a
 lag of 0.005-0.020 sec between consecutive cameras.
-To record video turn on live preview using Cmd('LiveViewWnd_Show') and
 user Cmd('StartRecord') and Cmd('StopRecord').
-The Capture method blocks code except, but only if acquisition + download
 take more then ~3 sec, then digiCamControl returns without error.
 
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
 
Ex: camera settings
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
 
Ex: two cameras
 C = CameraController;
 C.session.filenametemplate = '[Camera Name]'; %set filename pattern
 C.Cameras(1), C.property.devicename = 'Cam1'; %change camera name
 C.Cameras(2), C.property.devicename = 'Cam2';
 C.Cmd('CaptureAll')
 
Serge 2017
 Questions/bugs/fixes: s3rg3y@hotmail.com
 
