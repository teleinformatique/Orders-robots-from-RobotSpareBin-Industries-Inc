*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${True}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    ${orders_list}=    Download order csv file
    FOR    ${row}    IN    @{orders_list}
        Wait Until Keyword Succeeds    3x    2s    Fill form order    ${row}
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Input another order
        Close the annoying modal
    END
    Create a ZIP file of receipt PDF files

    [Teardown]    Close All Browsers


*** Keywords ***
Open the robot order website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Download order csv file
    Download    https://robotsparebinindustries.com/orders.csv    ${OUTPUT_DIR}${/}orderes.csv    overwrite=${True}
    ${orders_list}=    Read table from CSV    ${OUTPUT_DIR}${/}orderes.csv    header=${True}
    RETURN    ${orders_list}

Fill form order
    [Arguments]    ${order}
    Wait Until Page Contains    Build and order your robot!
    Select From List By Value    id:head    ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    id:preview
    Click Button    id:order
    Wait Until Page Contains    Receipt

Close the annoying modal
    Click Button    OK

Fill the from csv data
    ${orders_list}=    Read table from CSV    ${OUTPUT_DIR}${/}orderes.csv    header=${True}
    FOR    ${order}    IN    @{orders_list}
        Wait Until Keyword Succeeds    3x    2s    Fill form order    ${order}
        Input another order
        Close the annoying modal
    END

Input another order
    Click Button When Visible    id:order-another

Store the receipt as a PDF file
    [Arguments]    ${order number}
    Log    ${order number}
    ${receipt html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt html}    ${OUTPUT_DIR}${/}receipts${/}${order number}.pdf
    RETURN    ${order number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order number}
    Screenshot    id:robot-preview-image    filename=${OUTPUT_DIR}${/}receipts${/}${order number}.png
    RETURN    ${order number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${OUTPUT_DIR}${/}receipts${/}${pdf}
    Add Watermark Image To Pdf    ${OUTPUT_DIR}${/}receipts${/}${screenshot}    ${OUTPUT_DIR}${/}receipts${/}${pdf}
    Remove File    ${OUTPUT_DIR}${/}receipts${/}${screenshot}
    Close Pdf

Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip
