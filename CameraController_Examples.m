%% Example: download settings
% best to set "Transfer" mode in bottom left of GUI to Camera and Computer
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
 
%% Example: camera settings
C = CameraController;
C.camera.isonumber = 100;
C.camera.fnumber = 4;
C.camera.shutterspeed = 1/200;
C.camera.compressionsetting = 'Large Fine JPEG';
C.camera.drive_mode = 'Single-Frame Shooting';

%% Example: simple capture
C = CameraController; %initialise
C.Capture %capture (filename set by "session.filenametemplate") 
C.Capture('MyPhoto') %capture (set custom filename)
C.Capture('[Time hh-mm-ss]') %capture (use time tag as filename)
file = C.lastfile %get last downloaded filenames

%% Example: timed capture
C = CameraController;
time = ceil(now*24*60*6)/24/60/6; %upcoming whole 10 seconds
file = [datestr(time,'yyyy-mm-dd_HHMMSS.FFF') '_' C.property.devicename]; %timestamp & camera name
C.Capture(file,time); %capture
datestr(time)

%% Example: two cameras
C = CameraController;
C.Cameras(1), C.property.devicename = 'Cam1'; %camera name
C.Cameras(2), C.property.devicename = 'Cam2';
C.session.filenametemplate = '[Camera Name]\[Time hh-mm-ss]'; %filename 
C.Cmd('CaptureAll')

%% Example: focus stacking
C = CameraController;
C.Cmd('LiveViewWnd_Show'), pause(1)  %turn on live preview
for k = 0:2                          %take 3 photos
    C.Focus(-2,'small',1)            %two small step towards near focus
    C.Capture(num2str(k,'Focus%g')); %capture and number the photos
end
C.Cmd('LiveViewWnd_Hide')            %turn off live preview to save battery

%% Example: stream live view
% To remove rectangle: Live View>Display>Show focus rectangle
% To reduce lag enable: Live View>Display>No processing
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

%% Example: debugging
C = CameraController;
C.Clock %show clock (take timed photo of clock to measure capture delay)
C.debug = 2; %display commands and replies

%% Example webserver commands:
% http://localhost:5513                                                     %primitive http GUI 
% http://localhost:5513/?SLC=CaptureNoAf&param1=Test\[Time%20hh-mm-ss]      %capture and set filename
% http://localhost:5513/?CMD=Capture                                        %capture and display controls webpage with currently selected (previous) photo
% http://localhost:5513/?CMD=CaptureAll                                     %capture with all connected cameras
% http://localhost:5513/?SLC=capture&camera=255076227371                    %capture with specified camera, NOT WORKING, Cam1 fires regardless of number
% http://localhost:5513/?SLC=capture&param1=filename&param2=                %param2 is ???
% http://localhost:5513/preview.jpg                                         %preview (~500k) currently selected photo
% http://localhost:5513/?CMD=LiveViewWnd_Show                               %start and display live preview
% http://localhost:5513/liveview.jpg                                        %live preview current frame
% http://localhost:5513/?CMD=LiveViewWnd_Hide                               %stop live preview
% http://localhost:5513/image/IMG_1200.jpg                                  %download image from hdd (must already have been downloaded from camera)
% http://localhost:5513/thumb/large/IMG_1145.jpg                            %thumb large from hdd (must already have been downloaded from camera)
% http://localhost:5513/thumb/small/IMG_1145.jpg                            %thumb small from hdd (must already have been downloaded from camera)
% http://localhost:5513/session.json                                        %current session data
% http://localhost:5513/?SLC=Get&param1=lastcaptured
% http://localhost:5513/?SLC=List&param1=camera
% http://localhost:5513/?SLC=List&param1=camera.fnumber
% http://localhost:5513/?SLC=Set&param1=session.folder&param2=c:\pictures
% http://localhost:5513/?SLC=Set&param1=session.filenametemplate&param2=capture1
 
%% Example CameraControlCmd.exe commands:
%These work even when digiCamControl is off, but they are very SLOW!
% system('"C:\Program Files (x86)\digiCamControl\CameraControlCmd.exe" /filename E:\test\test.jpg /capture')
% system('"C:\Program Files (x86)\digiCamControl\CameraControlCmd.exe" /captureallnoaf')
%See also: http://digicamcontrol.com/doc/userguide/cmd
%These apply to all cameras:
% /help                      - this screen
% /capture                   - capture photo
% /capturenoaf               - capture photo without autofocus
% /captureall                - capture photo with all connected devices
% /captureallnoaf            - capture photo without autofocus with all devices
% /format                    - format camera card(s)
% /session session_name      - use session [session_name]
% /preset preset_name        - use preset [preset_name]
% /folder path               - set the photo save folder
% /filenametemplate template - set the photo save file name template
% /filename fileName         - set the photo save file name
% /counter number            - set the photo initial counter
% /wait [mseconds]           - wait for a keypress or milliseconds
% /nop                       - force past usage with no parameters 
% /verbose                   - lots of status messages 
%These apply to main camera:
% /export filename.txt       - export current connected camera properties 
% /iso isonumber             - set the iso number ex. 100 200 400 
% /aperture aperture         - set the aperture number ex. 9,5 8,0 
% /shutter shutter speed     - set the shutter speed ex. "1/50" "1/250" 1s 3s 
% /ec compensation           - set the exposure comp. -1,5 +2 
% /compression compression   - set the compression Ex: JPEG_(NORMAL) RAW_+_JPEG_(FINE) 
%Nikon only:
% /comment comment           - set in camera comment string 
% /copyright copyright       - set in camera copyright string 
% /artist artist             - set in camera artist string 