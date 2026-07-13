function tests = test_oracle_not_used_online
tests = functiontests(localfunctions);
end

function testOfflineOracleCannotEnterControllerOrPlantPath(testCase)
a=implementation_assumptions(); definitions=estimator_definitions(1e-4);
verifyFalse(testCase,a.oracle_online_allowed);
verifyFalse(testCase,definitions.oracle.online);

root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
online_roots={fullfile(root,'src','+zhou_ipmsm','+controller'), ...
    fullfile(root,'src','+zhou_ipmsm','+sim'), ...
    fullfile(root,'src','+zhou_ipmsm','+model')};
for folder=online_roots
    files=dir(fullfile(folder{1},'**','*.m'));
    for k=1:numel(files)
        text=lower(string(fileread(fullfile(files(k).folder,files(k).name))));
        verifyFalse(testCase,contains(text,"interval_f_oracle_offline"), ...
            "Offline oracle referenced by online file "+files(k).name);
        verifyFalse(testCase,contains(text,"calculate_f_interval_oracle"), ...
            "Offline oracle referenced by online file "+files(k).name);
    end
end
end
