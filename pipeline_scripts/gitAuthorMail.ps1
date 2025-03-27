# Convert GIT_TOKEN into Base64 for Authorization header
$pat = $env:GIT_TOKEN
$header = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)")) }

# Get the commit ID from GitHub context
$commitID = $env:GITHUB_SHA

# Prepare the GitHub API URL
$mergeCommitsUrl = "$env:GIT_SERVER_URL$env:GITHUB_REPOSITORY/commits/$commitID"
Write-Host "$mergeCommitsUrl"
$mergeCommitsResponse = Invoke-RestMethod -Uri $mergeCommitsUrl -Headers $header -Method Get 
$commitAuthorName = $mergeCommitsResponse.author.login

Write-Host "Commit Author Name: $commitAuthorName"

# Get the commits by the same author
$commitUrl = "$env:GIT_SERVER_URL$env:GITHUB_REPOSITORY/commits?author=$commitAuthorName&per_page=100"
$commitResponse = Invoke-RestMethod -Uri $commitUrl -Headers $header -Method Get 
$commitCount = $commitResponse.Length

$email = ""
for ($i = 0; $i -lt $commitCount; $i++) {
    $authorName = $commitResponse[$i].author.login
    $authorEmail = $commitResponse[$i].commit.author.email

    if (($commitAuthorName -eq $authorName) -and (!($authorEmail.Contains('noreply')))) {
        $email = $commitResponse[$i].commit.author.email
        break
    }
}

if ([string]::IsNullOrEmpty($email)) {
    $email = "adithiyan@minusculetechnologies.com"
}

Write-Host "Author Email: $email" 
echo "gitAuthorEmail=$email" >> $env:GITHUB_ENV
# $email | Out-File -Append -FilePath $env:GITHUB_ENV
        