*** Settings ***
Library    OperatingSystem
Library    String
Library    Collections
Library    DatabaseLibrary
Library    CSVLib
Library    validate.py
Library    SeleniumLibrary

*** Variables ***
${ORIGINPATH}    C:\\Users\\jvisa\\OneDrive\\Documents\\UiPath\\RPA-projekti
${TARGETPATH}    C:\\VSCode\\rpa-projekti\\CSVs

# Database variables
${dbname}    projekti_laskutietokanta
${dbuser}    robotuser
${dbpass}    password
${dbhost}    localhost
${dbport}    3306
${viitenumero}    1531439
${iban}    FI05 1234 5600 7891 01 

*** Keywords ***
Make Connection
    [Arguments]    ${dbtoconnect}
    Connect To Database    pymysql    ${dbtoconnect}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}


*** Tasks ***
Empty the CSV directory from previous files
    # Tyhjennetään työkansio ennen laskujen käsittelyä
    ${filecount}=    Count Files In Directory    ${TARGETPATH}
    Remove Files    ${TARGETPATH}/*.csv
    Log To Console    Removed ${filecount} files

*** Tasks ***
Copy the created CSVs from the UiPath folder to the target path
    # Kopioidaan UiPathin tuotokset robotin omaan työkansioon. Riippuen 
    Copy Files    ${ORIGINPATH}/*.csv    ${TARGETPATH}
    ${filecount}=    Count Files In Directory    ${TARGETPATH}
    Log To Console    Copied ${filecount} files

*** Tasks ***
Read CSV file to list
    Make Connection    ${dbname}
    ${outputHeader}=     Get File    ${TARGETPATH}/InvoiceHeaderData.csv
    ${outputRows}=    Get File    ${TARGETPATH}/InvoiceRowData.csv
    Set Global Variable    ${outputHeader}
    Set Global Variable    ${outputRows}
    Log    ${outputHeader}
    Log    ${outputRows}


*** Tasks ***
Viitenumeron validointi
    # Tämä täytyy päivittää toimimaan csv:n datalla. Tällä hetkellä käytössä kovakoodattu viitenumero. 
    ${tarkistus}=    Split String To Characters    ${viitenumero}
    Log To Console    ${tarkistus}

    ${listanViimeinen}=    Set Variable    ${tarkistus.__len__()}
    ${listanViimeinen}=    Evaluate    ${listanViimeinen} - 1
    Log To Console    ${listanViimeinen}

    ${viitenumeroVika}=    Get From List    ${tarkistus}    ${listanViimeinen}
    Remove From List    ${tarkistus}    -1
    Log To Console    "Listalta poistettu: " + ${tarkistus}
    Reverse List    ${tarkistus}
    Log To Console    ${tarkistus}
    ${i}=    Set Variable    1
    
    # Kerrotaan viitenumero vuorotellen 7:llä, 3:lla ja 1:llä ja tallennetaan uudet arvot listaan.
    FOR    ${index}    IN RANGE    ${tarkistus.__len__()}
        ${element}=    Get From List    ${tarkistus}    ${index}
    
        IF    ${i} == 4
            ${i}    Set Variable    1
        END

        IF    ${i} == 1
            ${laskettu}=    Evaluate    int(${element}) * ${7}
            Log    ${laskettu} + " (kerrottu 7:lla)"
        ELSE IF    ${i} == 2
            ${laskettu}=     Evaluate    int(${element}) * ${3} 
            Log    ${laskettu} + " (kerrottu 5:lla)"
        ELSE
            ${laskettu}=     Evaluate    int(${element}) * ${1}
            Log    ${laskettu} + " (kerrottu 1:lla)"
        END
        
        Set List Value     ${tarkistus}    ${index}    ${laskettu}
        ${i}=    Evaluate    ${i}+1 
    
    END

    Log To Console    ${tarkistus}
    
    # Lasketaan viitenumeron kerrotut arvot yhteen
    ${viitesumma}=    Set Variable    0
    FOR    ${index}    IN RANGE    ${tarkistus.__len__()}
        ${element}=    Get From List    ${tarkistus}    ${index}
        ${viitesumma}=    Evaluate    ${viitesumma} + int(${element})
        Log To Console    "Viitesumma: " + ${viitesumma}
    END
    # Pyöristetään viitenumeron summa lähimpään kymmeneneen ja tarvittaessa lisätään 10.
    ${viitesummaRound}=    Convert To Number    ${viitesumma}    -1
    IF    ${viitesummaRound} < ${viitesumma}
        ${viitesummaRound}=    Evaluate    ${viitesummaRound} + 10
    END
    Log To Console    ${viitesummaRound}

    #tarkistusnumeron luonti
    ${tarkistusnumero}=    Evaluate    ${viitesummaRound} - ${viitesumma}
    IF    ${tarkistusnumero} == 10
       ${tarkistusnumero}=    Set Variable    0
    END
    Log    "Tarkistenumero: " + ${tarkistusnumero}
    
    # Tarkistusnumeron tarkistus
    IF    ${viitenumeroVika} == ${tarkistusnumero}
        Log To Console    "Viitenumeron viimeinen: " ${viitenumeroVika}
        Log To Console    "Tarkistenumero: " ${tarkistusnumero}
        Log To Console    "Kaikki hyvin!"
    ELSE
        Log To Console    "Viitenumeron viimeinen: " ${viitenumeroVika}
        Log To Console    "Tarkistenumero: " ${tarkistusnumero}
        Log To Console    "Numeroissa häikkää."
        
    END



*** Tasks ***
IBANin validointi
    # Valmistellaan iban poistamalla mahdolliset välilyönnit
    ${iban}=    Remove String    ${iban}    ${SPACE}
    Log To Console    ${iban}
    # Jaeteaan iban kahteen, joista ensimmäisestä neljästä tehdään lista
    ${ibanFirstFour}=    Get Substring    ${iban}    0    4
    ${ibanFirstFour}=    Split String To Characters    ${ibanFirstFour}
    Log To Console    ${ibanFirstFour}
    
    # Muutetaan maatunnuskirjaimet vastaamaan numeroarvoja
    FOR    ${index}    IN RANGE    ${ibanFirstFour.__len__()}
        ${element}=    Get From List    ${ibanFirstFour}    ${index}   
        
        IF    '${element}' == 'A'
            Set List Value    ${ibanFirstFour}    ${index}    10
        END
        IF    '${element}' == 'B'
            Set List Value    ${ibanFirstFour}    ${index}    11
        END
        IF    '${element}' == 'C'
            Set List Value    ${ibanFirstFour}    ${index}    12
        END
        IF    '${element}' == 'D'
            Set List Value    ${ibanFirstFour}    ${index}    13
        END
        IF    '${element}' == 'E'
            Set List Value    ${ibanFirstFour}    ${index}    14
        END
        IF    '${element}' == 'F'
            Set List Value    ${ibanFirstFour}    ${index}    15
        END
        IF    '${element}' == 'G'
            Set List Value    ${ibanFirstFour}    ${index}    16
        END
        IF    '${element}' == 'H'
            Set List Value    ${ibanFirstFour}    ${index}    17
        END
        IF    '${element}' == 'I'
            Set List Value    ${ibanFirstFour}    ${index}    18
        END
        IF    '${element}' == 'J'
            Set List Value    ${ibanFirstFour}    ${index}    19
        END
        IF    '${element}' == 'K'
            Set List Value    ${ibanFirstFour}    ${index}    20
        END
        IF    '${element}' == 'L'
            Set List Value    ${ibanFirstFour}    ${index}    21
        END             
        IF    '${element}' == 'M'
            Set List Value    ${ibanFirstFour}    ${index}    22
        END                                                         
        IF    '${element}' == 'N'
            Set List Value    ${ibanFirstFour}    ${index}    23
        END              
        IF    '${element}' == 'O'
            Set List Value    ${ibanFirstFour}    ${index}    24
        END              
        IF    '${element}' == 'P'
            Set List Value    ${ibanFirstFour}    ${index}    25
        END              
        IF    '${element}' == 'Q'
            Set List Value    ${ibanFirstFour}    ${index}    26
        END              
        IF    '${element}' == 'R'
            Set List Value    ${ibanFirstFour}    ${index}    27
        END              
        IF    '${element}' == 'S'
            Set List Value    ${ibanFirstFour}    ${index}    28
        END              
        IF    '${element}' == 'T'
            Set List Value    ${ibanFirstFour}    ${index}    29
        END              
        IF    '${element}' == 'U'
            Set List Value    ${ibanFirstFour}    ${index}    30
        END              
        IF    '${element}' == 'V'
            Set List Value    ${ibanFirstFour}    ${index}    31
        END              
        IF    '${element}' == 'W'
            Set List Value    ${ibanFirstFour}    ${index}    32
        END              
        IF    '${element}' == 'X'
            Set List Value    ${ibanFirstFour}    ${index}    33
        END              
        IF    '${element}' == 'Y'
            Set List Value    ${ibanFirstFour}    ${index}    34
        END              
        IF    '${element}' == 'Z'
            Set List Value    ${ibanFirstFour}    ${index}    35
        END              
    END
    Log To Console    ${ibanFirstFour}

    ${ibanLast}=    Get Substring    ${iban}    4
    Log To Console    "Iban jäljelle jäänyt: " ${ibanLast}
    
    # Yhdistetään Ibanin numeroiksi muutettu alkuosa ibanin loppuun
    ${ibanFirstFour}=    Evaluate    "".join(${ibanFirstFour})
    ${ibanNew}=    Catenate    SEPARATOR=    ${ibanLast}    ${ibanFirstFour}
    Log To Console    ${ibanNew}
    
    # Suoritetaan jako ja tarkistetaan jakojäännös (tavoite 1)
    ${ibanCheck}=    Evaluate    int(${ibanNew}) % 97
    Log To Console    ${ibanCheck}

    IF    ${ibanCheck} == 1
        Log To Console    Iban toimii!
    ELSE
        Log To Console    EI TOIMI IBAN!!!!!
        
    END


# *** Tasks ***
# Create Dictionaries



#     ${value}=     Create List    CompanyName    ReferenceNumber    InvoiceDate    DueDate    CompanyCode    BankAccountNumber    AmountExclVAT    VATAmount    TotalAmount
#     # ${value}=     Create List    CompanyName;ReferenceNumber;InvoiceDate;DueDate;CompanyCode;BankAccountNumber;AmountExclVAT;VATAmount;TotalAmount
#     ${outputHeaderDict}=    Read Csv To Dictionary    ${TARGETPATH}/InvoiceHeaderData.csv   
#     Log To Console    'Keys: ' + ${outputHeaderDict.keys()}


