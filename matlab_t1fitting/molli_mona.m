%% add path
addpath("functions");
warning('off')
pwd_path = pwd;
%% MOLLI fitting
MOLLI_REGISTER_FILES = dir('../data/MOLLI_pre_dataset/test_mat/*.mat');
MOLLI_NATIVE_FOLDER = '../data/MOLLI_original';
label = '../data/MOLLI_pre_dataset/test_t1SDerr';
mkdir(label)

nworker = 10
myCluster = parcluster('local');
parpool(myCluster, nworker)
parfor j = 1:length(MOLLI_REGISTER_FILES)
    name = MOLLI_REGISTER_FILES(j).name;
    subjectid = extractBefore(name, '_MOLLI'); 
    slice = str2num(name(end-4));
    disp(subjectid)
    register_x = load(strcat(MOLLI_REGISTER_FILES(j).folder, '/', MOLLI_REGISTER_FILES(j).name ));
    x = load(strcat(MOLLI_NATIVE_FOLDER, '/', subjectid, '_MOLLI.mat'));
    
    contour = x.contour2_pre{slice};
    % estimate the center and extent of LV
    center = mean(contour.epi, 1);
    diameter =  max(contour.epi, [],  1) - min(contour.epi, [],  1);
    
    % build data structure
    data = struct;
    orig_vols = squeeze(x.volume_pre(:, :, slice, :));
    regi_vols = register_x.img;
%     compute the registration volume
    data.frames = regi_vols;
    data.tvec = squeeze(x.tvec_post(slice, :));
    
    % fitting configurations
    configs = struct;
    configs.stype = 'MOLLI';

    configs.center = center; 
    configs.diameter = diameter;
    configs.alpha = 1.3; % bounding box size = 1.3 x LV extent
    
    % Least square fitting
    configs.type = 'Gaussian';
    % if exist(sprintf("%s/MOLLI_%s_%d.mat", label, subjectid, slice), 'file') == 2
    %     fprintf("Subject %s Slice %d exist. \n", subjectid, slice);
    %     continue
    % end
    [pmap, sd, null_index, S, areamask] = mestimation_abs(data, configs);

    fd = {data, pmap, sd, contour, null_index, S, areamask};
    parsave(sprintf("%s/MOLLI_%s_%d.mat", label, subjectid, slice), fd);
    fprintf("Subject %s Slice %d. \n", subjectid, slice); 
    % figure, imagesc(S')
    % saveas(gcf, sprintf("%s/MOLLI_test_%s_%d.png", label, subjectid, slice))
    % close gcf

end

