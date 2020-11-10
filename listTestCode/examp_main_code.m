
%% Example 1: draw a green rectangle on the center of the screen
 
% Clear the workspace and close screens
sca;         % closes all screens  
clear all;   % clear all variables
KbName('UnifyKeyNames');
Priority(2);

% ----- put all key presses on the command window
input ('start>>> PRESS ENTER','s'); % prints to command window

% ----- soundfile
path_store_data = './data/';
path_audio_data = '/Users/neeks/Desktop/Documents/work/research/my_repos/eyeTracking_langTCD/data/STIMULI/german/wavFilesTest/';
stimuli_list = 'stimuli_list.csv';

% ----- read the csv list
fid = fopen([path_audio_data stimuli_list]);
tline = fgetl(fid);
i = 1;
stimuli_file = {};
while ischar(tline)
    stimuli_file{i} = strsplit(tline,',');
    i = i+1;
    tline = fgetl(fid);
end
fclose(fid);

% ----- enter subject ID
if 0
fail_1 ='Program aborted. Participant number not entered'; % error message which is printed to command window
prompt = {'Enter subject ID:'};
dlg_title = 'New Subject';
num_lines = 1;
def = {'0'};
answer = inputdlg(prompt,dlg_title,num_lines,def); %presents box to enter data into
switch isempty(answer)
    case 1 %deals with both cancel and X presses
        error(fail_1)
    case 0
        data.subID = (answer{1});
end
end
data.subID = 'sub_00';

% ----- make the subject directory
if ~exist([path_store_data data.subID], 'dir')
   mkdir([path_store_data data.subID])
end

try
    % Call defaults
    PsychDefaultSetup(1); % Executes the AssertOpenGL command & KbName('UnifyKeyNames')
    Screen('Preference', 'SkipSyncTests', 2); % DO NOT KEEP THIS IN EXPERIMENTAL SCRIPTS!

    % Setup screens
    getScreens   = Screen('Screens'); % Gets the screen numbers, typically 0 = primary and 1 = external
    chosenScreen = max(getScreens);   % Chose which screen to display on (here we chose the external)
    rect         = [];                % Full screen

    % Get luminance values
    white = WhiteIndex(chosenScreen); % 255
    black = BlackIndex(chosenScreen); % 0
    grey  = white/2; 

    % Open a psychtoolbox screen
    [w, scr_rect] = PsychImaging('OpenWindow',chosenScreen,grey,rect); % here scr_rect gives us the size of the screen in pixels  
    [centerX, centerY] = RectCenter(scr_rect); % get the coordinates of the center of the screen

    % Get flip and refresh rates
    ifi = Screen('GetFlipInterval', w); % the inter-frame interval (minimum time between two frames)
    hertz = FrameRate(w); % check the refresh rate of the screen


    %% SCREEN: SCREEN
    % DRAW A RECTANGLE
    % First we will define the size of the rectangle as a proportion of the screen size.
    % Remember that when we draw things, we move from top-left-X to top-Left-Y to bottom-Right-X to bottom-right-Y. 

    rectangle         = [0 0 scr_rect(3)/3 scr_rect(4)/2]; % dimensions of the rectangle
    rectangleColour   = [0 0 0]; % The fill colour (RGB)
    rectanglePosition = CenterRectOnPointd(rectangle,centerX,centerY); % centers the rectangle on the XY coord we specify

    % Draw the rectangle to the buffer
    Screen('FillRect',w,rectangleColour,rectanglePosition);
    % Draw text into the buffer
    Screen('TextSize',w,30);
    Screen('TextFont',w,'Times');
    Screen('TextStyle',w,0); % type = 0 (regular), 1 (bold), 2 (italic)
    Screen('DrawText',w,'Welcome to the Experiment',centerX-200,centerY-50,[255,255, 255, 255]);
    Screen('TextSize',w,20);
    Screen('DrawText', w, 'a. Be seated comfortably.',centerX-150, centerY+0,[255,255, 255, 255]);
    Screen('DrawText', w, 'b. Put on the earphones.', centerX-150, centerY+25,[255, 255, 255, 255]);
    Screen('TextSize',w,15);
    [nx, ny, bbox] = DrawFormattedText(w,'PRESS ENTER TO CONTINUE',centerX-90, centerY+200,[255,255,255,255],0);
    Screen('FrameRect', w, [255 255 255], bbox+[-5 -5 5 5]);
    % Flip the buffer
    Screen('Flip',w); 
    % Check for keyboard press
    KbWait; % waits for a keyboard press before continuing
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
    while 1
        if keyCode(40) % check for ENTER key
            break;
        else
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        end
    end
    
    % file to store 
    if 1
    fileID = fopen([path_store_data data.subID '/resp.csv'],'w');
    fprintf(fileID,'FNAME,RT,RESP\n');
    end
    trials = 0;
    %% SCREEN: FIXATION and Play Audio 
    tot_trials = 2; 
    indx_set = randsample(1:length(stimuli_file),tot_trials);
    for i = 1:tot_trials
        
        % make FIXATION sign
        % Set up alpha-blending for smooth (anti-aliased) lines
        Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        % Here we set the size of the arms of our fixation cross
        fixCrossDimPix = 40;
        % Now we set the coordinates (these are all relative to zero we will let
        % the drawing routine center the cross in the center of our monitor for us)
        xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
        yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
        allCoords = [xCoords; yCoords];
        % Set the line width for our fixation cross
        lineWidthPix = 4;
        % Draw the fixation cross in white, set it to the center of our screen and
        % set good quality antialiasing
        Screen('DrawLines', w, allCoords,lineWidthPix, white, [centerX centerY], 2);
        %%%%% load audio buffer
        [sig,freq] = audioread([path_audio_data stimuli_file{indx_set(i)}{1}]);
        sig = sig.';
        trials = trials+1;
        sig_stereo = [sig; sig]; %duplicate it (one for each channel for stereo sound) 
        chan = 2;
        audioBuff = PsychPortAudio('Open',[],1,[],freq,chan,[],0.015); % Like with the buffer screen window,
        PsychPortAudio('FillBuffer',audioBuff,sig_stereo); % Place our tone in the buffer
        %%%%% Flip to the screen
        Screen('Flip', w);
        %%%%% Release audio buffer
        PsychPortAudio('Start',audioBuff); %This works like the Screen('Flip')
        PsychPortAudio('Stop', audioBuff, 1);
        PsychPortAudio('Close', audioBuff); % Close the audio device
        jitter = randsample(linspace(500,850),1)/1000;
        %%%%% Flip screen for 1/2 talker
        Screen('FillRect',w,rectangleColour,rectanglePosition);
        % Draw text into the buffer
        Screen('TextSize',w,30);
        Screen('TextFont',w,'Times');
        Screen('TextStyle',w,0); % type = 0 (regular), 1 (bold), 2 (italic)
        Screen('DrawText',w,'Number of Talker',centerX-200,centerY-50,[255,255, 255, 255]);
        Screen('TextSize',w,15);
        [nx, ny, bbox] = DrawFormattedText(w,'PRESS 1 or 2',centerX-90, centerY+200,[255,255,255,255],0);
        Screen('FrameRect', w, [255 255 255], bbox+[-5 -5 5 5]);
        % Flip the buffer
        Screen('Flip',w);
        % Count key press time
        keyIsDown=0; timeSt = GetSecs;
        keyOne = 30; keyTwo = 31;
        while 1
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyCode(keyOne)
                rt = 1000.*(secs - timeSt);
                resp = 1;
                fprintf(fileID,'%s,%f,%d\n',stimuli_file{indx_set(i)}{1},rt,resp);
                break;
            elseif keyCode(keyTwo)
                rt = 1000.*(secs - timeSt);
                fprintf(fileID,'%s,%f,%d\n',stimuli_file{indx_set(i)}{1},rt,resp);
                resp = 2;
                break;
            end
        end
        WaitSecs(jitter);
    end
    %% SCREEN: Thank you.
    str_1 = ['This completes the experiment. Thank you very much.'];
    Screen('TextSize',w,25);
    [nx, ny, bbox] = DrawFormattedText(w,str_1,centerX-200,centerY-50,[255,255,255,255],0);
    % Screen('FrameRect', w, [255 255 255], bbox+[-5 -5 5 5]);

    Screen('TextSize',w,15);
    [nx, ny, bbox] = DrawFormattedText(w,'PRESS ENTER TO CLOSE',centerX-60, centerY+200,[255,255,255,255],0);
    Screen('FrameRect', w, [255 255 255], bbox+[-5 -5 5 5]);
    Screen('Flip',w); 

    keyCode = 0;
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
    while 1
        if keyCode(40) % check for ENTER key
            data.flag_end = 1;
            break;
        else
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        end
    end
    sca; % close all screens
%% catch
catch  
    sca; % closes the screens
    ShowCursor; % shows the mouse cursor
    psychrethrow(psychlasterror); %prints error message to command window 
end
