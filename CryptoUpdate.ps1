$FileGroupExist = (get-fsrmfilegroup -name "CryptoGroup")

if ($FileGroupExist -eq $true) {
        Set-FsrmFileGroup -Name "CryptoGroup" -IncludePattern @((Invoke-WebRequest -Uri "https://fsrm.experiant.ca/api/v1/get" -UseBasicParsing).content `
         | convertfrom-json | ForEach-Object {$_.filters}) 
    } Else {
        New-FsrmFileGroup -Name "CryptoGroup" -IncludePattern @((Invoke-WebRequest -Uri "https://fsrm.experiant.ca/api/v1/get" -UseBasicParsing).content `
         | convertfrom-json | ForEach-Object {$_.filters}) 
    }