#Code Analyzer Report
$codeAnalyzerFiles = @("apexCodeAnalyzer.json","lwcCodeAnalyzer.json","auraCodeAnalyzer.json")
$sfdxCodeFilesLsit = @()
$addSfdxCode = @()
$body= @()
$sfdxCodeFilesCount = ""
$sfdxCodeError = 0
$errorProneStatus = "<br>"
foreach($tempFile  in $codeAnalyzerFiles )
{
    $filePath = ".\"+$tempFile 
    $sfdxCodeResponse = Get-Content $filePath | ConvertFrom-Json
    $sfdxCodeResult = $sfdxCodeResponse[0].result  
    if(($($sfdxCodeResult.Count) -ne 0) -and !($sfdxCodeResult.Contains("No rule violations found")))
    {
        $sfdxCodeFilesLsit += $tempFile 
        $sfdxCodeFilesCount = $($sfdxCodeResult.Count)
    }
}
if($sfdxCodeFilesCount -gt 0) {
$addSfdxCode += @"
<html>
    <body> 
        <h2>Salesforce Code Analyzer Report</h2>
        <p><b>Warning :</b> Below are the issues found in the code. Kindly review and fix it to maintain code qaulity and refer the below mentioned <b>Error Reference Url</b> column in the table for the standard steps to be followed while coding.</p>
            <table>
                <colgroup>
                    <col />
                    <col />
                    <col />
                    <col />
                    <col />
                    <col />
                </colgroup>
                <tr>
                    <th>FileName</th>
                    <th>Message</th>
                    <th>Line</th>
                    <th>Category</th>
                    <th>RuleName</th>
                    <th>Error Reference Url</th>
                </tr>
"@
}
$categotySorted = @("Error Prone","Security","Best Practices","Performance","Code Style")
foreach($codeFile in $sfdxCodeFilesLsit )
{
    $filePath = ".\"+$codeFile
    $sfdxCodeResponse = Get-Content $filePath | ConvertFrom-Json
    $sfdxCodeResult = $sfdxCodeResponse[0].result
    $engineName = ""
    if($sfdxCodeResponse.status -eq 0)
    {
        foreach($sfdxCode in $sfdxCodeResult)
        {
            $engineName = $sfdxCode.engine
            $sfdxFile = $sfdxCode.fileName
            $sfdxName = $sfdxFile.Split("/")
            $sfdxCodeCount = $($sfdxName.Count - 1)
            $sfdxCodeName = $sfdxName[$sfdxCodeCount]
            $codeViolations = $sfdxCode.violations
            if($engineName -eq "pmd") {
                $codeViolations = $codeViolations | Sort-Object { $categotySorted.IndexOf($_.category) }
            } else {
                $codeViolations = $codeViolations | Sort-Object category
            }

            foreach($codeViolate in $codeViolations)
            {
               # if($($codeViolate.category) -eq "Error Prone") {
                   # $sfdxCodeError = 1
                   # $errorProneStatus = "<p><b>Error :</b> Pull request failed due to <b>Error Prone</b> issue found in the code please fix it and then try merge again. </p>"
               # }

                if($sfdxCodeName -eq "-") {
                    $addSfdxCode += @"
                    <tr>
"@
                }
                else
                {
                    $addSfdxCode += @"
                    <tr>
                        <td rowspan='$($codeViolations.Count)'valign='top'>$sfdxCodeName</td>
"@
                }
                $addSfdxCode += @"
                <td>$($codeViolate.message)</td>
                <td>$($codeViolate.line)</td>
                <td>$($codeViolate.category)</td>
                <td>$($codeViolate.ruleName)</td>
                <td><a href='$($codeViolate.url)'>$($codeViolate.url)</a></td>
            </tr>
"@
                $sfdxCodeName = "-"
            }
        } 

    } 
}
if($sfdxCodeFilesCount -gt 0) {
$addSfdxCode += @"
        </table>
        $errorProneStatus
    </body>
</html>       
"@
}
$body += $addSfdxCode

#Deployment Details
$output = Get-Content .\deploymentOut.json | ConvertFrom-Json
$depStatus = $($output[0].result.status)
$copmponentSuccess = $output[0].result.details.componentSuccesses
$copmponentFailures = $output[0].result.details.componentFailures
$successCount = $copmponentSuccess.Count
$failureCount = $copmponentFailures.Count
for($i=0; $i -lt $successCount; $i++){
    $output[0].result.details.componentSuccesses[$i].success = "Success"
}
for($i=0; $i -lt $failureCount; $i++){
    $output[0].result.details.componentFailures[$i].success = "Failed"
}

$branchName = $env:GIT_TARGET_BRANCH_NAME
$sandboxName = $branchName.Split('/')[1]

$removeableField = @("CustomField","WebLink","ListView","BusinessProcess","ValidationRule","CompactLayout","RecordType","FieldSet","ListView")
$body += @"
<html>
<body> 
    <h2>Deployment Details</h2>
    <p><b>Deployment Status :</b> $($output[0].result.status)</p>
    <p><b>Created BY :</b> $($output[0].result.createdByName)</p>
    <p><b>Total Number of Components :</b> $($output[0].result.numberComponentsTotal)</p>
    <p><b>Number of Components Deployed :</b> $($output[0].result.numberComponentsDeployed)</p>
    <p><b>Number of Components Failed :</b> $($output[0].result.numberComponentErrors)</p>
    <p><b>Last Modified Date :</b> $($output[0].result.lastModifiedDate)</p>
    <p><b>Org Name :</b> $sandboxName</p>
    <p><b>Source Branch Name :</b> $env:GIT_SOURCE_BRANCH_NAME</p>
    <p><b>Target Branch Name :</b> $env:GIT_TARGET_BRANCH_NAME</p>
    <h2>Note: </h2> 
    <p><b>******Object count includes fields, listview, validation and so on******</b></p> 
</body>
</html>
"@

$header = @"
<style>BODY{font-family: Arial; font-size: 13pt; color:black;}
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; }
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black; }
</style>
"@

Write-Host "Deployment Status : $($output[0].result.status)"
Write-Host "Created Date : $($output[0].result.createdDate)"
Write-Host "Created BY : $($output[0].result.createdByName)"
Write-Host "Total Number of Components : $($output[0].result.numberComponentsTotal)"
Write-Host "Number of Components Deployed : $($output[0].result.numberComponentsDeployed)"
Write-Host "Last Modified Date : $($output[0].result.lastModifiedDate)"
if($depStatus -eq "Succeeded")
{
    $body += "<br><h2>Successful Component Details</h2><br>"
    $JSONResult = $output | Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentSuccesses 
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File Name";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}} | Sort-Object success > .\mailResult.txt
    $removeUnwantedField = ""
    $removeXml = $JSONResult | Select-Object | Where-Object { $_.fullName -ne "package.xml" }
    $tempJSONResult = $removeXml
    foreach($field in $removeableField){
        $removeUnwantedField = $tempJSONResult | Select-Object | Where-Object { $_.componentType -ne "$field" }
        $tempJSONResult = $removeUnwantedField
    }
    $queryBody = $removeUnwantedField | Select-Object  @{Name="Component Type";Expression={$_.componentType}},@{Name="File Name";Expression={$_.fileName}},@{Name="Full Name";Expression={$_.fullName}},@{Name="Status";Expression={$_.success}} | Sort-Object success | ConvertTo-Html -Head $header
    $body += $queryBody
    $subject =  "Successful Validation"
}
else 
{
    $body += "<br><h2>Failure Component Details</h2><br>"
    $JSONResult = $output |Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentFailures 
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File Name";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success};}, @{Name="Failure Reason";Expression={$_.problem};} | Sort-Object success > .\mailResult.txt
    $body += $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File Name";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}}, @{Name="Failure Reason";Expression={$_.problem};} | Sort-Object success | ConvertTo-Html -Head $header
    if($($output[0].result.numberComponentsDeployed) -ne 0)
    {
        $body += "<br><h2>Successful Component Details</h2><br>"
    }
    $JSONResult = $output | Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentSuccesses 
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File Name";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}} | Sort-Object success > .\mailResult.txt
    $removeUnwantedField = ""
    $removeXml = $JSONResult | Select-Object | Where-Object { $_.fullName -ne "package.xml" }
    $tempJSONResult = $removeXml
    foreach($field in $removeableField){
        $removeUnwantedField = $tempJSONResult | Select-Object | Where-Object { $_.componentType -ne "$field" }
        $tempJSONResult = $removeUnwantedField
    }
    $queryBody = $removeUnwantedField | Select-Object  @{Name="Component Type";Expression={$_.componentType}},@{Name="File Name";Expression={$_.fileName}},@{Name="Full Name";Expression={$_.fullName}},@{Name="Status";Expression={$_.success}} | Sort-Object success | ConvertTo-Html -Head $header
    $body += $queryBody
    $subject =  "Failure Deployment"           
}

$username = $env:USERNAME  #$($env:userName)  # email using to send the attachment
$password = $env:PASSWORD  # password -> gzgavgcrqsmochdo 16 character app password created in Google account settings for the above email
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

$sendAddress = "$env:gitAuthorEmail"

$to     =  $sendAddress
$Cc   =  "aeroadithiyan3@gmail.com"
$from    =  $env:USERNAME
$mail = New-Object System.Net.Mail.Mailmessage $from, $to, $subject, $body
$mail.cc.Add($Cc)
$mail.IsBodyHTML=$true
$server = "smtp.office365.com"
$port   = 587
$smtp = New-Object System.Net.Mail.SMTPClient $server,$port
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Management.Automation.PSCredential ($username,$securePassword)
try { 

 $smtp.send($mail)

}

catch { 

 Write-Host "Error occured : $_"

}

echo "gitCodeAnalyzer=$sfdxCodeError" >> $env:GITHUB_ENV
echo "status=$depStatus" >> $env:GITHUB_ENV