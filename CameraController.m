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
%-digiCamControl's "Sync camera time" has known problems (2017 Apr).
%-If set to video mode the focus step size may become smaller and it may
% take ~600 steps, about 2 minutes, to move focus end-to-end on a Canon.
%-camera.exposurestatus was removed because it wasn't working (Canon 70D).
%-When digiCamControl 2.0.72 starts focusmode is set to blank (Canon 70D)
%-Other known issues: http://digicamcontrol.com/phpbb/viewforum.php?f=4
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
 
%Changes:
%v1.2.2 (2017-05-05)
%-Support a remote http server
%-Better error handling
%-Allow commas in filenames
%-Minor changes and better help
 
%ReadMe:
% fprintf(fopen('ReadMe.txt','w'),'%s',help('CameraController'));fclose all

%Example HTTP webserver commands, use urlread(url)
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

%Can use CameraControlCmd.exe when digiCamControl is off! VERY SLOW!
% http://digicamcontrol.com/doc/userguide/cmd
%Examples:
% system('"C:\Program Files (x86)\digiCamControl\CameraControlCmd.exe" /filename E:\test\test.jpg /capture')
% system('"C:\Program Files (x86)\digiCamControl\CameraControlCmd.exe" /captureallnoaf')
%Applies to all cameras:
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
%Applies main camera:
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

%Can use dll files diectly using NET.addAssembly, did not work for me...
% https://github.com/JonHoy/Matlab_DSLR_Camera_Control/
%>> camera.CapturePhoto();
% Error using CameraControl_MATLAB (line 20)
% Message: The method or operation is not implemented.
% Source: CameraControl.Devices
% HelpLink: 

classdef CameraController < handle
    %% Properties
    properties (Dependent = true) %accessed by other methods
        camera   %GET/SET camera  settings: fnumber, isonumber, shutterspeed, compressionsetting, drive_mode, ...
        session  %GET/SET session settings: folder, filenametemplate, counter, downloadonlyjpg, downloadthumbonly, deletefileaftertransfer, useoriginalfilename, ...
        property %GET/SET device  settings: serialnumber, devicename, nodownload, counter, counterinc, captureinsdram, ...
    end
    properties (SetAccess = private) %read only
        connection; %protocol used to communicate with digiCamControl (set by CheckConnection)
        options     %list valid camera options
        cmds        %list of all commands
        lastfile    %last downloaded filename
        lasterr     %last error message
    end
    properties (Hidden = true) %hidden
        webserver = 'localhost'; %ip/hostname of PC running digiCamControl webserver (leave blank to use dccfolder)
        dccfolder = ''; %folder with CMD on where digiCamControl is running (used only if webserver fails)
        debuglevel = 1; %debug level: 1-print requests, 2-print replies (interfears with outo-compleate)
    end
    
    %% Constructor
    methods (Hidden)
        function C = CameraController(ip,exe,dbg)
            if nargin<1 || isempty(ip),  ip  = 'localhost'; end %default HTTP webserver address
            if nargin<2 || isempty(exe), exe = C.FindDCC;   end %default CMD utility folder location
            if nargin>2 &&~isempty(dbg), C.debuglevel = dbg;end %custom debug level
            [status,err] = C.CheckConnection(ip,exe);
            if status
                [name,err] = C.CheckCamera;
                if ~isempty(name)
                    disp(['C.property.devicename: ' name])
                end
            end
            C.Error(err,1)
        end
    end
    
    %% Methods
    methods
        function [status,err] = CheckConnection(C,ip,fold)
            %Check if digiCamControl responds to HTTP or CMD commands.
            %If successful set C.connection to 'http' or 'cmd' else ''.
            % C.CheckConnection
            % C.CheckConnection(ip)      -custom C.webserver address
            % C.CheckConnection(ip,fold)   -custom C.dccfolder folder
            % [status,err] = C.CheckConnection
            if nargin>=2 && ~isempty(ip),  C.webserver = ip;   end %custom HTTP Webserver address
            if nargin>=3 && ~isempty(fold),C.dccfolder = fold; end %custom CMD Utility folder
            status = 0; err = ''; %init
            if ~isempty(C.webserver)
                [status,err] = C.TestHTTP(C.webserver);
                if status
                    C.connection = 'http';
                end
            end
            if ~status && ~isempty(C.dccfolder)
                [status,err] = C.TestCMD(C.dccfolder);
                if status
                    C.connection = 'cmd';
                else
                    C.connection = ''; %no connection
                end
            end
            C.Error(err,nargout<2)
        end
        
        function [name,err] = CheckCamera(C)
            %Detect camera name (if any) and update its allowed setting
            [name,err] = C.Get('property.devicename'); %check if a camera is connected
            if strcmp(name,' ()') || ~isempty(err)
                err = 'no camera detected';
                name = '';
            else
                C.options = C.Options; %cache camera options
                C.cmds = C.List('Cmds'); %cache commands
            end
            C.Error(err,nargout<2)
        end
        
        function [out,err] = Capture(C,file,time,mode,lag,wait)
            %Capture photo, now or at set timed, with one or all cameras
            % Capture         -capture photo now
            % Capture(file)      -filename, if downloading (no extension)
            % Capture(file,time)    -start time or -delay in seconds
            % Capture(file,time,mode)    -{'no'} 'af' 'All Cameras'
            % Capture(file,time,mode,lag)   -capture lag (sec) {0.4}
            % Capture(file,time,mode,lag,wait) -wait until finished {1}|0
            % [out,err] = Capture(..)        -return error messages
            if nargin<2 || isempty(file), file = '';   end %custom file name
            if nargin<3 || isempty(time), time = [];   end %start capture now or at this absolute time
            if nargin<4 || isempty(mode), mode = 'no'; end %capture mode, 'NoAF' 'AF' 'All'
            if nargin<5 || isempty(lag),  lag  = [];   end %for timed capture start capture this many seconds ahead of specified time
            if nargin<6 || isempty(wait), wait = true; end %wait for capture to be completed before returning
            if ~isempty(file) && (strcmpi(mode(1:2),'al') || any(file==' ') && isequal(C.connection,'cmd'))
                %If user wants a custom filename then set it now if:
                %1) CaptureAll is being used
                %2) filename has a space & cmd utility is being used (SLOW! CMD commands take around 0.4s to run!)
                C.Run(['Set session.filenametemplate ' file]) %set the file
                file = '';
            end
            if ~isempty(time) %is this a timed capture
                if isscalar(time) && time<=0 %delay of minus this many seconds
                    pause(abs(time))
                else %time must be datestr, datevec or datenum
                    if isempty(lag)
                        switch C.connection
                            case 'http', lag = 0.05;
                            case 'cmd',  lag = 0.40;
                        end
                    end
                    time = datenum(time)-lag/24/60/60; %time = datenum(time)-(fudg+focus*0.03-~wait*0.04)/24/60/60;
                    while time>now %loop allows clock adjustments during wait
                        pause(min((time-now)*24*60*60,0.5))
                    end
                end
            end
            switch lower(mode(1:2))
                case {0 'no'}, [out,err] = C.Run('CaptureNoAf',file,[],wait);
                case {1 'af'}, [out,err] = C.Run('Capture'    ,file,[],wait);
                case {2 'al'}, [out,err] = C.Cmd('CaptureAll'); %CaptureAll does not allow extra argument
            end
            if ~nargout
                clear out
            end
        end
        
        function [out,err] = Cameras(C,val)
            %List connected cameras or sellect a camera
            % SN = Cameras        -list of connected cameras serials
            % SN = Cameras(index)  -set current camera using list index
            % SN = Cameras(serial)  -set current camera using serial number
            % [SN,err] = Cameras(.)  -return error string
            %Use property.serialnumber to get current camera's serial
            [SN_list,err] = C.List('cameras'); %all cameras serial numbers
            if nargin>1
                if isnumeric(val) %index selection mode
                    try
                        val = SN_list{val};
                    catch %#ok<CTCH>
                        out = '';
                        err = 'invalid camera index';
                        C.Error(err,nargout<2)
                        return
                    end
                end
                old = C.Get('property.serialnumber'); %current camera serial number
                [out,err] = C.Set('camera',val,old,SN_list); %change camera if different
                if ~strcmp(out,old) %has selected camera changed
                    C.options = C.Options; %cache new camera options
                    C.cmds = C.List('Cmds'); %cache single-line-commands
                end
            else
                out = SN_list;
            end
            C.Error(err,nargout<2)
        end
        
        function [out,err] = Sessions(C,val)
            %List available session or set current session
            % names = Sessions    -list available session names
            % name = Sessions(name)  -set current session
            % [name,err] = Sessions(.)  -return error string
            %Note: use session.name to get current session
            [list,err] = C.List('sessions'); %all session names
            if nargin>1
                if isnumeric(val) %index selection mode
                    try
                        val = list{val};
                    catch %#ok<CTCH>
                        out = '';
                        err = 'invalid camera index';
                        C.Error(err,nargout<2)
                        return
                    end
                end
                old = C.Get('session'); %current session name
                [out,err] = C.Set('session',val,old,list);
            else
                out = list;
            end
        end
        
        function [status,err] = Cmd(C,cmd)
            %Run a single line command, or list available commands.
            % cmds = Cmd         -list of single-line-commands (cellstr)
            % [cmd,err] = Cmd(cmd) -run command and return errors (string) 
            status = 0; %init
            [I,mch] = C.Compare(C.cmds,cmd);
            if sum(I) == 1
                [~,err] = C.Run('Do',mch); %Do commands do not return anything
                if isempty(err)
                    status = 1;
                end
            else
                err = sprintf('Invalid command: options are:%s',sprintf('\n''%s''',C.cmds{:}));
            end
            C.Error(err,nargout<2)
        end
        
        function [status,err] = Focus(C,Num,Mode,Wait)
            %Adjust camera focus, or auto-focus
            % Focus([])    -auto focus, lens must be set to AF
            % Focus(Num)      -number of steps, +ve=far-field, -ve=near
            % Focus(Num,Mode)    -type of step {'small'} 'med' 'large'
            % Focus(Num,Mode,Wait)  -time delay per step (sec)
            %Starts live view, lens can be in MF|AF, camera can be in M|A..
            %Step size can be set in: File>Settings>Live view
            C.Cmd('LiveViewWnd_Show') %can skip if LiveView is on
            if nargin<2 || isempty(Num)
                [status,err] = C.Cmd('LiveView_Focus'); %auto focus, user must wait for focus to finish manually
            elseif Num ~= floor(Num);
                err = 'Focus step must be an integer';
            elseif Num==0
                %do nothing
            else
                if nargin<3 || isempty(Mode) %default step mode
                    Mode = 'small';
                end
                if nargin<4 || isempty(Wait) %default delay
                    switch lower(Mode(1))
                        case 's', Wait = 0.4; %adjust these
                        case 'm', Wait = 2;
                        case 'l', Wait = 10;
                    end
                end
                if Num > 0, cmd = 'P'; %towards far focus
                else        cmd = 'M'; %towards near focus
                end
                switch lower(Mode(1))
                    case {1 's'}, %do nothing
                    case {2 'm'}, cmd = [cmd cmd];
                    case {3 'l'}, cmd = [cmd cmd cmd];
                end
                for k = 1:abs(Num)
                    [status,err] = C.Cmd(['LiveView_Focus_' cmd]); %send command
                    pause(Wait)
                end
            end
            C.Error(err,nargin<2)
        end
        
        function Clock(~,run_in_this_session)
            %Display figure with a clock with miliseconds for testing.
            % Clock
            %This should be done using listeners, this is super ugly!
            if nargin<2 || ~run_in_this_session
                !matlab -nodesktop -nosplash -minimize -r "try C=CameraController;C.Timer(1);catch,exit,end" &
                %!matlab            -nosplash -minimize -r "try C=CameraController;com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame.hide;C.Timer(1);catch,exit,end" &
                return
            end
            figure(1), clf, axis off
            set(gcf,'color','k','name','Timer','numb','off','menu','n','tool','n')
            h0 = text(0.5,0.95,'','fonts',60,'hor','cen','color','w');
            h1 = text(0  ,0.7 ,'','fonts',60,'hor','cen','color','w');
            h2 = text(0  ,0.5 ,'','fonts',60,'hor','cen','color','w');
            h3 = text(0  ,0.3 ,'','fonts',60,'hor','cen','color','w');
            h4 = text(0.5,0.0 ,'','fonts',60,'hor','cen','color','w');
            o = now; %init
            n = 100;
            D = nan(1,n);
            c = 1;
            %addlistener(h4,'String','PostSet',@(~,~)set(gco,'String',datestr(rand,'SS.FFF')));
            %set(h4,'String',datestr(now,'SS.FFF'))
            while 1
                pause(0.0001)
                t = now;
                p1 = floor(mod(t*24*60*60    ,10)); %sec
                p2 = floor(mod(t*24*60*60*10 ,10)); %1/10 sec
                p3 = floor(mod(t*24*60*60*100,10)); %1/100 sec
                set(h1,'pos',[p1/10 0.7 0],'str',num2str(p1))
                set(h2,'pos',[p2/10 0.5 0],'str',num2str(p2))
                set(h3,'pos',[p3/10 0.3 0],'str',num2str(p3))
                d = t - o;
                D(c) = d;
                c = mod(c,n)+1;
                o = t;
                t = datestr(t,'HH:MM:SS.FFF');
                set(h0,'str',t)
                set(h4,'str',num2str(nanmean(D)*24*60*60,'%.3fs'))
                drawnow
            end
        end
    end
    
    %% Hidden methods
    methods (Hidden)
        function [out,err] = Run(C,cmd,prp,val,wait)
            %Send HTTP or CMD command to digiCamControll
            % Run(cmd)       -action (string)
            % Run(cmd,prp)       -first argument (string)
            % Run(cmd,prp,val)       -optional argument, default ''
            % Run(cmd,prp,val,wait)  -wait for commands to finish, default true
            % [out,err] = Run(..)    -output reply and error strings
            if nargin<3 || isempty(prp), prp = ''; end
            if nargin<4 || isempty(val), val = ''; end
            if nargin<5 || isempty(wait),wait = true; end
            out = ''; err = ''; %init
            switch C.connection
                case 'http' %webserver
                    cmd = ['http://' C.webserver ':5513/?SLC=' cmd]; 
                    if ~isempty(prp)
                        cmd = [cmd '&param1=' regexprep(prp,{' ' '=' ';'},{'%20' '%3D' '%3B'})]; %allow spaces and equal signs [www.w3schools.com/tags/ref_urlencode.asp]
                    end
                    if ~isempty(val)
                        val = regexprep(val,{' ' '='},{'%20' '%3D'}); %replace spaces and equal signs
                        val = regexprep(val,'[<>:"\\|?*]',''); %windows filename forbids [<>:"/\\|?*], but [/] is needed for fractions
                        if ~isempty(val)
                            cmd = [cmd '&param2=' val];
                        end
                    end
                    if C.debuglevel >= 2 %display HTTP command
                        %disp(['>> ' cmd]) %plain text
                        %disp(['>> urlread(' cmd ')']) %matlab command
                        %disp(['<a href="' cmd '">' cmd '</a> ']) %clickable link that opens browser 
                        disp(['<a href="matlab:urlread(''' cmd ''')">' cmd '</a> ']) %clickable link that runs in matlab
                    end
                case 'cmd'
                    cmd = ['"' fullfile(C.dccfolder,'CameraControlRemoteCmd.exe') '" /c ' cmd ]; %spaces are not allowed in filename, this also prohibits the use of most tags
                    if ~isempty(prp)
                        cmd = [cmd ' "' strrep(prp,' ','_') '"'];
                    end
                    if ~isempty(val)
                        val = regexprep(val,'[<>:"\\|?*;]',''); %windows filename forbids [<>:"/\\|?*], but [/] is needed for fractions, and dcc cmd forbids [;]
                        if ~isempty(val)
                            cmd = [cmd ' ' val];
                        end
                    end
                    if C.debuglevel >= 2 %display CMD command
                        %disp(['>> ' cmd]) %plain text
                        disp(['>> system(''' cmd ''')']) %matlab command
                        % disp(['<a href="' cmd '">' cmd '</a> ']) %clickable link that opens browser 
                        % disp(['<a href="matlab:system(''"' cmd ''')">' cmd '</a> ']) %clickable link that runs in matlab
                        % t=['<a href="matlab:system(''"' cmd ''')">' cmd '</a> '];
                        % t = system([''char([' sprintf('%g ',t) '])''])
                        % t=['matlab:eval(''system([''' t '''])'')']
                        % 
                        % disp(['<a href="matlab:system(''hi'')">' cmd '</a> ']) %clickable link that runs in matlab
                        % disp(['<a href="matlab:eval([system(''hi'')])>' cmd '</a> ']) %clickable link that runs in matlab
                    end
            end
            if wait || strcmp(C.connection,'http') %should program wait while command executes
                %currently can't not wait for compleation with webserver.'
                switch C.connection
                    case 'http' %webserver
                        [out,status] = urlread(cmd); %send httm request and read reply
                        if C.debuglevel>=3
                            disp(out) %display replies
                        end
                        if ~isempty(out) && out(end)==10; %remove trailing linefeeds
                            out(end) = [];
                        end
                        if isempty(out)
                            %should this issue an error???
                        end
                        out = strrep(out,'Cannot perform runtime binding on a null reference','No camera detected'); %improve some error msgs
                        if ~status || strcmp(out,'Unknow parameter') || strncmpi(out,'Wrong value',11) || strcmp(out,'No camera detected')
                            err = out;
                            out = '';
                        end
                    case 'cmd'
                        [failed,out] = system(cmd); %run cmd command and read reply
                        if C.debuglevel>=3
                            disp(['ans =' 10 out]) %display replies
                        end
                        [out,err] = C.CleanCMD(out);
                        if C.debuglevel>=4
                            disp(['ans =' 10 out]) %display replies
                        end
                        if failed || strncmpi(out,'error',5)
                            err = out;
                            out = '';
                        end
                end
            else %don't wait for completion (return a java runtime object)
                try
                    out = java.lang.Runtime.getRuntime().exec(cmd);
                catch e
                    err = sprintf(e.message);
                end
            end
            C.Error(err,nargout<2)
        end
        function [out,err] = Get(C,prop)
            [out,err] = C.Run('Get',prop);
            out = regexprep(out,{'True' 'False'},{'true' 'false'}); %HACK
            C.Error(err,nargout<2)
        end
        function [new,err] = Set(C,prp,val,old,opt)
            % [new,err] = Set(C,prp,val,old,opt)
            if nargin<4, old = ''; end %current value, to avoid superfluos set commands
            if nargin<5, opt = {}; end %default valid options
            new = ''; err = ''; %init
            if ~ischar(val)
                val = mat2str(val); %convert numbers to strings
            end
            if ~isempty(opt) %are valid options known
                [~,val] = C.Compare(opt,val); %find match
                if isempty(val) %no match found
                    err = sprintf('Invalid assignment: options are:%s',sprintf(' ''%s''',opt{:}));
                    C.Error(err,nargout<2)
                    return
                end
            end
            if strcmpi(old,val) %is old value known and is it different
                new = val; %do nothing
            else
                [~,err] = C.Run('Set',prp,val); %send command
                new = C.Get(prp); %varify value after set (can skip this)
                if ~isequal(new,val) && ~isequal(str2num(lower(new)),str2num(lower(val))) %varify success, allows: 'True'='true'=true=1
                    err = sprintf('Set command failed: %s',err);
                end
            end
            C.Error(err,nargout<2)
        end
        function [out,err] = List(C,cmd)
            [out,err] = C.Run('List',cmd);
            if ~isempty(out) && isempty(err)
                out = regexprep(out,{'True' 'False'},{'true' 'false'}); %HACK
                out = regexp(strtrim(out),'\n','split')';
            end
            C.Error(err,nargout<2)
        end
        function s = Options(C)
            %Get a list of valid camera options as struct of cellstr
            params = fieldnames(C.camera); %list of parameters
            for k = 1:numel(params)
                s.(params{k}) = C.List(['camera.' params{k}])'; %list options for each parameter
            end
        end
    end
    
    %% get/set methods
    %Set methods do not know which sub-field(s) were set, to avoid setting
    %all fields they GET current values and SET only those that changed.
    methods
        function s = get.camera(C) %Get current camera settings as struct, empty if no camera
            s = C.List('camera'); %camera settings as cellstr, eg 'camera.fnumber=4.0'
            if isempty(s)
                C.Error('No camera detected')
            else
                s = regexp(s,'camera\.(.*?)=(.*)','tokens','once'); %split fields and values, eg {{'fnumber' '4.0'};...}
                s = cat(1,s{:})'; %form a cellstr table 2-by-n
                s(1,:) = regexprep(s(1,:),{'\.','-'},''); %remove ".","-" from field names
                s = struct(s{:}); %make a struct
                if isfield(s,'exposurestatus')
                    s = rmfield(s,'exposurestatus'); %"exposurestatus" is read only and does not appear to change with a Canon
                end
            end
        end
        function s = get.session(C)
            s = C.List('session');
            s = regexp(s,'session\.(.*?)=(.*)','tokens','once');
            s = cat(1,s{:})';
            %s(2,strcmpi(s(2,:),'True' )) = {true};
            %s(2,strcmpi(s(2,:),'False')) = {false};
            s(2,:) = regexprep(s(2,:),{'^False$' '^True$'},{'false' 'true'}); %change case for consistancy
            s = struct(s{:});
        end
        function s = get.property(C)
            s = C.List('property');
            s = regexp(s,'property\.(.*?)=(.*)','tokens','once');
            s = cat(1,s{:})';
            %s(2,strcmpi(s(2,:),'True' )) = {true};
            %s(2,strcmpi(s(2,:),'False')) = {false};
            s(2,:) = regexprep(s(2,:),{'^False$' '^True$'},{'false' 'true'}); %change case for consistancy
            s = struct(s{:});
        end
        function c = get.lastfile(C)
            c = C.Get('lastcaptured');
            if any(strcmp(c,{'-' '?'}))
                c = '';
            end
        end
        %Due to the way this class is structured attempts to set a property
        %will first trigger a get method (not needed) and then set method.
        function set.camera(C,new)
            %dcc can list valid option for each camera.parameter, so we
            %can do a bit of common sence check to guess which value the
            %user wanted or tell the user valid options if we can't figure
            %it out. But there are a few strange transient parameter that
            %make this tricky, eg camera.focusmode & camera.bracketing
            %which are sometimes not reported by "Get camera".
            old = C.camera; %get current settings
            if ~isempty(old)
                for f = fieldnames(new)' %step through parameters
                    if ~isfield(C.options,f{1}) %have options for this parameter been cached
                        [list,err] = C.List(['camera.' f{1}]); %is this a valid parameter
                        if isempty(err)
                            C.options.(f{1}) = list'; %update valid parameter options
                        else
                            C.Error(err,1) %display error
                            continue
                        end
                    end
                    if ~isfield(old,f{1})
                        old.(f{1}) = ''; %init
                    end
                    C.Set(['camera.' f{1}],new.(f{1}),old.(f{1}),C.options.(f{1})); %Set each property if it changed and if value is valid
                end
            end
        end
        function set.session(C,new)
            old = C.session;
            for f = fieldnames(new)'
                C.Set(['session.',f{1}],new.(f{1}),old.(f{1}),'');
            end
        end
        function set.property(C,new)
            old = C.property;
            for f = fieldnames(new)'
                C.Set(['property.',f{1}],new.(f{1}),old.(f{1}),'');
            end
        end
    end
    
    %% Helper functions
    methods (Static = true, Hidden = true)
        function [status,err] = TestHTTP(ip)
            %Test HTTP webserver communication
            % [status,err] = TestHTTP(ip)
            status = 0; err = ''; %init
            try
                t = java.net.URL([],['http://' ip ':5513'],sun.net.www.protocol.http.Handler).openConnection; %does this work on linux?
                %t.setConnectTimeout(0.5); t.setReadTimeout(0.5); %timeout not working, defaults to ~2.5 seconds
                t.getInputStream;
                status = 1; %success
            catch e
                if     strfind(e.message,'connect timed out'), err = 'HTTP connect timed out';
                elseif strfind(e.message,'UnknownHost'),       err = 'HTTP unknown address';
                elseif strfind(e.message,'Permission denied'), err = 'HTTP permission denied';
                else                                           err = ['HTTP ' e.message];
                end
            end
        end
        function [status,err] = TestCMD(dccfolder)
            %Test CMD utility communication
            % [status,err] = TestCMD(dccfolder)
            status = 0; err = ''; %init
            [~,t] = system('tasklist /FI "imagename eq CameraControl.exe"'); %can skip this test, but will take a long time to fail if app is not running
            if isempty(strfind(t,'CameraControl.exe'))
                err = 'CMD main application not running';
            else
                exe = fullfile(dccfolder,'CameraControlRemoteCmd.exe');
                if ~exist(exe,'file')
                    err = 'CMD utility not found';
                else
                    [fail,msg] = system(['"' exe '" /c Get "property.devicename"']);
                    if ~fail
                        status = 1; %success
                    else
                        err = ['CMD ' msg];
                    end
                end
            end
        end
        function dccfolder = FindDCC
            %Check default install location for digiCamControl app
            % dccfolder = FindDCC
            if ~isempty(java.lang.System.getenv('ProgramFiles(x86)')) %is windows 64 bit
                dccfolder = fullfile(char(java.lang.System.getenv('ProgramFiles(x86)')),'digiCamControl'); %default folder on win64
            else
                dccfolder = fullfile(char(java.lang.System.getenv('ProgramFiles')),'digiCamControl'); %default folder on win32
            end
            if ~isdir(dccfolder)
                dccfolder = '';
            end
        end
        function [str,err] = CleanCMD(str)
            %clean up cmd responce (faster then using /clean argument)
            str = regexp(str,'(?<=:;response:).*?(?=[;]*\n)','match','once');
            if strncmpi(str,'error',5) %was an error generated
                err = regexprep(str,'error;message:',''); %clean error message
                str = '';
            else
                err = '';
                if ~isempty(str) && strcmp(str(1),'[') %is string a list
                    str = regexprep(str,{'","' '^[' ']$'},{'"\n"' '' ''}); %replace commas with linefeed, remove start end braces
                end
                str = regexprep(str,{'\\\\' '"'},{'\\' ''}); %remove any escape charecter and quotes
            end
        end
        function [I,mch] = Compare(opt,str)
            %Flexible comparison of cellstr to string, return best match
            % [I,mch] = Compare(opt,str)
            I = strcmpi(str,opt); %compare whole string
            if ~any(I) %try start of string comparison
                num = str2num(str); %#ok<ST2NM> eg '1/200'=0.005
                if ~isempty(num)
                    I = cellfun(@(x)isequal(str2num(x),num),opt); %#ok<ST2NM> may want to a rounding tollarance
                end
                if ~any(I) %try numeric comparison
                    I = strncmpi(opt,str,numel(str));
                    if ~any(I) %try fragment of string comparison
                        I = ~cellfun(@isempty,strfind(lower(opt),lower(str))); 
                    end
                end
            end
            if sum(I)==1
                mch = opt{I};
            else
                mch = '';
            end
        end
    end
    methods (Access = private)
        function Error(C,err,display)
            if ~isempty(err)
                C.lasterr = err; %save last error
                if display
                    fprintf('%s\n',err)
                end
            end
        end
    end
    
    %% Hide handle methods by overloading them
    methods(Hidden)
        function l = addlistener(varargin), l = addlistener@handle(varargin{:}); end
        function     notify     (varargin),     notify@handle     (varargin{:}); end
        function     delete     (varargin),     delete@handle     (varargin{:}); end
        function h = findobj    (varargin), h = findobj@handle    (varargin{:}); end
        function p = findprop   (varargin), p = findprop@handle   (varargin{:}); end
        function b = eq(varargin),          b = eq@handle(varargin{:});          end
        function b = ne(varargin),          b = ne@handle(varargin{:});          end
        function b = lt(varargin),          b = lt@handle(varargin{:});          end
        function b = le(varargin),          b = le@handle(varargin{:});          end
        function b = gt(varargin),          b = gt@handle(varargin{:});          end
        function b = ge(varargin),          b = ge@handle(varargin{:});          end
        %isvalid is a sealed method and cannot be overloaded
    end
end
