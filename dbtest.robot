*** Settings ***
Library     DatabaseLibrary

*** Variables ***
${dbname}    projekti_laskutietokanta
${dbuser}    robotuser
${dbpass}    password 
${dbhost}    localhost
${dbport}    3306

*** Keywords ***
Make Connection
    Log To Console    ${dbpass}
    [Arguments]    ${dbtoconnect}
    Connect To Database    pymysql    ${dbtoconnect}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}

*** Tasks ***
Select Data From DB
    Make Connection    ${dbname}

    @{invoiceStatusList}=    Query    select * from invoiceStatus;

    FOR    ${element}    IN    @{invoiceStatusList}
        Log    ${element}
        Log    ${element}[0]
        Log    ${element}[1]
        
    END

    Disconnect From Database

*** Tasks ***
Insert Data to DB
    Make Connection    ${dbname}
    
    #insert ei toimi, sillä robotrolella ei ole käyttöoikeutta siihen 
    #grant insert on invoicestatus to robotrole;
    ${insertStmt}=    Set Variable    insert into invoicestatus (id, name) values (100, 'testi');
    Log To Console    ${insertStmt}
    Execute Sql String    ${insertStmt}

    Disconnect From Database