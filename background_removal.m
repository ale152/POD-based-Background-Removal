function background_removal
%BACKGROUND_REMOVAL POD-based background removal for Particle Image Velocimetry
% This software is an implementation of the algorithm described in the
% following research paper:
% "POD-based background removal for Particle Image Velocimetry"
% M.A. Mendeza, M. Raiola, A. Masullo, S. Discetti, A. Ianiro, R. Theunissen, J.-M.Buchlin
% Experimental Thermal and Fluid Science, Volume 80, January 2017, Pages 181–192.
% 
% For information, feedback and bug report, please visit the website:
% http://seis.bris.ac.uk/~aexrt/PIVPODPreprocessing
%
% This software is distributed under the CC BY-NC-SA 4.0 license by Creative Common.

% Generate figure
fig = figure('Name','POD-based background removal for Particle Image Velocimetry', ...
    'numbertitle', 'off', ...
    'ToolBar', 'none', ...
    'menu','none', ...
    'units','normalized', ...
    'closereq',@exit_program, ...
    'KeyPressFcn',@key_shortcut, ...
    'outerposition',[0 .1 .5 .9]);

% Generate toolbar
show_modes_toolbar(fig,'main')

% Generate menu
menu_1 = uimenu(fig,'Label','File');
menu_11 = uimenu(menu_1,'Label','Select training images');
uimenu(menu_11,'Label','Pick multiple files... (Ctrl+I)','Callback',{@select_images,'direct'})
uimenu(menu_11,'Label','Pick matching pattern... (Ctrl+O)','Callback',{@select_images,'pattern'})
uimenu(menu_1,'Label','Start a new session','Callback',{@delete_temporary_files,0},'Separator','off')
uimenu(menu_1,'Label','Exit (Ctrl+Q)','Callback',@exit_program,'Separator','off')

menu_2 = uimenu(fig,'Label','Settings');
uimenu(menu_2,'Label','Set temporary folder...','Callback',@change_temp_fold)
uimenu(menu_2,'Label','Output filename...','Callback',@set_bg_filename);
uimenu(menu_2,'Label','Max memory usage...','Callback',@set_memory);
uimenu(menu_2,'Label','Memory info','Callback',@memory_info);

menu_3 = uimenu(fig,'Label','Run');
uimenu(menu_3,'Label','Evaluate video spectrum (Ctrl+R)','Callback',@evaluate_spectrum);
uimenu(menu_3,'Label','Evaluate modes (Ctrl+M)','Callback',@evaluate_modes);
uimenu(menu_3,'Label','Evaluate automatic threshold (Ctrl+T)','Callback',@set_automatic_modes);
menu_31 = uimenu(menu_3,'Label','Remove background','Separator','on');
uimenu(menu_31,'Label','From training images (Ctrl+B)','Callback',{@remove_background,'training'});
menu_311 = uimenu(menu_31,'Label','From a new target...');
uimenu(menu_311,'Label','Pick multiple files...','Callback',{@remove_background,'new_target_direct'})
uimenu(menu_311,'Label','Pick matching pattern...','Callback',{@remove_background,'new_target_pattern'})
uimenu(menu_31,'Label','Preview on current image (Ctrl+P)','Callback',{@remove_background,'preview'});


menu_4 = uimenu(fig,'Label','Windows');
uimenu(menu_4,'Label','Show status','CallBack',{@show_window,'status'})
uimenu(menu_4,'Label','Show spectrum','CallBack',{@show_window,'spectrum'})
uimenu(menu_4,'Label','Show modes','CallBack',{@show_window,'modes'})
uimenu(menu_4,'Label','Bring all to front (Ctrl+A)','CallBack',{@show_window,'rearrange'})
menu_41 = uimenu(menu_4,'Label','Open in explorer','Separator','on');
uimenu(menu_41,'Label','Working folder','Callback',{@open_explorer,'working'})
uimenu(menu_41,'Label','Temporary folder','Callback',{@open_explorer,'temp'})
uimenu(menu_41,'Label','Input folder','Callback',{@open_explorer,'input'})
uimenu(menu_41,'Label','Output folder','Callback',{@open_explorer,'output'})

menu_5 = uimenu(fig,'Label','Help');
uimenu(menu_5,'Label','About','Callback',{@about,'about'});
uimenu(menu_5,'Label','License','Callback',{@about,'license'});
uimenu(menu_5,'Label','Cite this work','Callback',{@about,'citation'});
uimenu(menu_5,'Label','Temporary files','Callback',{@about,'temp_files'},'Separator','on');

% Initialize gloval variables
hand = [];
initialize_program
initialize_session
bgremkey = 'backgroundremovaltool000000001';

% Status window
update_status(0);
update_status(sprintf('--- %s ---',datestr(now)));
update_status(sprintf('Temporary folder: %s',hand.pathtemp));
update_status(sprintf('Image folder: %s',hand.path_in))
update_status('Please select images to analyse from the menu "File"')

warning('off','MATLAB:imagesci:rtifc:zDepthIgnored')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function select_images(~,~,mode)
        % Select a set of images. Only files names are stored into memory,
        % the user check the images before loading them into memory
        
        % If the user selects new images, a new session must be started
        initialize_session
        
        % Select images with dialog
        if strcmp(mode,'direct')
            [bfa,bfb] = uigetfile({'*.tif;*.tiff;*.bmp;*.jpg;*.gif;*.raw', ...
                'Image files'; '*.*',  'All files'},'Select images...',hand.path_in,'MultiSelect','on');
            
            if ~iscell(bfa) || numel(bfa) < 2
                return
            end
            
            hand.file_in = bfa;
            hand.path_in = bfb;
            hand.pathtemp = bfb;
            hand.NImg = numel(bfa);
            
            % Select images with pattern
        elseif strcmp(mode,'pattern')
            % Open the pattern select dialog
            [sel_folder,filelist,range] = pattern_selection;
            
            % Check folder selection
            if isnumeric(sel_folder) && sel_folder == 0
                return
            end
            
            % Check having at least 2 images with the range
            try
                file_sel = {filelist.name};
                file_sel = file_sel(range(1):range(2));
                if numel(file_sel) > 1
                    % Select files
                    hand.file_in = file_sel;
                    hand.path_in = sel_folder;
                    hand.pathtemp = hand.path_in;
                    hand.NImg = numel(hand.file_in);
                else
                    error('The user pattern selected less than two images')
                end
            catch me
                msgbox(me.message,'Error','Error');
                update_status(' ');
                update_status(me.message);
                return
            end
            
        end
        
        % Save gui data
        hand.Check_imload = false;
        hand.Check_imsel = true;
        
        % Show the first image
        callback_arrows(0,0,0,'main')
        
        % Update status
        update_status(-1)
        update_status(' ');
        msg = sprintf('Temporary folder: %s',hand.pathtemp);
        update_status(msg)
        msg = sprintf('Image folder: %s',hand.path_in);
        update_status(msg)
        
        % Set preference on last folder used
        setpref('background_removal','last_folder',hand.path_in);
        
        % Update status
        msg = sprintf('%d images selected',hand.NImg);
        update_status(msg)
        msg = 'Arrows can be used to inspect the set of images';
        update_status(msg)
        msg = ['Please inspect your images or evaluate the video spectrum ' ...
            'from the menu "Run"'];
        update_status(msg)
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function load_images_memory(~,~)
        % Load the images into memory or generate temporary files if they
        % don't fit
        
        % Check that the user selected the images
        if ~hand.Check_imsel
            msgbox('No images selected. Please select images from menu "File".', ...
                'No images selected','Warn');
            return
        end
        
        % Process the images
        NImg = hand.NImg;
        sector = 1;
        
        % Load images into memory and save them into temporary files. Each
        % temporary file is a "bloc" that contains a matrix M.
        wh = waitbar(0,'','Name','Load images in memory');
        for im_i = 1:NImg
            if ishandle(wh)
                waitbar(im_i/NImg,wh,sprintf('Loading image %d of %d...',im_i,NImg));
            else
                wh = waitbar(im_i/NImg,sprintf('Loading image %d of %d...',im_i,NImg));
            end
            filename = fullfile(hand.path_in,hand.file_in{im_i});
            try
                A = imread(filename);
            catch me
                Message = sprintf(['An error occurred during the analysis ' ...
                    'of the images.\n"%s".\nThe error occurred while trying to ' ...
                    'open the file:\n%s\nPlease report the error at the ' ...
                    'following page.'],me.message,hand.file_in{im_i});
                msgbox(Message,'Error','Error');
                close(wh)
                web('http://seis.bris.ac.uk/~aexrt/PIVPODPreprocessing/bugreport.html', '-browser')
                return
            end
            
            % Initialize variables
            if im_i == 1
                [H,W] = size(A);
                
                % Evaluate the memory needed
                sys = memory;
                MemAv = sys.MaxPossibleArrayBytes;
                % Memory available / bytes per element / image size / 2
                % Divided by 2 is because two dataset must be kept in memory
                MaxImg = floor(MemAv/hand.bytesPerElem/(H*W)/2*hand.mem_safe);
                N_bloc = floor(NImg/MaxImg);
                if N_bloc == 0
                    hand.Use_tmp_file = false;
                else
                    N_bloc = N_bloc+1;
                    hand.Use_tmp_file = true;
                    % Handle the memory info message
                    if ~ispref('background_removal','mem_warn_msg') || getpref('background_removal','mem_warn_msg')
                        Message = ['The memory available in this system is not '...
                            'enough to process the selected set of images. '...
                            'Some temporary files will be stored in the temporary '...
                            'folder on you hard drive to allow the calculation and '...
                            'this process may slow down the analysis. Do you '...
                            'wish to continue anyway?'];
                        button = questdlg(Message,'Memory info','Yes','No','Yes, don''t show again','Yes');
                        if isempty(button) || strcmp(button,'No')
                            close(wh)
                            return
                        end
                        if strcmp(button,'Yes, don''t show again')
                            setpref('background_removal','mem_warn_msg',false)
                        end
                    end
                end
                
                M_bloc = zeros(min(MaxImg,NImg),H*W,'single');
            end
            
            M_bloc(im_i-(sector-1)*MaxImg,:) = single(A(:));
            
            if im_i == sector*MaxImg || im_i == NImg
                if hand.Use_tmp_file
                    tmp_filename = fullfile(hand.pathtemp,sprintf('Temp_%d.mat',sector));
                    if ishandle(wh)
                        waitbar(im_i/NImg,wh,sprintf('Saving temporary file %d of %d...',sector,N_bloc));
                    else
                        wh = waitbar(im_i/NImg,sprintf('Saving temporary file %d of %d...',sector,N_bloc));
                    end
                    save(tmp_filename ,'M_bloc','bgremkey','-v7.3')
                    sector = sector+1;
                    M_bloc = zeros(min(MaxImg,NImg-(sector-1)*MaxImg),H*W,'single');
                else
                    hand.M_bloc = M_bloc;
                end
            end
        end
        close(wh)
        
        % Save gui data
        hand.Check_imload = true;
        hand.N_bloc = N_bloc;
        hand.Dim = [H W];
        hand.Check_eigproc = false;
        hand.MaxImg = MaxImg;
        
        % Update status
        update_status(' ');
        msg = sprintf('%d temporary file created',hand.N_bloc);
        update_status(msg)
        msg = sprintf('%d images loaded into memory',hand.NImg);
        update_status(msg)
        msg = 'Please evaluate the images spectrum from the menu "Run"';
        update_status(msg)
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function evaluate_spectrum(~,~)
        % Evalaute the spectrum of the images
        
        % Check that the user selected the images
        if ~hand.Check_imsel
            msgbox('No images selected. Please select images from menu "File".', ...
                'No images selected','Warn');
            return
        elseif ~hand.Check_imload;
            % If images haven't been loaded in memory, load them before
            % evaluating the modes.
            load_images_memory(0,0);
            % If the user didn't load the images into memory
            if ~hand.Check_imload
                return
            end
        end
        
        NImg = hand.NImg;
        N_bloc = hand.N_bloc;
        MaxImg = hand.MaxImg;
        
        wh = waitbar(0,'','Name','Evaluating eigenvalues...');
        
        % Create the matrix C. It can't be single because it may contain very high
        % values and a double precision is required
        
        if hand.Use_tmp_file
            C = zeros(NImg);
            for bloc_i = 1:N_bloc
                if ishandle(wh)
                    waitbar(bloc_i/N_bloc,wh,sprintf('Loading bloc %d of %d...',bloc_i,N_bloc));
                else
                    wh = waitbar(bloc_i/N_bloc,sprintf('Loading bloc %d of %d...',bloc_i,N_bloc));
                end
                tmp_filename = fullfile(hand.pathtemp,sprintf('Temp_%d.mat',bloc_i));
                data_i = load(tmp_filename,'M_bloc');
                
                % Covariance on the diagonal elements can be directly calculated
                % using M_block
                index = (1:MaxImg) + (bloc_i-1)*MaxImg;
                index = index(index <= NImg);
                C(index,index) = data_i.M_bloc*transpose(data_i.M_bloc);
                
                for bloc_j = bloc_i+1:N_bloc
                    tmp_filename = fullfile(hand.pathtemp,sprintf('Temp_%d.mat',bloc_j));
                    data_j = load(tmp_filename,'M_bloc');
                    
                    ind2 = (1:MaxImg) + (bloc_j-1)*MaxImg;
                    ind2 = ind2(ind2 <= NImg);
                    C(index,ind2) = data_i.M_bloc * transpose(data_j.M_bloc);
                    C(ind2,index) = transpose(C(index,ind2));
                    % Matlab doesn't overwrite the memory when loading
                    % data, therefore the variable must be deleted to allow
                    % the new one to be loaded
                    clear('data_j')
                end
                % Matlab doesn't overwrite the memory when loading
                % data, therefore the variable must be deleted to allow
                % the new one to be loaded
                clear('data_i')
            end
        else
            C = hand.M_bloc * transpose(hand.M_bloc);
        end
        
        % Update status
        update_status(' ');
        msg = 'Images spectrum correctly evaluated';
        update_status(msg)
        msg = 'Image modes can now be evaluated through the menu "Run"';
        update_status(msg)
        
        [PSI,LAMBDA] = svd(C);
        eigVal = diag(LAMBDA); clear LAMBDA
        mean_PSI = mean(PSI,1);
        
        close(wh)
        
        % Save gui data
        hand.eigVal = eigVal;
        hand.mean_PSI = mean_PSI;
        hand.PSI = PSI;
        hand.Check_eigproc = true;
        
        % Plot spectrum
        plot_spectrum(0);
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function evaluate_modes(~,~)
        % Evaluate the eigenmodes of the images
        
        % Check that the user selected the images
        if ~hand.Check_imsel
            msgbox('No images selected. Please select images from menu "File".', ...
                'No images selected','Warn');
            return
        end
        
        % Check if images are loaded into memory
        if ~hand.Check_imload
            load_images_memory(0,0)
            evaluate_spectrum(0,0)
        end
        
        % Check if the spectrum has been evaluated
        if ~hand.Check_eigproc
            evaluate_spectrum(0,0)
        end
       
        if hand.NMod_saved > 0
            defans = {num2str(hand.NMod_saved)};
        else
            N_auto = automatic_N_modes;
            defans = {num2str(N_auto)};
        end
        
        answ = inputdlg({'Select the number of images eigenmodes to calculate and save'}, ...
            'Evaluate eigenmodes',1,defans);
        if isempty(answ)
            return
        end
        NMod = str2double(answ);
        
        NImg = hand.NImg;
        N_bloc = hand.N_bloc;
        MaxImg = hand.MaxImg;
        
        % Plot eigenvalues
        if ~isfield(hand,'figure_modes') || ~ishandle(hand.figure_modes)
            hand.figure_modes = figure('Name','Modes', ...
                'numbertitle', 'off', ...
                'ToolBar', 'none', ...
                'menu','none','units','normalized', ...
                'KeyPressFcn',@key_shortcut, ...
                'outerposition',hand.pos_modes);
            hand_child = guihandles(hand.figure_modes);
            hand_child.parent = fig;
            hand_child.title = 'modes';
            show_modes_toolbar(hand.figure_modes,'modes')
        else
            figure(hand.figure_modes)
        end
        
        wh = waitbar(0,'','Name','Evaluating spectrum...');
        % Check if there are other modes already saved
        if hand.NMod_saved > 0
            first_mod = hand.NMod_saved;
        else
            first_mod = 1;
        end
        hand.NMod_saved = NMod;
        hand.Check_modproc = true;
        
        % Evaluate new modes
        for mod_i = first_mod:NMod
            % Evaluate PHI
            if hand.Use_tmp_file
                for bloc_i = 1:N_bloc
                    if ishandle(wh)
                        waitbar(((mod_i-1)*N_bloc+bloc_i)/(NMod*N_bloc), ...
                            wh,sprintf('Evaluating mode %d of %d...',mod_i,NMod));
                    else
                        wh = waitbar(((mod_i-1)*N_bloc+bloc_i)/(NMod*N_bloc), ...
                            sprintf('Evaluating mode %d of %d...',mod_i,NMod));
                    end
                    tmp_filename = fullfile(hand.pathtemp,sprintf('Temp_%d.mat',bloc_i));
                    data = load(tmp_filename,'M_bloc');
                    
                    if bloc_i == 1
                        PHI_bloc = zeros(size(data.M_bloc,2),1);
                    end
                    index = (1:MaxImg) + (bloc_i-1)*MaxImg;
                    index = index(index <= NImg);
                    PHI_bloc = PHI_bloc + transpose(data.M_bloc)*hand.PSI(index,mod_i);
                    % Matlab doesn't overwrite the memory when loading
                    % data, therefore the variable must be deleted to allow
                    % the new one to be loaded
                    clear('data')
                end
            else
                if ishandle(wh)
                    waitbar(mod_i/NMod,wh,sprintf('Evaluating mode %d of %d...',mod_i,NMod));
                else
                    wh = waitbar(mod_i/NMod,sprintf('Evaluating mode %d of %d...',mod_i,NMod));
                end
                PHI_bloc = transpose(hand.M_bloc)*hand.PSI(:,mod_i);
            end
            PHI_bloc = PHI_bloc/sqrt(sum(PHI_bloc.^2));
            
            % Evaluate T
            if hand.Use_tmp_file
                TCoeff_bloc = zeros(NImg,1);
                for bloc_i = 1:N_bloc
                    tmp_filename = fullfile(hand.pathtemp,sprintf('Temp_%d.mat',bloc_i));
                    data = load(tmp_filename,'M_bloc');
                    index = (1:MaxImg) + (bloc_i-1)*MaxImg;
                    index = index(index <= NImg);
                    TCoeff_bloc(index,1) = data.M_bloc*PHI_bloc;
                    % Matlab doesn't overwrite the memory when loading
                    % data, therefore the variable must be deleted to allow
                    % the new one to be loaded
                    clear('data')
                end
            else
                TCoeff_bloc = hand.M_bloc*PHI_bloc; %#ok<NASGU>
            end
            
            tmp_filename = fullfile(hand.pathtemp,sprintf('Modes_%d',mod_i));
            save(tmp_filename,'PHI_bloc','TCoeff_bloc','bgremkey','-v7.3')
            
            % Show evaluated mod
            callback_arrows(0,0,0,'modes');
            hand.showing_mod_i = hand.showing_mod_i+1;
            
            set(0,'CurrentFigure',wh)
            uistack(wh,'top')
        end
        close(wh)
        
        update_status(' ');
        msg = sprintf('%d modes were evaluated and stored into files',NMod-first_mod+1);
        update_status(msg)
        msg = 'Arrows can be used to inspect the modes';
        update_status(msg)
        msg = 'Select "Save images without background" from the menu "Run" after inspecting the modes';
        update_status(msg)
        
        % Save gui data
        hand.showing_mod_i = NMod;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set_automatic_modes(~,~)
        % Set the automatic number of modes
        
        % Check that the user selected the images
        if ~hand.Check_imsel
            msgbox('No images selected. Please select images from menu "File".', ...
                'No images selected','Warn');
            return
        end
        
        % Check if images are loaded into memory
        if ~hand.Check_imload
            load_images_memory(0,0)
            evaluate_spectrum(0,0)
        end
        
        % Check if the spectrum has been evaluated
        if ~hand.Check_eigproc
            evaluate_spectrum(0,0)
        end
        
        % Ask the user the the epsilon
        prompt = {'Insert epsilon 1 (sigma):','Insert epsilon 2 (psi):'};
        def = {num2str(hand.eps_auto_sigma), ...
            num2str(hand.eps_auto_psi)};
        answ = inputdlg(prompt,'Insert epsilon tolerances',1,def);
        
        if isempty(answ)
            return
        end
        
        hand.eps_auto_sigma = str2double(answ(1));
        hand.eps_auto_psi = str2double(answ(2));
        N_auto = automatic_N_modes;
        
        update_status(' ');
        if N_auto > 0
            Message = sprintf(['The automatic number of modes based on '...
                'the user input epsilon is %d'],N_auto);
            msgbox(Message,'Automatic number of modes')
            update_status(Message)
        else
            Message = sprintf(['The user input epsilon did not produce any '...
                'automatic number of modes.\nPlease select a different value of epsilon']);
            msgbox(Message,'Automatic number of modes','Warn')
            update_status(Message)
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function N_auto = automatic_N_modes
        % Evaluate the automatic number of modes
        N_auto = 0;
        for i = 1:hand.NImg-1
            Mean_PSI = abs(mean(hand.PSI(:,i)));
            Sig_Diff = abs(hand.eigVal(i)-hand.eigVal(i+1))/(hand.eigVal(round(hand.NImg/2)));
            if Mean_PSI < hand.eps_auto_psi && ...
                    Sig_Diff < hand.eps_auto_sigma*hand.eigVal(1)
                N_auto = i;
                return
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function remove_background(~,~,target)
        % Remove the background from images using the selected modes
        
        if ~hand.Check_modproc
            msgbox(['Images must be processed before background can be removed.' ...
                'Please select "Run -> Evaluate modes" and try again'], ...
                'Images not processed','Warn');
            return
        end
        
        % Check the target
        if strcmp(target,'training')
            % Remove the background from the training images
            target_list = hand.file_in;
            target_path = hand.path_in;
            NImg = numel(hand.file_in);
        elseif strcmp(target,'new_target_direct')
            % Select a new set of images from which remove the background
            [bfa,bfb] = uigetfile({'*.tif;*.tiff;*.bmp;*.jpg;*.gif;*.raw', ...
                'Image files'; '*.*',  'All files'},'Select images...',hand.path_in,'MultiSelect','on');
            
            % User select one single file
            if ~iscell(bfa)
                if bfa == 0
                    % No selection
                    return
                else
                    % Single selection
                    bfa = {bfa};
                end
            end
            
            target_list = bfa;
            target_path = bfb;
            NImg = numel(bfa);
        elseif strcmp(target,'new_target_pattern')
            % Open the pattern select dialog
            [sel_folder,filelist,range] = pattern_selection;
            
            % Check folder selection
            if isnumeric(sel_folder) && sel_folder == 0
                return
            end
            
            % Check having at least 2 images with the range
            try
                file_sel = {filelist.name};
                file_sel = file_sel(range(1):range(2));
                if numel(file_sel) > 0
                    % Select files
                    target_list = file_sel;
                    target_path = sel_folder;
                    NImg = numel(target_list);
                else
                    error('The user pattern selected less than two images')
                end
            catch me
                msgbox(me.message,'Error','Error');
                update_status(' ');
                update_status(me.message);
                return
            end
          
        elseif strcmp(target,'preview')
            msg = sprintf(['Number of eigenmodes to remove from the reconstruction\n'...
                'Modes available: %d'],hand.NMod_saved);
            answ = inputdlg({msg},'Select eigenmodes',1,{num2str(hand.NMod_saved)});
            if isempty(answ)
                return
            end
            NMod = str2double(answ(1));
            
            % Read image from file
            filename = fullfile(hand.path_in,hand.file_in{hand.showing_im_i});
            A = imread(filename);
            [H,W] = size(A);
            
            tmp_im = single(A(:))';
            for mod_i = 1:NMod
                tmp_filename = fullfile(hand.pathtemp,sprintf('Modes_%d',mod_i));
                data = load(tmp_filename,'PHI_bloc','TCoeff_bloc');
                tmp_im = tmp_im - data.TCoeff_bloc(mod_i,1) * data.PHI_bloc(:,1)';
            end
            
            Img_rec = reshape(tmp_im,H,W);
            
            % Show the current image without background
            set(0,'CurrentFigure',fig)
            cla
            imagesc(Img_rec)
            if hand.im_caxis.active
                caxis(hand.im_caxis.val)
            else
                caxis([0 max(Img_rec(:))])
                hand.im_caxis.val = caxis;
            end
            colormap gray
            axis ij equal tight
            set(gca,'color','none')
            title(sprintf('Preview of image "%s" without background\nModes removed: %d', ...
                hand.file_in{hand.showing_im_i},NMod), ...
                'interpreter','none')
            figure(fig)
            
            return
        end
        
        % Select folder for the output images
        bf = uigetdir(hand.path_in,'Select output folder...');
        if bf
            hand.path_out = bf;
        else
            return
        end
        
        % Ask the user to export background images
        Message = ['Selected images will be exported without background. ' ...
            'Do you also want to export background images in different files?'];
        button = questdlg(Message,'Save background','Yes','No','No');
        
        if strcmp(button,'Yes')
            save_background = true;
        else
            save_background = false;
        end
        
        msg = sprintf(['Number of eigenmodes to remove from the reconstruction\n'...
            'Modes available: %d'],hand.NMod_saved);
        answ = inputdlg({msg},'Select eigenmodes',1,{num2str(hand.NMod_saved)});
        NMod = str2double(answ(1));
        
        % Check number of modes available
        if NMod > hand.NMod_saved
            msg = ['The number of modes selected is higher than the number of ', ...
                    'modes available. Please reduce the number of modes to ', ...
                    'remove or evaluate more modes.'];
            msgbox(msg,'Modes not available','Warn');
            update_status(' ');
            update_status(msg)
            return
        end
        
        wh = waitbar(0,'','Name','Save images');
        % Subtract background from images
        if ~exist(hand.path_out,'dir')
            mkdir(hand.path_out)
        end
        
        for im_i = 1:NImg
            if ishandle(wh)
                waitbar(im_i/NImg,wh,sprintf('Saving image %d of %d...',im_i,NImg))
            else
                wh = waitbar(im_i/NImg,sprintf('Saving image %d of %d...',im_i,NImg));
            end
            % Read image from file
            filename = fullfile(target_path,target_list{im_i});
            A = imread(filename);
            if ~isnumeric(A)
                msgbox('Target image not compatible.','Error','Error');
                return
            end
            [H,W] = size(A);
            
            tmp_im = single(A(:))';
            for mod_i = 1:NMod
                tmp_filename = fullfile(hand.pathtemp,sprintf('Modes_%d',mod_i));
                data = load(tmp_filename,'PHI_bloc','TCoeff_bloc');
                tmp_im = tmp_im - data.TCoeff_bloc(im_i,1) * data.PHI_bloc(:,1)';
            end
            
            Img_rec = reshape(tmp_im,H,W);
            filename = fullfile(hand.path_out,sprintf('%s%s',hand.file_out_prefix,target_list{im_i}));
            % Create a variable with the same bitdepth as the original image
            bf = zeros(size(A),'like',A);
            bf(:) = Img_rec(:);
            imwrite(bf,filename,'Compression','none');
            
            % Save single background if requested
            if save_background
                filename_bg = fullfile(hand.path_out,sprintf('background_%s',target_list{im_i}));
                backg = A-bf;
                imwrite(backg,filename_bg,'Compression','none');
            end
        end
        
        close(wh)
        update_status(' ');
        msg = sprintf('%d images saved without background',NImg);
        update_status(msg)
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot_spectrum(show_current)
        % Generate or update the figures of the spectrum with the current
        % position, if available
        
        % Plot eigenvalues
        if ~isfield(hand,'figure_spectrum') || ~ishandle(hand.figure_spectrum)
            hand.figure_spectrum = figure('Name','Video spectrum', ...
                'numbertitle', 'off','units','normalized', ...
                'KeyPressFcn',@key_shortcut, ...
                'outerposition',hand.pos_spect);
            remove_buttons(hand.figure_spectrum);
            hand_child = guihandles(hand.figure_spectrum);
            hand_child.parent = fig;
            hand_child.title = 'spectrum';
        else
            set(0,'CurrentFigure',hand.figure_spectrum)
        end
        subplot(1,2,1)
        plot(1:hand.NImg,hand.eigVal,'o-','linewidth',2)
        xlabel('k')
        ylabel('\sigma_n')
        
        % Add the current position
        if show_current
            hold on
            plot(hand.showing_mod_i,hand.eigVal(hand.showing_mod_i), ...
                'or','linewidth',2,'markerfacecolor','r')
            hold off
        end
        title('Video spectrum')
        
        % Plot mean PSI
        subplot(1,2,2)
        plot(1:hand.NImg,hand.mean_PSI,'o-','linewidth',2)
        xlabel('k')
        ylabel('<\psi_k,1>')
        title('Mode''s Temporal Averages')
        
        % Add the current position
        if show_current
            hold on
            plot(hand.showing_mod_i,hand.mean_PSI(hand.showing_mod_i), ...
                'or','linewidth',2,'markerfacecolor','r')
            hold off
        end
        
        if show_current
            % Plot temporal coefficient
            if ~isfield(hand,'figure_tcoeff') || ~ishandle(hand.figure_tcoeff)
                hand.figure_tcoeff = figure('Name','Temporal coefficient', ...
                    'numbertitle', 'off','units','normalized', ...
                    'KeyPressFcn',@key_shortcut, ...
                    'outerposition',hand.pos_psi);
                remove_buttons(hand.figure_tcoeff);
                hand_child = guihandles(hand.figure_tcoeff);
                hand_child.parent = fig;
                hand_child.title = 'psi';
            else
                set(0,'CurrentFigure',hand.figure_tcoeff)
            end
            
            plot(1:hand.NImg,hand.PSI(:,hand.showing_mod_i),'o-','linewidth',2)
            xlabel('k')
            ylabel('\psi')
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function show_modes_toolbar(fig_sel,fig_name)
        % Get default toolbar from dummy figure
        delme = figure('Visible','off');
        h_pan = findall(delme,'ToolTipString','Pan');
        h_zoomin = findall(delme,'ToolTipString','Zoom In');
        h_zoomout = findall(delme,'ToolTipString','Zoom Out');
        % New element for the toolbar
        right_ico = [NaN 32 48 48 48 48 48 48 48 48 48 48 32 32 NaN NaN NaN 32 204 143 143 143 143 143 143 143 143 143 84 32 NaN NaN NaN 32 204 143 143 143 143 143 143 143 143 143 84 32 153 NaN NaN NaN 32 204 143 143 143 143 143 143 143 84 32 153 153 NaN NaN NaN 32 204 143 143 143 143 143 143 143 84 32 153 153 NaN NaN NaN NaN 32 204 143 143 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN 32 204 143 143 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN NaN 32 204 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN NaN NaN 32 204 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN 32 204 143 84 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 204 143 84 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 143 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 143 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 153 NaN NaN NaN NaN NaN NaN NaN 255 65 61 61 61 61 61 61 61 61 61 61 65 65 255 255 255 65 255 225 225 225 225 225 225 225 225 225 120 65 255 255 255 65 255 225 225 225 225 225 225 225 225 225 120 65 153 255 255 255 65 255 225 225 225 225 225 225 225 120 65 153 153 255 255 255 65 255 225 225 225 225 225 225 225 120 65 153 153 255 255 255 255 65 255 225 225 225 225 225 120 65 153 153 255 255 255 255 255 65 255 225 225 225 225 225 120 65 153 153 255 255 255 255 255 255 65 255 225 225 225 120 65 153 153 255 255 255 255 255 255 255 65 255 225 225 225 120 65 153 153 255 255 255 255 255 255 255 255 65 255 225 120 65 153 153 255 255 255 255 255 255 255 255 255 65 255 225 120 65 153 153 255 255 255 255 255 255 255 255 255 255 65 225 65 153 153 255 255 255 255 255 255 255 255 255 255 255 65 225 65 153 153 255 255 255 255 255 255 255 255 255 255 255 255 65 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 65 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 153 255 255 255 255 255 255 255 255 1 59 59 59 59 59 59 59 59 59 59 1 1 255 255 255 1 153 60 60 60 60 60 60 60 60 60 47 1 255 255 255 1 153 60 60 60 60 60 60 60 60 60 47 1 153 255 255 255 1 153 60 60 60 60 60 60 60 47 1 153 153 255 255 255 1 153 60 60 60 60 60 60 60 47 1 153 153 255 255 255 255 1 153 60 60 60 60 60 47 1 153 153 255 255 255 255 255 1 153 60 60 60 60 60 47 1 153 153 255 255 255 255 255 255 1 153 60 60 60 47 1 153 153 255 255 255 255 255 255 255 1 153 60 60 60 47 1 153 153 255 255 255 255 255 255 255 255 1 153 60 47 1 153 153 255 255 255 255 255 255 255 255 255 1 153 60 47 1 153 153 255 255 255 255 255 255 255 255 255 255 1 60 1 153 153 255 255 255 255 255 255 255 255 255 255 255 1 60 1 153 153 255 255 255 255 255 255 255 255 255 255 255 255 1 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 1 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 153 255 255 255 255 255 255 255];
        left_ico = [NaN NaN NaN NaN NaN NaN NaN NaN 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 143 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 143 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 204 143 84 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 204 143 84 32 153 153 NaN NaN NaN NaN NaN NaN NaN NaN 32 204 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN NaN NaN 32 204 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN NaN 32 204 143 143 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN 32 204 143 143 143 143 143 84 32 153 153 NaN NaN NaN NaN 32 204 143 143 143 143 143 143 143 84 32 153 153 NaN NaN NaN 32 204 143 143 143 143 143 143 143 84 32 153 153 NaN NaN 32 204 143 143 143 143 143 143 143 143 143 84 32 153 NaN NaN 32 204 143 143 143 143 143 143 143 143 143 84 32 NaN NaN NaN 32 48 48 48 48 48 48 48 48 48 48 32 32 NaN NaN 255 255 255 255 255 255 255 255 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 65 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 65 153 153 255 255 255 255 255 255 255 255 255 255 255 255 65 225 65 153 153 255 255 255 255 255 255 255 255 255 255 255 65 225 65 153 153 255 255 255 255 255 255 255 255 255 255 65 255 225 120 65 153 153 255 255 255 255 255 255 255 255 255 65 255 225 120 65 153 153 255 255 255 255 255 255 255 255 65 255 225 225 225 120 65 153 153 255 255 255 255 255 255 255 65 255 225 225 225 120 65 153 153 255 255 255 255 255 255 65 255 225 225 225 225 225 120 65 153 153 255 255 255 255 255 65 255 225 225 225 225 225 120 65 153 153 255 255 255 255 65 255 225 225 225 225 225 225 225 120 65 153 153 255 255 255 65 255 225 225 225 225 225 225 225 120 65 153 153 255 255 65 255 225 225 225 225 225 225 225 225 225 120 65 153 255 255 65 255 225 225 225 225 225 225 225 225 225 120 65 255 255 255 65 61 61 61 61 61 61 61 61 61 61 65 65 255 255 255 255 255 255 255 255 255 255 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 1 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 1 153 153 255 255 255 255 255 255 255 255 255 255 255 255 1 60 1 153 153 255 255 255 255 255 255 255 255 255 255 255 1 60 1 153 153 255 255 255 255 255 255 255 255 255 255 1 153 60 47 1 153 153 255 255 255 255 255 255 255 255 255 1 153 60 47 1 153 153 255 255 255 255 255 255 255 255 1 153 60 60 60 47 1 153 153 255 255 255 255 255 255 255 1 153 60 60 60 47 1 153 153 255 255 255 255 255 255 1 153 60 60 60 60 60 47 1 153 153 255 255 255 255 255 1 153 60 60 60 60 60 47 1 153 153 255 255 255 255 1 153 60 60 60 60 60 60 60 47 1 153 153 255 255 255 1 153 60 60 60 60 60 60 60 47 1 153 153 255 255 1 153 60 60 60 60 60 60 60 60 60 47 1 153 255 255 1 153 60 60 60 60 60 60 60 60 60 47 1 255 255 255 1 59 59 59 59 59 59 59 59 59 59 1 1 255 255];
        circ_ico = [NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 32 32 32 32 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 84 32 204 204 204 204 32 84 NaN NaN NaN NaN NaN NaN NaN NaN 32 204 143 143 143 143 204 32 153 NaN NaN NaN NaN NaN NaN 32 204 143 143 143 143 143 143 84 32 NaN NaN NaN NaN NaN NaN 32 204 143 143 143 143 143 143 84 32 153 NaN NaN NaN NaN NaN 32 204 143 143 143 143 143 143 84 32 153 NaN NaN NaN NaN NaN 32 204 143 143 143 143 143 143 84 32 153 NaN NaN NaN NaN NaN NaN 32 84 143 143 143 143 84 32 153 153 NaN NaN NaN NaN NaN NaN 84 32 84 84 84 84 32 84 153 NaN NaN NaN NaN NaN NaN NaN NaN 153 32 32 32 32 153 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 153 153 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 65 65 65 65 255 255 255 255 255 255 255 255 255 255 120 65 255 255 255 255 65 120 255 255 255 255 255 255 255 255 65 255 225 225 225 225 255 65 153 255 255 255 255 255 255 65 255 225 225 225 225 225 225 120 65 255 255 255 255 255 255 65 255 225 225 225 225 225 225 120 65 153 255 255 255 255 255 65 255 225 225 225 225 225 225 120 65 153 255 255 255 255 255 65 255 225 225 225 225 225 225 120 65 153 255 255 255 255 255 255 65 120 225 225 225 225 120 65 153 153 255 255 255 255 255 255 120 65 120 120 120 120 65 120 153 255 255 255 255 255 255 255 255 153 65 65 65 65 153 153 153 255 255 255 255 255 255 255 255 255 255 153 153 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 1 1 1 1 255 255 255 255 255 255 255 255 255 255 47 1 153 153 153 153 1 47 255 255 255 255 255 255 255 255 1 153 60 60 60 60 153 1 153 255 255 255 255 255 255 1 153 60 60 60 60 60 60 47 1 255 255 255 255 255 255 1 153 60 60 60 60 60 60 47 1 153 255 255 255 255 255 1 153 60 60 60 60 60 60 47 1 153 255 255 255 255 255 1 153 60 60 60 60 60 60 47 1 153 255 255 255 255 255 255 1 47 60 60 60 60 47 1 153 153 255 255 255 255 255 255 47 1 47 47 47 47 1 47 153 255 255 255 255 255 255 255 255 153 1 1 1 1 153 153 153 255 255 255 255 255 255 255 255 255 255 153 153 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255];
        color_ico = [NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 NaN 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 155 155 155 155 155 165 185 203 223 237 237 237 237 0 153 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 153 NaN 153 153 153 153 153 153 153 153 153 153 153 153 153 153 153 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 255 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 156 172 192 210 230 237 237 237 237 232 214 195 176 0 153 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 153 255 153 153 153 153 153 153 153 153 153 153 153 153 153 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 255 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 236 237 237 237 237 226 207 188 168 155 155 155 155 0 153 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 153 255 153 153 153 153 153 153 153 153 153 153 153 153 153 153 153 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255];
        adj_ico = [NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN 66 66 66 66 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 66 198 247 247 231 66 66 NaN NaN NaN NaN NaN NaN NaN NaN 66 189 255 255 255 255 214 214 66 66 8 8 NaN NaN NaN NaN 66 189 255 NaN 255 255 255 255 255 66 NaN NaN 8 66 66 NaN 66 189 255 NaN 255 255 66 66 255 66 198 198 8 NaN NaN NaN 66 189 255 255 255 255 255 255 255 66 82 82 8 NaN NaN NaN 66 189 255 255 255 255 189 189 66 66 8 16 NaN NaN NaN NaN NaN 66 189 189 189 189 66 66 NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN 66 66 66 66 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 66 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 255 255 255 255 255 255 255 60 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 60 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 60 255 255 255 255 255 255 255 60 255 255 60 60 60 60 255 255 255 255 255 255 255 255 255 255 255 60 190 243 239 227 60 60 255 255 255 255 255 255 255 255 60 186 255 255 255 255 207 207 60 60 8 8 255 255 255 255 60 182 255 255 255 255 255 255 255 60 255 255 12 60 60 255 60 182 255 255 255 255 60 60 255 60 195 195 12 255 255 255 60 182 255 255 255 255 255 255 255 60 85 85 12 255 255 255 60 182 255 255 255 255 182 182 60 60 12 16 255 255 255 255 255 60 182 182 182 182 60 60 255 255 255 255 255 255 255 60 255 255 60 60 60 60 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 60 255 255 255 255 255 255 255 255 255 255 255 255 60 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 60 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 16 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 16 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 16 255 255 255 255 255 255 255 16 255 255 16 16 16 16 255 255 255 255 255 255 255 255 255 255 255 16 74 57 74 66 16 16 255 255 255 255 255 255 255 255 16 24 214 247 132 74 0 0 16 16 8 8 255 255 255 255 16 24 222 255 173 74 74 0 0 16 255 255 16 16 16 255 16 24 222 255 0 90 16 16 0 16 189 189 16 255 255 255 16 24 156 90 74 74 74 0 0 16 74 74 16 255 255 255 16 24 82 0 0 0 24 24 16 16 16 16 255 255 255 255 255 16 24 24 24 24 16 16 255 255 255 255 255 255 255 16 255 255 16 16 16 16 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 16 255 255 255 255 255 255 255 255 255 255 255 255 16 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 16 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255];
        right_ico = reshape(right_ico,16,16,3)/255;
        left_ico = reshape(left_ico,16,16,3)/255;
        circ_ico = reshape(circ_ico,16,16,3)/255;
        color_ico = reshape(color_ico,16,16,3)/255;
        adj_ico = reshape(adj_ico,16,16,3)/255;
        toolb_h = uitoolbar(fig_sel);
        uipushtool(toolb_h,'TooltipString','Show next',...
            'CData',left_ico, ...
            'ClickedCallback', {@callback_arrows,-1,fig_name});
        uipushtool(toolb_h,'TooltipString','Jump to...',...
            'CData',circ_ico, ...
            'ClickedCallback', {@callback_arrows,nan,fig_name});
        uipushtool(toolb_h,'TooltipString','Show previous',...
            'CData',right_ico, ...
            'ClickedCallback', {@callback_arrows,+1,fig_name});
        uipushtool(toolb_h,'TooltipString','Change colormap',...
            'CData',color_ico, ...
            'ClickedCallback', @change_colormap);
        uipushtool(toolb_h,'TooltipString','Adjust image color limit',...
            'CData',adj_ico, ...
            'ClickedCallback', {@adjust_image,fig_name});
        set(h_zoomin,'Parent',toolb_h);
        set(h_zoomout,'Parent',toolb_h);
        set(h_pan,'Parent',toolb_h);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function callback_arrows(~,~,next,fig_name)
        % Update the figure content when user clicks on the arrows
        
        % Check if the arrow was pressed in the figure of modes or main
        if strcmp(fig_name,'modes') && hand.Check_modproc
            % Jump to
            if isnan(next)
                answ = inputdlg('Jump to mode', ...
                    'Jump to mode...',1,{num2str(hand.showing_mod_i)});
                
                hand.showing_mod_i  = min(max(str2double(answ),1),hand.NMod_saved);
            else
                hand.showing_mod_i = min(max(hand.showing_mod_i+next,1),hand.NMod_saved);
            end
            H = hand.Dim(1);
            W = hand.Dim(2);
            
            tmp_filename = fullfile(hand.pathtemp,sprintf('Modes_%d',hand.showing_mod_i));
            data = load(tmp_filename,'PHI_bloc');
            PHI_bloc = reshape(data.PHI_bloc,H,W);
            
            % Plot the spectrum
            plot_spectrum(1)
            
            % Show the mode
            set(0,'CurrentFigure',hand.figure_modes)
            cla
            imagesc(reshape(PHI_bloc,H,W))
            if hand.phi_caxis.active
                caxis(hand.phi_caxis.val)
            else
                caxis auto
                hand.phi_caxis.val = caxis;
            end
            colormap hot
            axis ij equal tight
            colorbar
            rr = sqrt(1-hand.showing_mod_i/hand.NImg);
            title(sprintf(['Preview mode %d of %d\n', ...
                'Recovery ratio: %.2f'],hand.showing_mod_i,hand.NMod_saved,rr))

        elseif strcmp(fig_name,'main') && hand.Check_imsel
            % Jump to
            if isnan(next)
                answ = inputdlg('Jump to image', ...
                    'Jump to image...',1,{num2str(hand.showing_im_i)});
                
                hand.showing_im_i  = min(max(str2double(answ),1),hand.NImg);
            else
                hand.showing_im_i = min(max(hand.showing_im_i+next,1),hand.NImg);
            end
            
            filename = fullfile(hand.path_in,hand.file_in{hand.showing_im_i});
            A = imread(filename);
            % Show the image
            set(0,'CurrentFigure',fig)
            cla
            imagesc(A)
            if hand.im_caxis.active
                caxis(hand.im_caxis.val)
            else
                caxis auto
                hand.im_caxis.val = caxis;
            end
            colormap gray
            axis ij equal tight
            set(gca,'color','none')
            title(sprintf('Preview image %d of %d\n%s', ...
                hand.showing_im_i,hand.NImg,hand.file_in{hand.showing_im_i}), ...
                'interpreter','none')
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function show_window(~,~,show)
        % Generates the figures "status", "spectrum" and "modes" if they
        % don't exist or bring them up to front if they do. Rearrange all
        % the figures in the starting position
        
        % Check the input argument
        if strcmp(show,'status')
            %%%%%%%%%%%%%%%%%%%%
            % STATUS           %
            %%%%%%%%%%%%%%%%%%%%
            
            % Check if the window is open
            
            if ~isfield(hand,'figure_status') || ~ishandle(hand.figure_status)
                update_status(1);
            else
                figure(hand.figure_status)
            end
        elseif strcmp(show,'spectrum')
            %%%%%%%%%%%%%%%%%%%%
            % SPECTRUM         %
            %%%%%%%%%%%%%%%%%%%%
            
            % Check if eigenvalues have been evaluated
            if hand.Check_eigproc
                plot_spectrum(0)
            else
                msgbox('Please evaluate the spectrum before displaying it.', ...
                    'Spectrum not available','Warn');
            end
        elseif strcmp(show,'modes')
            %%%%%%%%%%%%%%%%%%%%
            % MODES            %
            %%%%%%%%%%%%%%%%%%%%
            
            % Show the modes window if it doesn't exist
            if hand.Check_modproc
                if ~isfield(hand,'figure_modes') || ~ishandle(hand.figure_modes)
                    hand.figure_modes = figure('Name','Spatial modes', ...
                        'numbertitle', 'off', ...
                        'ToolBar', 'none', ...
                        'menu','none','units','normalized', ...
                        'KeyPressFcn',@key_shortcut, ...
                        'outerposition',hand.pos_modes);
                    hand_child = guihandles(hand.figure_modes);
                    hand_child.parent = fig;
                    hand_child.title = 'modes';
                    show_modes_toolbar(hand.figure_modes,'modes')
                    % Update the content of the figure
                    callback_arrows(0,0,0,'modes')
                else
                    figure(hand.figure_modes)
                end
            else
                msgbox('Please evaluate the modes before displaying them.', ...
                    'Modes not available','Warn');
            end
        elseif strcmp(show,'rearrange')
            %%%%%%%%%%%%%%%%%%%%
            % REARRANGE        %
            %%%%%%%%%%%%%%%%%%%%
            
            % Rearrange all the existing windows to the starting position
            set(fig,'OuterPosition',[0 .1 .5 .9])
            if isfield(hand,'figure_spectrum') && ishandle(hand.figure_spectrum)
                set(hand.figure_spectrum,'OuterPosition',hand.pos_spect)
                figure(hand.figure_spectrum)
            end
            if isfield(hand,'figure_tcoeff') && ishandle(hand.figure_tcoeff)
                set(hand.figure_tcoeff,'OuterPosition',hand.pos_psi)
                figure(hand.figure_tcoeff)
            end
            if isfield(hand,'figure_modes') && ishandle(hand.figure_modes)
                set(hand.figure_modes,'OuterPosition',hand.pos_modes)
                figure(hand.figure_modes)
            end
            if isfield(hand,'figure_status') && ishandle(hand.figure_status)
                set(hand.figure_status,'OuterPosition',hand.pos_status)
                figure(hand.figure_status)
            end
            figure(fig)
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set_bg_filename(~,~)
        
        answ = inputdlg('Insert a prefix to append to the images filenames', ...
            'Background prefix name',1,{hand.file_out_prefix});
        
        if ~isempty(answ)
            hand.file_out_prefix = answ{1};
        else
            return
        end
        
        % Update status
        update_status(' ');
        msg = sprintf('Background removed images will be saved using the prefix: %s',hand.file_out_prefix);
        update_status(msg)
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function change_temp_fold(~,~)
        % Change the temporary folder where files are stored. If images are
        % already loaded into memory, ask the user if they want to proceed
        
        % Check if there are images already loaded into memory
        if hand.Check_imload
            Message = sprintf(['A set of images has already been loaded into memory. ' ...
                'By changing the temporary folder a new session will be started.\n' ...
                'Do you wish to continue?']);
            button = questdlg(Message,'Change temporary folder','Yes','No','Yes');
        else
            button = 'Yes';
        end
        
        if strcmp(button,'Yes')
            % Set new temporary folder
            bf = uigetdir(hand.pathtemp,'Select temporary folder...');
            if bf
                initialize_session
                hand.pathtemp = bf;
            else
                return
            end
            
            % Update status
            update_status(' ');
            msg = sprintf('Temporary folder changed to: %s',hand.pathtemp);
            update_status(msg)
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function memory_info(~,~)
        
        if hand.Check_imsel
            filename = fullfile(hand.path_in,hand.file_in{1});
            A = imread(filename);
            [H,W] = size(A);
            NImg = hand.NImg;
        else
            H = 1000;
            W = 1000;
            NImg = 100;
        end
        
        % Evaluate the memory needed
        sys = memory;
        MemAv = sys.MaxPossibleArrayBytes;
        MaxImg = floor(MemAv/hand.bytesPerElem/(H*W)/2*hand.mem_safe);
        N_bloc = floor(NImg/MaxImg);
        N_bloc(N_bloc>0) = N_bloc+1;
        % Dialog
        Message = sprintf(['Memory available: %.2f GB\n' ...
            'Memory usable: %.2f GB\n' ...
            'Max #N images (without temp file): %d\n' ...
            'Temporary files needed: %d'],...
            MemAv/1e9, MemAv/1e9*hand.mem_safe, MaxImg, N_bloc);
        
        if ~hand.Check_imsel
            Message = sprintf(['No images selected!\nValues are shown ' ...
                'for 100 test images of 1 Mpx\n%s'],Message);
        end
        
        msgbox(Message,'Memory info','help')
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set_memory(~,~)
        % Change the maximum memory usable for the software
        
        % Evaluate the memory needed
        sys = memory;
        MemAv = sys.MaxPossibleArrayBytes;
        
        Message = sprintf(['In order to prevent system crashes, only part of' ...
            ' total memory available in the system is used by the software.' ...
            'The usable memory can be changed from this dialog. Using ' ...
            'the entire memory could cause crashes and instabilities!\n\n'...
            'Total memory available: %.2fGB\nUsable memory: %.2f GB\n' ...
            'Fraction of the total memory to use (between 0.1 and 1):'], ...
            MemAv/1e9,MemAv/1e9 * hand.mem_safe);
        defans = {num2str(hand.mem_safe)};
        answ = inputdlg({Message},'Change memory usage',1,defans);
        
        if isempty(answ)
            return
        end
        
        old = hand.mem_safe;
        hand.mem_safe = max(0.1,min(1,str2double(answ)));
        
        update_status(' ');
        msg = sprintf(['Fraction of usable memory changed from '...
            '%.2f to %.2f'],old,hand.mem_safe);
        update_status(msg)
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function change_colormap(~,~)
        
        col = colormap;
        if col(1,1) == col(1,2)
            colormap hot
            colorbar
        else
            colormap gray
            colorbar hide
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function adjust_image(~,~,fig_name)
        
        % If no image is selected, simply return
        if ~hand.Check_imsel
            return
        end
        % Check in which window the button was pressed
        if strcmp(fig_name,'modes')
            cax = hand.phi_caxis.val;
        elseif strcmp(fig_name,'main')
            cax = hand.im_caxis.val;
        end
        
        mi = num2str(cax(1));
        ma = num2str(cax(2));
        
        Message = sprintf(['Insert grayscale display limit. Press cancel ' ...
            'for automatic\nMinimum:']);
        answ = inputdlg({Message,'Maximum:'}, ...
            'Adjust image display',1,{mi ma});
        if isempty(answ)
            if strcmp(fig_name,'modes')
                hand.phi_caxis.active = false;
            elseif strcmp(fig_name,'main')
                hand.im_caxis.active = false;
            end
        else
            cax = str2double(answ);
            cax(2) = max(cax(2),cax(1)+1e-6);
            if strcmp(fig_name,'modes')
                hand.phi_caxis.val = cax;
                hand.phi_caxis.active = true;
            elseif strcmp(fig_name,'main')
                hand.im_caxis.val = cax;
                hand.im_caxis.active = true;
            end
        end
        
        % Update the figure
        callback_arrows(0,0,0,fig_name)
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function remove_buttons(sfig)
        % Get default toolbar from dummy figure
        delme = figure('Visible','off');
        h_pan = findall(delme,'ToolTipString','Pan');
        h_zoomin = findall(delme,'ToolTipString','Zoom In');
        h_zoomout = findall(delme,'ToolTipString','Zoom Out');
        h_datac = findall(delme,'ToolTipString','Data Cursor');
        % Generate new toolbar
        set(sfig,'MenuBar','none')
        toolb_h = uitoolbar(sfig);
        % Add elements to toolbar
        set(h_zoomin,'Parent',toolb_h);
        set(h_zoomout,'Parent',toolb_h);
        set(h_pan,'Parent',toolb_h);
        set(h_datac,'Parent',toolb_h);
        close(delme)
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function update_status(msg)
        % Append the message contained in the variable msg to the status
        % window
        % msg = -1, the status window will cleared
        % msg = 0, the status window will be cleared and the window initialized
        % msg = 1, the status window will be reopened if closed
        persistent h_listbox listbox
        
        % Clear the status
        if isnumeric(msg) && (msg == 0 || msg == -1)
            listbox = {};
        end
        
        % Initialize the window
        if isnumeric(msg) && (msg == 0 || msg == 1)
            % Create the status window
            hand.figure_status = figure('Name','Status', ...
                'numbertitle', 'off', ...
                'ToolBar', 'none', ...
                'menu','none', ...
                'units','normalized', ...
                'KeyPressFcn', @key_shortcut, ...
                'outerposition',hand.pos_status);
            % Get the size of the window in pixels
            set(hand.figure_status,'units','pixels')
            bf = get(hand.figure_status,'position');
            set(hand.figure_status,'units','normalized')
            
            % Create the listbox
            h_listbox = uicontrol(hand.figure_status, ...
                'Style','listbox',...
                'Position',[0 0 bf(3) bf(4)],...
                'String',listbox,...
                'BackgroundColor','w',...
                'units','pixel');
            set(h_listbox,'units','normalized')
        end
        
        if ischar(msg)
            listbox = {msg, listbox{:}}; %#ok<CCAT>
            set(h_listbox,'String',listbox)
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [sel_folder,filelist,range] = pattern_selection
        % Open a dialog to select files with a pattern and folder
        
        % First, select a folder
        sel_folder = uigetdir(hand.path_in,'Select images folder...');
        % Detect no folder selected
        if ~ischar(sel_folder) && sel_folder == 0
            sel_folder = 0;
            filelist = 0;
            range = 0;
            return
        end
        % Detect a default filename for the images
        flist = [dir(fullfile(sel_folder,'*.tif'));
            dir(fullfile(sel_folder,'*.tiff'));
            dir(fullfile(sel_folder,'*.bmp'));
            dir(fullfile(sel_folder,'*.png'));
            dir(fullfile(sel_folder,'*.jpg'))];
        if numel(flist) > 0
            defname = {flist(round(end/2)).name};
        else
            defname = {'*.tif'};
        end
        % Then, insert a pattern
        answ = inputdlg({sprintf(['Enter the file extension or wildcard ' ...
            'pattern to select files\n\n' ...
            'Ex: airfoil_*a.tif will select:\n' ...
            'airfoil_1a.tif, airfoil_0001a.tif, airfoil_0002a.tif, etc.'])}, ...
            'Select images',1,defname);
        % Check empty pattern
        if isempty(answ)
            sel_folder = 0;
            filelist = 0;
            range = 0;
            return
        end
        % Check that the files exist
        filelist = dir(fullfile(sel_folder,answ{1}));
        if numel(filelist) < 2
            msgbox('No files found with the selected pattern.', ...
                'No images selected','Warn');
            msg = sprintf('No images found with the pattern "%s" in the folder "%s"',answ{1},sel_folder);
            update_status(' ');
            update_status(msg)
            range = 0;
            return
        else
            prompt = {sprintf(['%d images were found with the user pattern\n' ...
                'Plese input the range of images to select.\nFrom:'],numel(filelist)), ...
                'To:'};
            answ = inputdlg(prompt,'Select images',1,{'1', num2str(numel(filelist))});
            range = [str2double(answ{1}) str2double(answ{2})];
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function open_explorer(~,~,folder)
        if strcmp(folder,'working')
            winopen(pwd)
        elseif strcmp(folder,'temp')
            winopen(hand.pathtemp)
        elseif strcmp(folder,'input')
            winopen(hand.path_in)
        elseif strcmp(folder,'output')
            winopen(hand.path_out)
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function about(~,~,entry)
        % Show about information
        
        if strcmp(entry,'about')
            Message = sprintf(['This code is developed in collaboration between the von Karman '...
                'Institute, the Universidad Carlos III de Madrid and the University of Bristol.\n'...
                '\nPlease report any bug at:\na.masullo@bristol.ac.uk\n' ...
                'Version: %s\n'],hand.Version);
            answ = questdlg(Message,'POD-based background removal for Particle Image Velocimetry', ...
                'Report a bug','Ok','Ok');
            if strcmp(answ,'Report a bug')
                web('http://seis.bris.ac.uk/~aexrt/PIVPODPreprocessing/bugreport.html', '-browser')
            end
        elseif strcmp(entry,'license')
            Message = sprintf(['This code is distributed under the CC BY-NC-SA 4.0 license '...
                'by Creative Common. You are free to share, copy and redistribute this software '...
                'as long as you do it under the same license as the original.\n'...
                'You must give appropriate credit to the authors of this sofware.\n' ...
                'You may NOT use this software for commercial purposes.']);
            answ = questdlg(Message,'POD-based background removal for Particle Image Velocimetry', ...
                'View the full license','Ok','Ok');
            if strcmp(answ,'View the full license')
                web('https://creativecommons.org/licenses/by-nc-sa/4.0/', '-browser')
            end
        elseif strcmp(entry,'temp_files')
            Message = 'The background removal tool requires the entire set of images to be loaded into memory. If the available memory is insufficient for the operation, images will be processed through some temporary files that will be stored on the hard drive. The process of saving/loading temporary files can be time consuming but it allows the user to process any set of images independently from the memory available.';
            msgbox(Message,'POD-based background removal for Particle Image Velocimetry')
        elseif strcmp(entry,'citation')
            Message = sprintf(['To cite this work in you paper, please refer to:\n' ...
                'POD-based background removal for particle image velocimetry\n' ...
                'Authors:\nM.A. Mendez, M. Raiola, A. Masullo, S. Discetti, ' ...
                'A. Ianiro, R. Theunissen and J.-M. Buchlin\n', ...
                'Experimental Thermal and Fluid Science, 80, 181-192\n', ...
                'http://dx.doi.org/10.1016/j.expthermflusci.2016.08.021']);
            answ = questdlg(Message,'POD-based background removal for Particle Image Velocimetry', ...
                'Copy BibTeX to clipboard','Open link to paper','Ok','Ok');
            if strcmp(answ,'Open link to paper')
                web('http://dx.doi.org/10.1016/j.expthermflusci.2016.08.021', '-browser')
            elseif strcmp(answ,'Copy BibTeX to clipboard')
                bib = sprintf(['@article{Mendez2017181,\n', ...
                    'title = "POD-based background removal for particle image velocimetry ",\n', ...
                    'journal = "Experimental Thermal and Fluid Science ",\n', ...
                    'volume = "80",\n', ...
                    'number = "",\n', ...
                    'pages = "181 - 192",\n', ...
                    'year = "2017",\n', ...
                    'note = "",\n', ...
                    'issn = "0894-1777",\n', ...
                    'doi = "http://dx.doi.org/10.1016/j.expthermflusci.2016.08.021",\n', ...
                    'url = "http://www.sciencedirect.com/science/article/pii/S0894177716302266",\n', ...
                    'author = "M.A. Mendez and M. Raiola and A. Masullo and S. Discetti and A. Ianiro and R. Theunissen and J.-M. Buchlin",\n', ...
                    'keywords = "\\{PIV\\} image pre-processing",\n', ...
                    'keywords = "POD decomposition of video sequences",\n', ...
                    'keywords = "Reduced Order Modeling (ROM) "\n', ...
                    '}\n\n']);
                clipboard('copy',bib)
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function delete_temporary_files(~,~,exit)
        % Delete all the temporary files saved by the software and start a
        % new session. If exit is false, ask a confirmation to the user,
        % otherwise proceed without confirmation
        
        if exit
            button = 'Yes';
        else
            Message = ['This action will delete all the temporary files created and ' ...
                'will start a new session. Do you wish to continue?'];
            button = questdlg(Message,'Start new session','Yes','No','Yes');
        end
        
        if strcmp(button,'Yes')
            % Delete temporary files
            deleted_mod = 0;
            deleted_tmp = 0;
            target = dir(fullfile(hand.pathtemp,'Temp_*.mat'));
            for i = 1:numel(target)
                tmp = fullfile(hand.pathtemp,target(i).name);
                % Check that the file removed were created by this software
                data = load(tmp,'bgremkey');
                if ~isempty(fieldnames(data)) && strcmp(data.bgremkey,bgremkey)
                    delete(tmp)
                    deleted_tmp = deleted_tmp+1;
                end
            end
            target = dir(fullfile(hand.pathtemp,'Modes_*.mat'));
            for i = 1:numel(target)
                tmp = fullfile(hand.pathtemp,target(i).name);
                % Check that the file removed were created by this software
                data = load(tmp,'bgremkey');
                if ~isempty(fieldnames(data)) && strcmp(data.bgremkey,bgremkey)
                    delete(tmp)
                    deleted_mod = deleted_mod+1;
                end
            end
            
            if ~exit
                % Close windows
                openFigures = get(0,'Children');
                openFigures(openFigures == fig) = [];
                close(openFigures)
                % Clear status window
                update_status(0)
                msg = sprintf('%d temporary files deleted',deleted_tmp);
                update_status(msg)
                msg = sprintf('%d stored modes deleted',deleted_mod);
                update_status(msg)
                update_status(sprintf('Temporary folder: %s',hand.pathtemp));
                update_status(sprintf('Image folder: %s',hand.path_in))
                update_status('Please select images to analyse from the menu "File"')
                
                % Initialize a new session
                initialize_session
            end

        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function exit_program(~,~)
        % Delete temporary files
        delete_temporary_files(0,0,1)
        % Close all the windows
        close all force
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initialize_program
        % Initialize global variables
        hand.Version = '1.0 beta';
        hand.file_out_prefix = 'bgrem_';
        if ispref('background_removal','last_folder')
            hand.pathtemp = getpref('background_removal','last_folder');
            hand.path_in = getpref('background_removal','last_folder');
        else
            hand.pathtemp = pwd;
            hand.path_in = pwd;
        end
        hand.path_out = hand.path_in;
        hand.Use_tmp_file = false;
        hand.mem_safe = 0.8;
        % Built in
        hand.bytesPerElem = 4; % 4 for single, 8 for double
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initialize_session
        % This function initializes the global variable to a new session.
        hand.NImg = 0;
        hand.showing_im_i = 1;
        hand.showing_mod_i = 1;
        hand.NMod_saved = 0;
        
        % Epsilon for the automatic threshold
        hand.eps_auto_psi = 1e-4;
        hand.eps_auto_sigma = 1e-4;
        
        hand.im_caxis.active = false;
        hand.phi_caxis.active = false;
        % Checks
        hand.Check_imsel = false; % Images selected
        hand.Check_imload = false; % Images loaded into memory
        hand.Check_eigproc = false; % Eigenvalues evaluated
        hand.Check_modproc = false; % Modes evaluated
        % Figure positions
        hand.pos_spect = [.5 .7 .5 .3];
        hand.pos_psi = [.5 .4 .5 .3];
        hand.pos_status = [.5 .1 .5 .3];
        hand.pos_modes = [0.05 .05 .5 .9];
        
        % Random image
        show_initial_image
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function show_initial_image
        figure(fig)
        imagesc(magic(32)),colormap gray
        drawnow
        set(gca,'visible','off')
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function key_shortcut(~,data)
        % Handle the keyboard shortcut
        
        if strcmp(data.Key,'control')
            % Filter out the control key alone
            return
        end
        
        if ~isempty(data.Modifier) && strcmp(data.Modifier{1},'control') 
            switch data.Key
                case 'i'
                    select_images(0,0,'direct')
                case 'o'
                    select_images(0,0,'pattern')
                case 'l'
                    load_images_memory(0,0)
                case 'q'
                    exit_program(0,0)
                case 'r'
                    evaluate_spectrum(0,0)
                case 'm'
                    evaluate_modes(0,0)
                case 'a'
                    show_window(0,0,'rearrange')
                case 'b'
                    remove_background(0,0,'training')
                case 'p'
                    remove_background(0,0,'preview')
                case 't'
                    set_automatic_modes(0,0)
            end
        end
        
    end
end