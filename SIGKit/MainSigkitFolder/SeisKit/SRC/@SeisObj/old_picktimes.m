% function [RecXProf,T] = picktimes(theSeisObj)
function picktimes(theSeisObj)
    %picktimes A routine for picking first arrivals in a seismic trace.
    %   
    %With this picking routine, the user will be given three opportunities
    %to pick the first arrivals on a set of geophones.
    %
    %1) On the wiggle plot created when the data file is first read in.
    %Click on each first arrival and hit enter when done making all the
    %picks. These picks will not be saved but will be shown on the
    %individual traces for comparison.
    %
    %2) On individual plots of each trace. For geophone 1, you will only
    %be shown the trace for that geophone but on all subsequent
    %geophones, you will see the trace for that geophone in the bottom
    %panel as well as the trace from the geophone before it. ONLY click
    %on the first arrival in the bottom panel.
    %
    %Carefully assess each trace clicking on the first arrival with the
    %left mouse button if you would like to save the first arrival or with
    %the right mouse button anywhere on the trace if you are not
    %comfortable with making a pick on this trace
    %
    %3) When all the picks are made on the individual traces, you will
    %be given a final opportunity to review the traces. A movie of the
    %trace picks will appear along with a dialog box. Carefully scroll
    %through the picks making a note of any traces that you would like
    %another opportunity to review (the frame number in the lower right
    %hand corner of the movie corresponds to the channel number). Type in
    %the each channel that you would like to review separated by a space or
    %click ok if you are happy with your picks. 
    %
    %The picks will automatically be saved to a file with the same stem as
    %the input file used for making the first arrival picks. The dialog box
    %also gives you the opportunity to save the movie of your picks; the
    %movie is not saved by default!!!!
    
    %setup path to save the results of the picking routine
    fs = filesep;
    filepath = pwd;
    
    Savepath = strcat([filepath fs 'Seismics' fs 'Processed_files']);

     if ishandle(1) && strcmp(get(1, 'type'), 'figure')
        uiwait(msgbox('pick ALL first breaks now, press enter when done'))
        [X,F] = ginput;
        X = round(X);
     else 
        plot(theSeisObj,'clipped')
        uiwait(msgbox('pick ALL first breaks now, press enter when done'))
        [X,F] = ginput;
        X = round(X);
    end
    hold on;
    plot(X,F,'b+');

    % quality control of picks
    % check that red line alligns with first break of each wiggle
    %             T = T*theSeisObj.SamplingInt(1)*1000;

    %create a plot of the individual traces for reselecting
    %first motions
    msgbox('please repick first breaks')
    scrsz = get(0,'ScreenSize');
    t = theSeisObj.RecTime;
    traces = theSeisObj.W;
    Traces = traces(1:theSeisObj.NumSamples,:);



    %The filtered trace is not being plotted at the moment
    %because I found that it is sometimes accidentally selected
    %instead of the actual trace which results in an error.
    T =zeros(length(theSeisObj.Channels),1);
    button = zeros(length(theSeisObj.Channels),1);
    
    for index=1:numel(theSeisObj.Channels)
        f = figure('Position',[1 1 scrsz(3)*0.9 scrsz(4)*0.9], 'Visible','off');
        %                 plot(t, TRnorm(:,index), 'b');
        ax = axes('Units','pixels');
        normTrace(:,index) = Traces(:,index)/max(Traces(:,index));
    Tmin = min(normTrace(:,index));
    Tmax = max(normTrace(:,index));
        if index==1
            plot(t, Traces(:,index)/max(Traces(:,index)), 'k');
            hold on;
            plot([F(index) F(index)],[1 -1], 'r');
            title(['Shot at ',num2str(theSeisObj.ShotXProf),...
                ' m and geophone at ',num2str(theSeisObj.RecXProf(index)),' m'])
            xlabel('Time (ms)')
            ylabel('Normalized Trace Amplitude')
            legend('Normalized Trace','Original Pick')
             PicksUI(Tmin,Tmax,ax);
             f.Visible ='on';
             waitfor(f,'Name');
            [T(index),A,button(index)]=ginput(1);
            plot([T(index) T(index)],[1 -1], 'c', 'linewidth',2)
            M(index) = getframe(gcf);
            close
            clear f;
        else
            subplot(2,1,1)
            plot(t, Traces(:,index-1)/max(Traces(:,index-1)), 'k');
            hold on;
            plot([F(index-1) F(index-1)],[1 -1], 'r');
            title(['Previous Trace; Geophone at ', ...
                num2str(theSeisObj.RecXProf(index-1)),' m'])
            xlabel('Time (ms)')
            ylabel('Normalized Trace Amplitude')
            plot([T(index-1) T(index-1)],[1 -1], 'c', 'linewidth',2);
            legend('Normalized Trace','Original Pick','New Pick')
            
            h = subplot(2,1,2);
            plot(t, Traces(:,index)/max(Traces(:,index)), 'k');
            hold on;
            plot([F(index) F(index)],[1 -1], 'r');
            title(['Shot at ',num2str(theSeisObj.ShotXProf),...
                ' m and geophone at ',num2str(theSeisObj.RecXProf(index)),' m'])
            xlabel('Time (ms)')
            ylabel('Normalized Trace Amplitude')
            PicksUI(Tmin,Tmax,h)
            f.Visible = 'on';
            waitfor(f, 'Name');
            [T(index),A,button(index)]=ginput(1);
            plot([T(index) T(index)],[1 -1], 'c', 'linewidth',2)
            legend('Normalized Trace','Original Pick','New Pick')
            M(index) = getframe(gcf);
            close
            clear f;
        end
    end

    %show picks
    RecXProf = theSeisObj.RecXProf;
    dt = theSeisObj.SamplingInt(1);
   
    %Give the user one last chance to verify their picks
    uiwait(msgbox('Please look carefully through the Picks Movie to verify your picks'));

    implay(M,1)


    prompt = {[ 'If satisfied with picks type "y" at the prompt.' ...
        'Otherwise list the traces # that you would like to repick separated by a space']...
        ,'Would you like to save the movie?'};
    dialog_title = 'Verify Picks';
    num_lines = 1;
    default_ans = {'y','n'};
    options.WindowStyle = 'normal';


    answer = inputdlg(prompt,dialog_title,num_lines,default_ans, options);

    %save the picks to a .mat file name using the same line number
    %as the original file.


    if numel(theSeisObj.FileNumber)==1
        filename = [num2str(theSeisObj.FileNumber),'_picks.mat'];

    else
        filename = [num2str(theSeisObj.FileNumber(1)),'_', ...
            num2str(theSeisObj.FileNumber(2)), '_picks.mat'];
    end

    if strcmp('y',answer{1});
        f = find(button==1);
        RecXProf = RecXProf(f);
        PickTime =T(f);
        ShotXProf = theSeisObj.ShotXProf;
        
        %plot the new picks on the original trace figure as red
        %pluses on the original figure
        
        if ishandle(1) && strcmp(get(1, 'type'), 'figure')
           figure(1)
           plot(RecXProf, PickTime, 'r+')
        else
            plot(theSeisObj,'clipped');
            hold on
            plot(RecXProf, PickTime, 'r+')
        end
        
        %test the existence of a Processed files directory for saving the file.
        %If the directory does not exist, make one then save the files to it.
        
        
        if exist(Savepath,'dir')
            save([Savepath fs,filename],'RecXProf','PickTime','ShotXProf');
        else mkdir (Savepath)
            save([Savepath fs ,filename],'RecXProf','PickTime','ShotXProf');
        end
        
        
    else
        WIndex = str2num(answer{1});
        figure('Position',[1 1 scrsz(3)*0.9 scrsz(4)*0.9]);
        for i =1:numel(WIndex)
            subplot(2,1,1)
            plot(t, Traces(:,WIndex(i)-1)/max(Traces(:,WIndex(i)-1)), 'k');
            hold on;
            plot([T(WIndex(i)-1) T(WIndex(i)-1)],[1 -1], 'r');
            title(['Previous Trace; Geophone at ', ...
                num2str(theSeisObj.RecXProf(index-1)),' m'])
            xlabel('Time (ms)')
            ylabel('Normalized Trace Amplitude')
            plot([T(WIndex(i)-1) T(WIndex(i)-1)],[1 -1], 'c', 'linewidth',2);
            
            subplot(2,1,2)
            plot(t, Traces(:,WIndex(i))/max(Traces(:,WIndex(i))), 'k');
            hold on;
            plot([T(WIndex(i)) T(WIndex(i))],[1 -1], 'r');
            xlabel('Time (ms)')
            ylabel('Normalized Trace Amplitude')
            title(['Shot at ',num2str(theSeisObj.ShotXProf),...
                ' m and geophone at ',num2str(theSeisObj.RecXProf(WIndex(i))),' m'])
            
            [T(WIndex(i)),A,button(WIndex(i))]=ginput(1);
            plot([T(WIndex(i)) T(WIndex(i))],[1 -1], 'c', 'linewidth',2)
            legend('Normalized Trace','Original Pick', 'New Pick')
            %         M(index) = getframe(gcf);
            close
        end
        f = find(button==1);
        RecXProf = RecXProf(f)';
        PickTime =T(f);
        ShotXProf = theSeisObj.ShotXProf;
        
        %provide a summary plot of the arrivals on all 24 channels
        %         if ishandle(1) && strcmp(get(1, 'type'), 'figure')
        %             clf
        %             plot(theSeisObj,'clipped');
        %             hold on
        %             plot(RecXProf, PickTime, 'r+')
        %         else
        %             figure
        %             plot(theSeisObj,'clipped');
        %             hold on
        %             plot(RecXProf, PickTime, 'r+')
        %         end
        
        if exist(Savepath,'dir')
            save([Savepath fs,filename],'RecXProf','PickTime','ShotXProf');
        else mkdir (Savepath)
            save([Savepath fs ,filename],'RecXProf','PickTime','ShotXProf');
        end
        
        
    end

    %save the picks movie to a .gif file with the same stem as the input file.
    fCount = numel(theSeisObj.Channels);
    [im,map] = rgb2ind(M(1).cdata,256,'nodither');
    im(1,1,1,fCount) = 0;
    Kk = 1;

    for n = 1:length(M)
        im(:,:,1,Kk) = rgb2ind(M(n).cdata,map,'nodither');
        Kk = Kk+1;

    end

    %let the user decide whether or not the movie should be saved
    SaveMovie =answer{2};

    if strcmp(SaveMovie,'y');
     imwrite(im,map,[Savepath fs num2str(theSeisObj.FileNumber), ...
         '_Shot_animation.gif'],'DelayTime',1,'LoopCount',inf)
    end

end

