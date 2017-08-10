Configuration Crypto_FSRM {
    param(
        [Parameter(Mandatory=$True)]
        [String]$ScriptSource,

        [Parameter(Mandatory=$true)]
        [String]$CredAsset,

        [Parameter(Mandtory=$True)]
        [String]$ScriptDest,

        [Parameter(Mandtory=$True)]
        [String]$MailServer,

        [Parameter(Mandtory=$True)]
        [String]$AdminEmail,

        [Parameter(Mandtory=$True)]
        [String]$FromEmail,

        [Parameter(Mandtory=$True)]
        [String]$TemplateName,

        [Parameter(Mandtory=$True)]
        [String]$ScreenPath
    )


    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName AzureAutomationAuthoringToolkit
    Import-DscResource -ModuleName xComputerManagement
    Import-DSCResource -ModuleName FSRMDsc

    $servicePrincipalConnection=Get-AutomationConnection -Name 'AzureRunAsConnection'     
 
    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
        -ErrorAction 'Continue'

    $PSCreds = Get-AutomationPSCredential –Name $CredAsset -ErrorAction Continue

    Node CryptoCanary
    
    {    
        File ScriptFolder
        {
            Type = 'Directory'
            Ensure = "Present"
            DestinationPath = $ScriptDest
        }

        File DownloadCanary
        {
            Ensure = 'Present'
            Credential = $PSCreds
            SourcePath = $ScriptSource
            DestinationPath = $ScriptDest
            Type = "File"
            #Recurse = $true
            #Force = $true
        }
    
        xScheduledTask UpdateCanary
        {
            Ensure             = 'Present'
            TaskName           = "UpdateCanary"
            ActionExecutable   = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ActionArguments    = "-File `"$ScriptDest\CryptoUpdate.ps1`""
            ScheduleType       = 'Once'
            RepeatInterval     = '00:00:15'
            RepetitionDuration = '00:00:16'
            Enable             = $true  
        }
        
        WindowsFeature FSRM
        {
            Name = "FS-Resource-Manager"
            Ensure = "Present"
            IncludeAllSubFeature = $true
        }

        FSRMSettings FSRMSettings
        {
            Id = 'Default'
            SmtpServer = $MailServer
            AdminEmailAddress = $AdminEmail
            FromEmailAddress = $FromEmail
            CommandNotificationLimit = 90
            EmailNotificationLimit = 90
            EventNotificationLimit = 90
        }

        FSRMFileScreenTemplate CreateTemplate
        {
            Name = $TemplateName
            Description = 'Template for all files to update in the Crypto Canary'
            Ensure = 'Present'
            Active = $true
            IncludeGroup = 'CryptoGroup'
        }

        FSRMFileScreen CreateScreen
        {
            Path = $ScreenPath
            Description = 'FileScreen for warning of crypto based files'
            Ensure = 'Present'
            Active = $true
            IncludeGroup = 'CryptoGroup'
            Template = $TemplateName
        }

        FSRMFileScreenTemplateAction SendEmail
        {
            Name = $TemplateName
            Ensure = 'Present'
            Type = 'Email'
            Subject = 'Unauthorized file matching [Violated File Group] file group detected'
            Body = 'The system detected that user [Source Io Owner] attempted to save [Source File Path] on [File Screen Path] on server [Server]. This file matches the #Violated File Group] file group which is not permitted on the system.'
            MailCC = $AdminEmail
            MailTo = '[Source Io Owner Email]'
            DependsOn = '[FSRMFileScreenTemplate]CreateTemplate'
        }      
    }       
}