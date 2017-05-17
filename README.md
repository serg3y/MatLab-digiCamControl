%Controller for tethered DSLR cameras using <a href=http://digicamcontrol.com/>digiCamControl</a> (Windows app) 
% C = CameraController     -create class (auto detects digiCamControl)
% C = CameraController(ip)  -address of pc running digiCamControl Webserver
% C = CameraController(ip,fold) -folder with digiCamControl CMD Utility
% 
%Description:
%-This class can control supported DSLR cameras to capture photos or video,
% configure file download and change camera settings such as ISO, exposure,
% focus, aperture(fnumber), flash, white balance, compression, etc.
% 
%Setup:
%1.Install and run digiCamControl, BETA v2.0.69 or greater, from:
%  https://sourceforge.net/projects/digicamcontrol/files/latest/download
%  (digiCamControl is a multi purpose, free, open source, Windows only
%  application that can control a host of <a href=http://digicamcontrol.com/cameras>supported cameras</a>)
%2.Connect one or more camera by USB or WiFi to the PC and ensure
%  digiCamControl detects the camera(s). 
%  (This class communicates with camera(s) via digiCamControl, using the
%  inbuilt <a href=http://digicamcontrol.com/doc/userguide/web>HTTP Webserver</a>, when enabled, or <a href=http://digicamcontrol.com/doc/userguide/remoteutil>CMD Utility</a>.) 
%3.To enable Webserver go to File>Settings>Webserver (RESTART REQUIRED).
%  (Webserver is MUCH faster and allows camera(s) to be controlled from
%  other networked computers running MatLab, even LINUX - not tested!)
%4.Read the help and try an example. For digiCamControl <a href=http://digicamcontrol.com/doc>documentation</a>,
%  <a href=http://digicamcontrol.com/phpbb/>forums</a> or to make a <a href=http://digicamcontrol.com/donate>donation</a> visit http://digiCamControl.com
% 
%Remarks:
%-When this class is deffined it will try to retrieve camera settings from
% the digiCamControl app using either HTTP (faster) or CMD interface.
%-Redefine this class if switching cameras or start/stopping the Webserver.
%-Method in this class are Capitalised and have additional descriptions.
%-It may be possible to run under Linux without a dedicated Windows machine
% by running digiCamControl inside a Windows vertial machine, NOT TESTED!
%-This class can NOT stream video or live preview to MatLab.
% 
%Camera Settings:
%-Some settings will not work if camera is not set to Manual (M).
%-To change focus ensure lens is set to Manual Focus (MF) and use
% Cmd('LiveView_Focus_*') where * is: 
% near focus: M (small step), MM (medium step), MMM (large step)
% far focus:  P (small step), PP (medium step), PPP (large step)
%-Small focus step can be hard to notice.
%-Focus step size & speed is set in: File>Settings>Live view
%-Lens motors are usually servos (not stepper motors) so a specific focal
% distance is hard to reproduce programmatically. To 'reset' go to the
% physical limit, in either direction, and count steps from that point.
% 
%Image Capture:
%-When Webserver is NOT enabled capture latency is 0.3-0.6 sec (depending
% on hardware) and variance is about ±0.03 sec.
%-When Webserver is enabled File>Settings>Webserver (+RESTART) commands are
% passed via http with shorter latencies of ~0.05 sec.
%-To measure the delay and variance try imaging the computer's own clock by
% running the Clock method provided in this class.
%-Cmd('CaptureAll') will trigger all connected cameras but there will be a
% lag of 0.005-0.020 sec between consecutive cameras.
%-To record video turn on live preview using Cmd('LiveViewWnd_Show') and
% user Cmd('StartRecord') and Cmd('StopRecord').
%-The Capture method blocks code (default) except if acquisition + download
% take more then ~3 sec, then digiCamControl returns without error.
% 
%Image download:
%-download is affected by several settings including:
% C.session.folder                  = 'C:\DSLR';
% C.session.filenametemplate        = '[Camera Name]\[Date yyyy-MM-dd]';
% C.session.alowfolderchange        = 1;
% C.session.allowoverwrite          = 1;
% C.session.deletefileaftertransfer = 1;
% C.session.lowercaseextension      = 1;
% C.session.downloadonlyjpg         = 0;
% C.session.downloadthumbonly       = 0;
% C.session.useoriginalfilename     = 0;
% C.session.asksavepath             = 0;
%-"filenametemplate" affects downloaded files and not camera files,
% and only works if useoriginalfilename == 0.
%-File input to Capture can't have spaces, if spaces are needed set the
% filename using "session.filenametemplate" property.
%-"filenametemplate" supports only a specific set of [tags].
%-"folder" does not support [tags], instead use "\" in "filenametemplate".
%-For all [tags] go to: Session>Edit Current Session>File Name Template.
%-Some useful [tags] are: [Date yyyy-MM-dd-hh-mm-ss],[Camera Name],
% [Exif.Photo.ExposureTime],[Exif.Photo.FNumber],[Exif.Photo.ISOSpeedRatings]
%-[tags] can be used as
% 
%digiCamControl Issues:
%-digiCamControl’s "Sync camera time" has known problems (2017 Apr).
%-If set to video mode the focus step size may become smaller and it may
% take ~600 steps, about 2 minutes, to move focus end-to-end on a Canon.
%-camera.exposurestatus was removed because it wasn't working (Canon 70D).
%-When digiCamControl 2.0.72 starts focusmode is set to blank (Canon 70D)
%-For all issues see: http://digicamcontrol.com/phpbb/viewforum.php?f=4
%-Set property.nodownload is not working
%-Get camera.ae_bracketing fails, but List and Set work.
% 
%MatLab Issues:
%-When setting a camera property a List method is called twice, first to
% check the property exists and again to find which property was set.
% 
%Example: change settings
% C = CameraController;
% C.camera.isonumber = 100;
% C.camera.fnumber = 4;
% C.camera.shutterspeed = 1/200;
% C.camera.compressionsetting = 'Large Fine JPEG';
% C.camera.drive_mode = 'Single-Frame Shooting';
% C.session.downloadonlyjpg = false;
% C.session.folder = 'C:\DSLR';
% C.property.nodownload = false;        %BROKEN with CMD: "Object does not match target type." 
% C.session.useoriginalfilename = false;
% C.session.filenametemplate = '[Camera Name]\[Date yyyy-MM-dd]';
% C.session.allowoverwrite = true;
% C.session.counter = 1;
% C.session.lowercaseextension = 0;
% 
%Example: immediate capture
% C = CameraController;  %initialise
% C.Capture('FileName')  %capture and download image as "FileName.jpg"
% file = C.lastfile      %get last downloaded filenames
% 
%Example: timed capture
% C = CameraController;
% time = ceil(now*24*60*60+1.5)/24/60/60; %upcoming whole second
% file = [datestr(time,'yyyy-mm-dd_HHMMSS.FFF') '_' C.property.devicename]; %timestamp & camera name
% C.Capture(file,time); %capture
% datestr(time)
% 
%Example: two cameras
% C = CameraController;
% C.session.filenametemplate = 'MyTest_[Camera Name]'; %set filename pattern
% C.Cameras(1), C.property.devicename = 'Cam1'; %set camera name (optional)
% C.Cameras(2), C.property.devicename = 'Cam2';
% C.Cmd('CaptureAll')
% 
%Example: focus stacking
% C = CameraController;
% C.Cmd('LiveViewWnd_Show'), pause(1) %turn on live preview
% C.Capture('0'); %capture and number the first photo
% for k = 0:5
%     C.Cmd('LiveView_Focus_MM') %medium step towards near focus
%     pause(4) %wait for focus to change, may need to adjust delay!
%     C.Capture(num2str(k)); %capture and number the downloaded photos
% end
% C.Cmd('LiveViewWnd_Hide') %turn off live preview to save battery
%
%Serge 2017 Apr, email bugs/questions/corrections to: <a href="http://mailto:s3rg3y@hotmail.com">s3rg3y@hotmail.com</a>