% ------------------------------------------------------------------------------------
%---------------  Extraction of EDUCAT newsletter subscription ---------------
% ------------------------------------------------------------------------------------



% delaration of country question
country.id= [769:773];
country.name= ["Belgium", "France", "Netherlands", "UK", "Others"];

% create filename
filename =[datestr(now,'yyyy-mm-dd HH-MM')   '_EDUCAT_newsletter_extract.xlsx'];
filename = fullfile(pwd,filename);
i=0;
while exist(filename, 'file') == 2
    i = i+1;
    filename =[datestr(now,'yyyy-mm-dd HH-MM')   '_EDUCAT_newsletter_extract_V' int2str(i) '.xlsx'];
    filename = fullfile(pwd,filename);
end

%% Connection to the database

%             if isfile("../jdbc/mysql-connector-java-8.0.18.jar")
%                 javaclasspath("../jdbc/mysql-connector-java-8.0.18.jar");
%             elseif isfile("../mysql-connector-java-8.0.18/mysql-connector-java-8.0.18.jar")
%                 % legacy jdbc location
%                 javaclasspath("../mysql-connector-java-8.0.18/mysql-connector-java-8.0.18.jar");
%             else
%                 error("JDBC MySQL Connector not found, please download the connector from https://dev.mysql.com/downloads/connector/j/ and extract it in the 'jdbc' directory. Note: the mysql-connector-java-8.0.18.jar musn't be placed in a subdirectory, but directly in the root of the jdbc directory.");
%             end
%%

databaseName = "educat";
username = "analyst";
disp([' EDUCAT DB username: ' char(username)]);
if isfile("password.mat")
    load password.mat password;
end
if ~exist('password','var')
    password = input(' EDUCAT DB password: ','s');
    store_password = input(' store this password (Y/N): ','s');
    if store_password == "Y" || store_password == "y" || store_password == "yes"
        save password.mat password;
        warning off backtrace;
        warning("Password saved to 'password.mat' file");
        warning on backtrace;
    end
else
    disp(' EDUCAT DB password (retrieved from file)');
end

jdbcDriver = "com.mysql.cj.jdbc.Driver";
server = "jdbc:mysql://clouddb.myriade.be:20100/";


conn = database(databaseName, username, password, jdbcDriver, server);
%% Get newsletter subscription for each country

for i = 1 : length(country.id)
    sqlquery = ['SELECT `submissions`.`id`, '...
        '               IF(`t`.`answer_id`= 758, 1,0) AS `newsletter`, '...
        '               TRIM(`t2`.`value`) AS `First name`, '...
        '               TRIM(`t3`.`value`) AS `Last name`, '...
        '               TRIM(`t4`.`answer_id`)AS `Country`, '...
        '               TRIM(`t5`.`value`) AS `Company` '...
        ' FROM `submissions` '...
        ' INNER JOIN ( '...
        '               SELECT `submission_answers`.`submission_id`,`submission_answers`.`answer_id` '...
        '               FROM `submission_answers` '...
        '               INNER JOIN `submissions` '...
        '                  ON `submission_answers`.`submission_id` = `submissions`.`id`  '...
        '               WHERE (`submission_answers`.`question_id` = 260) '...
        ' ) AS `t` '...
        '      ON `submissions`.`id` = `t`.`submission_id` '...
        ' INNER JOIN ( '...
        '               	SELECT `submission_answers`.`submission_id`, '...
        '                                `submission_answers`.`value` '...
        '                  FROM `submission_answers` '...
        '               	INNER JOIN `submissions` '...
        '                      ON `submission_answers`.`submission_id` = `submissions`.`id`  '...
        '               	WHERE (`submission_answers`.`question_id` = 262 AND `submission_answers`.`answer_id` = 763) '...
        '   ) AS `t2` '...
        ' ON `submissions`.`id` = `t2`.`submission_id` '...
        ' INNER JOIN ( '...
        '               SELECT `submission_answers`.`submission_id`, '...
        '                             `submission_answers`.`value` '...
        '               FROM `submission_answers` '...
        '               INNER JOIN `submissions` '...
        '               	ON `submission_answers`.`submission_id` = `submissions`.`id`  '...
        '               WHERE (`submission_answers`.`question_id` = 262 AND `submission_answers`.`answer_id` = 762) '...
        '  ) AS `t3` '...
        ' ON `submissions`.`id` = `t3`.`submission_id` '...
        ' INNER JOIN ( '...
        '               	SELECT `submission_answers`.`submission_id`, `submission_answers`.`answer_id`,`submission_answers`.`value` '...
        '               	FROM `submission_answers` '...
        '                  INNER JOIN `submissions` '...
        '                      ON `submission_answers`.`submission_id` = `submissions`.`id`  '...
        '                  WHERE (`submission_answers`.`question_id` = 263 AND (`submission_answers`.`answer_id` BETWEEN 769 AND 773)) '...
        ' ) AS `t4` '...
        ' ON `submissions`.`id` = `t4`.`submission_id` '...
        ' LEFT JOIN ( '...
        '               	SELECT `submission_answers`.`submission_id`, '...
        '                                 `submission_answers`.`value` '...
        '               	FROM `submission_answers` '...
        '               	INNER JOIN `submissions` '...
        '                       ON `submission_answers`.`submission_id` = `submissions`.`id`  '...
        '               	WHERE (`submission_answers`.`question_id` = 262 AND `submission_answers`.`answer_id` = 766) '...
        ' ) AS `t5` '...
        ' ON `submissions`.`id` = `t5`.`submission_id`;'];
    
    extract = select( conn,sqlquery);
    % Validation of emailaddresses
    
    sqlquery = ['SELECT `submission_answers`.`submission_id`, '...
        '                                 `submission_answers`.`value` '...
        '               	FROM `submission_answers` '...
        '               	FULL OUTER JOIN `submissions` '...
        '                       ON `submission_answers`.`submission_id` = `submissions`.`id`  '...
        '               	WHERE (`submission_answers`.`question_id` = 262 AND `submission_answers`.`answer_id` = 766) ;'];
    extractCategories = select( conn,sqlquery);
    %% Fill categories with descriptions
    
    for j=1: numel(extractCategories.id)
        id = str2double(extract.category) ==str2double(extractCategories.id(j));
        extract.category(id) = (extractCategories.category(j));
    end
    %%
    
%     rgx = '^[a-zA-Z0-9\._]+\@[a-zA-Z0-9\.\-]+\.[a-zA-Z]+$';
%     ValidEmail = regexp(extract.Email,rgx);
%     extract.ValidEmail(1: length(extract.Email)) ="nok";
%     extract.ValidEmail( cellfun(@(x) isequal(x,1),ValidEmail)) = "ok";
%     % Write to sheet
%     
%     writetable(extract,filename,'Sheet',country.name(i),'Range','A1')
end