# CryptoCanaryDSC
Building off of a script created for the FSRM Crypto Canary to utilize DSC.

Origonal PS Script can be found here. https://github.com/nexxai/CryptoBlocker

## Modules

All modules required to run this VIA Azure Automation can be found on the PowerShell Gallery.

I have included ZIP files of these modules that are current as of 8/10/2017.

## CryptoUpdate.ps1

This script is the bread and butter for you. This does all of the updating for the group.

I recomend keeping the timer at a 15 minute schedule. It is very light and it is good to knwo you are up to date.

You can change this to meet your needs.

## FSRMCrypto.ps1

This is the DSC file to ensure that you are up to date. This creates a schedule based off the CryptoUpdate.ps1 script.

Using the parameters you configure you have the ability to define where and how everything is configured and change on the fly.

I have this script pulling from the source in an Azure FileShare, you may have a different source. Please be sure to add your source
in order to copy the script over from the central script store.