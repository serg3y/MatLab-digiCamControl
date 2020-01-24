%Controller (v1.3.5) for tethered DSLR cameras using <a href=http://digicamcontrol.com/>digiCamControl</a> app.
% C = CameraController   -create class
% C = CameraController(dcc)  -digiCamControl location
% C = CameraController(dcc,debug)  -set debug level
%dcc: digiCamControl's webserver IP or CMD remote utility folder.
% If empty this class tests the default webserver, 'localhost:5513', then
% default app install locations, 'C:\Program Files (x86)\digiCamControl'.
%debug: 0=silent, 1=minimal (default), 2=print requests, 3=print replies
% 
%Description:
%-This class uses digiCamControl (windows only app) to control supported
% cameras: set ISO, exposure, focus, aperture(fnumber), white balance,
% stream liveview, capture photos & video, configure file download, etc.
%-digiCamControl is a multi purpose, free, open source, Windows only
% application that can control a host of <a href=http://digicamcontrol.com/cameras>supported cameras</a>. 
% 
%Setup:
%1.Install latest version of digiCamControl from:
%  https://sourceforge.net/projects/digicamcontrol/files/latest/download
%2.Enable webserver: File > Settings > Webserver > Enable "Use web server,
%  & "Allow interaction via webserver", use port "5513" > *!RESTART APP!*
%3.Connect one or more cameras using USB cable (or WiFi if supported?).
%4.For full control of a Canon DSLR set body and lens to manual.
%5.Use digiCamControl app to ensure camera is working.
% 
%Remarks:
%-This class communicates with camera(s) via digiCamControl's included 
% <a href=http://digicamcontrol.com/doc/userguide/web>webserver</a>(recommended) or <a href=http://digicamcontrol.com/doc/userguide/remoteutil>CMD Utility</a>. 
%-The webserver is much faster and allows camera(s) to be controlled from
% any Windows/Linux computer on the network or via the <a href=http://digicamcontrol.com/doc/userguide/settings#webserver>internet</a>. 
%-Visit http://digiCamControl.com for <a href=http://digicamcontrol.com/doc>documentation</a>, <a href=http://digicamcontrol.com/phpbb/>forums</a> and to <a href=http://digicamcontrol.com/donate>donate</a>.
%-Method in this class are Capitalised and have additional descriptions.
%-When this class is created it does a one-off retrieval of allowed camera
% options. Reinitialise this class when swapping cameras.
% 
%Limitations:
%-This class can only stream liveview (low-rez, noisy, ~15Hz) from 
% <a href=http://digicamcontrol.com/cameras>supported cameras</a>. However digiCamControl does support "Open Broadcaster
% Software" (OBS) and "XSplit", see <a href=http://digicamcontrol.com/doc/usecases/live>Streaming</a> and <a href=http://digicamcontrol.com/phpbb/search.php?keywords=%5BOBS+%7C+XSplit+%7C+streaming%5D&terms=any&author=&sc=1&sf=all&sr=posts&sk=t&sd=d&st=0&ch=300&t=0&submit=Search>Search Forums</a> for info.
%-Non-alphanumeric characters found in some Nikon camera properties are
% being removed. These properties can be read but cannot be set. 
% eg "-", "." in "center-weighted_area" "active_d-lighting" "long_exp._nr"
%-digiCamControl issues: http://digicamcontrol.com/phpbb/viewforum.php?f=4
%-Focus method does not know how long it needs to wait after a focus change
% is requested, see Focus method help to set custom delays.
%-LiveView can only be 'streamed' when using the webserver.
% 
%Camera Settings:
%-Some settings will not have affect if camera is not in Manual mode (M).
%-To control focus ensure lens is set to Manual Focus (MF):
%-Focus step size & speed can be modified in: <a href=http://digicamcontrol.com/doc/userguide/settings#live-view>File>Settings>Live view</a>
%-Note: Lenses use servo motors which have no discrete physical 'steps'. To
% achieve a specific focus reproducibly try to go to the lens's physical
% limit, in either direction, and apply the same 'steps' from there.
% 
%Image Capture:
%-To reduce capture latency from 0.3-0.6 sec to ~0.05s ensure webserver is
% enabled, File>Settings>Webserver>Enable>RESTART APP
%-To measure delay and variance try imaging the computer's own clock by
% calling the Clock method provided with this class, C.Clock, however
% I do not know how to measure monitor display latency and variance.
%-Cmd('CaptureAll') will trigger all connected cameras but there will be a
% lag of 0.005-0.020 sec between consecutive cameras.
%-To record video turn on live preview using Cmd('LiveViewWnd_Show') and
% user Cmd('StartRecord') and Cmd('StopRecord').
% 
%Image Download:
%-Download is affected by Transfer mode (in app) and session settings.
%-Transfer mode is set via the main app to: PC & Camera | Camera only, if
% set to Camera only some session settings will be ignored. Set it to PC
% & Camera and use session setting "deletefileaftertransfer" if needed.
%-session setting "filenametemplate" works only if "useoriginalfilename" is
% disabled, and it is applied to downloaded files only, not camera files.
% It supports many useful [tags], eg: [Date yyyy-MM-dd], [Time hh-mm-ss],
% [Date yyyy-MM-dd-hh-mm-ss], [Exif.Photo.ExposureTime],
% [Exif.Photo.FNumber], [Exif.Photo.ISOSpeedRatings], etc 
% (for a full list go to: Session>Edit Current Session>File Name Template)
%-"filenametemplate" can be set when calling the Capture method and applies
% to all connected cameras. To distinguish cameras use [Camera Name] or
% [Camera Counter 4 digit] tags in the template.
%-"folder" does not support [tags], instead use "\" in "filenametemplate".
%-Manual download of files from the camera can only be done via the app.
% 
%Example:
% C = CameraController; %initialise
% C.session.folder = 'C:\DSLR'; %download settings
% C.session.filenametemplate = '[Camera Name]\[Date yyyy-MM-dd-hh-mm-ss]';
% C.camera.isonumber = 3200; %camera settings
% C.camera.fnumber = 5.6;
% C.camera.shutterspeed = 1/200;
% C.Capture %capture
% C.lastfile %last filename
% 
%Serge 2018
% GitHub: https://github.com/serg3y/MatLab-digiCamControl
% Bugs/fixes: s3rg3y@hotmail.com (include software versions, camera model)
% Note: I am not a developer of the digiCamControl app.
 
%TODO:
%-Allow camera to be changed on the fly, but how to detect camera change
% without increasing capture delay by doing a camera check before each command?
%-Due to the way this class is structured (using structs to group multiple
% properties) when setting a property a get method is run, which is not
% needed, and then the set method, but how to avoid this while
% maintaining the user interface? 
%-detect CMD utility location even if digiCamControll is installed to
% locations other then %ProgramFiles% or %ProgramFiles(x86)%.
%-Still needs a lot more testing, especially on Linux.
 
%Change Log:
%v1.3.5 (2018-12-12)
%-Support for older versions of MatLab, eg 2015b
%v1.3.4 (2018-11-30)
%-fixed error msg when no camera is connected
%v1.3.3 (2018-11-23)
%-fixed multiple camera support and improved the multiple camera example
%v1.3.2 (2018-08-05)
%-webserver IP can include a port number (default: 'localhost:5513')
%-capture "lag" now a property rather then input to Capture method
%-fixed error with duplicate fields on Nikon
%-debug property no longer hidden
%v1.3.1.2 (2018-07-03)
%-mostly comments
%v1.3.1 (2018-02-24)
%-bunch of minor stuff
%v1.3 (2017-07-22)
%-Support a remote http webserver
%-Better error handling
%-Allow commas in filenames
%-Minor changes and better help
 
%Description for MatLab central:
% clc,disp(regexprep(help('CameraController'),{'<a .*?>|</a>|^ |.{63}$' '\n ' ' *'},{'' '\n' ' '})) 
 
classdef CameraController < handle
    %% Properties
    properties (Dependent = true) %accessed by other methods
        camera   %GET/SET camera  settings: fnumber, isonumber, shutterspeed, compressionsetting, drive_mode, ...
        session  %GET/SET session settings: folder, filenametemplate, counter, downloadonlyjpg, downloadthumbonly, deletefileaftertransfer, useoriginalfilename, ...
        property %GET/SET device  settings: serialnumber, devicename, nodownload, counter, counterinc, captureinsdram, ...
    end
    properties (SetAccess = private) %read only
        options    %list of valid camera options (cached during class creation)
        cmds       %list of valid commands (cached during class creation)
        connection %protocol used to communicate with digiCamControl (set by CheckConnection)
        lastfile   %last downloaded filename
        lasterr    %last error message
    end
    properties
        dcc %ip of PC running digiCamControl webserver OR folder on this computer with digiCamControl CMD utility
        debug %debug level: 0-silent, 1-basic info (default), 2-print requests, 3-print replies 
        lag %timed capture will start this many seconds ahead of specified time to adjust for interface and camera delays (default: 0.05 for webserver and 0.4 for CMD)
    end
    
    %% Constructor
    methods (Hidden = true)
        function C = CameraController(dcc,debug)
            if nargin<1 || isempty(dcc),   C.dcc = '';  else, C.dcc   = dcc; end
            if nargin<2 || isempty(debug), C.debug = 1; else, C.debug = debug; end
            if C.CheckConnection(C.dcc) %prints error msgs, if any
                switch C.connection
                    case 'HTTP', C.lag = 0.05;
                    case 'CMD',  C.lag = 0.4;
                end
                if C.debug > 0
                    fprintf('connection type is: ''%s'' (capture lag set to %g sec, affects only "timed capture")\n',C.connection,C.lag)
                    fprintf('digiCamControl location is: ''%s''\n',C.dcc)
                end
                [name,serials] = C.CheckCamera;
                if ~isempty(name)
                    t = sprintf('%s, ',serials{:});
                    if C.debug > 0
                        fprintf('connected camera serials are: ''%s''\n',t(1:end-2))
                        fprintf('current camera name is: ''%s''\n',name)
                    end
                end
            end
        end
    end
    
    %% Methods
    methods
        function [status,err] = CheckConnection(C,dcc)
            %Check if digiCamControl responds to HTTP or CMD commands.
            %If successful set C.connection to 'HTTP' or 'CMD' else ''.
            % C.CheckConnection    -try to connect to 'localhost' via http
            %                       else dcc install folder via cmd
            % C.CheckConnection(ip)   -use custom webserver address
            % C.CheckConnection(fold)   -use custom cmd utility folder
            % [status,err] = C.CheckConnection
            C.connection = ''; err = ''; %init
            if nargin<2 || isempty(dcc) %auto: try default webserver IP, then default CMD location
                C.dcc = 'localhost:5513'; %default HTTP
                [status,err1] = C.TestHTTP(C.dcc);
                if status
                    C.connection = 'HTTP'; %success
                else
                    [C.dcc,err2] = C.FindDCC;
                    if ~isempty(err2)
                        err = [err1 ', ' err2]; %multiple errors
                    else
                        [status,err3] = C.TestCMD(C.dcc);
                        if status %success
                            C.connection = 'CMD';
                            if C.debug > 0
                                fprintf('Note: It is recomended to use HTTP webserver to reduce capture latency and to stream LiveView\n')
                            end
                        else
                            err = [err1 ', ' err3]; %multiple errors
                        end
                    end
                end
            else %try one
                switch upper(dcc)
                    case 'HTTP', C.dcc = 'localhost:5513'; %try default HTTP location
                    case 'CMD',  [C.dcc,err] = C.FindDCC; %try default CMD location
                    otherwise,   C.dcc = dcc; %custom location
                end
                if ~isempty(C.dcc)
                    if exist(C.dcc,'file')==7 %isdir, must be CMD location
                        [status,err] = C.TestCMD(C.dcc);
                        if status
                            C.connection = 'CMD';
                        end
                    else %assume HTTP location
                        if ~any(C.dcc==':') %address only, no port
                            C.dcc = [C.dcc ':5513']; %append default port
                        end
                        [status,err] = C.TestHTTP(C.dcc);
                        if status
                            C.connection = 'HTTP';
                        end
                    end
                end
            end
            C.Error(err,nargout<2)
        end
        function [name,serials,err] = CheckCamera(C)
            %Detect camera name (if any) and update its allowed setting
            name = ''; %init
            [serials,err] = C.Cameras;
            if ~isempty(serials) %is a camera connected
                [name,err] = C.Get('property.devicename');
                C.options = C.Options; %cache camera options
                C.cmds = C.List('Cmds'); %cache commands
            end
            C.Error(err,nargout<3)
        end
        
        function [out,err] = Capture(C,file,time,mode,block)
            %Capture photo, now or at set timed, with one or all cameras
            % Capture         -capture photo now
            % Capture(file)       -filename, if downloaded (no extension)
            % Capture(file,time)      -start time (datenum) or -delay (sec)
            % Capture(file,time,mode)      -{'noaf'} 'af' 'all'
            % Capture(file,time,mode,block)    -wait until finished {true}
            % [out,err] = Capture(..)          -catch error messages
            %file: filename, if downloaded to pc (no extension)
            %      eg ['[Date yyyy-MM-dd]\' datestr(now,'HH-MM-SS.FFF')]
            %time: if empty - capture immediately
            %      if positive or string - absolute time of when to capture
            %         (ie datenum or datestr, eg '2018-05-25 23:38:44.50')
            %      if negative - a delay for capture in seconds (eg -10)
            %mode: 'noaf' - capture without autofocus (default)
            %      'af'   - autofocus and if successful then capture
            %      'all'  - capture with all connected cameras
            %block:if true wait for capture to be completed (default)
            if nargin<2 || isempty(file), file = '';    end %custom file name
            if nargin<3 || isempty(time), time = [];    end %start capture now or at this absolute time
            if nargin<4 || isempty(mode), mode = 'noaf';end %capture mode, 'noaf' 'af' 'all'
            if nargin<5 || isempty(block),block= true;  end %wait for capture to be completed before returning
            if ~isempty(file) && (strcmpi(mode,'all') || any(file==' ') && isequal(C.connection,'CMD')) 
                %user wants to set the filename but this is not allowed
                %(directly) when using CaptureAll or when using CMD if
                %filename contains a space, so lets set it manualy now.
                C.Run(['Set session.filenametemplate ' file]) %set filename
                file = '';
            end
            if ~isempty(time) %timed capture
                if isscalar(time) && time<=0 %delay by minus this many seconds
                    pause(abs(time))
                else %time is datestr, datevec or datenum
                    time = datenum(time)-C.lag/24/60/60; %when to capture
                    while time>now %wait, loop to allow for system clock to be adjusted during long waits
                        pause(min((time-now)*24*60*60,0.5))
                    end
                end
            end
            switch lower(mode) %capture
                case 'noaf', [out,err] = C.Run('CaptureNoAf',file,[],block);
                case 'af',   [out,err] = C.Run('Capture'    ,file,[],block);
                case 'all',  [out,err] = C.Cmd('CaptureAll'); %CaptureAll does not support extra argument
            end
            if ~nargout
                clear out
            end
        end
        
        function [I,err] = LiveView(C)
            err = ''; %init
            I = [];
            if strcmp(C.connection,'HTTP')
                try
                    I = imread(['http://' C.dcc '/liveview.jpg'],'jpg');
                catch e
                    if strcmp(e.identifier,'MATLAB:imagesci:imread:readURL')
                        err = 'HTTP connection timed out';
                    elseif strcmp(e.identifier,'MATLAB:imagesci:jpeg_depth:unhandledLibraryError')
                        err = 'Live view not active';
                        %alternative is to turn on live view and wait
                        %upto ~4 sec for image, however when live-view is
                        %turned off the old live view image is cached and
                        %there is no way to tell that live view is actually
                        %off. So the onus is on user to ensure live view is
                        %turned on and is running.
                        % warning('off','MATLAB:imagesci:jpeg_depth:libraryMessage') %suppress repeated warnings
                        % C.Cmd('LiveViewWnd_Show'); %start live view
                        % C.Cmd('All_Minimize');     %minimise live view window
                        % for k = 1:40
                        %     pause(0.1)
                        %     try
                        %         I = imread(['http://' C.dcc ':5513/liveview.jpg'],'jpg');
                        %     end
                        %     if ~isempty(I)
                        %         break
                        %     end
                        % end
                        % if isempty(I)
                        %     err = 'Live view not active';
                        % end
                    else
                        err = e.message;
                    end
                end
            elseif strcmp(C.connection,'CMD')
                err = 'LiveView only works with HTTP webserver';
            else
                err = 'Check connection';
            end
            C.Error(err,nargout<2)
        end
        
        function [out,err] = Cameras(C,val)
            %List connected cameras or select a camera
            % SN = Cameras        -list of connected cameras serials
            % SN = Cameras(index)  -set current camera using list index
            % SN = Cameras(serial)  -set current camera using serial number
            % [SN,err] = Cameras(..) -catch error messeges
            %Use property.serialnumber to get current camera's serial
            [serials,err] = C.List('cameras'); %all cameras serial numbers
            if isempty(serials) || isequal(serials,{'OK'})
                err = 'No camera detected';
                out = '';
            elseif nargin>1 %select a specific camera
                if isnumeric(val) %index selection mode
                    try
                        val = serials{val};
                    catch %#ok<CTCH>
                        out = '';
                        err = 'Invalid camera index';
                        C.Error(err,nargout<2)
                        return
                    end
                end
                old = C.Get('property.serialnumber'); %current camera serial number
                [out,err] = C.Set('camera',val,old,serials); %change camera if different
                if ~strcmp(out,old) %has selected camera changed
                    C.options = C.Options; %cache new camera options
                    C.cmds = C.List('Cmds'); %cache single-line-commands
                end
            else
                out = serials;
            end
            C.Error(err,nargout<2)
        end
        
        function [out,err] = Sessions(C,val)
            %List available session or set current session
            % names = Sessions    -list available session names
            % name = Sessions(name)  -set current session
            % [name,err] = Sessions(.)  -catch error messeges
            %Note: use session.name to get current session
            [list,err] = C.List('sessions'); %all session names
            if nargin>1
                if isnumeric(val) %index selection mode
                    try
                        val = list{val};
                    catch %#ok<CTCH>
                        out = '';
                        err = 'Invalid camera index';
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
            [I,mch] = C.Match(cmd,C.cmds);
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
            %Adjust camera focus, or attempt to auto-focus
            % Focus    -auto focus, lens must be set to AF
            % Focus(Num)  -number of steps, +ve=far field -ve=near field
            % Focus(Num,Mode)  -type of step {'small'} 'med' 'large'
            % Focus(Num,Mode,Wait)  -time delay per step (sec)
            %Starts live view, lens can be in MF|AF, camera can be in M|A..
            %Step size can be set in: File>Settings>Live view
            C.Cmd('LiveViewWnd_Show') %can skip if LiveView is on
            if nargin<2 || isempty(Num)
                [status,err] = C.Cmd('LiveView_Focus'); %auto focus, user must wait for focus to finish manually
            elseif Num ~= floor(Num)
                err = 'Focus step must be an integer';
            elseif Num==0
                %do nothing
            else
                if nargin<3 || isempty(Mode) %default step mode
                    Mode = 'small';
                end
                if nargin<4 || isempty(Wait) %default delay
                    switch lower(Mode(1))
                        case {1 's'}, Wait = 1; %adjust these defaults
                        case {2 'm'}, Wait = 5;
                        case {3 'l'}, Wait = 15;
                    end
                end
                if Num>0, cmd = 'P'; %move towards far focus
                else,     cmd = 'M'; %move towards near focus
                end
                switch lower(Mode(1))
                    case {1 's'} %do nothing
                    case {2 'm'}, cmd = [cmd cmd];
                    case {3 'l'}, cmd = [cmd cmd cmd];
                end
                for k = 1:abs(Num)
                    [status,err] = C.Cmd(['LiveView_Focus_' cmd]); %send command
                    pause(Wait) %wait for focus adjustment to hopefully finish
                end
            end
            C.Error(err,nargin<2)
        end
 
        function Clock(~,run_in_this_session)
            %Display a clock with miliseconds for time tests
            % Clock   -start in new MatLab session so as not to block code
            % Clock(1)  -start using this session, blocking code execution
            if nargin<2 || ~run_in_this_session %start in a new process
                fprintf('Starting another MatLab session to display clock...\n')
                %!matlab -nodesktop -nosplash -minimize -r "try C=CameraController;C.Clock(1);catch,exit,end" & 
                !matlab -nosplash -minimize -r "try C=CameraController;com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame.hide;C.Clock(1);catch,exit,end" &
                %^UGLY! can this be done with threads?
            else %run with this MatLab session (block code)
                clf(figure(1)), axis off
                set(gcf,'color','k','name','Clock','numb','off','menu','n','tool','n')
                h0 = text(0.5,0.95,'time'    ,'fontsize',60,'hor','cen','color','w');
                h1 = text(0.5,0.7 ,'seconds' ,'fontsize',60,'hor','cen','color','w');
                h2 = text(0.5,0.5 ,'tenths'  ,'fontsize',60,'hor','cen','color','w');
                h3 = text(0.5,0.2 ,'hundreds','fontsize',60,'hor','cen','color','w');
                h4 = text(0.5,-0.05,'Delay:' ,'fontsize',30,'hor','cen','color','w');
                old = now; %time of previous frame
                num = 10; %measure time elapsed between n frames to display average time per frame
                delay = nan(1,num);
                idx = 1; %circular counter
                %addlistener(h4,'String','PreSet',@(~,~)H.UpdateClock(h0,h1,h2,h3,h4,old,num,OLD,idx)); %this isn't working execution
                while true
                    pause(0.0001)
                    new = now;
                    p1 = floor(mod(new*24*60*60    ,10)); %sec
                    p2 = floor(mod(new*24*60*60*10 ,10)); %1/10 sec
                    p3 = floor(mod(new*24*60*60*100,10)); %1/100 sec
                    set(h0,'str',datestr(new,'HH:MM:SS.FFF'))
                    set(h1,'pos',[p1/10 0.6 0],'str',num2str(p1))
                    set(h2,'pos',[p2/10 0.4 0],'str',num2str(p2))
                    set(h3,'pos',[p3/10 0.2 0],'str',num2str(p3))
                    delay(idx) = new-old; %update delay amounts
                    idx = mod(idx,num)+1; %update circular counter
                    old = new;            %update previous frame time
                    set(h4,'str',num2str(nanmean(delay)*24*60*60,'Delay > %.3f sec'))
                    drawnow
                end
            end
        end
        
    end
    
    %% Hidden methods
    methods (Hidden = true)
        function [out,err] = Run(C,cmd,prp,val,block)
            %Send command to digiCamControll
            % Run(cmd)       -command (string)
            % Run(cmd,prp)       -argument or property {''} (string)
            % Run(cmd,prp,val)       -property value {''}
            % Run(cmd,prp,val,block) -wait for command to finish {true}
            % [out,err] = Run(..)    -output reply and error strings
            if nargin<3 || isempty(prp),  prp  = '';  end
            if nargin<4 || isempty(val),  val  = '';  end
            if nargin<5 || isempty(block),block= true;end
            out = ''; err = ''; %init
            switch C.connection
                case 'HTTP' %webserver
                    cmd = ['http://' C.dcc '/?SLC=' cmd]; 
                    if ~isempty(prp)
                        cmd = [cmd '&param1=' regexprep(prp,{' ' '=' ';'},{'%20' '%3D' '%3B'})]; %allow spaces and equal signs [www.w3schools.com/tags/ref_urlencode.asp]
                    end
                    if ~isempty(val)
                        val = regexprep(val,{' ' '='},{'%20' '%3D'}); %replace spaces and equal signs
                        val = regexprep(val,'[<>"|?*]',''); %windows filenames forbid [<>:"/\|?*], [/] is needed for fractions, [:\] is used for subfolders
                        if ~isempty(val)
                            cmd = [cmd '&param2=' val];
                        end
                    end
                    if C.debug > 1 %display HTTP requests
                        %disp(['>> ' cmd]) %plain text
                        %disp(['>> urlread(' cmd ')']) %matlab command
                        %disp(['<a href="' cmd '">' cmd '</a> ']) %clickable link that opens browser 
                        disp(['<a href="matlab:urlread(''' cmd ''')">' cmd '</a> ']) %clickable link that runs in matlab
                    end
                case 'CMD'
                    cmd = ['"' fullfile(C.dcc,'CameraControlRemoteCmd.exe') '" /c ' cmd ]; %spaces are not allowed in filename, this also prohibits the use of most tags
                    if ~isempty(prp)
                        cmd = [cmd ' "' strrep(prp,' ','_') '"'];
                    end
                    if ~isempty(val)
                        val = regexprep(val,'[<>"|?*;]',''); %windows filename forbids [<>:"/\\|?*], dcc cmd forbids [;], [/] is needed for fractions, [:\] is used for subfolders
                        if ~isempty(val)
                            cmd = [cmd ' ' val];
                        end
                    end
                    if C.debug > 1 %display CMD requests
                        %disp(['>> ' cmd]) %plain text
                        disp(['>> system(''' cmd ''')']) %matlab command
                        % disp(['<a href="' cmd '">' cmd '</a> ']) %clickable link that opens browser 
                        % disp(['<a href="matlab:system(''"' cmd ''')">' cmd '</a> ']) %clickable link that runs in matlab (broken) 
                    end
            end
            if strcmp(C.connection,'HTTP') %use webserver 
                if block %wait while command executes
                    [out,status] = urlread(cmd); %#ok<URLRD> %send httm request and read reply
                        if C.debug > 2
                            disp(out) %display replies
                        end
                        if ~isempty(out) && out(end)==10 %remove trailing linefeeds
                            out(end) = [];
                        end
                        out = strrep(out,'Cannot perform runtime binding on a null reference','No camera detected'); %translate some error msgs
                        out = strrep(out,'Unknow ','Unknown '); %spellcheck
                        if ~status || strcmp(out,'Unknown parameter') || strncmpi(out,'Wrong value',11) || strcmp(out,'No camera detected')
                            err = out;
                            out = '';
                        end
                else %dont wait
                    [~,~] = system(['start /B curl http://' C.dcc '/?SLC=CaptureNoAf']); %ignore output
                end
            else %use CMD utility
                if block
                    [failed,out] = system(cmd); %run cmd command and read the reply
                    if C.debug > 2
                        disp(['ans =' 10 out]) %display replies
                    end
                    [out,err] = C.CleanCMD(out);
                    if failed || strncmpi(out,'error',5)
                        err = out;
                        out = '';
                    end
                else
                    try
                        out = java.lang.Runtime.getRuntime().exec(cmd);
                    catch e
                        err = sprintf(e.message);
                    end
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
            if nargin<4, old = ''; end %current value, to avoid superfluous set commands
            if nargin<5, opt = {}; end %default valid options
            new = ''; err = ''; %init
            if ~ischar(val)
                val = mat2str(val); %convert numbers to strings
            end
            if ~isempty(opt) %are valid options known
                [~,val] = C.Match(val,opt); %find match
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
                new = C.Get(prp); %verify value after set (can skip this)
                if ~isequal(new,val) && ~isequal(str2num(lower(new)),str2num(lower(val))) %#ok<ST2NM> %verify success, allows: 'True'='true'=true=1
                    err = sprintf('Set command failed: %s',err);
                end
            end
            C.Error(err,nargout<2)
        end
        
        function [out,err] = List(C,cmd)
            %List properties or values as cellstr, one per cell
            [out,err] = C.Run('List',cmd);
            if ~isempty(out) && isempty(err) %got a string, no error
                out = regexprep(out,{'True' 'False'},{'true' 'false'}); %HACK
                out = regexp(strtrim(out),'\n','split')';
            else %error
                out = {}; %return an empty cell, not an empty char
            end
            C.Error(err,nargout<2)
        end
        
        function [s,err] = Options(C)
            %Returns a list of valid camera options as struct
            params = fieldnames(C.camera); %list of parameters
            for k = 1:numel(params)
                [s.(params{k}),err] = C.List(['camera.' params{k}]); %list options for each parameter
                s.(params{k}) = s.(params{k})';
            end
        end
    end
    
    %% get/set methods
    %Set methods do not know which sub-field(s) were set, to avoid setting
    %all fields they GET current values and SET only those that changed.
    methods
        function s = get.camera(C)
            %Get current camera settings as struct, empty struct if no camera
            s = C.List('camera'); %get camera settings as cellstr, eg {'camera.fnumber=4.0';...}
            if ~isempty(s)
                s = regexp(s,'camera\.(.*?)=(.*)','tokens','once'); %split fields and values, eg {{'fnumber' '4.0'};...}
                s = cat(1,s{:})'; %make 2-by-n cellstring {'prop1'...;'val1'...}
                s(1,:) = regexprep(s(1,:),'[^\w]',''); %remove "." "-" from field names (Nikon), set methods will not work for affected fields
                [~,i] = unique(s(1,:)); i = sort(i); %remove duplicate fields, old matlab support
                s = s(:,i); %remove duplicate fields
                s = struct(s{:}); %make a struct
                if isfield(s,'exposurestatus')
                    s = rmfield(s,'exposurestatus'); %"exposurestatus" is read only and does not appear to change with a Canon, get rid of it to reduce confusion
                end
            else %no camera
                s = struct; %return empty struct instead of empty cell
            end
        end
        
        function s = get.session(C)
            s = C.List('session');
            if ~isempty(s)
                s = regexp(s,'session\.(.*?)=(.*)','tokens','once');
                s = cat(1,s{:})';
                s(2,:) = regexprep(s(2,:),{'^False$' '^True$'},{'false' 'true'}); %change case for consistency
                s = struct(s{:});
            end
        end
        
        function s = get.property(C)
            s = C.List('property');
            if ~isempty(s)
                s = regexp(s,'property\.(.*?)=(.*)','tokens','once');
                s = cat(1,s{:})';
                s(2,:) = regexprep(s(2,:),{'^False$' '^True$'},{'false' 'true'}); %change case for consistency
                s = struct(s{:});
            end
        end
        
        function c = get.lastfile(C)
            c = C.Get('lastcaptured');
            if any(strcmp(c,{'-' '?'}))
                c = '';
            end
        end
        
        function set.camera(C,new)
            %dcc can list valid option for each camera.parameter, so we
            %can do some common sense checks to guess which value the
            %user wanted or tell the user valid options if we can't figure
            %it out. But there are a few strange transient parameters that
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
                            C.Error(err) %display error
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
            %Test webserver communication
            % [status,err] = TestHTTP(ip)
            status = 0; err = ''; %init
            try
                t = java.net.URL([],['http://' ip],sun.net.www.protocol.http.Handler).openConnection; %does this work on linux?
                %t.setConnectTimeout(0.5); t.setReadTimeout(0.5); %timeout not working, defaults to ~2.5 seconds
                t.getInputStream;
                status = 1; %success
            catch e
                if     strfind(e.message,'connect timed out'), err = 'webserver connection timed out';
                elseif strfind(e.message,'Connection refused'),err = 'webserver connection refused (turn on digiCamControl webserver & restart digiCamControl)';
                elseif strfind(e.message,'UnknownHost'),       err = 'webserver address unknown';
                elseif strfind(e.message,'Permission denied'), err = 'webserver permission denied';
                else,                                          err = ['webserver ' e.message];
                end
            end
        end
        
        function [fold,err] = FindDCC
            %Check default install location for digiCamControl app
            % [fold,err] = FindDCC
            err = ''; %init
            fold = fullfile(char(java.lang.System.getenv('ProgramFiles(x86)')),'digiCamControl');
            if exist(fold,'file')~=7 %~isdir(fold)
                fold = fullfile(char(java.lang.System.getenv('ProgramFiles')),'digiCamControl');
                if exist(fold,'file')~=7 %~isdir(fold)
                    fold = '';
                    err = 'digiCamControl install folder not found';
                end
            end
        end
        
        function [status,err] = TestCMD(dccfolder)
            %Test CMD utility communication
            % [status,err] = TestCMD(dccfolder)
            status = 0; err = ''; %init
            [~,t] = system('tasklist /FI "imagename eq CameraControl.exe"'); %can skip this test, but will take a long time to fail if app is not running
            if isempty(strfind(t,'CameraControl.exe')) %#ok<STREMP> compatible with old MatLab
                err = 'digiCamControl is not running';
            else
                exe = fullfile(dccfolder,'CameraControlRemoteCmd.exe');
                if ~exist(exe,'file')
                    err = 'CameraControlRemoteCmd.exe not found';
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
                str = regexprep(str,{'\\\\' '"'},{'\\' ''}); %remove any escape character and quotes
            end
        end
        
        function [I,mch] = Match(str,opt)
            %Flexible comparison of cellstr to string, return best match
            % [I,mch] = Match(str,opt)
            I = strcmpi(str,opt); %compare whole string
            if ~any(I) %compare start of string
                num = str2num(str); %#ok<ST2NM> eg '1/200'=0.005
                if ~isempty(num)
                    I = cellfun(@(x)isequal(str2num(x),num),opt); %#ok<ST2NM> may want to do a rounding tolerance
                end
                if ~any(I) %try numeric comparison
                    I = strncmpi(opt,str,numel(str));
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
            if ~isempty(err) && (nargin<3 || display)
                C.lasterr = err; %save last error
                fprintf(2,'%s\n',err); %display error using red text, but do not abbort execution
            end
        end
    end
    
    %% Hide handle methods by overloading them
    methods (Hidden = true)
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
    end
end