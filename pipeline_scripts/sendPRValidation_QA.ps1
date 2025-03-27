$codeAnalyzerFiles = @("apexCodeAnalyzer.json","lwcCodeAnalyzer.json","auraCodeAnalyzer.json")
$sfdxCodeFilesLsit = @()
$addSfdxCode = @()
$gitJsonBody = @()
$sfdxCodeFilesCount = 0
$sfdxCodeResultCount = 0
$codeIteration = 0
$gitJsonBodyIndex = 0
$gitJsonBodyList = [Ordered]@{}
$multipleComment = $false
#$sfdxCodeError = 0
$errorProneStatus = "<br>"
foreach($tempFile  in $codeAnalyzerFiles)
{
    $filePath = ".\"+$tempFile 
    $sfdxCodeResponse = Get-Content $filePath | ConvertFrom-Json
    $sfdxCodeResult = $sfdxCodeResponse[0].result 
    $sfdxCodeResultCount += $sfdxCodeResult.Count 
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
$gitTable = @"
<html>
    <body> 
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
                #     $sfdxCodeError = 1
                #     $errorProneStatus = "<p><b>Error :</b> Pull request failed due to <b>Error Prone</b> issue found in the code please fix it and then try merge again. </p>"
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
            $codeIteration += 1
            if($($addSfdxCode.Count) -gt 200)  
            {
                $addSfdxCode += @"
        </table>
    </body>
</html> 
"@
                $gitJsonBodyList.add($gitJsonBodyIndex,$addSfdxCode)
                $addSfdxCode = @()
                $addSfdxCode += $gitTable
                $multipleComment = $true
                $gitJsonBodyIndex += 1
            } elseif(($sfdxCodeResultCount -eq $codeIteration) -and $multipleComment) {
                $gitJsonBodyList.add($gitJsonBodyIndex,$addSfdxCode)
                
            }
        } 

    } 
}
if($sfdxCodeFilesCount -gt 0) {
$gitJsonBody += $addSfdxCode 
$gitJsonBody += @"
        </table>
        $errorProneStatus
    </body>
</html>       
"@
}

#Deployment Details
$output = Get-Content .\deploymentOut.json | ConvertFrom-Json
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
$gitDepJsonBody = @()
$gitFailedBody = @()
$removeableField = @("CustomField","WebLink","ListView","BusinessProcess","ValidationRule","CompactLayout","RecordType","FieldSet","ListView")
$gitDepJsonBody += @"
<html>
<body> 
    <h2>Deployment Details</h2>
</body>
</html>
"@
$githeader = @" 
"@
$gitJSONResult = $output | Select-Object -expand  result
$gitDepJsonBody += $gitJSONResult | Select-Object  @{Name="Deployment Status";Expression={$_.status}},@{Name="Number of Components Deployed";Expression={$_.numberComponentsDeployed}},@{Name="Number of Components Failed";Expression={$_.numberComponentErrors}} | ConvertTo-Html -Head $githeader
$gitDepJsonBody +=  "<p><b>Note:</b> Object count includes fields, listview, validation, and so on. </p>"
$gitDepJsonBody += "<br><h2>Component Details</h2><br>"
if($output[0].result.status -eq "Succeeded")
{ 
    $JSONResult = $output | Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentSuccesses 
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}} | Sort-Object success > .\mailResult.txt
    $removeUnwantedField = ""
    $removeXml = $JSONResult | Select-Object | Where-Object { $_.fullName -ne "package.xml" }
    $tempJSONResult = $removeXml
    foreach($field in $removeableField){
        $removeUnwantedField = $tempJSONResult | Select-Object | Where-Object { $_.componentType -ne "$field" }
        $tempJSONResult = $removeUnwantedField
    }
    $gitDepJsonBody += $removeUnwantedField | Select-Object  @{Name="Component Type";Expression={$_.componentType}},@{Name="File";Expression={$_.fileName}},@{Name="Full Name";Expression={$_.fullName}},@{Name="Status";Expression={$_.success}} | Sort-Object success | ConvertTo-Html -Head $githeader
}
else 
{
    $JSONResult = $output | Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentSuccesses 
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}} | Sort-Object success > .\mailResult.txt
    $removeUnwantedField = ""
    $removeXml = $JSONResult | Select-Object | Where-Object { $_.fullName -ne "package.xml" }
    $tempJSONResult = $removeXml
    foreach($field in $removeableField){
        $removeUnwantedField = $tempJSONResult | Select-Object | Where-Object { $_.componentType -ne "$field" }
        $tempJSONResult = $removeUnwantedField
    }
    $gitFailedBody += $removeUnwantedField
    $JSONResult = $output |Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentFailures  
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}}, @{Name="Failure Reason";Expression={$_.problem}} | Sort-Object success > .\mailResult.txt
    $gitFailedBody += $JSONResult
    $gitDepJsonBody += $gitFailedBody | Select-Object  @{Name="Component Type";Expression={$_.componentType}},@{Name="File";Expression={$_.fileName}},@{Name="Full Name";Expression={$_.fullName}},@{Name="Status";Expression={$_.success}}, @{Name="Failure Reason";Expression={$_.problem}} | Sort-Object success | ConvertTo-Html -Head $githeader

}
$pullRequestID = $env:GITHUB_REF -replace 'refs/pull/(\d+)/merge','$1'
$githeader =@{
    Authorization = "token $env:GIT_TOKEN"
    Accept = "application/vnd.github.v3+json"
}
$jsonBodyCount = $gitJsonBodyList.Count
if($jsonBodyCount -eq 0) {
    $gitJsonBody += $gitDepJsonBody
    $gitbody = @{
        body = "$gitJsonBody"
    } | ConvertTo-Json
    $pullReqStatusUrl = "$env:GIT_SERVER_URL$env:GITHUB_REPOSITORY/issues/$pullRequestID/comments"
    Write-Host "pullReqStatusUrl : $pullReqStatusUrl"
    $pullReqStatusResponse = Invoke-RestMethod -Uri $pullReqStatusUrl -Headers $githeader -Method Post -Body $gitbody
} else {
    $gitJsonBodyList.add(201,$gitDepJsonBody)
    Write-Host "No Of Comments Generated : $($gitJsonBodyList.Count)"
    foreach ($gitMulBody in $gitJsonBodyList.GetEnumerator() )
    {
        $gitbody = @{
            body = "$($gitMulBody.Value)"
        } | ConvertTo-Json
        $pullReqStatusUrl = "$env:GIT_SERVER_URL$env:GITHUB_REPOSITORY/issues/$pullRequestID/comments"
        $pullReqStatusResponse = Invoke-RestMethod -Uri $pullReqStatusUrl -Headers $githeader -Method Post -Body $gitbody
    }
}
